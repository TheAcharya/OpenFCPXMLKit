# Shot Extraction integration tests

Optional integration tests that extract still-image shots (PNG + CSV / Notion JSON) from a local FCPXML fixture. Use this target when you want to compare OpenFCPXMLKit Shot Extraction output against a real project without running the CLI each time.

**Target:** `ShotExtractionTest` (Swift Testing)  
**Depends on:** `OpenFCPXMLKit`  
**Tests:** **4** `@Test` methods in `@Suite("Shot Extraction export")` / `ShotExtractionExportTests`  
**Public suite (keep in sync):** **1173** listed (`1161` OpenFCPXMLKitTests + **8** ExcelReportTest + **4** ShotExtractionTest; all Swift Testing); **60** public samples

Unit-level Shot Extraction behaviour (Shot ID padding, duration flooring, folder formats, reject video/titles/audio, dry-run, Notion key order) lives in **`OpenFCPXMLKitTests`** — see [Tests/README.md](../README.md) (`FCPXMLShotExtractionTests`).

---

## Fixture input (`.fcpxml` or `.fcpxmld`)

Tests accept **either** format. The primary timeline must be **still images only** (no primary video, titles/generators, or audio). Connected-lane audio is ignored.

| Format | What you provide | How it is loaded |
|--------|------------------|------------------|
| **`.fcpxmld`** | A bundle directory containing `Info.fcpxml` | `FCPXMLFileLoader` reads `Info.fcpxml` inside the bundle |
| **`.fcpxml`** | A single XML file | Loaded directly |

Still-image media must resolve on disk (absolute `media-rep` URLs or paths relative to `mediaBaseURL`).

### Fixture resolution order

1. **Environment variable** — `OFK_SHOT_EXTRACTION_FCPXML` set to a `.fcpxml` path or `.fcpxmld` bundle path  
2. **Preferred local names** — `Sample.fcpxmld` then `Sample.fcpxml` in this directory  
3. **Preferred under `Output/`** — `Output/Sample.fcpxmld` then `Output/Sample.fcpxml`  
4. **Auto-discovery** — first valid `.fcpxml` / `.fcpxmld` in this directory, then under `Output/`

If no fixture is found, tests **cancel** via `try Test.cancel(…)` so CI can pass without a local fixture. Missing still media or a non-still primary timeline also **cancels** (does not fail CI).

### Scene number

| Source | Notes |
|--------|--------|
| `OFK_SHOT_EXTRACTION_SCENE_NUMBER` | Preferred when set |
| Digits in the first timeline display name | e.g. project `Scene 20` → `20` |
| Default | `1` |

### Setup (local)

Place a stills-only export here (not committed — see `.gitignore`):

```
Tests/ShotExtractionTest/
├── Sample.fcpxmld/          ← bundle (recommended)
│   └── Info.fcpxml
└── Sample.fcpxml            ← or a single file
```

Or point at an existing path (for example a Submitted inbox export):

```bash
export OFK_SHOT_EXTRACTION_FCPXML="/path/to/Scene 20.fcpxmld"
export OFK_SHOT_EXTRACTION_SCENE_NUMBER=20   # optional if the project name contains digits
```

---

## Generated output

Running the export tests writes under **`Output/`** (gitignored):

| File / folder | Format | Notes |
|---------------|--------|--------|
| `{timeline}-{timestamp}-[CSV]/` / `[Notion]/` | Full export folder | PNGs + manifest (`.long` folder format; fixed timestamp for stable names) |
| `OFK-Shots.csv` | CSV alias | Copy of the CSV manifest for stable review paths |
| `OFK-Shots.json` | Notion alias | Copy of the Notion JSON (keys in CSV column order; Shot ID array order) |
| `OFK-Shots-result.json` | Result summary | MarkersExtractor-style summary from the CSV + result-file test |

Open `OFK-Shots.csv` / `OFK-Shots.json` locally to compare against a CLI `--extract-shots` run.

---

## CLI parity

```bash
OpenFCPXMLKit-CLI --extract-shots \
  --scene-number 20 \
  --extract-format notion \
  --folder-format long \
  --icon "🎬" \
  --result-file-path /path/to/result.json \
  /path/to/Scene.fcpxmld \
  /path/to/output-dir
```

See [Documentation/Manual/21-Shot-Extraction.md](../../Documentation/Manual/21-Shot-Extraction.md).

---

## Running tests

```bash
# All 4 integration tests (requires a local stills fixture + reachable media)
swift test --filter ShotExtractionExportTests

# Entire Shot Extraction target
swift test --filter ShotExtractionTest
```

---

## Files

| File | Purpose |
|------|---------|
| `ShotExtractionFixture.swift` | Resolves fixture URL, scene number, media base, Output/; cancel helpers |
| `ShotExtractionExportTests.swift` | CSV / Notion / dry-run / result-file exports |
| `Output/` | Generated PNGs, manifests, and aliases (gitignored) |

---

## CI

- **Without fixture:** tests **cancel** (`Test.cancel`); job stays green.  
- **With fixture:** checkout or copy a stills `.fcpxmld` / `.fcpxml` into `Tests/ShotExtractionTest/`, or set `OFK_SHOT_EXTRACTION_FCPXML` in the workflow. Media files must be reachable.

Example:

```yaml
env:
  OFK_SHOT_EXTRACTION_FCPXML: ${{ github.workspace }}/Tests/ShotExtractionTest/Sample.fcpxmld
  OFK_SHOT_EXTRACTION_SCENE_NUMBER: "20"
```

---

## Adding more tests

Reuse `ShotExtractionFixture.requireFixtureURL()` and `extractOrCancel` / `planOrCancel`. Use `import Testing` only — do not mix XCTest.

Prefer **`OpenFCPXMLKitTests` / `FCPXMLShotExtractionTests`** for logic that does not need a full local fixture.
