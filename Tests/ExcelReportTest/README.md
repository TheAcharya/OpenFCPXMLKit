# Excel report integration tests

Optional integration tests that build real `.xlsx` workbooks from a local FCPXML project. Use this target when you want to compare OpenFCPXMLKit output against reference exports without running the CLI each time.

**Target:** `ExcelReportTest`  
**Depends on:** `OpenFCPXMLKit`, `XLKit`  
**Tests:** 1 (`ExcelReportExportTests`)

Unit-level reporting behaviour (column layout, column exclusion, disabled-clip filtering, timecode formats / DF·NDF, format-aware headers, build-phase order, workbook cell formatting and sheet-specific colour rules) lives in **`OpenFCPXMLKitTests`** — see [Tests/README.md](../README.md#reporting--excel-export).

---

## Fixture input (`.fcpxml` or `.fcpxmld`)

Tests accept **either** format:

| Format | What you provide | How it is loaded |
|--------|------------------|------------------|
| **`.fcpxmld`** | A bundle directory (e.g. `MyProject.fcpxmld/`) containing `Info.fcpxml` | `FCPXMLFileLoader` reads `Info.fcpxml` inside the bundle |
| **`.fcpxml`** | A single XML file | Loaded directly |

Relative media paths for the **Media Summary** sheet are resolved from the bundle directory (for `.fcpxmld`) or the file's parent folder (for `.fcpxml`). `ExcelReportFixture.mediaBaseURL(for:)` supplies `ReportOptions.mediaBaseURL` automatically.

### Fixture resolution order

1. **Environment variable** — `OFK_REPORTING_FCPXML_BUNDLE` set to a `.fcpxml` path or `.fcpxmld` bundle path  
2. **Preferred local names** — `Sample.fcpxmld` then `Sample.fcpxml` in this directory  
3. **Auto-discovery** — first valid `.fcpxml` / `.fcpxmld` in this directory (excluding `Output/`, Swift sources, and markdown)

If no fixture is found, tests **skip** (`XCTSkip`) so CI can pass without a local project.

### Setup (local)

Place your project here (not committed — see `.gitignore`):

```
Tests/ExcelReportTest/
├── Sample.fcpxmld/          ← bundle (recommended; matches Final Cut export)
│   └── Info.fcpxml
└── Sample.fcpxml            ← or a single file
```

You can also use any other name; discovery will pick the first valid `.fcpxml` / `.fcpxmld` alphabetically if `Sample.*` is absent.

Or point at an existing path:

```bash
export OFK_REPORTING_FCPXML_BUNDLE="/path/to/Project.fcpxmld"
# or
export OFK_REPORTING_FCPXML_BUNDLE="/path/to/Project.fcpxml"
```

---

## Generated output

Running the export test writes workbooks to **`Output/`** (also gitignored):

| File | Report preset | CLI equivalent | Contents |
|------|---------------|----------------|----------|
| `Output/OFK-Default.xlsx` | `ReportOptions.roleInventoryOnly` | `OpenFCPXMLKit-CLI --report <fixture> <dir>` | **Selected Roles Inventory** + per-role sheets (23 fixed columns + Row + dynamic metadata keys) |
| `Output/OFK-Full.xlsx` | `ReportOptions.full` | `OpenFCPXMLKit-CLI --report --report-full <fixture> <dir>` | Default sheets plus Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, **Summary** (project title header + black data rows), and **Media Summary** (red missing-media paths) |

Cell colours, header styling, and section-sheet colour rules are covered by **`FCPXMLReportExcelExportTests`** in `OpenFCPXMLKitTests`. This integration target checks that a real fixture produces complete workbooks; open `OFK-Full.xlsx` locally to compare layout and formatting against a reference export if you maintain one.

See [Output/README.md](Output/README.md) for details on that folder.

`testExportDefaultAndFullWorkbooks` asserts that the default export includes only role inventory, and that the full export includes every optional section (`summary`, `mediaSummary`, markers, keywords, titles, transitions, effects, speed-change effects).

---

## CLI parity

The integration target mirrors the two most common CLI flows. For filtered exports, use the CLI or build reports in code:

```bash
# Omit disabled clips, columns, and use frame-count timecode (not covered by ExcelReportExportTests)
OpenFCPXMLKit-CLI --report --report-full \
  --exclude-disabled-clips \
  --exclude-column Reel \
  --exclude-column Metadata \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir
```

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.excludeDisabledClips = true
options.excludedColumns = ["Reel", "Metadata"]
options.timecodeFormat = .frames
let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
let report = try await fcpxml.buildReport(options: options) { phase in
    // phase order matches GUI / workbook: inventory first
    _ = phases
}
```

See [Documentation/Manual/19-Reporting.md](../../Documentation/Manual/19-Reporting.md) for the full API (`ReportTimecodeFormat`, progress phases, column exclusion).

---

## Running tests

```bash
# Export Default + Full workbooks (requires a local fixture)
swift test --filter ExcelReportExportTests

# Entire Excel report target
swift test --filter ExcelReportTest
```

First run on a large project can take ~1–2 minutes (report build + XLKit save).

---

## Files

| File | Purpose |
|------|---------|
| `ExcelReportFixture.swift` | Resolves fixture URL, `mediaBaseURL`, and `Output/` path; defines output file names |
| `ExcelReportExportTests.swift` | Builds and writes `OFK-Default.xlsx` and `OFK-Full.xlsx` |
| `Output/` | Generated workbooks (created by tests; gitignored) |

---

## CI

- **Without fixture:** tests skip; job stays green.  
- **With fixture:** checkout or copy a `.fcpxmld` / `.fcpxml` into `Tests/ExcelReportTest/`, or set `OFK_REPORTING_FCPXML_BUNDLE` in the workflow.

Example:

```yaml
env:
  OFK_REPORTING_FCPXML_BUNDLE: ${{ github.workspace }}/Tests/ExcelReportTest/Sample.fcpxmld
```

---

## Adding more tests

Put new test classes in this directory. Reuse `ExcelReportFixture.requireFixtureURL()` and `ExcelReportFixture.outputDirectoryURL()` for consistent fixture and output paths.

Good candidates for this target:

- Golden-file parity against a reference `.xlsx` (keep references out of git if large or licensed)
- Filtered exports (`excludeDisabledClips`, `excludedColumns`, `excludedRoles`) written to additional `Output/` files
- Sheet/column-count or cell-format smoke checks on a known fixture

Prefer **`OpenFCPXMLKitTests`** for logic that does not need a full local project (column resolution, layout, `ReportTimecodeFormat`, `ReportBuildPhase` order, synthetic workbook structure, Summary/Media Summary/Keywords/Effects colour rules).
