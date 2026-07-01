# Excel report integration tests

Optional integration tests that build real `.xlsx` workbooks from a local FCPXML project. Use this target when you want to compare OpenFCPXMLKit output against reference exports without running the CLI each time.

**Target:** `ExcelReportTest`  
**Depends on:** `OpenFCPXMLKit`, `XLKit`

---

## Fixture input (`.fcpxml` or `.fcpxmld`)

Tests accept **either** format:

| Format | What you provide | How it is loaded |
|--------|------------------|------------------|
| **`.fcpxmld`** | A bundle directory (e.g. `MyProject.fcpxmld/`) containing `Info.fcpxml` | `FCPXMLFileLoader` reads `Info.fcpxml` inside the bundle |
| **`.fcpxml`** | A single XML file | Loaded directly |

Relative media paths in the Summary sheet are resolved from the bundle directory (for `.fcpxmld`) or the file's parent folder (for `.fcpxml`).

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

| File | CLI equivalent | Contents |
|------|----------------|----------|
| `Output/OFK-Default.xlsx` | `OpenFCPXMLKit-CLI --report <fixture> <dir>` | Role inventory only (Selected Roles + per-role sheets) |
| `Output/OFK-Full.xlsx` | `OpenFCPXMLKit-CLI --report --report-full <fixture> <dir>` | Role inventory + Markers, Keywords, Titles & Generators, Transitions, Effects, Speed Change Effects, Summary |

See [Output/README.md](Output/README.md) for details on that folder.

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
| `ExcelReportFixture.swift` | Resolves fixture URL and `Output/` path |
| `ExcelReportExportTests.swift` | Builds and writes `OFK-Default.xlsx` and `OFK-Full.xlsx` |
| `Output/` | Generated workbooks (created by tests) |

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

Put new test classes in this directory. Reuse `ExcelReportFixture.requireFixtureURL()` and `ExcelReportFixture.outputDirectoryURL()` for consistent fixture and output paths. Parity checks against reference `.xlsx` files can read from `Output/` or from a separate local reference folder (keep references out of git if they are large or licensed).
