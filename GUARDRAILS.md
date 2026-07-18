# OpenFCPXMLKit — Guardrails

Hard constraints for contributors and AI agents. Prefer this file when deciding **what not to do**; prefer [ARCHITECTURE.md](ARCHITECTURE.md) for **how the system is shaped**.

**See also:** [ARCHITECTURE.md](ARCHITECTURE.md), [.cursorrules](.cursorrules), [AGENT.md](AGENT.md), [Tests/README.md](Tests/README.md), [CONTRIBUTING.md](CONTRIBUTING.md).

**Current suite (keep in sync):** **1084** tests listed in `swift test --list-tests` — **1078** in `OpenFCPXMLKitTests` (1075 XCTest + 3 Swift Testing `@Test`) + **6** optional `ExcelReportTest`; **60** public sample `.fcpxml` files.

---

## How to use this document

| Audience | Expectation |
|----------|-------------|
| **Human contributors** | Treat §1–§8 as merge blockers unless an ADR / maintainer explicitly waives a rule. |
| **AI agents** | Read this file before structural or reporting changes. Do not rationalize around a guardrail; ask or stop. |
| **Both** | When a rule is learned from a regression, add a new entry under §9 (Signs) with Trigger / Instruction / Reason / Provenance. |

**Relationship to other docs**

- **ARCHITECTURE.md** — layers, folders, design decisions, diagrams.
- **AGENT.md / .cursorrules** — living agent briefing (must stay in sync with each other).
- **GUARDRAILS.md** — short, enforceable “never / always” list. Keep it scannable; link out for depth.

---

## 1. Naming & product identity

| Rule | Detail |
|------|--------|
| **OpenFCPXMLKit only** | Use OpenFCPXMLKit naming in code, comments, symbols, CLI, and logs (`ServiceLogger`, `OFKXML*`, `createService()`, …). No legacy fork identifiers. |
| **No marketing names in code** | Never use “PBF” or “Production’s Best Friend” in source, comments, symbol names, or CLI/log output. Describe reporting neutrally (“Excel report”, “PDF report”, “role inventory”, “workbook export”). Those marketing terms may appear **only** in prose docs (README, CHANGELOG, Manual, agent guides). |
| **Tests are FCPXML-prefixed** | Every XCTest case class is `FCPXML…` except the module umbrella `OpenFCPXMLKitTests`. |

---

## 2. Layer boundaries (non-negotiable)

Extend the engine **bottom-up**. Do not invent FCPXML meaning inside Reporting.

```text
XML → Parsing → Model → Extraction → Projection → Reporting
```

| Always | Never |
|--------|-------|
| Put new XML facts in **Model / Parsing** first | Parse or reinterpret FCPXML only inside `Reporting/` builders |
| Put occupancy / retiming / channel visibility in **Projection** | Duplicate timeline math, role resolution, or story walks in Excel/PDF exporters |
| Keep **Reporting** presentation-thin (rows, columns, colours, sheet layout) | Add report-only ad hoc XML walks when Extraction/Projection can supply the fact |
| Prefer **Projection-first** for Markers / Keywords / Titles / Transitions / Effects (Extraction fallback) | Bypass `ReportProjectionContext` / project-once when those sections are enabled |

See ARCHITECTURE.md §2.7 for the full “where to put a change” table.

---

## 3. FCPXML compatibility & versions

| Rule | Detail |
|------|--------|
| **1.5 floor** | Remain backward compatible with FCPXML **1.5**. Optional attributes/elements from later versions (e.g. 1.11, 1.13) must be omitted or ignored when reading/writing/converting to 1.5. Mark newer features in comments with the minimum version (`FCPXML 1.13+`). |
| **Supported range** | DTDs and parsing cover **1.5–1.14**. Do not claim support for versions outside that without DTD + tests. |
| **Conversion strips** | Version conversion must set the root version **and** strip elements not in the target DTD. Validate after convert when the CLI/API path requires it. |
| **Bundle format** | `.fcpxmld` only for versions that support it (`FCPXMLVersion.supportsBundleFormat` → 1.10+). 1.5–1.9 always `.fcpxml`. |
| **Frame rates** | Only Final Cut Pro rates used in tests and public APIs: 23.976, 24, 25, 29.97, 30, 50, 59.94, 60. |

---

## 4. Architecture & concurrency

| Rule | Detail |
|------|--------|
| **Protocol + DI** | Core operations live behind protocols with sync and async APIs. Inject via `FCPXMLService` / `FCPXMLUtility`; do not hard-wire concrete types in public extension APIs. |
| **`defaultForExtensions`** | Extension APIs that cannot take parameters use **`FCPXMLUtility.defaultForExtensions`** only. Custom behaviour → modular API with `using:`. No hidden concrete types. |
| **One load path** | URL loading goes through **`FCPXMLFileLoader`** (`.fcpxml` / `.fcpxmld`). Do not add a second URL→document path. |
| **OFKXML on all platforms** | Cross-platform code uses `OFKXML*` + `OFKXMLDefaultFactory()`. Do not assume Foundation `XMLDocument` on iOS. Full DTD validation is macOS-only; iOS uses structural validation. |
| **Sendable honesty** | Foundation XML, OFKXML wrappers, and SwiftTimecode types are **not** Sendable. Provide async/await, but **do not** introduce Task-based concurrency over those types. |
| **Strict concurrency** | Code must build under Swift 6 `-strict-concurrency=complete` (CI enforces this). Prefer removing `@unchecked Sendable` over spreading it. |
| **SwiftTimecode API** | Use `Timecode(.realTime(seconds:), at:)` and `.fps23_976`, `.fps24`, … — not legacy `._24` / `realTime: at:` initialisers. |

---

## 5. Reporting & CLI honesty

| Rule | Detail |
|------|--------|
| **Build once, export many** | Build a single `Report`; export Excel and/or PDF from that model. Do not diverge section logic between exporters. |
| **Presentation vs security** | `protectSheets` / `--protect-sheets` is an **Excel edit lock**, not file-open encryption. Document that clearly in help and Manual. Do **not** imply PDF password protection from this flag. |
| **Markers “Hidden”** | Out-of-bounds markers (`start` outside host media range) are **not** FCPXML `hidden-clip-marker` (1.13+). Default omits out-of-bounds markers; `--include-markers-outside-clip-boundaries` adds them + a **Hidden** column. **Hidden** is not a `--exclude-column` / `ReportColumn` target. |
| **Universal Row** | Tabular Excel/PDF sheets get a 1-based **Row** column by default (`ensuringRowColumn` / `allowsInjectedRowColumn`) unless explicitly excluded. |
| **CLI modifiers need `--report`** | Report-only flags (`--report-full`, section flags, `--protect-sheets`, `--create-pdf`, exclusions, …) must require `--report`. |
| **No help-submenu refactor by default** | Keep flat ArgumentParser flags + `@OptionGroup` unless a maintainer explicitly requests a subcommand redesign. |

---

## 6. Tests & fixtures

| Rule | Detail |
|------|--------|
| **Tests with behaviour** | Public API and report behaviour changes need tests. Prefer core (parse / extract / project) tests **plus** report shape tests when fixing a report gap. |
| **Hybrid XCTest** | Do **not** wholesale migrate XCTest → Swift Testing. Stay hybrid; use Swift Testing selectively for new/parameterized tests when it helps. |
| **Missing samples skip** | Tests that need a sample use `XCTSkip` when the file is absent — do not fail CI on optional local fixtures. |
| **Never commit private FCPXML** | `Tests/Submitted FCPXML/` inbox contents and private ExcelReportTest fixtures (`.fcpxml` / `.fcpxmld` under those trees) are **gitignored**. Never commit or push private project XML to GitHub. Anonymise → reproduce → fix → promote a **minimal public** sample when appropriate. |
| **ExcelReportTest is optional** | Integration target may skip without a local fixture; do not make CI depend on private Sample bundles. |
| **Update counts when adding tests** | Keep listed counts aligned in `Tests/README.md`, `AGENT.md`, and `.cursorrules` when you add or remove tests. |

---

## 7. Documentation & changelog

| Rule | Detail |
|------|--------|
| **AGENT ↔ .cursorrules** | When you update one, update the other. Same overview, architecture, test structure, and conventions. |
| **Feature docs** | User-visible behaviour → Manual (esp. 16 CLI / 19 Reporting / 20 Projection) and CLI README as needed. Structural boundaries → ARCHITECTURE.md. Hard constraints → this file. |
| **CHANGELOG** | Keep a Changelog format. Version heading links to the GitHub release tag. Sections: **✨ New Features**, **🔧 Improvements**, **🐛 Bug Fixes** (empty → “None in this release.”). |
| **File headers** | New Swift files use the project header (see ARCHITECTURE.md §5.2): OpenFCPXMLKit URL line, MIT, tabbed purpose block — no `Created by` / extra copyright lines. |

---

## 8. Safety & scope

| Rule | Detail |
|------|--------|
| **No unsafe / C escape hatches** | Do not introduce unsafe pointers, dynamic code execution, or C APIs for convenience. |
| **No exploit / malware work** | Do not write exploits, exploit PoCs, or attack tooling against any system. |
| **Secrets stay out of git** | Do not commit `.env`, credentials, or private media paths that identify a customer library. Anonymise sample paths. |
| **Destructive git only if asked** | No force-push to main, hard reset, or hook-skipping unless the user explicitly requests it. |
| **Commit only when asked** | Agents create commits only when the user explicitly requests a commit. |

---

## 9. Signs (learned constraints)

Append new signs when a failure repeats or a design decision must not drift. Keep each entry short.

### Template

```markdown
### Sign: short-title
- **Trigger:** When …
- **Instruction:** Always / Never …
- **Reason:** …
- **Provenance:** YYYY-MM-DD — brief note (PR / incident / design lock)
```

### Active signs

### Sign: reporting-stays-thin
- **Trigger:** A report sheet is missing a clip, marker, role, effect, or duration fact.
- **Instruction:** Check Model → Extraction → Projection before adding XML walks in `Reporting/`.
- **Reason:** Duplicate walks diverge from CLI presets and timeline tools; ARCHITECTURE §2.7.
- **Provenance:** 2026-07 — Timeline Projection / reporting layer lock.

### Sign: markers-hidden-vs-hidden-clip-marker
- **Trigger:** Implementing or documenting “hidden markers”.
- **Instruction:** Treat timeline/Tags-hidden markers as **out-of-bounds `start`**; do not conflate with empty `hidden-clip-marker` (1.13+). Default filter omits out-of-bounds; opt-in flag adds **Hidden** column.
- **Reason:** Matches FCP Tags behaviour; MarkersExtractor #34-inspired semantics.
- **Provenance:** 2026-07 — design lock for `--include-markers-outside-clip-boundaries`.

### Sign: protect-sheets-is-edit-lock
- **Trigger:** Password / protect / encrypt options for reports.
- **Instruction:** `--protect-sheets` / `protectSheets` applies XLKit worksheet protection only. Do not advertise workbook open-password or PDF encryption via this flag.
- **Reason:** XLKit supports sheet protection, not file encryption; PDF passwords belong in Preview (or a future dedicated API).
- **Provenance:** 2026-07 — design lock for `--protect-sheets`.

### Sign: no-wholesale-swift-testing-migration
- **Trigger:** Urge to “modernise” the test suite to Swift Testing.
- **Instruction:** Stay hybrid; migrate selectively for new/parameterized tests only.
- **Reason:** Large XCTest surface; migration risk outweighs benefit without a dedicated project.
- **Provenance:** 2026-07 — explicit project decision.

### Sign: never-commit-submitted-fcpxml
- **Trigger:** Debugging with a user-supplied `.fcpxml` / `.fcpxmld`.
- **Instruction:** Keep it under `Tests/Submitted FCPXML/` (gitignored). Promote only anonymised minimal public fixtures.
- **Reason:** Private library paths and project names must not land on GitHub.
- **Provenance:** Standing project policy — see `Tests/Submitted FCPXML/README.md`.

---

## 10. Quick checklist before merge

- [ ] Change sits in the correct layer (ARCHITECTURE §2.7 / Guardrails §2).
- [ ] Public behaviour has tests; optional fixtures use `XCTSkip`.
- [ ] No PBF / legacy naming in code or CLI output.
- [ ] FCPXML 1.5 compatibility preserved; newer features version-marked.
- [ ] Concurrency: no Task over non-Sendable XML/timecode types.
- [ ] Docs: AGENT.md ↔ .cursorrules if agent briefing changed; Manual/CLI/CHANGELOG as needed.
- [ ] Private FCPXML / secrets not staged.

---

## 11. References

- **Internal:** [ARCHITECTURE.md](ARCHITECTURE.md), [AGENT.md](AGENT.md), [.cursorrules](.cursorrules), [Tests/README.md](Tests/README.md), [Tests/Submitted FCPXML/README.md](Tests/Submitted%20FCPXML/README.md), [Documentation/Manual/00-Index.md](Documentation/Manual/00-Index.md).
- **External:** [Final Cut Pro XML](https://fcp.cafe/developers/fcpxml/), [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/), [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/).
