# Excel and PDF report integration tests

Optional integration tests that build real `.xlsx` workbooks and `.pdf` reports from a local FCPXML fixture. Use a normal **project** export or a standalone **compound-clip** export (event `ref-clip` with no `<project>`). Use this target when you want to compare OpenFCPXMLKit output against reference exports without running the CLI each time.

**Target:** `ExcelReportTest`  
**Depends on:** `OpenFCPXMLKit`, `XLKit`  
**Tests:** 2 (`ExcelReportExportTests`)

Unit-level reporting behaviour (column layout, column exclusion, disabled-clip filtering, timecode formats / DF·NDF, format-aware headers, build-phase order, workbook cell formatting, PDF cover/TOC/pagination, shared row colours, **standalone compound-clip timeline resolution**) lives in **`OpenFCPXMLKitTests`** — see [Tests/README.md](../README.md#reporting--excelpdf-export) (`FCPXMLCompoundClipReportTests`, `FCPXMLReportPDFExportTests`, and related files).

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

If no fixture is found, tests **skip** (`XCTSkip`) so CI can pass without a local fixture.

### Setup (local)

Place your project or compound-clip export here (not committed — see `.gitignore`):

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

Running the export tests writes workbooks and a sample PDF to **`Output/`** (also gitignored):

| File | Report preset | CLI equivalent | Contents |
|------|---------------|----------------|----------|
| `Output/OFK-Default.xlsx` | `ReportOptions.roleInventoryOnly` | `OpenFCPXMLKit-CLI --report <fixture> <dir>` | **Selected Roles Inventory** + per-role sheets (23 fixed columns + Row + dynamic metadata keys) |
| `Output/OFK-Full.xlsx` | `ReportOptions.full` | `OpenFCPXMLKit-CLI --report --report-full <fixture> <dir>` | Default sheets plus Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, **Summary** (project title header + black data rows), and **Media Summary** (red missing-media paths) |
| `Output/OFK-Default.pdf` | `ReportOptions.roleInventoryOnly` | `OpenFCPXMLKit-CLI --report --create-pdf <fixture> <dir>` | Role-inventory PDF with cover page, TOC, and per-sheet tinted content pages |

Cell colours, header styling, and section-sheet colour rules are covered by **`FCPXMLReportExcelExportTests`** and **`FCPXMLReportPDFExportTests`** in `OpenFCPXMLKitTests`. This integration target checks that a real fixture produces complete workbooks and a readable PDF; open `OFK-Full.xlsx` or a full `--create-pdf` export locally to compare layout against a reference export if you maintain one.

See [Output/README.md](Output/README.md) for details on that folder.

`testExportDefaultAndFullWorkbooks` asserts that the default export includes only role inventory, and that the full export includes every optional section (`summary`, `mediaSummary`, markers, keywords, titles, transitions, effects, speed-change effects).

`testExportDefaultRoleInventoryPDF` writes `OFK-Default.pdf` and asserts a valid `%PDF` header and minimum size.

---

## CLI parity

The integration target mirrors common CLI flows. For filtered or full PDF exports, use the CLI or build reports in code:

```bash
# Excel + PDF with the same report configuration
OpenFCPXMLKit-CLI --report --report-full --create-pdf \
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
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: xlsxURL)
try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)
```

See [Documentation/Manual/19-Reporting.md](../../Documentation/Manual/19-Reporting.md) for the full API (`ReportPDFExport`, `ReportTimecodeFormat`, progress phases, column exclusion).

---

## Running tests

```bash
# Export Default + Full workbooks and Default PDF (requires a local fixture)
swift test --filter ExcelReportExportTests

# Entire Excel report target
swift test --filter ExcelReportTest
```

First run on a large fixture can take ~1–2 minutes (report build + XLKit save; PDF export is additional).

---

## Files

| File | Purpose |
|------|---------|
| `ExcelReportFixture.swift` | Resolves fixture URL, `mediaBaseURL`, and `Output/` path; defines output file names |
| `ExcelReportExportTests.swift` | Builds and writes `OFK-Default.xlsx`, `OFK-Full.xlsx`, and `OFK-Default.pdf` |
| `Output/` | Generated workbooks and PDFs (created by tests; gitignored) |

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

- Golden-file parity against a reference `.xlsx` or `.pdf` (keep references out of git if large or licensed)
- Filtered exports (`excludeDisabledClips`, `excludedColumns`, `excludedRoles`) written to additional `Output/` files
- Full `--create-pdf` smoke checks on a known fixture

Prefer **`OpenFCPXMLKitTests`** for logic that does not need a full local fixture (column resolution, layout, `ReportTimecodeFormat`, `ReportBuildPhase` order, synthetic workbook/PDF structure, Summary/Media Summary/Keywords/Effects colour rules, compound-clip-only timeline discovery).
