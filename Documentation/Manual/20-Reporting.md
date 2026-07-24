# 20 — Reporting, Excel & PDF Export

[← Manual Index](00-Index.md)

---

## Overview

The reporting subsystem builds structured **reports** from a parsed FCPXML document and exports them to an **`.xlsx` workbook** (via XLKit) and/or a **`.pdf` document** (via CoreGraphics). A report is assembled from independent **sections** (role inventory, markers, keywords, titles & generators, transitions, Non-Std Effects & Templates, Video & Audio Effects, speed-change effects, summary, media summary). In Excel, each section becomes one or more worksheet tabs; in PDF, each section becomes one or more content pages with a cover page and dynamic table of contents.

Everything lives under **`FinalCutPro.FCPXML`**:

- **buildReport(options:scope:onPhaseStarted:)** — convenience entry point on a parsed document.
- **ReportBuilder** — assembles a **Report** from a document or a single **Project**.
- **ReportOptions** — selects which sections to include, plus project filter, media base URL, role display preference, cover sheet, role exclusions, disabled-clip filtering, column exclusions, **timecodeFormat**, **mediaResolutionPolicy**, **mediaSummaryDistinguishProxyAndOriginal**, optional **copyrightLabel**, **includeMarkersOutsideClipBoundaries**, and **protectSheets** (Excel edit lock).
- **ReportTimecodeFormat** — how timeline time values appear in workbook/PDF cells (`HH:MM:SS:FF`, Frames, Feet+Frames, `HH:MM:SS`).
- **Report** — the assembled value type (one optional property per section, plus resolved column exclusions, `timecodeFormat`, `copyrightLabel`, and `protectSheets`).
- **ReportBuildPhase** — content phases in product / workbook order; use `enabledPhases(for:)` for GUI progress bars.
- **ReportColumn** — logical columns that can be omitted globally at export (Excel and PDF).
- **ReportExcelExport** — turns a `Report` into an XLKit `Workbook` or writes it to disk (honours `protectSheets`).
- **ReportPDFExport** — turns a `Report` into PDF `Data` or writes a multi-page `.pdf` file (ignores `protectSheets`).

All **build** APIs are **async**. PDF export is **synchronous** once a `Report` exists.

**Project-once Projection:** When Role Inventory, Markers, Keywords, Titles & Generators, Transitions, Effects, Speed Change Effects, Media Summary, or Summary is enabled, `ReportBuilder` projects the timeline **once** (progress phase `.projecting`) and shares `ReportProjectionContext` across those sections. Markers / Keywords / Titles / Transitions / Effects are Projection-first with Extraction fallback. See [12 — Timeline Projection](12-Timeline-Projection.md).

**Configuration parity:** Build the report **once** with `ReportOptions`, then export to Excel, PDF, or both. Section flags, `excludedColumns`, `excludedRoles`, `excludeDisabledClips`, `timecodeFormat`, `copyrightLabel`, `includeMarkersOutsideClipBoundaries`, and `projectName` all apply to both exporters (they shape the shared `Report`). **`protectSheets` is Excel-only** (worksheet edit lock — not encryption). PDF adds presentation-only features (cover page, TOC with sheet colour chips + tint washes, per-sheet content tints, pagination, remaining-column width expansion after exclusions, truncation) on top of the same `Report` data.

---

## Quick start

```swift
import OpenFCPXMLKit

let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

// Build a report (role inventory + every optional sheet)
let report = try await fcpxml.buildReport(options: .full)

// Write it to an .xlsx workbook
let xlsxURL = URL(fileURLWithPath: "/path/to/Report.xlsx")
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: xlsxURL)

// Optionally write the same report to PDF (same sections, columns, and timecode format)
let pdfURL = URL(fileURLWithPath: "/path/to/Report.pdf")
try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)
```

`buildReport` throws **ReportError** (`noProjectsFound`, `projectNotFound(name)`) when no reportable timeline can be resolved. Resolution uses ``FinalCutPro/FCPXML/allReportTimelineSources()``: normal `<project>` sequences first, then event-level compound clips (`ref-clip` → `media`/`sequence`) when the document has no project (FCP “Export XML” of a compound clip).

---

## ReportOptions

**ReportOptions** selects sections and configures the build.

### Section include flags

| Property | Default | Section |
|----------|---------|---------|
| `includeMarkers` | `true` | Markers |
| `includeKeywords` | `false` | Keywords |
| `includeTitlesAndGenerators` | `false` | Titles & Generators |
| `includeTransitions` | `false` | Transitions |
| `includeNonStandardEffectsTemplates` | `false` | Non-Std Effects & Templates (non-Apple / missing Motion templates; included in `.full`) |
| `includeEffects` | `false` | Video & Audio Effects |
| `includeSpeedChangeEffects` | `false` | Speed Change Effects |
| `includeSummary` | `false` | Summary (project metrics and role-duration totals) |
| `includeMediaSummary` | `false` | Media Summary (missing media file paths) |
| `includeRoleInventory` | `false` | Selected Roles Inventory + per-role sheets |
| `includeChapterMarkersInMarkersReport` | `true` | Include `chapter-marker` rows on the Markers sheet (Type = Chapter). Set `false` to omit; Excel Type filter can also hide them. |
| `includeMarkersOutsideClipBoundaries` | `false` | Include markers outside the host clip’s media range (hidden in FCP Tags/timeline) and show a **Hidden** column (✓/✗). Not part of `excludedColumns` / `--exclude-column`. |

### Other configuration

| Property | Default | Purpose |
|----------|---------|---------|
| `projectName` | `nil` | Pick a timeline by name when the document has more than one. Matches a `<project>` name or a standalone compound-clip / `ref-clip` name. When `nil`, the first project is preferred; if there is no project, the first event-level compound clip is used. |
| `mediaBaseURL` | `nil` | Base URL for resolving relative media paths when building the Media Summary missing-media list. The CLI defaults this to the document/bundle location. |
| `roleDisplayPreference` | `.builtIn` | Which inherited role to surface on compound clips (see [Role display preference](#role-display-preference)). |
| `workbookCoverSheet` | `.openFCPXMLKitDefault` | Optional cover sheet; set to `nil` to omit. |
| `copyrightLabel` | `nil` | Optional copyright / attribution line: Excel cover **A2**, PDF cover below Created-by, PDF footer centre. |
| `excludedRoles` | `[]` | Role or subrole names to omit from the role inventory. Excluding a main role also excludes its subroles. |
| `excludeDisabledClips` | `false` | Omit clips with `enabled="0"` from every timeline-based section. |
| `excludedColumns` | `[]` | Header names / aliases removed at Excel and PDF export (see [Column exclusion](#column-exclusion)). |
| `timecodeFormat` | `.smpteFrames` | Timeline cell display format (see [Timecode display format](#timecode-display-format)). |
| `mediaResolutionPolicy` | `.failSoft` | How projection failures are handled (see [Media resolution policy](#media-resolution-policy)). |
| `mediaSummaryDistinguishProxyAndOriginal` | `false` | When `true`, Media Summary uses separate Missing Original / Missing Proxy columns. |
| `summaryOverlapAwareDurations` | `false` | When `true`, Summary role durations use occupied-union via Projection occupancy. |
| `emitPerSourceInventoryRows` | `false` | When `true`, Role Inventory may emit distinct rows per media `src` index. |
| `protectSheets` | `false` | When `true`, Excel export applies XLKit worksheet protection to **every** sheet (cover + content). Edit lock only — **not** file-open encryption; PDF ignores this flag. CLI `--protect-sheets`. |

### Presets

`ReportOptions` provides ready-made configurations:

```swift
.roleInventoryOnly                 // Selected Roles Inventory + per-role sheets only
.markersOnly                       // Markers sheet only
.keywordsOnly
.titlesAndGeneratorsOnly
.transitionsOnly
.nonStandardEffectsTemplatesOnly   // Non-Std Effects & Templates sheet only
.effectsOnly
.speedChangeEffectsOnly
.summaryOnly                       // Summary sheet only (project metrics + role durations)
.mediaSummaryOnly                  // Media Summary sheet only (missing media paths)
.full                              // role inventory + every optional sheet (chapter markers on Markers by default)
```

```swift
// Custom selection with filtering
var options = FinalCutPro.FCPXML.ReportOptions(
    includeMarkers: true,
    includeRoleInventory: true,
    includeSummary: true,
    includeMediaSummary: true,
    excludedRoles: ["Effects", "Music ▸ Score"],
    excludeDisabledClips: true,
    excludedColumns: ["Reel", "Metadata", "Source File Path"]
)
options.projectName = "Opening Scene"
options.mediaBaseURL = URL(fileURLWithPath: "/path/to/project.fcpxmld")
options.timecodeFormat = .frames
let report = try await fcpxml.buildReport(options: options)
```

---

## Timecode display format

**ReportTimecodeFormat** controls how every timeline / source time column is written in report cells. Set it on **`ReportOptions.timecodeFormat`**; the value is stored on **`Report.timecodeFormat`** and used by Excel and PDF export for both cell values and (non-default) column header suffixes.

| Case | CLI / `rawValue` | Example cell | Default header suffix |
|------|------------------|--------------|------------------------|
| `.smpteFrames` | `HH:MM:SS:FF` | `01:02:03:04` or `01:00:00;00` (drop-frame) | *(none — e.g. `Timeline In`)* |
| `.frames` | `Frames` | `1500` | ` (frames)` — e.g. `Timeline In (frames)` |
| `.feetAndFrames` | `Feet+Frames` | `60+10` | ` (feet+frames)` |
| `.smpteNoFrames` | `HH:MM:SS` | `01:02:03` | ` (HH:MM:SS)` |

Drop-frame vs non-drop-frame for `.smpteFrames` follows the sequence `tcFormat` (SwiftTimecode `stringValue()`): semicolon before frames for DF, colons only for NDF.

Row / section models expose format-aware headers via `columnHeaders(timecodeFormat:)` (static `columnHeaders` remains the default SMPTE list). `--exclude-column "Timeline In"` still matches suffixed headers such as `Timeline In (frames)`.

Builders that sort after formatting (Keywords, Effects, Speed Change) use numeric compare for **Frames** and **Feet+Frames** so chronology matches SMPTE order.

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.timecodeFormat = .frames
let report = try await fcpxml.buildReport(options: options)
// Cells are frame counts; headers e.g. "Timeline In (frames)", "Position (frames)"
```

---

## Report structure

**Report** exposes one optional property per section, plus identifying metadata:

- `projectName: String`, `eventName: String?`
- `roleInventory: RoleInventoryReportSection?`
- `markers: MarkersReportSection?`
- `keywords: KeywordsReportSection?`
- `titlesAndGenerators: TitlesReportSection?`
- `transitions: TransitionsReportSection?`
- `effects: EffectsReportSection?`
- `speedChangeEffects: SpeedChangeEffectsReportSection?`
- `summary: SummaryReportSection?`
- `mediaSummary: MediaSummaryReportSection?`
- `workbookCoverSheet: ReportWorkbookCoverSheet?` — optional Excel cover worksheet; branding text is also used on the PDF cover page and running footer
- `copyrightLabel: String?` — optional copyright / attribution line (Excel cover **A2**; PDF cover below branding; PDF footer centre)
- `excludedColumns: Set<ReportColumn>` — resolved from `ReportOptions.excludedColumns` at build time
- `timecodeFormat: ReportTimecodeFormat` — copied from options; drives Excel and PDF headers and cell formatting
- `protectSheets: Bool` — copied from options; Excel export applies worksheet protection when `true` (PDF ignores)
- **`exportBrandingText`** — resolved branding label from `workbookCoverSheet` (or the OpenFCPXMLKit default) for Excel cover cell A1 and PDF cover/footer

A section property is `nil` when that section was not requested. Every section conforms to **ReportSection** and exposes a `defaultSheetName`. Row models expose `columnHeaders` / `columnHeaders(timecodeFormat:)` and `columnValues` in matching order, so sections can be rendered by either export backend.

### Sheet obligation contracts

These contracts define what a “near-zero miss” report must not omit when the corresponding FCPXML facts exist. Empty sheets are allowed only when the document truly has no matching content (or filters such as `excludeDisabledClips` / `excludedRoles` remove everything).

| Sheet | Obligation (FCPXML-derived) |
|-------|-----------------------------|
| Selected Roles Inventory / per-role | One row per inventoried host clip × role (Projection windows when inventory is enabled). Nested connected hosts stay inventoried when they have an **own role assignment**; fully occluded hosts with that assignment are retained (not folded solely for occlusion). Fixed columns after **Row** as listed below; dynamic metadata keys discovered on those clips |
| Markers | Every non-filtered marker on the report timeline (standard / to-do / **chapter** by default); host clip name and timeline position. Default omits markers whose `start` is outside the host media range unless `includeMarkersOutsideClipBoundaries` is set. Set `includeChapterMarkersInMarkersReport` to `false` to omit chapter markers. |
| Keywords | Every keyword range attached to timeline hosts in scope |
| Titles & Generators | Every title / generator clip in scope with clip name, timeline bounds, and Role ▸ Subrole from the title’s video `role` (default **Titles** when omitted; custom library roles preserved) |
| Transitions | Every transition element on the report spine(s) in scope |
| Non-Std Effects & Templates | Every non-Apple `<effect>` resource (optional); missing Motion template paths flagged `MISSING` |
| Video & Audio Effects | Every reportable filter / adjustment effect with clip association |
| Speed Change Effects | Every non-identity retiming (Projection `RetimingSegment` preferred) |
| Summary | Project title + duration/resolution/frame-rate metrics when available; role-duration rows for inventory roles |
| Media Summary | Every unresolved original (and, when distinguished, proxy) file URL referenced by projected channels or document media-rep / locator fallback |

**Not an obligation miss:** missing media files on disk (they belong on Media Summary), vendor-broken XML outside DTD, or creative intent not encoded in FCPXML.

### Projection migration checklist (Markers / Keywords / Titles / Transitions)

| Sheet | Status |
|-------|--------|
| **Markers** | **Projection-first** via ``ProjectedClipAnnotations`` (title + clip hosts, including `mc-clip` / `ref-clip`; occluded hosts still contribute markers). Extraction fallback when Projection has no marker annotations **or** annotations filter to zero rows. Chapter markers included by default (`includeChapterMarkersInMarkersReport`). |
| **Keywords** | **Projection-first** via ``ProjectedClipAnnotations`` (same host / occlusion policy as Markers; keyword ranges clamped to host media). Extraction fallback when Projection has no keyword annotations **or** annotations filter to zero rows. |
| **Titles & Generators** | **Projection-first** via ``WindowTitleAnnotation`` on ``ProjectedClipAnnotations``; Role ▸ Subrole from host annotation roles via ``ReportFormatting/titleRoleSubrole(from:roleDisplayPreference:)`` (Extraction path uses ``titleRoleSubrole(for:roleDisplayPreference:)``). Extraction fallback when Projection has no title annotations. Occupancy-gated (visible hosts only). |
| **Transitions** | **Projection-first** via ``WindowTransitionAnnotation`` on ``ProjectedClipAnnotations``. Extraction fallback when Projection has no transition annotations. Occupancy-gated. |
| **Effects** | **Projection-first** via ``WindowReportEffectAnnotation`` (shared ``EffectsCollector`` semantics + occlusion filter for video filters). Extraction fallback when Projection has no effect annotations. Occupancy-gated. |

### Sections and columns

**Row column (all tabular sheets):** Excel and PDF export prepend a 1-based **Row** column to every tabular sheet — Selected Roles Inventory and per-role sheets, Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, the Summary role-duration table, and Media Summary — unless `ReportColumn.row` is excluded. Inventory sheets include Row in their layout; other sheets receive it at export via **`ReportColumnExclusion.ensuringRowColumn`**. PDF pagination pins or injects the same column for multi-page / multi-column-set tables (see [PDF export](#pdf-export)). The **Non-Std Effects & Templates** sheet uses its own fixed columns (Name, Kind, Status, Path, UID) without an injected Row column.

#### Role inventory

**RoleInventoryReportSection** contains:

- `selectedRoles: [RoleClipReportRow]` — rows for the **Selected Roles Inventory** sheet.
- `roleSheets: [RoleSheet]` — one sheet per role (same column layout as the main inventory sheet).
- `metadataColumnKeys: [String]` — dynamic metadata key columns appended after the fixed inventory columns.

Each inventory sheet uses a **Row** index column, then fixed columns, then sorted dynamic metadata keys discovered across all inventory rows. Reel, Scene, Take, Camera Name, **Codecs**, and **Ingest Date** metadata keys that already have dedicated columns are not duplicated in the dynamic metadata block.

**Nested / occluded connected hosts:** Role Inventory does not fold a negative-lane connected host into its parent when the host has an **own role assignment**. Own assignment = active `audio-channel-source` roles, `asset-clip` `audioRole` / `videoRole`, or first-generation `audio` / `video` children with an explicit `role` (`fcpHasStandaloneConnectedInventoryAssignment()`). The same helper gates both nested-host escape (`fcpIsNestedConnectedInventoryHost`) and fully-occluded retention (`retainsFullyOccludedHostForRoleInventory`). Hosts with **no** own assignment may still fold into the parent (for example Nested SFX under a sync-clip). Channel sources still override clip-level `audioRole` when present. Projection windows for these clips were already correct — this is inventory-selection policy in Parsing + `RoleInventoryClipCollector`, not a Projection change. See GUARDRAILS Sign `connected-role-inventory-survives-nesting`.

**Under-spine connected titles / video / generators:** Final Cut Pro commonly places audio under the primary storyline (`lane < 0`), but titles, generators, and other video may also connect there. Role Inventory includes:

- Connected **titles** (category Connected / Secondary title) using `Title.role` via `ReportFormatting.titleRoleSubrole` — not a hard-coded **Titles** label when a custom video role is set.
- Connected leaf **`<video>` / generators** on negative lanes (Connected generator / Connected video). Negative-lane leaf **`<audio>`** remains folded into host channel/sync sources and is skipped as a separate leaf row.

Markers on title hosts attribute the title’s video **main** role (same casing policy as Role Inventory main roles). Parsing, Extraction, and Projection already discover these elements; Reporting must not collapse or drop them. See GUARDRAILS Sign `title-roles-honor-attribute`.

**Per-role Total footer:** Each non-empty per-role sheet ends with a blank row, then a **Total:** label under **Timeline Out** and an optimistic sum of that sheet’s **Clip Duration** values under **Clip Duration**. Both cells use the same black-background / white-text style as column headers. **Selected Roles Inventory** has no Total footer. If Timeline Out or Clip Duration is excluded, the footer is omitted. The sum is presentation-thin (`RoleInventorySheetTotal` — parses already-formatted `clipDuration` strings); it is **not** overlap-aware (Summary’s `summaryOverlapAwareDurations` stays Summary-only). Excel and PDF draw the same footer in the table content area (not the PDF running page footer).

**RoleClipReportRow** fixed columns (in export order, after **Row**):

| Column | Field |
|--------|-------|
| Role ▸ Subrole | `roleSubrole` |
| Clip Name | `clipName` |
| Category | `category` |
| Enabled | `enabled` (`✓` / `✗`) |
| Timeline In | `timelineIn` |
| Timeline Out | `timelineOut` |
| Clip Duration | `clipDuration` |
| Source In | `sourceIn` |
| Source Out | `sourceOut` |
| Source Duration | `sourceDuration` |
| Duplicate Frames | `duplicateFrames` |
| Markers | `markers` |
| Keywords | `keywords` |
| Effects | `effects` |
| Notes | `notes` |
| Reel | `reel` |
| Scene | `scene` |
| Take | `take` |
| Camera Angle | `cameraAngle` |
| Camera Name | `cameraName` |
| Frame Rate/Sample Rate | `frameRateSampleRate` |
| Frame Size / Audio Config | `frameSize` |
| Source File Name | `sourceFileName` |
| Source File Path | `sourceFilePath` |
| Codecs | `codecs` |
| Ingest Date | `ingestDate` |

Additional metadata appears in columns keyed by the raw FCPXML metadata key (for example `com.apple.proapps.studio.rawToLogConversion`). Access values via `metadataValues: [String: String]`. Codecs and Ingest Date are promoted to fixed columns and omitted from that dynamic block.

Use **RoleInventoryColumnLayout** (internal layout helper) or `RoleClipReportRow.fixedColumnHeaders` / `fixedColumnValues` when working with the fixed column block programmatically.

#### Markers

**MarkersReportSection** of **MarkerReportRow**: **Row**, Marker Name, Type, Notes, Position, Clip Name, Role ▸ Subrole, Reel, Scene, Source Position — and, when `includeMarkersOutsideClipBoundaries` is `true`, a trailing **Hidden** column (✓/✗). (**Row** is added at export unless excluded.)

**Chapter markers** (`chapter-marker`) are included by default (`includeChapterMarkersInMarkersReport == true`, including `.markersOnly` and CLI `--report-markers`). They appear with **Type = Chapter**; filter in Excel or set the option to `false` to omit them.

By default, markers whose `start` lies outside the host clip’s media range (`[start, start + duration)`) are **omitted** — Final Cut Pro hides them from the timeline and Tags list. Set `includeMarkersOutsideClipBoundaries` (CLI `--include-markers-outside-clip-boundaries`) to include them; the sheet then gains **Hidden** (✓ = outside bounds, ✗ = inside). **Hidden** is not a `ReportColumn` / `--exclude-column` target.

This is **not** the FCPXML 1.13+ empty `hidden-clip-marker` element (see [14 — Typed Models](14-Typed-Models.md#hidden-clip-marker-fcpxml-113)). Boundary helper: `FCPXMLMarkerClipBoundary`; Projection annotations expose `isOutsideClipBoundaries`.

Audio/video hosts may fan out one marker to multiple Role ▸ Subrole rows (e.g. Video + Dialogue) — same position, intentional duplication for role inventory parity.

**MarkerReportType**: `.standard`, `.incompleteToDo`, `.completedToDo`, `.chapter`.

#### Keywords

**KeywordsReportSection** of **KeywordReportRow**: **Row**, Keyword, Notes, Timeline In/Out, Duration, Clip Name, Role ▸ Subrole, Reel, Scene.

#### Titles & Generators

**TitlesReportSection** of **TitleReportRow**: **Row**, Clip Name, Enabled, Apple, Role ▸ Subrole, Timeline In/Out, Duration, Font, Title Text.

**Role ▸ Subrole:** Taken from the title’s video `role` attribute (`Title.role` / Projection host roles) through `ReportFormatting.titleRoleSubrole`. When `role` is omitted, the field is **Titles** (FCP default). Custom library roles appear as inventory-style `Main ▸ Subrole` strings and drive matching Role Inventory per-role sheets.

#### Transitions

**TransitionsReportSection** of **TransitionReportRow**: **Row**, Transition, Category, Apple, Timeline In/Out, Duration.

#### Non-Std Effects & Templates

**NonStandardEffectsTemplatesReportSection** of **NonStandardEffectTemplateReportRow**: Name, Kind (Effect / Title / Transition / Generator), Status (`MISSING` when the template path is absent on disk), Path, UID.

Lists **non-Apple** `<effect>` resources from the document (UID does not match Apple-supplied Motion/FxPlug patterns). Missing Motion template paths are flagged like Media Summary’s missing media, but for effects/templates. Sheet tab title is shortened to **Non-Std Effects & Templates** (Excel’s 31-character limit). Enabled via `includeNonStandardEffectsTemplates` / CLI `--report-non-standard-effects`; included in `.full`. Empty inventories omit the sheet at export.

**Row colours (Excel and PDF):** Because this sheet has no Role ▸ Subrole column, colours come from **Kind** (and Effect UID) via `FCPXMLReportRowColorPolicy.bucket(forNonStandardKind:uid:)`:

| Kind | Colour |
|------|--------|
| Title | purple `#9933FF` |
| Transition | gray `#808080` |
| Generator | blue `#0066FF` |
| Effect | green `#00AA44` when UID looks audio (`AudioUnit:`, `FFAudio…`); otherwise blue `#0066FF` |

#### Video & Audio Effects

**EffectsReportSection** of **EffectReportRow**: **Row**, Effect, Settings, Enabled, Apple, Clip Name, Role ▸ Subrole, Timeline In/Out.

#### Speed Change Effects

**SpeedChangeEffectsReportSection** (reuses **EffectReportRow**, including leading **Row** at export).

#### Summary

**SummaryReportSection** (`defaultSheetName`: **Summary**):

- `projectSummary: ProjectSummary?` — title, duration, resolution, frame rate, audio sample rate.
- `roleDurations: [SummaryRoleDurationRow]` — **Row**, Role ▸ Subrole, Estimated Total, % of Total (Row prepended at export).
  - `percentOfTotal` is a **fraction** (`roleSeconds / projectSeconds`; may exceed `1.0` when summed clip durations overlap).
  - `formattedPercentOfTotal(_:)` produces the Excel/`0.0%` display string (for example `0.42` → `42.0%`). PDF `columnValues` use this; Excel writes the numeric fraction with `0.0%` format.
  - `isSectionSubtotal` is `true` for the visual-section subtotal row (empty Role ▸ Subrole, non-empty Estimated Total).

In Excel export, the **project title** is written in **B1** (not A1) with table-header style (bold white text on a black fill) so column **A** stays a narrow **Row** index. Cells **A1**, **C1**, **D1**, and **E1** use the same black fill so row 1 reads as one continuous banner across the metrics width. The role-duration header row also paints **E3** black (empty) so the band aligns with column **E** metrics. Column **B** is auto-fit with a generous title-based minimum width. In Excel and PDF export, when both visual and audio roles are present, a **visual-section subtotal** row (empty Role ▸ Subrole, summed Estimated Total / % of Total) uses black fill and **bold** white text at body size (not centred / larger header styling) across the role-duration columns on whatever row it lands — no blank separator row. In Excel that band spans **A–E**; PDF fills the full table width for that data row. Project metrics and role-duration body cells use default **black** text (no role colour coding). **% of Total** is a fraction (for example `0.42`); Excel writes it as a numeric cell with `0.0%` format, and PDF renders the same display text (for example `42.0%`).

See [Sheet order and formatting](#sheet-order-and-formatting) for colours on other sheets.

#### Media Summary

**MediaSummaryReportSection** (`defaultSheetName`: **Media Summary**):

- `missingMediaPaths: [String]` — combined missing file paths (default export column **Missing Media**).
- `missingOriginalMediaPaths` / `missingProxyMediaPaths` — classified when Projection windows expose `original-media` / `proxy-media` URLs.
- `distinguishProxyAndOriginal` — mirrors `ReportOptions.mediaSummaryDistinguishProxyAndOriginal`.

Default export: **Row** | **Missing Media** (black header). Paths render in **red** (`#FF0000`).

When `mediaSummaryDistinguishProxyAndOriginal` is `true`: **Row** | **Missing Original** | **Missing Proxy** (same red body styling). Document-only fallback (no projection windows) cannot distinguish kinds and places paths in the original bucket.

Relative paths resolve against `mediaBaseURL` when provided.

---

## Media resolution policy

**`ReportMediaResolutionPolicy`** controls Projection / geometry failures during `buildReport` — not whether missing files appear on Media Summary.

| Mode | Behaviour |
|------|-----------|
| `.failSoft` (default) | Projection errors yield empty windows; sections continue best-effort (Media Summary falls back to document media-rep / locator scan). |
| `.failLoud` | Throws **`ReportError.projectionFailed`** and aborts the build. |

Missing files on disk remain Media Summary **content** under either mode. CLI: `--media-resolution fail-soft|fail-loud`.

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.mediaResolutionPolicy = .failLoud
let report = try await fcpxml.buildReport(options: options)
```

---

## Excluding disabled clips

Set **`excludeDisabledClips`** to `true` to omit clips with `enabled="0"` from every report section that walks the timeline:

- Role inventory (Selected Roles Inventory and per-role sheets)
- Markers, Keywords, Titles & Generators, Transitions
- Video & Audio Effects, Speed Change Effects
- Summary role-duration totals

Default is `false`, so disabled clips remain in the workbook (typically with **Enabled** shown as `✗`), matching Final Cut Pro export behaviour.

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.excludeDisabledClips = true
let report = try await fcpxml.buildReport(options: options)
```

---

## Column exclusion

**ReportColumn** identifies logical columns that can be removed from **every applicable workbook sheet** at export time. Set **`excludedColumns`** on `ReportOptions` using header names or common aliases; unknown labels are ignored.

At build time, labels are resolved to `Set<ReportColumn>` and stored on **`Report.excludedColumns`**. Excel and PDF export apply the same filtering to role inventory sheets, markers, keywords, titles, transitions, effects, speed-change effects, summary (including project metric cells), and media summary.

**`ReportColumnExclusion.filter`** calls **`ensuringRowColumn`** first (prepends the 1-based **Row** column unless `.row` is excluded), then removes other excluded columns. PDF table pagination uses **`allowsInjectedRowColumn(excluded:)`** so excluding `.row` also suppresses multi-page / multi-column-set Row injection (`preparePaginatedTable(allowInjectedRowColumn:)`).

### ReportColumn cases

| Case | Primary header | Notes |
|------|----------------|-------|
| `.row` | Row | 1-based row index on **all** Excel/PDF tabular sheets (inventory, Markers … Media Summary, Summary role-duration table). Also suppresses PDF multi-page / multi-column-set Row injection. Aliases: Row Numbers, Row Number. |
| `.roleSubrole` | Role ▸ Subrole | |
| `.clipName` | Clip Name | |
| `.category` | Category | |
| `.enabled` | Enabled | |
| `.timelineIn` | Timeline In | |
| `.timelineOut` | Timeline Out | |
| `.clipDuration` | Clip Duration | |
| `.duration` | Duration | Titles, keywords, transitions |
| `.sourceIn` | Source In | |
| `.sourceOut` | Source Out | |
| `.sourceDuration` | Source Duration | |
| `.sourcePosition` | Source Position | Markers |
| `.duplicateFrames` | Duplicate Frames | Source-range reuse duration (blank when none); after Source Duration |
| `.markers` | Markers | |
| `.keywords` | Keywords / Keyword | |
| `.effects` | Effects / Effect | |
| `.notes` | Notes | |
| `.reel` | Reel | |
| `.scene` | Scene | |
| `.take` | Take | |
| `.cameraAngle` | Camera Angle | |
| `.cameraName` | Camera Name | |
| `.frameRateSampleRate` | Frame Rate/Sample Rate | Also matches Frame Rate, Sample Rate |
| `.frameSize` | Frame Size / Audio Config | Video: `W × H`; audio-only: layout/channels (aliases include Frame Size) |
| `.sourceFileName` | Source File Name | |
| `.sourceFilePath` | Source File Path | Also matches Missing Media, Missing Original, Missing Proxy on Media Summary |
| `.codecs` | Codecs | Promoted from `com.apple.proapps.spotlight.kMDItemCodecs` |
| `.ingestDate` | Ingest Date | Promoted from `com.apple.proapps.mio.ingestDate` |
| `.metadata` | *(dynamic keys)* | Removes all dynamic metadata key columns on role inventory sheets |

### Accepted aliases

Matching is **case- and diacritic-insensitive**. Common aliases include:

- **Row Numbers**, **Row Number** → `.row`
- **Role Subrole**, **Role • Subrole** → `.roleSubrole`
- **Metadata** → all dynamic metadata key columns (and keys prefixed with `com.apple.` when matched by header)
- **Frame Rate**, **Sample Rate** → `.frameRateSampleRate`

```swift
var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
options.excludedColumns = [
    "Row Numbers",
    "Reel",
    "Metadata",
    "Source File Path"
]
let report = try await fcpxml.buildReport(options: options)
// report.excludedColumns contains the resolved Set<ReportColumn>
```

**RoleInventoryReportColumn** is a legacy type alias for **ReportColumn**.

---

## Role display preference

**RoleDisplayPreference** decides which inherited role to surface when a clip carries more than one, per **Context** (`.markers`, `.videoEffects`, `.audioEffects`). Use **`.builtIn`** for Final Cut Pro’s built-in main-role ordering only, or supply custom priority tables for project-specific roles (VFX, Atmosphere, Score Composer, Sound Mix, …):

```swift
let preference = FinalCutPro.FCPXML.RoleDisplayPreference(
    markerRolePriority: ["dialogue", "video", "titles", "srt", "effects", "music"],
    videoEffectRolePriority: ["video", "titles", "srt"],
    audioEffectRolePriority: ["dialogue", "effects", "music"]
)

var options = FinalCutPro.FCPXML.ReportOptions.full
options.roleDisplayPreference = preference
```

**`.builtIn` priorities** (FCP reserved defaults — Video, Titles, Dialogue, Effects, Music, plus caption formats such as SRT):

| Context | Priority (first match wins) |
|---------|------------------------------|
| Markers | dialogue → video → titles → srt → effects → music |
| Video effects | video → titles → srt |
| Audio effects | dialogue → effects → music |

`preferredRole(from:context:)`:

- **Effects contexts type-filter** candidates: video/caption roles for `.videoEffects`, audio roles for `.audioEffects`. A clip that only writes `audioRole` cannot paint a **video** filter green via Dialogue/Effects.
- **Markers** may still cross types (full inherited list).
- After the priority table, falls back to the first eligible role sorted by role type then name (so custom roles of the correct type remain eligible even when absent from the priority lists).

When a typed preferred role is missing, Video & Audio Effects formatting defaults Role ▸ Subrole to **Video** / **Dialogue** rather than picking a cross-type role.

---

## Progress callbacks

`buildReport` and `ReportBuilder` accept an **onPhaseStarted** handler (**ReportBuildPhaseHandler**) called as each enabled **ReportBuildPhase** begins. Sections are also **built** in that same order.

### Product / workbook order

**`ReportBuildPhase.enabledPhases(for:)`** is the single source of truth for GUI checkboxes, CLI progress, and section assembly:

1. Selected Roles Inventory (`.roleInventory`)
2. Markers
3. Keywords
4. Titles & Generators
5. Transitions
6. Non-Std Effects & Templates
7. Video & Audio Effects
8. Speed Change Effects
9. Summary
10. Media Summary

Only options that are enabled are included. Each phase has a human-readable `rawValue` (for example `"Selected Roles Inventory"`, `"Video & Audio Effects"`).

Use the same list in a GUI app for progress total and labels so they match your section checkboxes:

```swift
let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
// Use `phases.count` (+ 1 for “Saving Workbook”, + 1 more for “Saving PDF” when exporting both) for progress total.

let report = try await fcpxml.buildReport(options: options) { phase in
    // Fires in product order for each enabled section
    updateProgress(label: phase.rawValue)
}
```

---

## Excel export

**ReportExcelExport** renders a `Report` into an XLKit workbook:

```swift
// Build an in-memory Workbook (e.g. to inspect or add sheets)
let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)

// Write directly to disk
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)

// Sanitize an arbitrary string into a valid sheet name (≤ 31 chars, no : ? [ ] / \)
let name = FinalCutPro.FCPXML.ReportExcelExport.sanitizeSheetName("Video: Effects?")
```

### Sheet order and formatting

Sheet order follows the report:

1. Optional **cover sheet**
2. **Selected Roles Inventory** and per-role sheets
3. Markers, Keywords, Titles & Generators, Transitions
4. Non-Std Effects & Templates, Video & Audio Effects, Speed Change Effects
5. Summary, Media Summary

Role/subrole cells are colour-coded by category on inventory sheets (video/caption blue `#0066FF`, titles purple `#9933FF`, audio green `#00AA44`, gap gray `#808080`). The entire row is tinted on those sheets so clip names, timecodes, and other columns match the role colour.

Section sheets without a Category column use sheet-specific colour rules: **Keywords** rows are always blue; **Titles & Generators** infer purple for title roles; **Video & Audio Effects** and **Speed Change Effects** infer blue for video/title/caption-host rows and green for audio roles (effects Role ▸ Subrole uses type-filtered `preferredRole` so video filters are not painted green from an `audioRole`-only host); **Transitions** use gray text; **Non-Std Effects & Templates** colours by Kind / Effect UID (see [Non-Std Effects & Templates](#non-std-effects--templates)).

The **Summary** sheet uses default black text for project metrics and role-duration data. The **project title** is in **B1** (table header style: bold white on black) so column **A** remains a narrow **Row** index; **A1** / **C1–E1** share that black banner fill. Column **B** uses a generous title-based width. Role-duration column headers (including **Row**) and body cells follow the same black/white header convention as other sheets. The visual-section **subtotal** row (Excel and PDF) uses black fill with bold white body text — not header font size or centred alignment.

The **Media Summary** sheet lists missing file paths in **red** (`#FF0000`), with a leading **Row** column unless excluded.

**Markers** use marker-type colours for the whole row: standard blue, incomplete to-do red, completed to-do green, chapter orange.

Table headers on tabular sheets use a black fill with white text. Data columns are auto-sized per sheet (with wider minimum widths for path columns).

### Cover sheet

**ReportWorkbookCoverSheet** (`title`, `headerText`) adds an intro worksheet to the Excel workbook. Use **`.openFCPXMLKitDefault`** for the built-in "Created by OpenFCPXMLKit" sheet, a custom value, or `nil` to omit the Excel cover tab. **`headerText`** (via **`Report.exportBrandingText`**) is also shown on the PDF cover page and running footer even when the Excel cover sheet is omitted.

Optional **`ReportOptions.copyrightLabel`** / **`Report.copyrightLabel`** (CLI `--label-copyright`) adds a second line: Excel cover **A2** (same black/white banner style as A1), PDF cover below Created-by (same subtitle font/size), and PDF running footer **centre** (same footer font/size as Created-by branding).

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.workbookCoverSheet = FinalCutPro.FCPXML.ReportWorkbookCoverSheet(
    title: "Created by My Studio",
    headerText: "Created by My Studio"
)
options.copyrightLabel = "© 2026 My Studio"
```

### Sheet protection (Excel only)

Optional **`ReportOptions.protectSheets`** / **`Report.protectSheets`** (CLI `--protect-sheets`) applies XLKit worksheet protection to **every** sheet in the workbook after content is written (cover + inventory + section sheets). Defaults to `false`.

This is an **edit lock** to discourage accidental changes — **not** file-open encryption. Excel still opens the workbook without a password, and anyone can turn protection off in Excel unless you add a password later in Excel itself. **`ReportPDFExport` ignores this flag**; password-protect PDFs with Preview or another PDF tool after export.

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.protectSheets = true
```

---

## PDF export

**ReportPDFExport** renders a `Report` into a multi-page **A4 landscape** PDF using CoreGraphics:

```swift
// Build PDF data in memory
let pdfData = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)

// Write directly to disk
try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)
```

Throws **ReportPDFExportError** (`couldNotCreateDocument`, `couldNotWriteFile`) on failure.

**Public API surface:** build with `FinalCutPro.FCPXML.buildReport(options:)` (or `ReportBuilder`), then call `ReportPDFExport.makePDFData(from:)` / `export(_:to:)`. TOC colour chips, per-sheet tints, and column-width expansion are presentation behaviour of that export path (internal helpers: `FCPXMLReportPDFSheetPlan`, `FCPXMLReportPDFTableLayout`, `FCPXMLReportPDFStyle` / Canvas). No additional public types are required to opt in — excluding columns via `ReportOptions.excludedColumns` is enough for remaining columns to expand; every planned workbook sheet already carries a sequential colour index for TOC + content pages.

### Layout and presentation

PDF export mirrors Excel **section order** and **sheet names** (via `FCPXMLReportPDFSheetPlan`):

1. **Cover page** — project name, event name (when present), generated timestamp, `exportBrandingText`, optional `copyrightLabel` (same subtitle style), and an info box with a **black header band** (white **`info.circle`** SF Symbol + title **“About This PDF Export”**) and a smaller body paragraph describing experimental A4-landscape export, pagination/truncation, the default **Row** column (excludable like Excel), tinted matching pages, and a pointer to the companion `.xlsx` for the full dataset.
2. **Table of contents** — one or more pages listing every included section with start page numbers (built dynamically in a two-pass render so page numbers are accurate). The TOC is not a workbook sheet in Excel; it is PDF-only. Each TOC row uses the **same colour index** as that sheet’s content pages: a small **accent-palette colour chip** beside the row number, plus a light **content-tint wash** on the row (Menlo text stays high-contrast on the near-white wash).
3. **Content pages** — each enabled section, in workbook order, with running header (project name + section title) and footer (branding + page number).

Per-section presentation:

- **Per-sheet tint** — pages that belong to the same workbook section share a subtle background tint between the header rule and footer rule.
- **Row colours** — the same rules as Excel (`FCPXMLReportRowColorPolicy`): role inventory category colours, marker-type colours, keywords/titles/effects/transitions inference, Non-Std Kind/UID colours, red missing-media paths.
- **Summary role-duration table** — same layout semantics as Excel: injected **Row**, black header row, visual-section **subtotal** as a full-width black banner with bold white **body-size** text (`isSectionSubtotal`), and **% of Total** via `formattedPercentOfTotal` matching Excel’s `0.0%` display (not a raw Double string).
- **Per-role Total footer** — same blank row + **Total:** / Clip Duration sum as Excel (black/white header style), drawn in the table content area.
- **Non-Std Effects & Templates** — Name / Kind / Status / Path / UID (no injected Row); omitted when empty.
- **Tables** — black header row with white text; body uses Menlo. Column widths are measured from content (clamped for horizontal packing), then **expanded proportionally to fill the A4 landscape content width** when leftover space remains (for example after many `excludedColumns`). Wide tables still **paginate horizontally** into column sets (running header shows `Columns 2 of 5` when chunked); each set also fills the page width. Pinned **Row** columns keep their packed width.
- **Truncation** — cell text that exceeds column width is ellipsized (`…`). For the full untruncated dataset, use the Excel export.
- **Row column** — included by default on all tabular content (same as Excel) via **`ensuringRowColumn`**. On multi-page or multi-column-set tables, Row is **pinned** on the left; if headers lack Row and injection is allowed, PDF injects it via **`preparePaginatedTable(allowInjectedRowColumn:)`**. Exclude `ReportColumn.row` (CLI `--exclude-column Row`) to omit Row everywhere, including continuation pages.

### Configuration reflected in PDF

| Setting | PDF behaviour |
|---------|----------------|
| Section include flags | Only non-`nil` sections on `Report` are rendered |
| `excludedColumns` | Same `ReportColumnExclusion` filtering as Excel on every applicable section |
| `timecodeFormat` | Same formatted cell values and suffixed headers as Excel |
| `excludedRoles` | Applied at build time (fewer role-inventory rows/sheets) |
| `excludeDisabledClips` | Applied at build time (fewer rows in all timeline sections) |
| `projectName` | Applied at build time (timeline source and `report.projectName`) |
| `workbookCoverSheet` | `exportBrandingText` on cover and footer (Excel cover tab is separate) |
| `copyrightLabel` | Cover line below branding; centred running footer (Excel cover **A2**) |
| `includeMarkersOutsideClipBoundaries` | Applied at build time (Markers rows + optional **Hidden** column) |
| `protectSheets` | **Ignored** — Excel-only worksheet edit lock; use Preview → Encrypt for PDF open passwords |

Headers such as **Marker Name**, **Type**, or the opt-in **Hidden** column on the Markers sheet are **not** `ReportColumn` cases; `--exclude-column` cannot remove them in Excel or PDF.

---

## From the CLI

The same reports are available through **OpenFCPXMLKit-CLI**:

| Flag | Purpose |
|------|---------|
| `--report` | Role inventory only (Selected Roles Inventory + per-role sheets) |
| `--report-full` | Every optional sheet |
| `--report-markers`, `--report-keywords`, … | Individual optional sheets |
| `--report-non-standard-effects` | Non-Std Effects & Templates sheet |
| `--report-summary` | Summary sheet |
| `--report-media-summary` | Media Summary sheet |
| `--media-resolution <mode>` | `fail-soft` (default) or `fail-loud` for Projection failures |
| `--media-summary-distinguish-proxy` | Separate Missing Original / Missing Proxy columns on Media Summary |
| `--create-pdf` | Also write `{project-or-clip-name}.pdf` alongside the `.xlsx` (same report configuration) |
| `--label-copyright <text>` | Optional copyright / attribution line (Excel cover A2; PDF cover + footer centre) |
| `--report-project <name>` | Timeline name filter (project or standalone compound-clip name) |
| `--exclude-role <name>` | Omit roles from role inventory (repeatable) |
| `--exclude-disabled-clips` | Omit `enabled="0"` clips from all timeline sections |
| `--include-markers-outside-clip-boundaries` | Include out-of-bounds markers + Markers **Hidden** column |
| `--protect-sheets` | Excel worksheet edit lock on every sheet (not encryption; PDF unaffected) |
| `--exclude-column <name>` | Omit a column from every applicable sheet (repeatable) |
| `--timecode-format <format>` | Timeline cell format: `HH:MM:SS:FF` (default), `Frames`, `Feet+Frames`, `HH:MM:SS` |

See [18 — CLI](19-CLI.md#report) for full option reference and matching rules.

```bash
# Role inventory only
OpenFCPXMLKit-CLI --report /path/to/project.fcpxmld /path/to/output-dir

# Full workbook, omit disabled clips and selected columns
OpenFCPXMLKit-CLI --report --report-full \
  --exclude-disabled-clips \
  --exclude-column Reel \
  --exclude-column Metadata \
  /path/to/project.fcpxmld /path/to/output-dir

# Frame-count timecode columns (headers e.g. "Timeline In (frames)")
OpenFCPXMLKit-CLI --report --report-full \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir

# Partial export with role and column filtering
OpenFCPXMLKit-CLI --report --report-summary --report-media-summary \
  --exclude-role Effects \
  --exclude-column "Source File Path" \
  /path/to/project.fcpxmld /path/to/output-dir

# Excel + PDF (same sections, column exclusions, and timecode format)
OpenFCPXMLKit-CLI --report --report-full --create-pdf \
  --exclude-column Metadata \
  /path/to/project.fcpxmld /path/to/output-dir
```

---

## Investigating private / complex FCPXML

For real-world exports that must stay off GitHub, drop them in [Tests/Submitted FCPXML/Inbox/](../../Tests/Submitted%20FCPXML/README.md) (gitignored). Reproduce with `FCPXMLSubmittedFCPXMLSmokeTests`, CLI `--report`, or `ExcelReportTest` via `OFK_REPORTING_FCPXML_BUNDLE`. Anonymise before promoting a minimal fixture into `Tests/FCPXML Samples/FCPXML/`.

---

## Next

- [21 — Examples](21-Examples.md) — End-to-end workflows and code examples.
- [12 — Timeline Projection](12-Timeline-Projection.md) — windows, options, occupancy, and how report builders consume Projection.
- [11 — Extraction & Media](11-Extraction-Media.md) — Extraction presets and media copy (fallback / discovery).
- [19 — CLI](19-CLI.md) — building reports from the command line.

[← Manual Index](00-Index.md)


