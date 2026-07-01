# Excel report test output

This folder holds **generated** `.xlsx` workbooks from the `ExcelReportTest` target. It is gitignored; files here are produced on your machine when you run the export tests.

---

## What gets written

| File | Report preset | Description |
|------|---------------|-------------|
| **`OFK-Default.xlsx`** | `ReportOptions.roleInventoryOnly` | Selected Roles sheet and per-role inventory tabs only (same as CLI `--report` without `--report-full`) |
| **`OFK-Full.xlsx`** | `ReportOptions.full` | Default sheets plus Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, and Files summary |

Each test run **overwrites** these files if they already exist.

---

## Source FCPXML

Workbooks are built from whatever fixture `ExcelReportFixture` resolves:

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

Then open `OFK-Default.xlsx` or `OFK-Full.xlsx` in Excel, Numbers, or your diff tool and compare against a reference export (e.g. Production's Best Friend).

---

## Notes

- Output file names are fixed (`OFK-Default.xlsx`, `OFK-Full.xlsx`) so paths stay stable for scripts and future parity tests.  
- The CLI names files after the **project name** inside the FCPXML; test output uses these constant names instead.  
- Do not commit large generated workbooks unless you intentionally add golden files for regression testing.
