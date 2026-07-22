# Excel and PDF report test output

This folder holds **generated** `.xlsx` workbooks and `.pdf` reports from the `ExcelReportTest` target (**6** optional Swift Testing integration tests; part of the **1128**-test public suite). It is gitignored; files here are produced on your machine when you run the export tests. Without a local fixture, those tests **cancel** via `Test.cancel` and nothing is written.

---

## What gets written

| File | Report preset | Description |
|------|---------------|-------------|
| **`OFK-Default.xlsx`** | `ReportOptions.roleInventoryOnly` | Selected Roles Inventory sheet and per-role inventory tabs only (same as CLI `--report` without `--report-full`) |
| **`OFK-Full.xlsx`** | `ReportOptions.full` | Default sheets plus Markers … Non-Std Effects & Templates … Speed Change Effects (**Row** on tabular sheets except Non-Std), Summary (project title in **B1**), and Media Summary (**Row** + missing paths; default timecode format `HH:MM:SS:FF`; use CLI `--timecode-format` / `--media-summary-distinguish-proxy` for other modes) |
| **`OFK-Default.pdf`** | `ReportOptions.roleInventoryOnly` + `ReportPDFExport` | Role-inventory PDF with cover (black “About This PDF Export” + `info.circle`), TOC colour chips / content-tint washes, and tinted section pages (same as CLI `--report --create-pdf` without `--report-full`) |
| **`OFK-ExcludedColumns.pdf`** | role inventory + many `excludedColumns` | Same inventory with leftover page width redistributed across remaining columns |
| **`OFK-Copyright.xlsx`** / **`OFK-Copyright.pdf`** | role inventory + `copyrightLabel` | Same as default, with Excel cover **A2** and PDF cover/footer centre copyright line (`--label-copyright` parity) |
| **`OFK-OutsideClipBoundaries.xlsx`** / **`OFK-OutsideClipBoundaries.pdf`** | markers + `includeMarkersOutsideClipBoundaries` | Markers sheet with **Hidden** column (✓ outside host media range / ✗ inside); CLI `--include-markers-outside-clip-boundaries` |
| **`OFK-ProtectedSheets.xlsx`** | role inventory + `protectSheets` | Every worksheet protected (edit lock, no password); CLI `--protect-sheets`; Excel only |

Each test run **overwrites** these files if they already exist.

---

## Source FCPXML

Reports are built from whatever fixture `ExcelReportFixture` resolves:

- A **`.fcpxmld`** bundle (directory with `Info.fcpxml`), or  
- A **`.fcpxml`** single file  

Fixture lookup: `OFK_REPORTING_FCPXML_BUNDLE` → `Sample.fcpxmld` / `Sample.fcpxml` in the parent folder → **`Output/Sample.fcpxmld`** / **`Output/Sample.fcpxml`** → any other valid `.fcpxml` / `.fcpxmld` there.

`Output/Sample.fcpxmld` (and `Output/Sample.fcpxml`) are **gitignored** — keep private local fixtures there; do not commit them.

See [../README.md](../README.md) for full setup.

---

## Regenerating

From the repository root:

```bash
swift test --filter ExcelReportExportTests
```

Then open `OFK-Default.xlsx`, `OFK-Full.xlsx`, `OFK-Default.pdf`, `OFK-ExcludedColumns.pdf`, `OFK-Copyright.xlsx` / `OFK-Copyright.pdf`, `OFK-OutsideClipBoundaries.xlsx` / `OFK-OutsideClipBoundaries.pdf`, or `OFK-ProtectedSheets.xlsx` in Excel, Preview, or your diff tool and compare against a reference export.

For a full PDF on a real fixture (named after the project), use the CLI:

```bash
OpenFCPXMLKit-CLI --report --report-full --create-pdf \
  --label-copyright "© 2026 Example Studios" \
  /path/to/fixture.fcpxmld /path/to/output-dir
```

---

## Notes

- Output file names are fixed (`OFK-Default.xlsx`, `OFK-Full.xlsx`, `OFK-Default.pdf`, `OFK-ExcludedColumns.pdf`, `OFK-Copyright.xlsx`, `OFK-Copyright.pdf`, `OFK-OutsideClipBoundaries.xlsx`, `OFK-OutsideClipBoundaries.pdf`, `OFK-ProtectedSheets.xlsx`) so paths stay stable for scripts and future parity tests.  
- The CLI names files after the **project or compound-clip name** inside the FCPXML; test output uses these constant names instead.  
- Fixture bundles used for local investigation (e.g. `Sample.fcpxmld`) may also live here; discovery prefers root `Sample.*`, then falls back to `Output/`.  
- Do not commit large generated workbooks or PDFs unless you intentionally add golden files for regression testing.


