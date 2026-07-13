# Excel and PDF report test output

This folder holds **generated** `.xlsx` workbooks and `.pdf` reports from the `ExcelReportTest` target. It is gitignored; files here are produced on your machine when you run the export tests.

---

## What gets written

| File | Report preset | Description |
|------|---------------|-------------|
| **`OFK-Default.xlsx`** | `ReportOptions.roleInventoryOnly` | Selected Roles Inventory sheet and per-role inventory tabs only (same as CLI `--report` without `--report-full`) |
| **`OFK-Full.xlsx`** | `ReportOptions.full` | Default sheets plus Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, Summary, and Media Summary (default timecode format `HH:MM:SS:FF`; use CLI `--timecode-format` for other modes) |
| **`OFK-Default.pdf`** | `ReportOptions.roleInventoryOnly` | Role-inventory PDF with cover page, table of contents, and section content pages (same as CLI `--report --create-pdf` without `--report-full`) |

Each test run **overwrites** these files if they already exist.

---

## Source FCPXML

Reports are built from whatever fixture `ExcelReportFixture` resolves:

- A **`.fcpxmld`** bundle (directory with `Info.fcpxml`), or  
- A **`.fcpxml`** single file  

Fixture lookup: `OFK_REPORTING_FCPXML_BUNDLE` → `Sample.fcpxmld` / `Sample.fcpxml` in the parent folder → any other valid `.fcpxml` / `.fcpxmld` there.

See [../README.md](../README.md) for full setup.

---

## Regenerating

From the repository root:

```bash
swift test --filter ExcelReportExportTests
```

Then open `OFK-Default.xlsx`, `OFK-Full.xlsx`, or `OFK-Default.pdf` in Excel, Preview, or your diff tool and compare against a reference export.

For a full PDF on a real fixture (named after the project), use the CLI:

```bash
OpenFCPXMLKit-CLI --report --report-full --create-pdf /path/to/fixture.fcpxmld /path/to/output-dir
```

---

## Notes

- Output file names are fixed (`OFK-Default.xlsx`, `OFK-Full.xlsx`, `OFK-Default.pdf`) so paths stay stable for scripts and future parity tests.  
- The CLI names files after the **project or compound-clip name** inside the FCPXML; test output uses these constant names instead.  
- Do not commit large generated workbooks or PDFs unless you intentionally add golden files for regression testing.
