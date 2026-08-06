# Shot Extraction test output

This folder holds **generated** PNG shots, CSV / Notion manifests, and stable aliases from the `ShotExtractionTest` target (**4** optional Swift Testing integration tests). It is gitignored; files here are produced on your machine when you run the export tests. Without a local fixture (or when media is missing), those tests **cancel** via `Test.cancel` and nothing is written.

---

## What gets written

| File / folder | Description |
|---------------|-------------|
| **`{timeline}-2026-08-06-12-00-00-[CSV]/`** | Full CSV export (PNGs + `.csv` manifest); fixed timestamp from the fixture helper |
| **`{timeline}-2026-08-06-12-00-00-[Notion]/`** | Full Notion export (PNGs + `.json` manifest) |
| **`OFK-Shots.csv`** | Stable copy of the CSV manifest |
| **`OFK-Shots.json`** | Stable copy of the Notion JSON (CSV column key order; Shot ID array order) |
| **`OFK-Shots-result.json`** | Result summary from the CSV + `--result-file-path` parity test |

Each test run **overwrites** the aliases and reuses the fixed-timestamp export folders.

---

## Source FCPXML

Extractions from whatever fixture `ShotExtractionFixture` resolves (`OFK_SHOT_EXTRACTION_FCPXML` → `Sample.*` → auto-discovery). See [../README.md](../README.md).

---

## Regenerating

From the repository root:

```bash
swift test --filter ShotExtractionExportTests
```

Then open `OFK-Shots.csv` / `OFK-Shots.json` and compare against a CLI `--extract-shots` run.
