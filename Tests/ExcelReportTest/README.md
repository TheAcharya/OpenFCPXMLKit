# Excel and PDF report integration tests

Optional integration tests that build real `.xlsx` workbooks and `.pdf` reports from a local FCPXML fixture. Use a normal **project** export or a standalone **compound-clip** export (event `ref-clip` with no `<project>`). Use this target when you want to compare OpenFCPXMLKit output against reference exports without running the CLI each time.

**Target:** `ExcelReportTest` (Swift Testing)  
**Depends on:** `OpenFCPXMLKit`, `XLKit`  
**Tests:** **6** `@Test` methods in `@Suite("Excel report export")` / `ExcelReportExportTests`  
**Public suite (keep in sync):** **1124** listed (`1118` OpenFCPXMLKitTests + **6** ExcelReportTest; all Swift Testing); **60** public samples

Unit-level reporting behaviour (universal **Row** on all tabular sheets, Summary title in **B1**, column layout including **Duplicate Frames** / **Codecs** / **Ingest Date** / **Frame Size / Audio Config**, per-role **Total:** footers, Non-Std Effects & Templates sheet, column exclusion including `ReportColumn.row`, disabled-clip filtering, timecode formats / DF·NDF, format-aware headers, build-phase order including `.projecting` and Non-Std before Effects, workbook cell formatting, optional `copyrightLabel` cover/footer branding, `includeMarkersOutsideClipBoundaries` / Markers **Hidden** column, `protectSheets` worksheet protection, `ReportMediaResolutionPolicy` / Media Summary proxy-original distinction, PDF cover notes / black header + `info.circle`, TOC colour chips, column-width expansion after exclusions, pagination, shared row colours, **standalone compound-clip timeline resolution**, **Projection-first** Markers/Keywords/Titles/Transitions/Effects) lives in **`OpenFCPXMLKitTests`** — see [Tests/README.md](../README.md#reporting--excelpdf-export) (`FCPXMLCompoundClipReportTests`, `FCPXMLTimelineProjectionTests`, `FCPXMLReportObligationCorpusTests`, `FCPXMLMarkersReportTests`, `FCPXMLReportPDFExportTests`, `FCPXMLReportPDFSheetPlanTests`, `FCPXMLReportPDFTableLayoutTests`, `FCPXMLReportColumnExclusionTests`, `FCPXMLReportExcelExportTests`, `FCPXMLRoleInventorySheetTotalTests`, `FCPXMLRoleInventoryDuplicateFramesTests`, `FCPXMLNonStandardEffectsTemplatesReportTests`, and related files).

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
3. **Preferred under `Output/`** — `Output/Sample.fcpxmld` then `Output/Sample.fcpxml` (convenient when fixtures sit beside generated workbooks)  
4. **Auto-discovery** — first valid `.fcpxml` / `.fcpxmld` in this directory, then under `Output/` (skips Swift sources, markdown, `.xlsx`, and `.pdf`)

If no fixture is found, tests **cancel** via `try Test.cancel(…)` so CI can pass without a local fixture.

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
| `Output/OFK-Default.xlsx` | `ReportOptions.roleInventoryOnly` | `OpenFCPXMLKit-CLI --report <fixture> <dir>` | **Selected Roles Inventory** + per-role sheets (**Row** + **26** fixed columns including Duplicate Frames / Codecs / Ingest Date / Frame Size / Audio Config + dynamic metadata keys; per-role **Total:** footers) |
| `Output/OFK-Full.xlsx` | `ReportOptions.full` | `OpenFCPXMLKit-CLI --report --report-full <fixture> <dir>` | Default sheets plus Markers … Speed Change Effects (**Row** on each), **Summary** (project title in **B1**, narrow Row column A, black data rows), and **Media Summary** (**Row** + red missing-media paths) |
| `Output/OFK-Default.pdf` | `ReportOptions.roleInventoryOnly` | `OpenFCPXMLKit-CLI --report --create-pdf <fixture> <dir>` | Role-inventory PDF with cover page (black “About This PDF Export” + `info.circle`), TOC (accent colour chips + content-tint washes per sheet `colorIndex`), and per-sheet tinted content pages |
| `Output/OFK-ExcludedColumns.pdf` | role inventory + many `excludedColumns` | `--report --create-pdf --exclude-column …` | Same sheets with remaining columns expanded to fill A4 landscape width |
| `Output/OFK-Copyright.xlsx` / `Output/OFK-Copyright.pdf` | role inventory + `copyrightLabel` | `--report --create-pdf --label-copyright "…"` | Cover/footer copyright line for manual review of `--label-copyright` |
| `Output/OFK-OutsideClipBoundaries.xlsx` / `Output/OFK-OutsideClipBoundaries.pdf` | markers + `includeMarkersOutsideClipBoundaries` | `--report --report-markers --include-markers-outside-clip-boundaries --create-pdf` | Markers sheet with **Hidden** column (✓/✗) for out-of-bounds markers |
| `Output/OFK-ProtectedSheets.xlsx` | role inventory + `protectSheets` | `--report --protect-sheets` | Every worksheet protected (edit lock; not encryption; Excel only) |

Cell colours, header styling, section-sheet colour rules, TOC colour chips, and PDF column-width expansion are covered by **`FCPXMLReportExcelExportTests`**, **`FCPXMLReportPDFExportTests`**, **`FCPXMLReportPDFSheetPlanTests`**, and **`FCPXMLReportPDFTableLayoutTests`** in `OpenFCPXMLKitTests`. This integration target checks that a real fixture produces complete workbooks and readable PDFs; open `OFK-Full.xlsx`, `OFK-Default.pdf`, `OFK-ExcludedColumns.pdf`, `OFK-Copyright.xlsx` / `.pdf`, `OFK-OutsideClipBoundaries.xlsx` / `.pdf`, or `OFK-ProtectedSheets.xlsx` locally to compare layout, copyright branding, Markers **Hidden**, and sheet protection against a reference export if you maintain one.

See [Output/README.md](Output/README.md) for details on that folder.

`exportDefaultAndFullWorkbooks` asserts that the default export includes only role inventory, and that the full export includes every optional section (`summary`, `mediaSummary`, markers, keywords, titles, transitions, nonStandardEffectsTemplates, effects, speedChangeEffects).

`exportDefaultRoleInventoryPDF` writes `OFK-Default.pdf` and asserts a valid `%PDF` header and minimum size.

`exportRoleInventoryPDFWithManyExcludedColumns` writes `OFK-ExcludedColumns.pdf` after excluding many inventory columns (leftover horizontal space must expand remaining columns).

`exportRoleInventoryWithCopyrightLabel` writes `OFK-Copyright.xlsx` / `OFK-Copyright.pdf` and asserts Excel cover **A2** plus PDF cover/footer text for `--label-copyright` parity.

`exportMarkersIncludingOutsideClipBoundaries` writes `OFK-OutsideClipBoundaries.xlsx` / `OFK-OutsideClipBoundaries.pdf` with `includeMarkersOutsideClipBoundaries` (CLI `--include-markers-outside-clip-boundaries`), asserts the Markers **Hidden** column, and compares row counts against the default Markers filter.

`exportProtectedSheetsWorkbook` writes `OFK-ProtectedSheets.xlsx` with `protectSheets` (CLI `--protect-sheets`) and asserts every worksheet has XLKit sheet protection.

---

## CLI parity

The integration target mirrors common CLI flows. For filtered or full PDF exports, use the CLI or build reports in code:

```bash
# Excel + PDF with the same report configuration
OpenFCPXMLKit-CLI --report --report-full --create-pdf \
  --label-copyright "© 2026 Example Studios" \
  --media-resolution fail-soft \
  --media-summary-distinguish-proxy \
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
options.copyrightLabel = "© 2026 Example Studios"
options.mediaResolutionPolicy = .failSoft
options.mediaSummaryDistinguishProxyAndOriginal = true
let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
let report = try await fcpxml.buildReport(options: options) { phase in
    // phase order matches GUI / workbook: projecting (when needed), then inventory first
    _ = phases
}
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: xlsxURL)
try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)
```

See [Documentation/Manual/20-Reporting.md](../../Documentation/Manual/20-Reporting.md) and [11 — Timeline Projection](../../Documentation/Manual/12-Timeline-Projection.md) for the full API (`ReportPDFExport`, `ReportTimecodeFormat`, progress phases, column exclusion, Projection).

---

## Running tests

```bash
# All 6 exports (Default/Full xlsx, Default/Excluded/Copyright PDFs, OutsideClipBoundaries, ProtectedSheets; requires a local fixture)
swift test --filter ExcelReportExportTests

# Entire Excel report target
swift test --filter ExcelReportTest
```

First run on a large fixture can take ~1–2 minutes (report build + XLKit save; PDF export is additional).

---

## Files

| File | Purpose |
|------|---------|
| `ExcelReportFixture.swift` | Resolves fixture URL (including under `Output/`), `mediaBaseURL`, and `Output/` path; defines output file names |
| `ExcelReportExportTests.swift` | Builds and writes `OFK-Default.xlsx`, `OFK-Full.xlsx`, `OFK-Default.pdf`, `OFK-ExcludedColumns.pdf`, `OFK-Copyright.xlsx`, `OFK-Copyright.pdf`, `OFK-OutsideClipBoundaries.xlsx` / `.pdf`, and `OFK-ProtectedSheets.xlsx` |
| `Output/` | Generated workbooks and PDFs (created by tests; gitignored); may also hold local investigation fixtures such as `Sample.fcpxmld` |

---

## CI

- **Without fixture:** tests **cancel** (`Test.cancel`); job stays green.  
- **With fixture:** checkout or copy a `.fcpxmld` / `.fcpxml` into `Tests/ExcelReportTest/`, or set `OFK_REPORTING_FCPXML_BUNDLE` in the workflow.

Example:

```yaml
env:
  OFK_REPORTING_FCPXML_BUNDLE: ${{ github.workspace }}/Tests/ExcelReportTest/Sample.fcpxmld
```

---

## Adding more tests

Put new `@Test` methods (or suites) in this directory. Reuse `ExcelReportFixture.requireFixtureURL()` and `ExcelReportFixture.outputDirectoryURL()` for consistent fixture and output paths. Use `import Testing` only — do not mix XCTest.

Good candidates for this target:

- Golden-file parity against a reference `.xlsx` or `.pdf` (keep references out of git if large or licensed)
- Filtered exports (`excludeDisabledClips`, `excludedColumns`, `excludedRoles`) written to additional `Output/` files
- Full `--create-pdf` smoke checks on a known fixture

Prefer **`OpenFCPXMLKitTests`** for logic that does not need a full local fixture (column resolution, layout, `ReportTimecodeFormat`, `ReportBuildPhase` order including `.projecting`, Projection window / annotation tests, synthetic workbook/PDF structure, Summary/Media Summary/Keywords/Effects colour rules, compound-clip-only timeline discovery, `ReportMediaResolutionPolicy`).

