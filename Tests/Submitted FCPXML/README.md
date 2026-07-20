# Submitted FCPXML (Private Inbox)

Local-only drop zone for **private / user-supplied** FCPXML exports used when investigating parsing or Excel/PDF reporting edge cases.

**These files are never committed.** Contents are gitignored; only this README (and `.gitkeep`) is tracked. See [GUARDRAILS.md](../../GUARDRAILS.md) (Sign: never-commit-submitted-fcpxml) and [ARCHITECTURE.md](../../ARCHITECTURE.md) §8.

**Public suite counts (keep in sync):** **1124** tests listed (`1118` OpenFCPXMLKitTests + `6` ExcelReportTest; **all Swift Testing**); **60** public samples under `Tests/FCPXML Samples/FCPXML/` (e.g. `HiddenMarkers.fcpxml` was promoted from this workflow).

---

## Why this folder exists

Public fixtures live in `Tests/FCPXML Samples/FCPXML/` and ship with the package. Real-world exports often contain:

- Absolute media paths, volume names, library locations  
- macOS `<bookmark>` blobs (encoded paths)  
- Person / project / client names  

Use **Submitted FCPXML** as a temporary inbox so Cursor (or you) can analyse a private file locally, reproduce a failure, fix the engine, then — if useful — promote a **minimal anonymised** fixture into the public samples suite.

---

## Layout

```
Tests/Submitted FCPXML/
├── README.md                 ← tracked (this file)
├── Inbox/                    ← drop raw exports here (gitignored)
│   ├── CaseName.fcpxml
│   └── CaseName.fcpxmld/
├── Notes/                    ← optional local notes (gitignored)
│   └── CaseName.md
└── .gitkeep                  ← keeps empty Inbox/Notes visible in some UIs
```

Suggested naming: `YYYY-MM-DD-ShortLabel.fcpxml` (e.g. `2026-07-16-MulticamJLCuts.fcpxml`).

---

## Workflow (recommended)

1. **Drop** the private `.fcpxml` or `.fcpxmld` into `Inbox/`.
2. **Do not** add it to `Package.swift` resources or to `FCPXML Samples/`.
3. **Anonymise before any commit or PR** (even if you later promote a fixture):
   - Replace `file://` media / library paths with neutral ones (e.g. `file:///Users/user/Movies/…`).
   - Remove all `<bookmark>…</bookmark>` elements.
   - Scrub identifying project / event / clip / title names if needed.
4. **Reproduce** locally:
   ```bash
   # Parse smoke
   swift test --filter FCPXMLSubmittedFCPXMLSmokeTests

   # Or full report against the file via CLI / ExcelReportTest
   export OFK_REPORTING_FCPXML_BUNDLE="$(pwd)/Tests/Submitted FCPXML/Inbox/YourFile.fcpxml"
   swift test --filter ExcelReportExportTests
   ```
5. **Fix** parsing / Projection / Reporting in `Sources/OpenFCPXMLKit/`.
6. **Promote** (optional): add a **minimal anonymised** regression sample under `Tests/FCPXML Samples/FCPXML/` plus a focused `FCPXMLFileTest_*` or reporting test. Delete or keep the private original only in `Inbox/` (still gitignored).
7. **Never** paste private path strings, bookmarks, or client names into commit messages, CHANGELOG, or public docs.

---

## What agents / Cursor should do

When asked to investigate a file in this folder:

| Do | Don’t |
|----|--------|
| Load from disk via package-root path | Bundle it as a SwiftPM resource |
| Anonymise before proposing a public fixture | Commit `Inbox/` contents |
| Add a **small** regression test to the public suite when the bug is fixed | Dump the whole private timeline into public samples |
| Prefer Projection / Reporting / Parsing fixes over report-only XML hacks | Log or print absolute private paths in assertions |

Optional local notes in `Notes/` (e.g. expected sheet rows, frame rate, FCP version) help future sessions; those notes are also gitignored.

---

## Optional smoke tests

`OpenFCPXMLKitTests` includes **`FCPXMLSubmittedFCPXMLSmokeTests`**: if `Inbox/` has any `.fcpxml` / `.fcpxmld`, each is loaded and asserted to parse as `fcpxml`. If `Inbox/` is empty, the test **cancels** via `Test.cancel` so CI stays green.

This does **not** replace promoting anonymised fixtures into `FCPXML Samples/`.

---

## Relation to other folders

| Folder | Committed? | Purpose |
|--------|------------|---------|
| `Tests/FCPXML Samples/FCPXML/` | Yes | Canonical public fixtures + CI (**60** `.fcpxml` files) |
| `Tests/ExcelReportTest/` | Fixture no / README yes | Local full workbook/PDF visual check (**6** optional Swift Testing tests; cancel without fixture) |
| `Tests/Submitted FCPXML/` | README only | Private investigation inbox |

---

## Privacy checklist (before any share or promote)

- [ ] No real volume / user / company paths in `src` or `library location`
- [ ] No `<bookmark>` elements
- [ ] Identifying names scrubbed or genericised
- [ ] Regression covered by a **public** anonymised sample + test when appropriate

