# 19 — Reporting & Excel Export

[← Manual Index](00-Index.md)

---

## Overview

The reporting subsystem builds structured, spreadsheet-style **reports** from a parsed FCPXML document and writes them to an **`.xlsx` workbook** (via XLKit). A report is assembled from independent **sections** (role inventory, markers, keywords, titles & generators, transitions, effects, speed-change effects, summary), each of which becomes one or more sheets.

Everything lives under **`FinalCutPro.FCPXML`**:

- **buildReport(options:scope:onPhaseStarted:)** — convenience entry point on a parsed document.
- **ReportBuilder** — assembles a **Report** from a document or a single **Project**.
- **ReportOptions** — selects which sections to include, plus project filter, media base URL, role display preference, cover sheet, and role exclusions.
- **Report** — the assembled value type (one optional property per section).
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

**ReportOptions** selects sections and configures the build. Include flags:

| Property | Default | Section |
|----------|---------|---------|
| `includeMarkers` | `true` | Markers |
| `includeKeywords` | `false` | Keywords |
| `includeTitlesAndGenerators` | `false` | Titles & Generators |
| `includeTransitions` | `false` | Transitions |
| `includeEffects` | `false` | Video & Audio Effects |
| `includeSpeedChangeEffects` | `false` | Speed Change Effects |
| `includeSummary` | `false` | Summary |
| `includeRoleInventory` | `false` | Selected Roles + per-role sheets |
| `includeChapterMarkersInMarkersReport` | `false` | Add chapter markers to the Markers sheet |

Other fields:

- **projectName** (`String?`) — pick a project by name when the document has more than one (otherwise the first project is used).
- **mediaBaseURL** (`URL?`) — base URL for resolving relative media paths in the Summary sheet's missing-media detection. The CLI defaults this to the document/bundle location.
- **roleDisplayPreference** (`RoleDisplayPreference`) — which inherited role to surface on compound clips (see below). Default `.builtIn`.
- **workbookCoverSheet** (`ReportWorkbookCoverSheet?`) — optional cover sheet; defaults to `.openFCPXMLKitDefault`.
- **excludedRoles** (`[String]`) — role or subrole names to omit from the role inventory. Excluding a main role also excludes its subroles.

### Presets

`ReportOptions` provides ready-made configurations:

```swift
.roleInventoryOnly     // Selected Roles + per-role sheets only
.markersOnly           // Markers sheet only (the default)
.keywordsOnly
.titlesAndGeneratorsOnly
.transitionsOnly
.effectsOnly
.speedChangeEffectsOnly
.summaryOnly
.full                  // role inventory + every optional sheet (chapter markers included)
```

```swift
// Custom selection
var options = FinalCutPro.FCPXML.ReportOptions(
    includeMarkers: true,
    includeRoleInventory: true,
    excludedRoles: ["Effects", "Music ▸ Score"]
)
options.projectName = "Opening Scene"
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
- `workbookCoverSheet: ReportWorkbookCoverSheet?`

A property is `nil` when its section was not requested. Every section conforms to **ReportSection** and exposes a `defaultSheetName`. Each row model exposes `columnHeaders` (static) and `columnValues` in matching order, so sections can be rendered by any backend.

### Sections and columns

- **Role inventory** — **RoleInventoryReportSection**: `selectedRoles: [RoleClipReportRow]` (the "Selected Roles" sheet) and `roleSheets: [RoleSheet]` (one sheet per role). **RoleClipReportRow** columns: Role ▸ Subrole, Clip Name, Category, Enabled, Timeline In/Out, Clip Duration, Source In/Out, Source Duration, Markers, Keywords, Effects, Notes, Reel, Scene.
- **Markers** — **MarkersReportSection** of **MarkerReportRow**: Marker Name, Type, Notes, Position, Clip Name, Role ▸ Subrole, Reel, Scene, Source Position. **MarkerReportType**: `.standard`, `.incompleteToDo`, `.completedToDo`, `.chapter`.
- **Keywords** — **KeywordsReportSection** of **KeywordReportRow**: Keyword, Notes, Timeline In/Out, Duration, Clip Name, Role ▸ Subrole, Reel, Scene.
- **Titles & Generators** — **TitlesReportSection** of **TitleReportRow**: Clip Name, Enabled, Apple, Role ▸ Subrole, Timeline In/Out, Duration, Font, Title Text.
- **Transitions** — **TransitionsReportSection** of **TransitionReportRow**: Transition, Category, Apple, Timeline In/Out, Duration.
- **Video & Audio Effects** — **EffectsReportSection** of **EffectReportRow**: Effect, Settings, Enabled, Apple, Clip Name, Role ▸ Subrole, Timeline In/Out.
- **Speed Change Effects** — **SpeedChangeEffectsReportSection** (reuses **EffectReportRow**).
- **Summary** — **SummaryReportSection**: `projectSummary` (**ProjectSummary**: title, duration, resolution, frame rate, audio sample rate), `roleDurations` (**SummaryRoleDurationRow**: Role ▸ Subrole, Estimated Total, % of Total), and `missingMediaPaths`. The **% of Total** value is stored as a fraction (for example `0.42`) and written to Excel as a numeric cell with a percentage number format (`0.0%`).

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

`buildReport` and `ReportBuilder` accept an **onPhaseStarted** handler (**ReportBuildPhaseHandler**) called as each **ReportBuildPhase** begins (`.markers`, `.keywords`, `.titlesAndGenerators`, `.transitions`, `.effects`, `.speedChangeEffects`, `.summary`, `.roleInventory`). Each phase has a human-readable `rawValue` (for example `"Video & Audio Effects"`).

```swift
let report = try await fcpxml.buildReport(options: .full) { phase in
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

Sheet order follows the report: an optional **cover sheet**, then Selected Roles and per-role sheets, then Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, and Summary. Role/subrole cells are colour-coded by category (video/caption blue, titles purple, audio green, gap black), and table headers use a black fill with white text.

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

The same reports are available through **OpenFCPXMLKit-CLI** with `--report` (role inventory only), `--report-full` (all sheets), and per-section flags such as `--report-markers`, plus `--exclude-role` and `--report-project`. See [16 — CLI](16-CLI.md#report).

```bash
OpenFCPXMLKit-CLI --report /path/to/project.fcpxmld /path/to/output-dir
OpenFCPXMLKit-CLI --report --report-full /path/to/project.fcpxmld /path/to/output-dir
```

---

## Next

- [10 — Extraction & Media](10-Extraction-Media.md) — the extraction layer the report builders consume.
- [16 — CLI](16-CLI.md) — building reports from the command line.

[← Manual Index](00-Index.md)
