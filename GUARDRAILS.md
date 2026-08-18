# OpenFCPXMLKit — Guardrails

Hard constraints for contributors and AI agents. Prefer this file when deciding **what not to do**; prefer [ARCHITECTURE.md](ARCHITECTURE.md) for **how the system is shaped**.

**See also:** [ARCHITECTURE.md](ARCHITECTURE.md), [.cursorrules](.cursorrules), [AGENT.md](AGENT.md), [Tests/README.md](Tests/README.md), [CONTRIBUTING.md](CONTRIBUTING.md).

**Current suite (keep in sync):** **1222** tests listed in `swift test list` — **1208** in `OpenFCPXMLKitTests` + **10** optional `ExcelReportTest` + **4** optional `ShotExtractionTest` (all Swift Testing `@Test`; no XCTest); **60** public sample `.fcpxml` files.

---

## Table of Contents

- [How to use this document](#how-to-use-this-document)
- [1. Naming & product identity](#1-naming--product-identity)
- [2. Layer boundaries (non-negotiable)](#2-layer-boundaries-non-negotiable)
- [3. FCPXML compatibility & versions](#3-fcpxml-compatibility--versions)
- [4. Architecture & concurrency](#4-architecture--concurrency)
- [5. Reporting & CLI honesty](#5-reporting--cli-honesty)
- [6. Tests & fixtures](#6-tests--fixtures)
- [7. Documentation & changelog](#7-documentation--changelog)
- [8. Safety & scope](#8-safety--scope)
- [9. Signs (learned constraints)](#9-signs-learned-constraints)
  - [Active signs](#active-signs)
- [10. Quick checklist before merge](#10-quick-checklist-before-merge)
- [11. References](#11-references)

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
| **Tests are FCPXML-prefixed** | Every test suite type is `FCPXML…` except the module umbrella `OpenFCPXMLKitTests`. |

---

## 2. Layer boundaries (non-negotiable)

Extend the engine **bottom-up**. Do not invent FCPXML meaning inside Reporting.

```text
XML → Parsing → Model → Extraction → Projection → Reporting
```

**Authoring** (`Authoring/`) is a **parallel create path** (detached value graph). It must not feed Reporting, and Reporting must not depend on Authoring types.

| Always | Never |
|--------|-------|
| Put new XML facts in **Model / Parsing** first | Parse or reinterpret FCPXML only inside `Reporting/` builders |
| Put occupancy / retiming / channel visibility in **Projection** | Duplicate timeline math, role resolution, or story walks in Excel/PDF exporters |
| Keep **Reporting** presentation-thin (rows, columns, colours, sheet layout) | Add report-only ad hoc XML walks when Extraction/Projection can supply the fact |
| Prefer **Projection-first** for Markers / Keywords / Titles / Transitions / Effects (Extraction fallback) | Bypass `ReportProjectionContext` / project-once when those sections are enabled |
| Keep **Authoring** omit-on-write honest via `VersionAvailability` / `VersionFeatureGate` | Use Authoring types inside Reporting builders or invent FCPXML meaning only in Authoring when Model should own it |

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
| **Chapter markers on Markers** | `includeChapterMarkersInMarkersReport` defaults **`true`**. No separate CLI chapter flag; Excel Type = Chapter filter is the user-facing opt-out. API may set `false`. |
| **Universal Row** | Tabular Excel/PDF sheets get a 1-based **Row** column by default (`ensuringRowColumn` / `allowsInjectedRowColumn`) unless explicitly excluded. |
| **Row colour ≠ optional columns** | Row text colours come from typed row facts (`FCPXMLReportRowColorPolicy` semantic APIs), not from whether Role ▸ Subrole / Category / Kind columns are exported. Never gate Excel cell writes on colour lookup. Excluding those columns must not empty sheets or drop tinting (Sign `row-colour-survives-column-exclusion`). |
| **Empty enabled section sheets** | When a section is enabled but has no data rows, Excel and PDF **keep** headers and show one status cell via `ReportEmptySectionStatus` (**No Markers Found**, **No Keywords Found**, **No Titles & Generators Found**, **No Transitions Found**, **No Effects Found**, **No Speed Change Effects Found**, **No Non-Std Effects Found**, **No Roles Found**; Media Summary **No Missing Media**). Do **not** omit empty Markers/Keywords/Titles/Transitions/Effects/Non-Std/Selected Roles Inventory/Media Summary when that section is enabled. Per-role inventory tabs may still omit when empty. Summary keeps its project-metrics layout. |
| **Per-role Total footer** | Per-role inventory sheets may show an optimistic **Clip Duration** sum (`RoleInventorySheetTotal`). It is **not** overlap-aware; do not conflate with Summary’s `summaryOverlapAwareDurations`. Selected Roles Inventory has no Total footer. |
| **CLI modifiers need `--report`** | Report-only flags (`--report-full`, section flags including `--report-non-standard-effects`, `--protect-sheets`, `--create-pdf`, exclusions, …) must require `--report`. |
| **Excluded roles apply to all role-bearing sheets** | `excludedRoles` / `--exclude-role` omit matching Role ▸ Subrole rows from Role Inventory, Markers, Keywords, Titles & Generators, Video & Audio Effects, Speed Change Effects, and Summary durations. Do not filter inventory only. Empty Role ▸ Subrole fields stay. Transitions / Non-Std / Media Summary have no clip role column. |
| **No help-submenu refactor by default** | Keep flat ArgumentParser flags + `@OptionGroup` unless a maintainer explicitly requests a subcommand redesign. |

---

## 6. Tests & fixtures

| Rule | Detail |
|------|--------|
| **Tests with behaviour** | Public API and report behaviour changes need tests. Prefer core (parse / extract / project) tests **plus** report shape tests when fixing a report gap. |
| **Swift Testing only** | The suite is **100% Swift Testing** (`import Testing`, `@Suite` / `@Test` / `#expect` / `#require`). There is **no** `import XCTest` in `Tests/`. Do not reintroduce XCTest or mix frameworks in one file. Performance smoke uses `ContinuousClock` budgets, not XCTest `measure {}`. |
| **Bundled samples fail; optional fixtures cancel** | Bundled public samples **fail** if missing (`requireFCPXMLSample`). Optional fixtures (Submitted inbox, `OFK_REPORTING_FCPXML_BUNDLE`, ExcelReportTest Sample, `OFK_SHOT_EXTRACTION_FCPXML` / ShotExtractionTest Sample) **cancel** via `Test.cancel` (`requireSubmittedInboxItems` / `requireReportingFixtureFCPXML` / `ExcelReportFixture.requireFixtureURL` / `ShotExtractionFixture.requireFixtureURL`). Never throw `XCTSkip`. Harness: `FCPXMLTestSampleLoading` (`tryLoad*`) + `FCPXMLTestingSampleSupport` (`require*`). |
| **Never commit private FCPXML** | `Tests/Submitted FCPXML/` inbox contents and private ExcelReportTest / ShotExtractionTest fixtures (`.fcpxml` / `.fcpxmld` under those trees) are **gitignored**. Never commit or push private project XML to GitHub. Anonymise → reproduce → fix → promote a **minimal public** sample when appropriate. |
| **ExcelReportTest / ShotExtractionTest are optional** | Integration targets **cancel** without a local fixture; do not make CI depend on private Sample bundles. |
| **Update counts when adding tests** | Keep listed counts aligned in `Tests/README.md`, `GUARDRAILS.md`, `ARCHITECTURE.md`, `AGENT.md`, and `.cursorrules` when you add or remove tests (`swift test list`). |

---

## 7. Documentation & changelog

| Rule | Detail |
|------|--------|
| **AGENT ↔ .cursorrules** | When you update one, update the other. Same overview, architecture, test structure, and conventions. |
| **Feature docs** | User-visible behaviour → Manual (esp. [12 Timeline Projection](Documentation/Manual/12-Timeline-Projection.md) / [19 CLI](Documentation/Manual/19-CLI.md) / [20 Reporting](Documentation/Manual/20-Reporting.md) / [21 Shot Extraction](Documentation/Manual/21-Shot-Extraction.md) / [22 Examples](Documentation/Manual/22-Examples.md)) and CLI README as needed. Structural boundaries → ARCHITECTURE.md. Hard constraints → this file. |
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

### Sign: chapter-markers-on-markers-sheet
- **Trigger:** Markers report options, CLI `--report-markers`, or docs about chapter markers.
- **Instruction:** Keep `includeChapterMarkersInMarkersReport` default **`true`**. Do not add a CLI chapter toggle; users filter Type = Chapter in Excel or set the API to `false`.
- **Reason:** Chapter markers are first-class Tags content; Excel already exposes Type.
- **Provenance:** 2026-07-22 — product lock after Markers sheet review.

### Sign: markers-keywords-survive-host-occlusion
- **Trigger:** Connected / nested / occluded clip markers or keywords missing from reports.
- **Instruction:** Emit host annotations for `mc-clip` / `ref-clip`; use `.markersAndKeywordsOnly` for occluded hosts. Do not drop Markers Extraction solely for host full-occlusion. Titles/Transitions/Effects remain occupancy-gated. Fall back to Extraction when Projection annotations filter to zero rows. Missing sequence `tcFormat` → NDF.
- **Reason:** Tags markers/keywords on covered connected clips remain user-visible; occupancy gates media windows, not every annotation.
- **Provenance:** 2026-07-22 — Sample-02 / connected-clip Markers+Keywords regressions.

### Sign: protect-sheets-is-edit-lock
- **Trigger:** Password / protect / encrypt options for reports.
- **Instruction:** `--protect-sheets` / `protectSheets` applies XLKit worksheet protection only. Do not advertise workbook open-password or PDF encryption via this flag.
- **Reason:** XLKit supports sheet protection, not file encryption; PDF passwords belong in Preview (or a future dedicated API).
- **Provenance:** 2026-07 — design lock for `--protect-sheets`.

### Sign: swift-testing-only
- **Trigger:** Adding or changing any test under `Tests/`.
- **Instruction:** Use Swift Testing only (`@Suite` / `@Test` / `#expect` / `#require`). Never reintroduce XCTest or mix frameworks in one file. Harness: `tryLoad*` in `FCPXMLTestSampleLoading` (core) and `require*` in `FCPXMLTestingSampleSupport` (`Test.cancel` for optional fixtures; hard fail for missing bundled samples). Performance: `ContinuousClock` sanity budgets, not XCTest `measure`. Update suite counts in Tests/README + agent docs when the suite grows.
- **Reason:** Migration (former Phases 0–7) is complete; the suite is **1222** listed tests, all Swift Testing. Hybrid XCTest + Testing caused skip/cancel confusion and dual harness drift.
- **Provenance:** 2026-07-18 — phased migration completed; supersedes prior hybrid-only and cutover-phase Signs.

### Sign: effects-role-type-filter
- **Trigger:** Choosing Role ▸ Subrole for Video & Audio Effects / Speed Change Effects rows, or editing `RoleDisplayPreference.preferredRole` / `.builtIn`.
- **Instruction:** Effects contexts **must** type-filter candidates (video/caption vs audio). Do not let an `audioRole`-only host paint video-filter rows green via Dialogue/Effects. Keep `.builtIn` priorities to FCP default main-role names only; custom library roles belong in `ReportOptions.roleDisplayPreference`.
- **Reason:** Sample clips often write only `audioRole`; without type-filtering, video effects incorrectly inherit audio roles and green `#00AA44` text.
- **Provenance:** 2026-07-22 — Effects sheet colour regression on Sample.fcpxmld; fixed in `FCPXMLRoleDisplayPreference` + formatting defaults.

### Sign: summary-percent-is-fraction
- **Trigger:** Writing or displaying Summary **% of Total** (Excel, PDF, or `SummaryRoleDurationRow.columnValues`).
- **Instruction:** Store `percentOfTotal` as a **fraction** (`roleSeconds / projectSeconds`). Excel uses `0.0%` number format; PDF/text must use `formattedPercentOfTotal` (e.g. `0.42` → `42.0%`). Never dump `String(percentOfTotal)` in user-visible tables. Values may exceed `1.0` when summed durations overlap (default aggregation); do not “fix” by capping at 100% without an explicit overlap-aware policy change.
- **Reason:** PDF previously showed raw Doubles (`3.896…`) while Excel showed `389.6%` for the same fraction — user-visible Excel/PDF mismatch.
- **Provenance:** 2026-07-22 — Summary `% of Total` Excel vs PDF investigation on OFK-Full.

### Sign: authoring-not-in-reporting
- **Trigger:** Detached Authoring (`FinalCutPro.FCPXML.Authoring`) or report builders.
- **Instruction:** Keep Authoring parallel to live Model / Timeline Export. Do not import Authoring types into Reporting; do not invent FCPXML meaning only in Authoring when Model/Parsing should own it. Omit-on-write must consult `VersionAvailability` / `VersionFeatureGate`.
- **Reason:** Reporting consumes Extraction → Projection only; Authoring is a create/round-trip path.
- **Provenance:** 2026-07-19 — design lock for Authoring layer (3.2.0).

### Sign: connected-role-inventory-survives-nesting
- **Trigger:** Role Inventory missing a connected / nested clip role (Effects, Music, Dialogue, VFX, custom).
- **Instruction:** Never fold a negative-lane connected host into its parent when it has an **own role assignment**. Own assignment = active `audio-channel-source` roles, `asset-clip` `audioRole` / `videoRole`, or first-generation `audio`/`video` children with an explicit `role`. Apply the same rule in **both** `fcpIsNestedConnectedInventoryHost` and `retainsFullyOccludedHostForRoleInventory` via `fcpHasStandaloneConnectedInventoryAssignment()`. Hosts with **no** own assignment may still fold into the parent (Nested SFX under sync-clip). Channel sources still override clip-level `audioRole` when present.
- **Reason:** Audio Only_01 (2026-07-23) dropped Water Lake 3 Effects because only channel-source remaps escaped nesting; `audioRole`-only connected clips were wrongly excluded. Occlusion retention had the same gap.
- **Provenance:** 2026-07-23 — Audio Only_01 Effects-under-Music regression.

### Sign: title-text-same-line-runs-concatenate
- **Trigger:** Titles & Generators **Title Text** / Font, or `Title.concatenatedDisplayText`.
- **Instruction:** Join `text-style` runs **inside one `<text>`** with no separator (FCP on-screen: `1501` + `0` → `15010`). Use ` | ` only between separate `<text>` children (paragraphs / lines). Collapse duplicate identical Font specs. Fix in Model (`Title+Typed`); do not special-case in Reporting.
- **Reason:** Basic Title often splits a shot number across two style runs; joining every run with ` | ` produced `1501  |  0` instead of `15010`.
- **Provenance:** 2026-08-18 — Production Data Titles & Generators Title Text.

### Sign: title-roles-honor-attribute
- **Trigger:** Titles & Generators Role ▸ Subrole, Role Inventory title rows, Markers/Effects on title hosts, or connected clips under the primary storyline (`lane < 0`).
- **Instruction:** Never hard-code **Titles** when `Title.role` / Projection host video roles are present — use `ReportFormatting.titleRoleSubrole`. Default to **Titles** only when the attribute is omitted. Inventory negative-lane leaf `<video>` / generators; keep skipping negative-lane leaf `<audio>` (host channel/sync sources). Do not re-parse title roles only inside Excel/PDF exporters.
- **Reason:** Under-spine titles with custom library roles were exported under a hard-coded Titles label; leaf video under the spine was dropped by `shouldSkipLeafMedia`. Parsing/Extraction/Projection already had the facts.
- **Provenance:** 2026-07-24 — under-spine titles / leaf video reporting fix (3.2.5).

### Sign: host-roles-exclude-connected-titles
- **Trigger:** Role Inventory host `<clip>` / sync / angle video Role ▸ Subrole when a connected `<title>` has a custom `role` (e.g. VFX).
- **Instruction:** `_fcpRolesForNearestDescendant` must skip `.title` (with `.gap`) so connected title roles never become the host’s video role. Titles keep their own `role` for title inventory / Titles sheets; unrole’d hosts default via `addDefaultRoles` (typically **Video**). Do not “fix” this only in Reporting — Parsing owns local/inherited role facts.
- **Reason:** Spine clips with unrole’d media + connected VFX titles were inventoried under the title’s VFX role (Sample: 6 hosts mis-hosted onto Vfx Shot No-1).
- **Provenance:** 2026-08-14 — Sample.fcpxmld connected-title host role contamination.

### Sign: speed-change-merge-extraction-when-projection-incomplete
- **Trigger:** Speed Change Effects sheet missing optical-flow / wrapper `timeMap` rows that Extraction finds.
- **Instruction:** When Projection yields any speed rows, still **merge** Extraction rows whose `clipName` is absent from Projection (do not treat non-empty Projection as exclusive). Skip nested leaf `timeMap` rows when an ancestor already has `timeMap` (`hasRetimedAncestorClipHost`) to avoid duplicates. Prefer Projection display when both agree. Effect is **Optical Flow Retime** when `timeMap frameSampling` is optical-flow / classic / FRC; **Frame Blending Retime** for `frame-blending`; otherwise **Retime**. Settings is the speed percent only.
- **Reason:** Projection-first discarded Extraction entirely once any projected rows existed (Sample: ~37 projected vs ~59 extractable; optical-flow spine `<clip>` wrappers omitted). Default Effect `Retime 50.0%` hid Optical Flow Video Quality that FCP shows in the Retime Editor.
- **Provenance:** 2026-08-14 — Sample.fcpxmld Speed Change / optical-flow merge.

### Sign: empty-enabled-report-sheets-keep-status
- **Trigger:** Exporting Excel/PDF when an enabled section has zero data rows.
- **Instruction:** Keep sheet headers and write one `ReportEmptySectionStatus` / Media Summary **No Missing Media** status row. Never omit Markers, Keywords, Titles, Transitions, Effects, Speed Change, Non-Std, Selected Roles Inventory, or Media Summary solely because rows are empty when the section was requested. Per-role inventory tabs may still omit when empty.
- **Reason:** Matches Media Summary empty-state product behaviour; Excel and PDF stay aligned for full and single-section reports.
- **Provenance:** 2026-07-28 — empty-sheet status rows (3.3.1).

### Sign: shot-extraction-primary-stills-only
- **Trigger:** Shot Extraction `extract` / `plan` / CLI `--extract-shots` / `--dry-run`.
- **Instruction:** Reject primary-spine (lane absent or `0`) **video**, **titles / generators / Motion templates** (`<title>`), and **audio** clips. Connected lanes stay ignored. `plan` and `extract` share one validation path; dry-run throws the same ``ShotExtractionError`` messages (no writes).
- **Reason:** Shot Extraction is a stills-only primary timeline tool; GUI preflight needs identical validity rules.
- **Provenance:** 2026-07-28 — dry-run + expanded rejection (3.3.1).

### Sign: row-colour-survives-column-exclusion
- **Trigger:** Excel/PDF export with `--exclude-column` / `excludedColumns` for Role ▸ Subrole, Category, Kind, or other colour-source headers; or editing `FCPXMLReportWorkbookExporter` / `FCPXMLReportPDFExporter` / `FCPXMLReportRowColorPolicy`.
- **Instruction:** Always write remaining cell values independently of colour. Colour from typed row models (`fontColorHex(roleSubrole:categoryLabel:context:)` / Non-Std Kind APIs / marker type) — never require those columns to be present in filtered headers. Accept shell-friendly Role aliases (`Role > Subrole`, `Roles > Subrole`). Do not make colour “optional” when columns are excluded.
- **Reason:** Excluding Role ▸ Subrole emptied per-role Excel sheets because writes were gated on colour lookup of that header (3.3.3).
- **Provenance:** 2026-07-28 — Sample.fcpxmld Role ▸ Subrole exclusion / colour independence (3.3.3).

### Sign: role-inventory-screenshots-excel-only
- **Trigger:** Role Inventory Screenshot column / `--include-role-inventory-screenshots` / `includeScreenshotsInRoleInventory`.
- **Instruction:** Default **off**. When on, insert **Screenshot** after **Row** on Selected Roles Inventory and every per-role sheet; embed Source In frames via XLKit (aspect-preserving) at Excel export only. Scale thumbnails from source resolution with a **480px max long edge**. PDF must omit the column and never embed. Grab asset-relative Source In (clip `start` − asset `start`); always prefer `original-media`; use `proxy-media` only when the original is missing or unreadable (MXF / camera RAW) (Sign `role-inventory-screenshots-prefer-original`). Blank cell when both are missing/unreadable. Source File Path stays original-first. Not a `ReportColumn` / `--exclude-column` target. Do not use legacy marketing names in code.
- **Reason:** Opt-in keeps default exports fast/small; Source In matches FCP source viewer; Excel-only matches XLKit image APIs.
- **Provenance:** 2026-08-14 — Role Inventory screenshots feature (3.3.5).

### Sign: report-cover-four-row-branding
- **Trigger:** Excel cover sheet / PDF cover branding / `ReportWorkbookCoverSheet` / `copyrightLabel`.
- **Instruction:** Excel cover order is **A1** Created-by (`headerText`), **A2** `Created on yyyy-MM-dd-HH-mm-ss`, **A3** `Visit <visitURL>`, **A4** optional `copyrightLabel`. PDF cover matches that branding stack (after project/event). Customize Visit via `ReportWorkbookCoverSheet.visitURL` (API / GUI only — no CLI flag). Default Visit URL is the OpenFCPXMLKit GitHub repository.
- **Reason:** Stable four-row cover for product hosts; Visit URL is an integration concern, not a CLI switch.
- **Provenance:** 2026-08-14 — Cover branding expansion (3.3.5).

### Sign: role-inventory-screenshots-prefer-original
- **Trigger:** Role Inventory Screenshot column / `--include-role-inventory-screenshots` / `includeScreenshotsInRoleInventory` / `RoleInventoryScreenshotMedia`.
- **Instruction:** Always prefer `original-media` when that file exists. Use `proxy-media` only when the original is missing on disk or `RoleInventoryScreenshotGrabber` cannot decode it (MXF, camera RAW, and similar). Fail fast when the file exists but cannot be opened (TCC / permissions) so proxy can be tried. Resolve both URLs from the same unfolded leaf (`fcpMediaRepresentationURLs` or Projection `MediaChannel`). Do not change Source File Path / Name to proxy. PDF still omits screenshots. There is no codec allowlist — stills use ImageIO; video uses AVFoundation.
- **Reason:** Screenshot quality should match the original when it is readable; proxy is a fallback, not a substitute when both files exist.
- **Provenance:** 2026-08-15 — Role Inventory screenshot original-first + proxy fallback.

### Sign: excluded-roles-apply-to-all-sheets
- **Trigger:** `excludedRoles` / CLI `--exclude-role` / Production Data role opt-out.
- **Instruction:** Apply the same main-role-includes-subroles match to Role Inventory, Markers, Keywords, Titles & Generators, Video & Audio Effects, Speed Change Effects, and Summary components (so subtotals recompute). Never filter inventory only. Keep empty Role ▸ Subrole rows. Do not invent role meaning on Transitions, Non-Std Effects & Templates, or Media Summary.
- **Reason:** Excluding `VFX Shot No` left title Transform rows on Video & Audio Effects (and VFX rows on Titles / Markers / Summary) while inventory was already empty.
- **Provenance:** 2026-08-18 — Production Data Sample.fcpxmld / Video & Audio Effects role-exclusion gap.

### Sign: effect-settings-match-fcp-display
- **Trigger:** Video & Audio Effects Settings / Role Inventory **Effects** / `adjust-blend` / `adjust-transform` / `filter-video` params.
- **Instruction:** Keep `adjust-blend amount` as a 0.0–1.0 fraction in Extraction; format as Opacity percent × 100 (`0.3987` → `Opacity 39.9%`). Parse `adjust-transform` attributes and nested `param` keyframes in Model (`TransformAdjustment.componentSamples`); omit identity Position / Rotation / Scale; non-uniform scale is `Scale X …%, Y …%`. Filter Settings are inspector `param` name/value pairs (skip ozxml / base64 / empty names / Motion `Value` vertices); do not invent blob meaning. Resolve Apple from the `effect` resource UID, not a hardcoded `true`. Inventory **Effects** uses the same formatted settings (grouped names), not names-only. Do not invent a second unit system in Reporting.
- **Reason:** Transform on spine `<clip>` wrappers and keyframed scale never reached Effects; Opacity `0.3987` was printed as `0.4%`; inventory listed `Transform, Transform, Transform`; filter Settings duplicated the effect name and hid Color Adjustments inspector values.
- **Provenance:** 2026-08-18 — Production Data Sample.fcpxmld Video & Audio Effects / Role Inventory Effects.

### Sign: never-commit-submitted-fcpxml
- **Trigger:** Debugging with a user-supplied `.fcpxml` / `.fcpxmld`.
- **Instruction:** Keep it under `Tests/Submitted FCPXML/` (gitignored). Promote only anonymised minimal public fixtures.
- **Reason:** Private library paths and project names must not land on GitHub.
- **Provenance:** Standing project policy — see `Tests/Submitted FCPXML/README.md`.

---

## 10. Quick checklist before merge

- [ ] Change sits in the correct layer (ARCHITECTURE §2.7 / Guardrails §2).
- [ ] Public behaviour has tests (Swift Testing); optional fixtures use `Test.cancel`.
- [ ] No PBF / legacy naming in code or CLI output.
- [ ] FCPXML 1.5 compatibility preserved; newer features version-marked.
- [ ] Concurrency: no Task over non-Sendable XML/timecode types.
- [ ] Docs: AGENT.md ↔ .cursorrules if agent briefing changed; GUARDRAILS / ARCHITECTURE / Manual / CLI / CHANGELOG as needed.
- [ ] Private FCPXML / secrets not staged.
- [ ] Test counts still match `swift test list` if tests were added or removed.

---

## 11. References

- **Internal:** [ARCHITECTURE.md](ARCHITECTURE.md), [AGENT.md](AGENT.md), [.cursorrules](.cursorrules), [Tests/README.md](Tests/README.md), [Tests/Submitted FCPXML/README.md](Tests/Submitted%20FCPXML/README.md), [Documentation/Manual/00-Index.md](Documentation/Manual/00-Index.md), [Documentation/Coverage.md](Documentation/Coverage.md).
- **External:** [Final Cut Pro XML](https://fcp.cafe/developers/fcpxml/), [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/), [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/).


