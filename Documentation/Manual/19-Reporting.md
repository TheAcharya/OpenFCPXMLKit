# 19 — Reporting & Excel Export

[← Manual Index](00-Index.md)

---

## Overview

The reporting subsystem builds structured, spreadsheet-style **reports** from a parsed FCPXML document and writes them to an **`.xlsx` workbook** (via XLKit). A report is assembled from independent **sections** (role inventory, markers, keywords, titles & generators, transitions, effects, speed-change effects, summary, media summary), each of which becomes one or more sheets.

Everything lives under **`FinalCutPro.FCPXML`**:

- **buildReport(options:scope:onPhaseStarted:)** — convenience entry point on a parsed document.
- **ReportBuilder** — assembles a **Report** from a document or a single **Project**.
- **ReportOptions** — selects which sections to include, plus project filter, media base URL, role display preference, cover sheet, role exclusions, disabled-clip filtering, and column exclusions.
- **Report** — the assembled value type (one optional property per section, plus resolved column exclusions).
- **ReportColumn** — logical workbook columns that can be omitted globally at export.
- **ReportExcelExport** — turns a `Report` into an XLKit `Workbook` or writes it to disk.

All build APIs are **async**.

---

## Quick start

```swift
import OpenFCPXMLKit

let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

// Build a report (role inventory + every optional sheet)
let report = try await fcpxml.buildReport(options: .full)

// Write it to an .xlsx workbook
let outputURL = URL(fileURLWithPath: "/path/to/Report.xlsx")
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)
```

`buildReport` throws **ReportError** (`noProjectsFound`, `projectNotFound(name)`) when the requested project cannot be resolved.

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
| `includeEffects` | `false` | Video & Audio Effects |
| `includeSpeedChangeEffects` | `false` | Speed Change Effects |
| `includeSummary` | `false` | Summary (project metrics and role-duration totals) |
| `includeMediaSummary` | `false` | Media Summary (missing media file paths) |
| `includeRoleInventory` | `false` | Selected Roles Inventory + per-role sheets |
| `includeChapterMarkersInMarkersReport` | `false` | Add chapter markers to the Markers sheet |

### Other configuration

| Property | Default | Purpose |
|----------|---------|---------|
| `projectName` | `nil` | Pick a project by name when the document has more than one (otherwise the first project is used). |
| `mediaBaseURL` | `nil` | Base URL for resolving relative media paths when building the Media Summary missing-media list. The CLI defaults this to the document/bundle location. |
| `roleDisplayPreference` | `.builtIn` | Which inherited role to surface on compound clips (see [Role display preference](#role-display-preference)). |
| `workbookCoverSheet` | `.openFCPXMLKitDefault` | Optional cover sheet; set to `nil` to omit. |
| `excludedRoles` | `[]` | Role or subrole names to omit from the role inventory. Excluding a main role also excludes its subroles. |
| `excludeDisabledClips` | `false` | When `true`, clips with `enabled="0"` are omitted from every timeline-based section. Default includes disabled clips (matching Final Cut Pro workbook exports). |
| `excludedColumns` | `[]` | Column labels to omit from every applicable workbook sheet at export (see [Column exclusion](#column-exclusion)). |

### Presets

`ReportOptions` provides ready-made configurations:

```swift
.roleInventoryOnly       // Selected Roles Inventory + per-role sheets only
.markersOnly             // Markers sheet only
.keywordsOnly
.titlesAndGeneratorsOnly
.transitionsOnly
.effectsOnly
.speedChangeEffectsOnly
.summaryOnly             // Summary sheet only (project metrics + role durations)
.mediaSummaryOnly        // Media Summary sheet only (missing media paths)
.full                    // role inventory + every optional sheet (chapter markers included)
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
let report = try await fcpxml.buildReport(options: options)
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
- `workbookCoverSheet: ReportWorkbookCoverSheet?`
- `excludedColumns: Set<ReportColumn>` — resolved from `ReportOptions.excludedColumns` at build time

A section property is `nil` when that section was not requested. Every section conforms to **ReportSection** and exposes a `defaultSheetName`. Row models expose `columnHeaders` (static) and `columnValues` in matching order, so sections can be rendered by any backend.

### Sections and columns

#### Role inventory

**RoleInventoryReportSection** contains:

- `selectedRoles: [RoleClipReportRow]` — rows for the **Selected Roles Inventory** sheet.
- `roleSheets: [RoleSheet]` — one sheet per role (same column layout as the main inventory sheet).
- `metadataColumnKeys: [String]` — dynamic metadata key columns appended after the fixed inventory columns.

Each inventory sheet uses a **Row** index column, then fixed columns, then sorted dynamic metadata keys discovered across all inventory rows. Reel, Scene, Take, and Camera Name metadata keys that already have dedicated columns are not duplicated in the dynamic metadata block.

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
| Frame Size | `frameSize` |
| Source File Name | `sourceFileName` |
| Source File Path | `sourceFilePath` |

Additional metadata appears in columns keyed by the raw FCPXML metadata key (for example `com.apple.proapps.studio.rawToLogConversion`). Access values via `metadataValues: [String: String]`.

Use **RoleInventoryColumnLayout** (internal layout helper) or `RoleClipReportRow.fixedColumnHeaders` / `fixedColumnValues` when working with the fixed column block programmatically.

#### Markers

**MarkersReportSection** of **MarkerReportRow**: Marker Name, Type, Notes, Position, Clip Name, Role ▸ Subrole, Reel, Scene, Source Position.

**MarkerReportType**: `.standard`, `.incompleteToDo`, `.completedToDo`, `.chapter`.

#### Keywords

**KeywordsReportSection** of **KeywordReportRow**: Keyword, Notes, Timeline In/Out, Duration, Clip Name, Role ▸ Subrole, Reel, Scene.

#### Titles & Generators

**TitlesReportSection** of **TitleReportRow**: Clip Name, Enabled, Apple, Role ▸ Subrole, Timeline In/Out, Duration, Font, Title Text.

#### Transitions

**TransitionsReportSection** of **TransitionReportRow**: Transition, Category, Apple, Timeline In/Out, Duration.

#### Video & Audio Effects

**EffectsReportSection** of **EffectReportRow**: Effect, Settings, Enabled, Apple, Clip Name, Role ▸ Subrole, Timeline In/Out.

#### Speed Change Effects

**SpeedChangeEffectsReportSection** (reuses **EffectReportRow**).

#### Summary

**SummaryReportSection** (`defaultSheetName`: **Summary**):

- `projectSummary: ProjectSummary?` — title, duration, resolution, frame rate, audio sample rate.
- `roleDurations: [SummaryRoleDurationRow]` — Role ▸ Subrole, Estimated Total, % of Total.

In Excel export, the **project title** uses the table header style (bold white text on a black fill). Project metrics and role-duration rows use default **black** text (no role colour coding). The **% of Total** value is stored as a fraction (for example `0.42`) and written as a numeric cell with percentage number format (`0.0%`).

See [Sheet order and formatting](#sheet-order-and-formatting) for colours on other sheets.

#### Media Summary

**MediaSummaryReportSection** (`defaultSheetName`: **Media Summary**):

- `missingMediaPaths: [String]` — file paths that could not be resolved on disk.

The sheet renders a **Missing Media** section with a black header row (matching other report sheets). Each missing file path is written in **red** text (`#FF0000`). Relative paths are resolved against `mediaBaseURL` when provided.

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

At build time, labels are resolved to `Set<ReportColumn>` and stored on **`Report.excludedColumns`**. Excel export applies filtering to role inventory sheets, markers, keywords, titles, transitions, effects, speed-change effects, summary (including project metric cells), and media summary.

### ReportColumn cases

| Case | Primary header | Notes |
|------|----------------|-------|
| `.row` | Row | Row index on inventory sheets |
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
| `.duplicateFrames` | Duplicate Frames | Alias supported; no data column yet |
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
| `.frameSize` | Frame Size | |
| `.sourceFileName` | Source File Name | |
| `.sourceFilePath` | Source File Path | Also matches Missing Media on Media Summary |
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

**RoleDisplayPreference** decides which inherited role to surface when a clip carries more than one, per **Context** (`.markers`, `.videoEffects`, `.audioEffects`). Use **`.builtIn`** for Final Cut Pro's built-in main-role ordering, or supply custom priority tables for project-specific roles:

```swift
let preference = FinalCutPro.FCPXML.RoleDisplayPreference(
    markerRolePriority: ["dialogue", "video", "titles"],
    videoEffectRolePriority: ["video", "titles"],
    audioEffectRolePriority: ["dialogue", "effects", "music"]
)

var options = FinalCutPro.FCPXML.ReportOptions.full
options.roleDisplayPreference = preference
```

`preferredRole(from:context:)` returns the first matching role, falling back to a stable sort by role type then name.

---

## Progress callbacks

`buildReport` and `ReportBuilder` accept an **onPhaseStarted** handler (**ReportBuildPhaseHandler**) called as each enabled **ReportBuildPhase** begins.

Phases follow product / workbook order via **`ReportBuildPhase.enabledPhases(for:)`**:

`.roleInventory`, `.markers`, `.keywords`, `.titlesAndGenerators`, `.transitions`, `.effects`, `.speedChangeEffects`, `.summary`, `.mediaSummary`

(Only options that are enabled are included.) Each phase has a human-readable `rawValue` (for example `"Selected Roles Inventory"`, `"Video & Audio Effects"`).

```swift
let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
// Use `phases` for progress UI total / labels in GUI apps.

let report = try await fcpxml.buildReport(options: options) { phase in
    print("Building \(phase.rawValue)…")
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
4. Video & Audio Effects, Speed Change Effects
5. Summary, Media Summary

Role/subrole cells are colour-coded by category on inventory sheets (video/caption blue `#0066FF`, titles purple `#9933FF`, audio green `#00AA44`, gap gray `#808080`). The entire row is tinted on those sheets so clip names, timecodes, and other columns match the role colour.

Section sheets without a Category column use sheet-specific colour rules: **Keywords** rows are always blue; **Titles & Generators** infer purple for title roles; **Video & Audio Effects** and **Speed Change Effects** infer blue for video/VFX/title-host rows and green for audio roles; **Transitions** use gray text.

The **Summary** sheet uses default black text for project metrics and role-duration data. The **project title** (row 1) and column header rows use the standard table header style: bold white text on a black fill.

The **Media Summary** sheet lists missing file paths in **red** (`#FF0000`).

**Markers** use marker-type colours for the whole row: standard blue, incomplete to-do red, completed to-do green, chapter orange.

Table headers on tabular sheets use a black fill with white text. Data columns are auto-sized per sheet (with wider minimum widths for path columns).

### Cover sheet

**ReportWorkbookCoverSheet** (`title`, `headerText`) adds an intro sheet. Use **`.openFCPXMLKitDefault`** for the built-in "Created by OpenFCPXMLKit" sheet, a custom value, or `nil` to omit it:

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.workbookCoverSheet = FinalCutPro.FCPXML.ReportWorkbookCoverSheet(
    title: "Created by My Studio",
    headerText: "Created by My Studio"
)
```

---

## From the CLI

The same reports are available through **OpenFCPXMLKit-CLI**:

| Flag | Purpose |
|------|---------|
| `--report` | Role inventory only (Selected Roles Inventory + per-role sheets) |
| `--report-full` | Every optional sheet |
| `--report-markers`, `--report-keywords`, … | Individual optional sheets |
| `--report-summary` | Summary sheet |
| `--report-media-summary` | Media Summary sheet |
| `--report-project <name>` | Project name filter |
| `--exclude-role <name>` | Omit roles from role inventory (repeatable) |
| `--exclude-disabled-clips` | Omit `enabled="0"` clips from all timeline sections |
| `--exclude-column <name>` | Omit a column from every applicable sheet (repeatable) |

See [16 — CLI](16-CLI.md#report) for full option reference and matching rules.

```bash
# Role inventory only
OpenFCPXMLKit-CLI --report /path/to/project.fcpxmld /path/to/output-dir

# Full workbook, omit disabled clips and selected columns
OpenFCPXMLKit-CLI --report --report-full \
  --exclude-disabled-clips \
  --exclude-column Reel \
  --exclude-column Metadata \
  /path/to/project.fcpxmld /path/to/output-dir

# Partial export with role and column filtering
OpenFCPXMLKit-CLI --report --report-summary --report-media-summary \
  --exclude-role Effects \
  --exclude-column "Source File Path" \
  /path/to/project.fcpxmld /path/to/output-dir
```

---

## Next

- [10 — Extraction & Media](10-Extraction-Media.md) — the extraction layer the report builders consume.
- [16 — CLI](16-CLI.md) — building reports from the command line.

[← Manual Index](00-Index.md)
