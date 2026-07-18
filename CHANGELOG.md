# Changelog

All notable changes to OpenFCPXMLKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
OpenFCPXMLKit uses **New Features**, **Improvements**, and **Bug Fixes** for each release.

---

## [3.1.2](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.1.2) - 2026-07-19

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Swift Testing migration:** The entire test suite is now **Swift Testing** only (`@Suite` / `@Test` / `#expect` / `#require`). There is no remaining `import XCTest` under `Tests/`. Shared harness: `FCPXMLTestSampleLoading` (`tryLoad*`) + `FCPXMLTestingSampleSupport` (`require*`); bundled samples fail if missing; optional fixtures (Submitted inbox, reporting / ExcelReportTest Sample) use `Test.cancel`. Performance smoke uses `ContinuousClock` sanity budgets instead of XCTest `measure`. Suite count unchanged: **1084** listed in `swift test list` (**1078** OpenFCPXMLKitTests + **6** ExcelReportTest). See GUARDRAILS Sign: `swift-testing-only`.
- **Manual reorder:** Manual chapters renumbered to sequential **01–20** — Timeline Projection is **11**, Media Processing **12**, … Cross-Platform **16**, Errors **17**, CLI **18**, Reporting **19**, Examples **20**. Index, Documentation hub, README API links, ARCHITECTURE, AGENT, and `.cursorrules` updated to match.
- **Documentation sync:** GUARDRAILS, ARCHITECTURE (incl. Tests harness Mermaid), AGENT, `.cursorrules`, README, Tests READMEs, and ExcelReportTest / Submitted FCPXML READMEs refreshed for Swift Testing, `swift test list`, and current Manual chapter numbers.

### 🐛 Bug Fixes

- None in this release.

---

## [3.1.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.1.1) - 2026-07-18

### ✨ New Features

- **Markers outside clip boundaries:** By default the Markers report omits markers whose `start` is outside the host clip’s media range (hidden in Final Cut Pro’s timeline/Tags). Opt in with `ReportOptions.includeMarkersOutsideClipBoundaries` / CLI `--include-markers-outside-clip-boundaries` to include them and add a **Hidden** column (✓ outside / ✗ inside). The Hidden column is not part of `--exclude-column`. Sample: `HiddenMarkers.fcpxml`. Tests: `FCPXMLMarkersReportTests`, `FCPXMLFileTest_HiddenMarkers`; ExcelReportTest writes `OFK-OutsideClipBoundaries.xlsx` / `.pdf`.
- **Excel sheet protection:** `ReportOptions.protectSheets` / CLI `--protect-sheets` applies worksheet protection to every sheet in the Excel workbook (cover + content). Edit lock only — not file-open encryption; PDF export is unchanged (use Preview → Encrypt for PDF passwords). Tests: `FCPXMLReportExcelExportTests`; ExcelReportTest writes `OFK-ProtectedSheets.xlsx`.

### 🔧 Improvements

- **Documentation:** Added [GUARDRAILS.md](GUARDRAILS.md) as a companion to [ARCHITECTURE.md](ARCHITECTURE.md) — hard must / must-not constraints for contributors and agents (layer boundaries, naming, FCPXML 1.5 floor, reporting honesty, fixtures, Signs for learned locks). Cross-linked from README, Manual index, CONTRIBUTING, AGENT, and `.cursorrules`.
- **Documentation sync:** Test/sample counts and API surface refreshed across README, Manual, Tests READMEs, ARCHITECTURE (incl. Mermaid), AGENT, `.cursorrules`, and GUARDRAILS — **1084** listed tests (**1078** + **6**), **60** public FCPXML samples; documenting `includeMarkersOutsideClipBoundaries` / `--protect-sheets`. Manual chapters **19** / **16** / **17** / **12** / **01** / **20** aligned for `protectSheets`, Markers **Hidden** vs `hidden-clip-marker`, and Excel-only sheet protection.

### 🐛 Bug Fixes

- None in this release.

---

## [3.1.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.1.0) - 2026-07-16


### ✨ New Features

- **Effects → Projection:** Report builder prefers ``WindowReportEffectAnnotation`` collected during timeline Projection via shared ``EffectsCollector`` (filters, volume/implicit volume, transform rows, compositing, spatial conform; video-filter occlusion policy preserved). Extraction remains fallback when Projection has no effect annotations. Tests: `FCPXMLEffectsProjectionTests`.
- **Transitions → Projection:** Report builder prefers ``WindowTransitionAnnotation`` collected during timeline Projection (name, spine placement, Apple-supplied, timing). Extraction remains fallback when Projection has no transition annotations. Tests: `FCPXMLTransitionsProjectionTests`.
- **Titles & Generators → Projection:** Report builder prefers ``WindowTitleAnnotation`` collected during timeline Projection (title/generator story hosts, including titles with no nested story children). Extraction remains fallback when Projection has no title annotations. Tests: `FCPXMLTitlesProjectionTests`.
- **Markers + Keywords → Projection:** Report builders prefer ``ProjectedClipAnnotations`` collected during timeline Projection (covers title-hosted markers such as BasicMarkers). Extraction remains fallback when Projection has no marker/keyword annotations. Tests: `FCPXMLMarkersKeywordsProjectionTests`.
- **Timeline Projection:** New `Projection/` mid-layer between Extraction and Reporting. `TimelineProjecting` / `TimelineProjector` emit Sendable `MediaUsageWindow` values (per `MediaChannel`, `LanePath`, `RetimingSegment`) for visible usages with identity or `timeMap` retiming (normalized segments, reverse detection, multi-segment windows); `ConformRate` scale via shared `fcpConformRateScalingFactor`. Recursive story walk for nested spines and anchored children (`SpineProjection`, `ProjectionTiming`); J/L cuts via `AudioSplitRetiming`. Unfolds `mc-clip` angles (`MulticamProjection`), `ref-clip` media sequences (`RefClipProjection`), auditions, and `video`/`audio` leaves with `ChannelKindFilter` / `srcEnable`. Role Inventory, Speed Change, Media Summary, Effects, and Summary consume shared `ReportProjectionContext` windows (projected once per timeline); Speed Change prefers non-identity `RetimingSegment` facts; Role Inventory overlays timeline bounds from matching windows; Media Summary prefers window media URLs; Summary uses projection-backed spans; `TimelineOccupancyIndex` for overlap queries. Extraction remains the source for roles/metadata discovery where annotations are absent.
- **Reporting contracts:** Per-sheet obligation contracts (Manual 19); `ReportMediaResolutionPolicy` (`.failSoft` / `.failLoud`) with CLI `--media-resolution`; Media Summary optional Missing Original / Missing Proxy columns (`mediaSummaryDistinguishProxyAndOriginal`, `--media-summary-distinguish-proxy`). Tests: `FCPXMLReportObligationCorpusTests`.
- **Engine hygiene:** Project-once Projection contract for report sections that share windows; version-strip honesty (writers must not re-emit newer-schema facts into older targets); Double-safe Projection timing composition. Tests: `FCPXMLEngineHygieneTests` (project-once, strip honesty, Complex smoke budget) + Complex projection `measure` in `FCPXMLPerformanceTests`.

### 🔧 Improvements

- **CLI output directories:** `--report`, `--convert-version`, `--media-copy`, and `--create-project` create the output directory (and intermediates) when missing, instead of failing with a confusing ZIP/save error.
- **CLI orphan options:** `--timecode-format`, `--media-resolution`, and other REPORT modifiers require `--report`; `--extension-type` requires `--convert-version`.
- **CLI `--media-resolution` values:** Raw values / help use `fail-soft` and `fail-loud` (aliases `failSoft` / `failLoud` still accepted).
- **Projection geometry:** `MediaUsageWindow` optional roles/effects/breadcrumbs (`includeAnnotations`); `expandAllSourceChannels`; `RetimingSegment.composing` through ref-clip nests; Summary `summaryOverlapAwareDurations` (union via `TimelineOccupancyIndex`, default off). Tests: `FCPXMLProjectionCoverageTests` (annotations, per-src, compose, sync-in-mc, PhotoshopSample1, overlap-aware Summary).
- **Extraction fidelity:** Markers preset filters by host-clip occlusion (keeps BasicMarkers title markers; drops Occlusion3 fully occluded hosts); Keywords use `reportMainTimelineVisible`; `ExtractedElement` / context tools honour ExtractionScope audition/MC masks for inherited roles; report Projection sets `excludeFullyOccluded` (`TimelineProjectionOptions`). Tests: `FCPXMLExtractionNestFidelityTests`, `FCPXMLRoleInheritanceMatrixTests`, `FCPXMLExtractionProjectionPolicyTests`.
- **Parsing/Model coverage:** Audio channel/role sources expose DTD playback children (volume/loudness/EQ/voice isolation, `filter-audio`, `mute`); `AnalysisMarker` + Markers extraction/report type; shared `TextStyle` XML parse/build + typed `text-style-def` accessors; `tracking-shape` attributes; Sendable `CollectionFolder.smartCollections` via `SmartCollectionValue`.
- **Report export performance / progress:** Progress pipeline includes `Projecting Timeline`, content phases, then `Saving Workbook` / `Saving PDF` (ticks after saves complete). Excel cell writes are single-pass (no setRow + recolor), column autofit uses row text instead of rescanning `sheet.cells`, projection window matching is indexed, inventory extract is shared with Summary, PDF TOC measure pass skips text drawing, and Excel+PDF export can overlap on Sendable `Report` data.

- **Test suite:** Expanded to **1076** tests listed in `swift test --list-tests` (**1072** in `OpenFCPXMLKitTests`; plus **4** optional `ExcelReportTest`), including `GeneralDemo.fcpxml` / `FCPXMLFileTest_GeneralDemo`, private `Submitted FCPXML` inbox smoke test, `FCPXMLParsingCoverageTests`, extraction fidelity, `FCPXMLProjectionCoverageTests`, `FCPXMLReportObligationCorpusTests`, `FCPXMLEngineHygieneTests`, and `Text.textStyles` setter coverage.
- **Submitted FCPXML inbox:** `Tests/Submitted FCPXML/` for local private user exports (gitignored `Inbox/` / `Notes/`); workflow: anonymise → reproduce → fix → promote minimal public fixture. See `Tests/Submitted FCPXML/README.md`.
- **Documentation:** `ARCHITECTURE.md` §2.7, `AGENT.md`, `.cursorrules`, Manual chapters, and `Tests/README.md` updated for Timeline Projection and reporting contracts.
- **Conform scaling:** Shared `fcpConformRateScalingFactor(timelineFrameRate:mediaFrameRate:)` used by parsing and Projection.
- **Projection timing safety:** `ProjectionTiming` (and identity / timeMap / J–L placement) composes timeline fractions via `Double` intermediates so mixing `conform-rate` `Fraction(double:)` values with literal FCPXML rationals does not trap on `Int` overflow (regression: `24.fcpxml`).

### 🐛 Bug Fixes

- **`Text.textStyles` setter:** Updates child `text-style` elements (was incorrectly using `.text`); convenience init now applies the `textStyles` parameter. Test: `testTextTextStylesInitAndSetterReplaceTextStyleChildren`.

---

## [3.0.7](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.7) - 2026-07-15

### ✨ New Features

- **Report copyright label:** Optional ``ReportOptions/copyrightLabel`` / ``Report/copyrightLabel`` (CLI `--label-copyright`) writes Excel cover sheet cell **A2** below the Created-by brand row (same black/white banner style), shows the same line on the PDF cover below Created-by (subtitle font/size), and centres it in the PDF running footer (footer font/size). Optional `ExcelReportTest` writes `OFK-Copyright.xlsx` / `OFK-Copyright.pdf` for visual review (4 integration tests).

### 🔧 Improvements

- **Dependencies:** [SwiftExtensions](https://github.com/orchetect/swift-extensions) minimum raised to **3.0.0**. Adds [SwiftSemanticVersion](https://github.com/orchetect/swift-semantic-version) **1.0.0** for `FinalCutPro.FCPXML.Version` (`SemanticVersion` was extracted from SwiftExtensions in 3.0.0). Report formatting now uses SwiftExtensions `titleCased` instead of a local first-character-only helper. Unused `import SwiftExtensions` cleaned up; remaining imports use `internal import` (or `public import` where SE types appear in public API).
- **Test suite:** Expanded to **963** tests listed in `swift test --list-tests` (**959** in `OpenFCPXMLKitTests`: 956 XCTest + 3 Swift Testing `@Test`; plus **4** optional `ExcelReportTest`).
- **Documentation:** Manual **19 — Reporting** / **16 — CLI** / **17 — Examples** / **18 — Cross-Platform**, CLI README, project README, `AGENT.md`, `.cursorrules`, `ARCHITECTURE.md` (§2.7 + mermaid), `Tests/README.md`, and `Tests/ExcelReportTest` READMEs updated for `--label-copyright`, dependency notes, and test counts.

### 🐛 Bug Fixes

- None in this release.

---

## [3.0.6](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.6) - 2026-07-15

### ✨ New Features

- **Universal report Row column:** Excel and PDF tabular sheets (Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, Summary role-duration table, Media Summary, plus role inventory) include a 1-based **Row** column by default via `ReportColumnExclusion.ensuringRowColumn`. PDF multi-page / multi-column-set injection uses `allowsInjectedRowColumn` / `preparePaginatedTable(allowInjectedRowColumn:)`. CLI `--exclude-column Row` (aliases: Row Numbers, Row Number) omits Row everywhere.

### 🔧 Improvements

- **Summary Excel layout:** Project title moves to **B1** so column A stays a narrow **Row** column; title column width uses a generous autofit range (`summaryProjectTitleColumnWidth`).
- **PDF cover notes:** Black “About This PDF Export” header band with white `info.circle` SF Symbol; tightened cover body copy (default Row; exclude via `--exclude-column Row`).
- **Test suite:** Expanded to **960** tests listed in `swift test --list-tests` (**957** in `OpenFCPXMLKitTests`: 954 XCTest + 3 Swift Testing `@Test`; plus **3** optional `ExcelReportTest`).
- **Documentation:** Manual **19 — Reporting** / **16 — CLI**, CLI README, `AGENT.md`, `.cursorrules`, `ARCHITECTURE.md` (§2.7 + mermaid test counts), `Tests/README.md`, and `Tests/ExcelReportTest/README.md` updated for universal Row, Summary **B1**, PDF cover polish, and test counts.

### 🐛 Bug Fixes

- **Summary Row column width:** Long project titles no longer inflate the Excel **Row** column when the title shared column A.

---

## [3.0.5](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.5) - 2026-07-14

### ✨ New Features

- **PDF TOC sheet colour chips:** Table of Contents rows show an accent-palette colour chip and a light content-tint wash keyed to each workbook sheet title’s sequential `colorIndex` (same index as per-sheet content-page tints, including role sheets via `FCPXMLReportPDFSheetPlan`).

### 🔧 Improvements

- **PDF column width fill:** After horizontal packing, remaining columns expand proportionally to fill A4 landscape `contentWidth` when leftover space remains (for example after many `excludedColumns`). Pinned **Row** columns keep their packed width; wide tables still chunk horizontally and each chunk fills the page (`FCPXMLReportPDFTableLayout`).
- **Test suite:** Expanded to **951** tests listed in `swift test --list-tests` (**948** in `OpenFCPXMLKitTests`: 945 XCTest + 3 Swift Testing `@Test`; plus **3** optional `ExcelReportTest`), including `FCPXMLReportPDFTableLayoutTests`, `FCPXMLReportPDFSheetPlanTests`, and `testExportRoleInventoryPDFWithManyExcludedColumns` (`Output/OFK-ExcludedColumns.pdf`).
- **ExcelReportTest fixtures:** Preferred `Sample.fcpxmld` / `Sample.fcpxml` resolution also checks under `Output/`; auto-discovery falls back there as well.
- **Documentation:** Manual **19 — Reporting** / **16 — CLI**, CLI README, `AGENT.md`, `ARCHITECTURE.md` (§2.7 PDF presentation + mermaid), `.cursorrules`, `Tests/README.md`, and `Tests/ExcelReportTest/README.md` updated for TOC colour chips, column-width expansion, and test counts.

### 🐛 Bug Fixes

- **PDF tables after column exclusion:** Tables with few remaining columns no longer left a large empty band on the right of the page; leftover horizontal space is redistributed so columns fill the usable content width.

---

## [3.0.4](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.4) - 2026-07-13

### ✨ New Features

- **PDF report export:** `FinalCutPro.FCPXML.ReportPDFExport` (`makePDFData(from:)`, `export(_:to:)`) renders a built `Report` to a multi-page `.pdf` via CoreGraphics. All nine workbook sections are supported (Selected Roles Inventory, per-role sheets, Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, Summary, Media Summary) with dynamic column widths, pagination, and truncation for wide tables.
- **PDF presentation:** Cover page with workbook branding (`ReportWorkbookCoverSheet` / `exportBrandingText`), dynamic table of contents (section titles and page numbers), per-page header/footer rules, and section background tinting between header and footer bands.
- **CLI `--create-pdf`:** With `--report`, also writes `{project-or-clip-name}.pdf` beside the `.xlsx` workbook from the same built `Report`. Section flags, `--exclude-column`, `--exclude-role`, `--exclude-disabled-clips`, `--timecode-format`, and `--report-project` apply to both formats. Progress includes a **Saving PDF** step when enabled.

### 🔧 Improvements

- **Shared row colours:** Excel and PDF export now use `FCPXMLReportRowColorPolicy` for inventory, section-sheet, Summary, and Media Summary text colours (refactored from `FCPXMLReportWorkbookExporter`).
- **Test suite:** Expanded to **944** tests listed in `swift test --list-tests` (**942** in `OpenFCPXMLKitTests`: 939 XCTest + 3 Swift Testing `@Test`; plus **2** optional `ExcelReportTest`), including `FCPXMLReportPDFExportTests` (cover, TOC, section parity, pagination, branding), `testExportDefaultRoleInventoryPDF` integration coverage, and strengthened `FCPXMLCompoundClipReportTests` / `FCPXMLReportTimecodeFormatTests` regression assertions.
- **CLI help:** `--help` overview and REPORT option strings now describe Excel/PDF report export consistently (`--create-pdf`, `--timecode-format`, `--exclude-column`, `--report-project`).
- **Dependencies:** SwiftExtensions minimum raised to **2.3.2**.
- **Documentation:** Manual chapter **19 — Reporting, Excel & PDF Export**; updated **16 — CLI**, **17 — Examples**, and cross-platform notes; CLI README; `AGENT.md`, `ARCHITECTURE.md` (§2.7 / §8), `.cursorrules`; and `Tests/README.md` / `Tests/ExcelReportTest/README.md`.

### 🐛 Bug Fixes

- None in this release.

---

## [3.0.3](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.3) - 2026-07-10

### ✨ New Features

- **Compound-clip Excel reports:** `FinalCutPro.FCPXML.allReportTimelineSources()` discovers both project sequences and standalone compound-clip timelines (event-level `ref-clip` → `media`/`sequence`). `ReportBuilder` / `buildReport` and Summary use this so FCP “Export XML” of a compound clip (no `<project>`) produces role inventory, markers, and other sheets like a normal project.

### 🔧 Improvements

- **Test suite:** Expanded to **933** tests (**932** in `OpenFCPXMLKitTests` + **1** optional `ExcelReportTest`), including `FCPXMLCompoundClipReportTests`.

### 🐛 Bug Fixes

- **Report timeline resolution:** Documents that contain only an event-level compound clip no longer fail with `ReportError.noProjectsFound`; reporting walks the compound clip’s `media` sequence instead.

---

## [3.0.2](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.2) - 2026-07-08

### ✨ New Features

- **Configurable report timecode formats:** `ReportOptions.timecodeFormat` / `Report.timecodeFormat` (`ReportTimecodeFormat`) control timeline time cells across all report sheets. Modes: `.smpteFrames` (`HH:MM:SS:FF`, default), `.frames` (`Frames`), `.feetAndFrames` (`Feet+Frames`), and `.smpteNoFrames` (`HH:MM:SS`). CLI `--timecode-format` accepts the same values.
- **Format-aware column headers:** Timecode columns use dynamic suffixes in Excel (e.g. `Timeline In (frames)`); `ReportColumn` exclusion matches both plain and suffixed headers.
- **Shared build / progress order:** `ReportBuildPhase.enabledPhases(for:)` is the single source of truth for inventory-first product order (Selected Roles Inventory → Markers → … → Media Summary). `ReportBuilder`, CLI progress, and GUI `onPhaseStarted` callbacks share the same phase list.

### 🔧 Improvements

- **Timeline string formatting:** Report SMPTE cells use SwiftTimecode `stringValue()` so non-drop-frame uses `:` and drop-frame uses `;` before frames.
- **Sort guardrails:** Timeline position sorting is numeric for Frames and Feet+Frames (avoids lexicographic order issues such as `100` before `20`).
- **Test suite:** Expanded to **925** tests (**924** in `OpenFCPXMLKitTests` + **1** optional `ExcelReportTest`), including `FCPXMLReportTimecodeFormatTests` and `FCPXMLReportBuildPhaseTests`, plus format-aware header and numeric-sort coverage in formatting/column-exclusion tests.
- **Documentation:** Updated manual chapters **16 — CLI**, **17 — Examples**, and **19 — Reporting & Excel Export**; CLI README; project README; `AGENT.md`, `ARCHITECTURE.md` (§2.7 / §3), `.cursorrules`; and `Tests/README.md` / `Tests/ExcelReportTest/README.md`.

### 🐛 Bug Fixes

- **Drop-frame notation:** SMPTE report cells for drop-frame rates (e.g. 29.97 DF) now correctly use semicolon separators instead of always formatting as non-drop-frame.
- **Build progress order:** Report build and progress callbacks no longer finish inventory after optional sheets; phases now match the GUI / workbook product order (Selected Roles Inventory first).

---

## [3.0.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.1) - 2026-07-07

### ✨ New Features

- **Media Summary sheet:** Split missing-media reporting out of Summary into a dedicated **Media Summary** sheet. `ReportOptions.includeMediaSummary`, `.mediaSummaryOnly`, and CLI `--report-media-summary` (included in `--report-full`).
- **Global column exclusion:** `ReportOptions.excludedColumns` and `ReportColumn` omit named columns from every applicable workbook sheet at export. CLI `--exclude-column` (repeatable; case-insensitive aliases such as `Metadata`, `Row Numbers`, `Source File Path`).
- **Disabled-clip filtering:** `ReportOptions.excludeDisabledClips` and CLI `--exclude-disabled-clips` omit `enabled="0"` clips from all timeline-based report sections (role inventory, markers, keywords, titles, transitions, effects, speed-change effects, summary role durations).
- **Expanded role inventory columns:** **Selected Roles Inventory** and per-role sheets now use a shared 32-column layout (`RoleInventoryColumnLayout`): Row index, 23 fixed columns (including Take, Camera Angle/Name, Frame Rate/Sample Rate, Frame Size, Source File Name/Path), plus sorted dynamic metadata key columns.

### 🔧 Improvements

- **Sheet naming:** Main role inventory tab renamed to **Selected Roles Inventory**; workbook sheet titles use Title Case.
- **Excel export:** Improved column auto-fit (wider maximum and header-based minimum widths for path columns); `Report.excludedColumns` resolved at build time and applied across inventory, section sheets, summary metrics, and media summary. **`FCPXMLReportWorkbookExporter`** applies sheet-specific row text colours via `RoleRowColorContext`: inventory rows tinted by role category (video/caption blue, titles purple, audio green, gap gray); Keywords, Titles & Generators, Effects, Speed Change Effects, and Transitions use dedicated rules when Category is unavailable; Summary project title uses the table header style with black data rows; Media Summary missing paths use red text; Markers retain marker-type colours.
- **Test suite:** Expanded to **894** tests (893 in `OpenFCPXMLKitTests` + 1 optional `ExcelReportTest` integration), including `FCPXMLRoleInventoryColumnLayoutTests`, `FCPXMLReportColumnExclusionTests`, `FCPXMLReportExcludeDisabledClipsTests`, and `FCPXMLReportExcelExportTests` (workbook cell formatting: Summary title header, black role-duration data, red missing-media paths, inventory/section-sheet colour rules).
- **Documentation:** Updated manual chapters **16 — CLI** and **19 — Reporting & Excel Export** (workbook cell colour policy), CLI README, project README, `AGENT.md`, `ARCHITECTURE.md` (§2.7 reporting layers, top-down Mermaid diagrams), `.cursorrules`, and `Tests/README.md` / `Tests/ExcelReportTest/README.md`.

### 🐛 Bug Fixes

- **Summary sheet formatting:** Role-duration rows and **% of Total** no longer incorrectly tinted with role colours; data uses default black text. Project title row (row 1) now uses the table header style (bold white text on black fill).
- **Section sheet row colours:** Keywords, Titles & Generators, Effects, Speed Change Effects, and Transitions no longer default to green when the Category column is absent; each sheet now applies its documented colour rules.
- **Media Summary:** Missing media file paths now render in red (`#FF0000`).
- **Gap role colour:** Inventory gap rows use gray (`#808080`) instead of black.

---

## [3.0.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/3.0.0) - 2026-07-02

### ✨ New Features

- **Project renamed to OpenFCPXMLKit:** Pipeline Neo is now **OpenFCPXMLKit**. All code, APIs, documentation, and tooling use OpenFCPXMLKit naming exclusively — the `OpenFCPXMLKit` module, the `OpenFCPXMLKit-CLI` binary, and the `OFKXML*` cross-platform XML types. Existing FCPXML parsing, creation, and manipulation APIs remain source-compatible; the product name and module are what changed.
- **Production's Best Friend–style Excel reports:** A new reporting subsystem builds structured, multi-sheet `.xlsx` workbooks from an FCPXML/FCPXMLD, modelled on Production's Best Friend report layouts. Sheets include **Role Inventory** (Selected Roles plus per-role sheets), **Markers**, **Keywords**, **Titles & Generators**, **Transitions**, **Video & Audio Effects**, **Speed Change Effects**, and a **Summary** sheet with per-role duration totals and percentages. Workbook export is XLKit-backed with Production's Best Friend–style formatting (black header rows, role and marker colour coding, numeric percentage cells, column auto-fit).
- **Reporting API:** `FinalCutPro.FCPXML.buildReport(options:)` with `ReportBuilder`, typed `Report`/section/row models, and `ReportOptions` presets (`.full`, `.markersOnly`, `.roleInventoryOnly`, `.summaryOnly`, and more), plus role exclusions, project-name filtering, progress callbacks, and `RoleDisplayPreference`. `ReportExcelExport` renders any `Report` to a workbook or writes it to an `.xlsx` file.
- **CLI `--report`:** New REPORT command on **OpenFCPXMLKit-CLI**. `--report` alone exports the role inventory; `--report-full` adds every optional sheet; per-section flags (`--report-markers`, `--report-keywords`, `--report-titles-generators`, `--report-transitions`, `--report-effects`, `--report-speed-change-effects`, `--report-summary`) select individual sheets, and `--exclude-role` / `--report-project` refine the output. Writes `{project-name}.xlsx` to the output directory.
- **Extraction presets:** Added `TitlesExtractionPreset` and `EffectsExtractionPreset` alongside the existing presets to drive report-oriented element extraction.

### 🔧 Improvements

- **Dependencies:** Added **XLKit** for Excel workbook generation (`Reporting/Excel`).
- **Test suite:** Expanded to **877 tests** with dedicated reporting and extraction coverage (role inventory, markers, keywords, titles, transitions, effects, speed-change effects, summary, Excel export, role display/exclusion, and extraction scope/presets). Test files and classes are standardised on the **`FCPXML`** prefix, with the module-named umbrella `OpenFCPXMLKitTests` as the sole exception.
- **Documentation:** New manual chapter **19 — Reporting & Excel Export**; updated CLI and Extraction chapters, the manual index/README, and examples. `AGENT.md`, `ARCHITECTURE.md`, `.cursorrules`, and `Tests/README.md` updated for the reporting subsystem, OpenFCPXMLKit naming, and the standardised `FCPXML`-prefixed test naming.

### 🐛 Bug Fixes

- None in this release.

---

## [2.5.2](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.5.2) - 2026-03-27

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Timeline test availability wording:** Clarified `TimelineManipulationTests` availability comments to state behavior consistency across all supported macOS versions (12.0 and later), removing ambiguous minor-version phrasing.

### 🐛 Bug Fixes

- **Offset helper naming correctness:** In `FCPXMLElementOffset`, renamed a misleading local variable (`dur`) to `offset` in `_fcpOffsetAsTimecode`, aligning naming with actual semantics and reducing maintenance confusion.
- **Timestamp test redundancy removal:** Removed a redundant tolerance assertion in `testTimelineTimestampsInitialization` now that both timestamps are intentionally injected with the same baseline value.

---

## [2.5.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.5.1) - 2026-03-21

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Timeline API documentation:** Clarified `Timeline.insertingClipWithRipple` behavior to explicitly state that clips overlapping the insertion point but starting before it are not shifted.
- **Timeline test coverage clarity:** `TimelineManipulationTests` now includes explicit availability context for `@available(macOS 12.0, *)` and stronger comments describing ripple and lane-selection semantics.

### 🐛 Bug Fixes

- **Deterministic lane-selection assertions:** Updated `TimelineManipulationTests` to assert exact lane outcomes for outward lane search and multi-conflict auto-lane placement, preventing ambiguous assertions from masking behavior changes.
- **Timestamp test stability:** Reworked `testTimelineTimestampsInitialization` to use fixed injected timestamps instead of real-time clock comparisons, removing race-prone timing assertions.

---

## [2.5.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.5.0) - 2026-03-16

### ✨ New Features

- **Cross-platform XML abstraction layer — iOS support (PR [#17](https://github.com/TheAcharya/OpenFCPXMLKit/pull/17)):** Pipeline Neo can now target **iOS 15+** in addition to macOS. A protocol-based XML layer decouples the library from Foundation’s DOM API (macOS-only) and adds an AEXML-backed implementation for non-macOS platforms. Thanks @stovak!
- **New `Sources/PipelineNeo/XML/`:** Protocols `PNXMLNode`, `PNXMLElement`, `PNXMLDocument`, `PNXMLDTDProtocol`, `PNXMLFactory`; Foundation backend on macOS (byte-identical behavior); AEXML backend for iOS and other platforms; `PNXMLDefaultFactory()` for platform dispatch.
- **DTD validation:** On macOS, full DTD validation is unchanged. On iOS, **FCPXMLStructuralValidator** performs cross-platform structural validation (root element, required children, element allowlist, required attributes) when Foundation DTD is unavailable.
- **Package.swift:** `.iOS(.v15)` added to platforms; **AEXML** added as a dependency.
- **Backwards compatibility:** macOS behavior is unchanged; existing APIs remain source-compatible.

### 🔧 Improvements

- **Test suite:** Expanded to **686 tests**. Added `AEXMLSerializationParityTests` (AEXML round-trip and backend parity), `FCPXMLDTDValidatorTests` (platform-conditional DTD vs structural fallback), `FCPXMLStructuralValidatorTests` (cross-platform structural validation), and `ImportOptionsTests`. Updated `Tests/README.md` with current structure tree, categories, and coverage.
- **Documentation:** New manual chapter **18 — Cross-Platform & iOS**; updated Overview, Loading/Parsing, Validation, XML Extensions, and Documentation README. Aligned `AGENT.md`, `ARCHITECTURE.md`, and `.cursorrules` with cross-platform XML layer, iOS support, 686 tests, and `FCPXMLStructuralValidator` / PNXML naming.
- **CI:** New iOS Simulator build job.

### 🐛 Bug Fixes

- **`removeChildren(where:)` index mismatch (PR [#17](https://github.com/TheAcharya/OpenFCPXMLKit/pull/17)):** The default implementation previously used indices from `childElements` (elements only) when calling `removeChild(at:)` on the full `children` array (including text nodes), removing the wrong nodes when text/whitespace was present. It now iterates the full `children` array so indices match. Fixes failures in ImportOptionsTests and EventClips removal.

---

## [2.4.3](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.4.3) - 2026-03-07

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Documentation alignment:** Normalized `AGENT.md` and `.cursorrules` so both files reflect the same architecture guidance, section coverage, and documentation-sync checklist terminology.
- **CLI documentation:** Updated `Sources/PipelineNeoCLI/README.md` and manual pages (`Documentation/Manual/16-CLI.md`, `Documentation/Manual/17-Examples.md`) to use `--project-version` for create-project examples and option descriptions.
- **Test consistency:** Updated `TimelineManipulationTests.testTimelineModifiedAtUpdatesOnAutoLaneInsert` to remove an unnecessary `throws` signature and use explicit `do/catch` + `XCTFail` for clearer failure reporting.

### 🐛 Bug Fixes

- **Xcode 26 dynamic linking compatibility (PR #16):** Added `swift-log` as an explicit package dependency and `Logging` as a direct target dependency in `Package.swift` to resolve undefined `Logging.Logger` symbols when building Pipeline Neo as a dynamic framework under Xcode 26's stricter transitive dependency linking rules. Thanks @stovak!
- **CLI `--version` conflict:** Resolved option-name collision between the built-in `--version` flag and create-project's timeline version option by renaming the create-project option from `--version` to `--project-version`. `pipeline-neo --version` now correctly prints the CLI tool version.

---

## [2.4.2](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.4.2) - 2026-03-06

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Test quality:** Cleaned up `TimelineManipulationTests` by removing an unnecessary `throws` from `testTimelineModifiedAtUpdatesOnRippleInsert`, aligning the signature with actual non-throwing behavior and reducing static analysis noise.

### 🐛 Bug Fixes

- None in this release.

---

## [2.4.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.4.1) - 2026-03-02

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Test suite:** Expanded to **655 tests**. Added in TimelineExportValidationTests: testFCPXMLExporterExportsClipMarkers, testFCPXMLExporterExportsClipChapterMarkers, testFCPXMLExporterExportsClipKeywords, testFCPXMLExporterExportsClipRatings, testFCPXMLExporterExportsClipMetadata, testFCPXMLExporterClipMetadataAllTypesValidatesAgainstDTD (export with all metadata types then DTD validate), testFCPXMLExporterXmlDeclarationStandaloneNo (assert exported XML uses standalone="no" for DTD/xmllint compatibility).
- **PR #14 (clip-level metadata export):** Test coverage for FCPXMLExporter exporting clip-level metadata (markers, chapter-markers, keywords, ratings, custom metadata) as children of `<asset-clip>` per FCPXML DTD; tests in TimelineExportValidationTests; Tests/README.md updated with coverage and XML declaration standalone note. Thanks @stovak!
- **TimelineManipulationTests:** Addressed GitHub Code Scan findings: replaced actor-based `NowBox` + `DispatchSemaphore` with a lock-based class (`NSLock`) to avoid thread exhaustion and deadlock risk when providing injectable "now" in timestamp tests; replaced `XCTAssertNoThrow` with do-catch and non-optional bindings for `insertClipAutoLane` and `insertingClipAutoLane` to properly verify success and handle thrown errors.

### 🐛 Bug Fixes

- **xmllint / DTD validation:** Resolved "standalone" warnings when validating exported FCPXML with `xmllint --dtdvalid`. XML declaration now outputs `standalone="no"` instead of removing the attribute, so libxml2 treats the document as dependent on an external DTD and no longer warns about whitespace nodes from pretty-printing. Change in XMLDocumentExtension.fcpxmlString.

---

## [2.4.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.4.0) - 2026-02-23

### ✨ New Features

- **CLI `--create-project`:** Create a new empty FCPXML project from the command line. Under the TIMELINE section: `--create-project` with `--width`, `--height`, `--rate`, optional `--version` (default 1.14), and a single positional output directory. Project name is derived from format (e.g. `1920x1080@25p`). Mandatory DTD validation after build and before write; FCP-style output with DOCTYPE, format `colorSpace`, and optional default smart collections. Logging options (`--log`, `--log-level`, `--quiet`) apply to create-project output.
- **FCPXMLExporter:** New `includeDefaultSmartCollections` parameter (default `false`). When `true`, adds five FCP-style default smart collections under the library (Projects, All Video, Audio Only, Stills, Favorites). Exported document includes DOCTYPE; format elements always include `name` and `colorSpace` for compatibility with Final Cut Pro.

### 🔧 Improvements

- **Test suite:** Expanded to **648 tests**. Added `testEmptyTimelineCreationAtDifferentSizesAndFrameRates` (barebone empty `Timeline` at multiple sizes and frame rates: 720p, 1080p, 4K UHD, DCI 4K, custom 640×480; asserts name, clips, duration, format, aspectRatio). Added `testProjectCreationStyleExportValidatesAgainstDTD` (empty timeline export with `includeDefaultSmartCollections`, parse, and DTD validation). Added `testProjectCreationAtDifferentSizesAndFrameRates` (export at multiple sizes and frame rates, then parse and validate against DTD).
- **Documentation:** Updated `.cursorrules`, `AGENT.md`, `Tests/README.md`, and `README.md` with CLI create-project, test count 648, and empty timeline / project-creation test coverage. Manual (Timeline & Export, CLI, Examples) and `Sources/PipelineNeoCLI/README.md` updated for create-project usage and TIMELINE options.

### 🐛 Bug Fixes

- **FCP import:** Resolved "No declaration for attribute name of element library" by no longer writing a `name` attribute on the `library` element (FCPXML DTD allows only `location` and `colorProcessing`).
- **FCP import:** Resolved "unexpected value" for `format="r1"` by always writing a format `name` (e.g. `FFVideoFormatRateUndefined` for custom dimensions) and `colorSpace` on format elements in exported FCPXML.

---

## [2.3.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.3.1) - 2026-02-18

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Test suite:** Expanded to **638 tests** (from 587). Added comprehensive file tests for new FCPXML samples: `FCPXMLFileTest_360Video` (360 video features, color conform, bookmarks, smart collections), `FCPXMLFileTest_AuditionSample` (audition elements, conform-rate, keywords), `FCPXMLFileTest_ImageSample` (still image assets), `FCPXMLFileTest_Multicam` (multicam resources and clips), `FCPXMLFileTest_Photoshop` (Photoshop-specific FCPXML), `FCPXMLFileTest_SmartCollection` (smart collection parsing across multiple samples with match-clip, match-media, match-ratings). Updated existing file tests: `FCPXMLFileTest_CompoundClips` (CompoundClipSample), `FCPXMLFileTest_Keywords` (EventsWithKeywords, KeywordsWithinFolders), `CaptionTitleTests` (CaptionSample), `TimelineManipulationTests` (TimelineSample, TimelineWithSecondaryStoryline, TimelineWithSecondaryStorylineWithAudioKeyframes), `CutDetectionTests` (CutSample).
- **Audio keyframe tests:** Added `AudioKeyframeTests` (10 tests) for comprehensive audio keyframe validation: parsing `adjust-volume > param name="amount" > keyframeAnimation > keyframe` structures from FCPXML samples; decibel value validation (-3dB, -37dB format); time value validation (FCPXML fractional format); fadeIn/fadeOut integration; multiple keyframes in sequence; secondary storyline and nested clip detection. File tests: `TimelineWithSecondaryStorylineWithAudioKeyframes`, `TimelineSample`.
- **FCPXML samples:** Added 15 new sample files covering 360 video, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, and Photoshop integration. All samples verified for parsing and feature extraction.
- **Documentation:** Updated `Tests/README.md` with new test files (including `AudioKeyframeTests`), expanded file tests table, updated test count to 638, and enhanced scope description to include new FCPXML features tested.

### 🐛 Bug Fixes

- None in this release.

---

## [2.3.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.3.0) - 2026-02-16

### ✨ New Features

- **Live Drawing (FCPXML 1.11+):** Typed `LiveDrawing` model for the `live-drawing` story element (drawn/sketch content). Attributes: `role`, `dataLocator`, `animationType`; conforms to `FCPXMLElementClipAttributes` and `FCPXMLElementMetaTimeline`. Wired into `allTimelineCases`, `FCPXMLAnyTimeline` (`.liveDrawing(LiveDrawing)`), and `ElementModelType` / `AnyElementModelType`. Tests in APIAndEdgeCaseTests (init, attributes, AnyTimeline round-trip).
- **HiddenClipMarker (FCPXML 1.13+):** Typed `HiddenClipMarker` model (empty marker element). Included in `fcpxAnnotations` and `addToClip(annotationElements:)`. Version converter strips `hidden-clip-marker` when converting to &lt; 1.13. Tests in APIAndEdgeCaseTests and VersionConversionTests.
- **Format and Asset 1.13+:** Format `heroEye` (left | right) and Asset `heroEyeOverride`, `mediaReps` (multiple `media-rep`) with get/set, inits, and round-trip. Version converter strips `heroEye`/`heroEyeOverride` when converting to &lt; 1.13. Tests in FCPXMLFormatAssetTests and VersionConversionTests.
- **SmartCollection match rules:** Typed models and SmartCollection properties for `MatchUsage` (1.9+), `MatchRepresentation`, `MatchMarkers` (1.10+), `MatchAnalysisType` (1.14). Round-trip and version stripping. Tests in SmartCollectionTests.
- **Additional typed adjustments and Clip integration:** `ReorientAdjustment`, `OrientationAdjustment` (1.7+), `CinematicAdjustment` (1.10+), `ColorConformAdjustment` (1.11+), `Stereo3DAdjustment` (1.13+), `VoiceIsolationAdjustment` (1.14), `ConformAdjustment`, `RollingShutterAdjustment` with Clip accessors (`reorientAdjustment`, `orientationAdjustment`, `cinematicAdjustment`, `colorConformAdjustment`, `stereo3DAdjustment`, `voiceIsolationAdjustment`, `conformAdjustment`, `rollingShutterAdjustment`). Tests in AdjustmentTests.
- **FilterParameter and Keyframe auxValue (1.11+):** `FilterParameter` and `Keyframe` support `auxValue`; version converter strips param `auxValue` when target DTD does not include it. Tests in FilterTests.

### 🔧 Improvements

- **Version conversion:** `FCPXMLVersionConverter` uses DTD-derived allowlists (`FCPXMLDTDAllowlistGenerator.allowlist(fromDTDContent:)`) for element and attribute stripping; `EmbeddedDTDProvider` for CLI. Fallback to hand-maintained lists when DTD unavailable.
- **Documentation:** Manual restructured into chapter-based layout. New `Documentation/Manual/` with 18 files: 00-Index (table of contents), 01–17 covering Overview, Loading & Parsing, Timecode, Pipeline & Logging, Validation & Cut Detection, Version Conversion & Export, Timeline & Export, Timeline Manipulation, Timeline Metadata, Extraction & Media, Media Processing, Typed Models, XML Extensions, High-Level Model, Errors & Utilities, CLI, and Examples. `Documentation/README.md` updated with manual index and chapter links. Root `Documentation/Manual.md` now redirects to the structured manual.
- **Documentation:** Typed Models chapter (12) documents Live Drawing, HiddenClipMarker, Format/Asset 1.13+, SmartCollection match rules, and all adjustment/filter/caption/keyframe/collection models with examples.
- **Tests:** `Tests/README.md` reorganized with clear sections: table of contents by category (Structure & running, Coverage, Reference, Contributing & troubleshooting), test structure tree, shared utilities summary, tables for PipelineNeoTests MARK categories and for file tests (class | sample | asserts), and dedicated test files grouped by theme. Test count updated to **587 tests**. Added FCPXMLFormatAssetTests (LogicAndParsing).
- **Project rules:** `.cursorrules` and `AGENT.md` updated (backward compatibility note, Changelog section with styling: version links to release tags, ✨ New Features / 🔧 Improvements / 🐛 Bug Fixes).
- **FCPXMLClip+Adjustments:** Attribute names (e.g. `amount`, `enabled`, `type`) centralized in a private `AttributeName` enum to avoid typos and improve maintainability.
- **FCPXMLTitle+Typed:** Simplified optional-bold/italic/underline assignment from `condition ? true : nil` to `if condition { textStyle.property = true }` for clarity.
- **MediaRep:** Conforms to `@unchecked Sendable` for concurrent usage; bookmark child documented (single `bookmark` element for security-scoped bookmark data).

### 🐛 Bug Fixes

- **Gap `lane` setter:** Replaced `assertionFailure` with a no-op so setting `lane` on a gap clip no longer risks a crash in production.
- **MediaRep:** Added `FCPXMLElement` conformance so `_isElementTypeSupported` is correctly available and the type is consistent with other element models.
- **MediaRep init(bookmark: String):** Uses lossy UTF-8 encoding so the string-to-data conversion cannot fail silently by returning `nil`.

---

## [2.2.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.2.0) - 2026-02-14

### ✨ New Features

- **Typed adjustment models:** `CropAdjustment`, `TransformAdjustment`, `BlendAdjustment`, `StabilizationAdjustment`, `VolumeAdjustment`, `LoudnessAdjustment` with full `Clip` integration via computed properties.
- **Audio enhancement adjustments:** `NoiseReductionAdjustment`, `HumReductionAdjustment`, `EqualizationAdjustment`, `MatchEqualizationAdjustment` with parameter validation and `Clip` integration.
- **Transform360:** `Transform360Adjustment` model for 360° video (coordinate types spherical/cartesian, position/orientation, auto-orient, convergence, interaxial) with `Clip` integration.
- **Typed filter models:** `VideoFilter`, `AudioFilter`, `VideoFilterMask`, `FilterParameter` with keyframe animation support (`FadeIn`, `FadeOut`, `KeyframeAnimation`).
- **Caption and Title models:** `Caption` and `Title` with `TextStyle` and `TextStyleDefinition` for rich text formatting (font, fontSize, textAlignment, etc.).
- **Keyframe animation:** `KeyframeAnimation`, `Keyframe` (interpolation types), `FadeIn`/`FadeOut` (fade types), integrated with `FilterParameter`.
- **CMTime Codable:** Direct `CMTime` encoding/decoding as FCPXML time strings (`"value/timescale"s` format).
- **Collection organization:** `CollectionFolder` and `KeywordCollection` models for organizing clips and media with nested folder structures.

### 🔧 Improvements

- **CutDetector:** Edit type classification for non-adjacent clips now prioritizes transitions over gaps when multiple elements exist between clips.
- **XMLElementExtension:** Synchronized clip matching fixed to prevent duplicate entries when multiple nested children match the same resource.
- **XMLElementExtension:** Compound clip traversal fixed to properly check secondary storylines (spine elements) for matching resources.
- **XMLElementExtension:** `childElementsWithinRangeOf` now explicitly handles elements with missing timing attributes (`fcpxOffset`/`fcpxDuration`).
- **MediaExtractor:** URL resolution documentation enhanced for `nil` URLs and non-file URLs (automatically skipped during copy).
- **FCPXMLVersionConverter:** Explicit error handling for edge case where `rootElement()` returns `nil` during version conversion (debug assertion in development builds).
- **FCPXMLUtility:** Added validation methods `validateDocumentAgainstDTD`, `validateDocumentAgainstDeclaredVersion`, `performValidation` for API parity with `FCPXMLService` (sync and async).
- **FCPXMLUtility:** Added `filterElements(_:ofTypes:)` alias for API consistency with `FCPXMLService`.
- **ModularUtilities:** Validator instance creation optimized using a shared static validator instance.
- **FCPXMLUtility:** Refactored deprecated project time conversion methods (`projectTimecode`, `projectCounterTime`) to delegate to sequence methods, removing duplication.
- **FCPXMLService / FCPXMLUtility:** Async validation method documentation improved (CPU-bound behavior, non-Sendable type constraints).
- **ProgressBar:** Thread safety documentation enhanced with usage guidelines.
- **ProgressReporter:** Protocol documentation clarified for thread safety expectations.
- **Test suite:** Expanded to 535 tests; added AdjustmentTests, AudioEnhancementTests, Transform360Tests, CaptionTitleTests, KeyframeAnimationTests, CMTimeCodableTests, CollectionTests, FilterTests, CodableTests, ImportOptionsTests, SmartCollectionTests.
- **Documentation:** AGENT.md, .cursorrules, Tests/README.md, README.md, Documentation/Manual.md, and Documentation/README.md updated for new features and test count.

### 🐛 Bug Fixes

- None explicitly called out in this release (improvements above include behavioral fixes in CutDetector and XMLElementExtension).

---

## [2.1.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.1.0) - 2026-02-13

### ✨ New Features

- **Timeline manipulation:** Ripple insert (shifts subsequent clips), auto lane assignment, clip queries (by lane, time range, asset ID), lane range computation.
- **Timeline metadata:** Markers, chapter markers, keywords, ratings, custom metadata on timeline and clips.
- **Timestamps:** `createdAt` and `modifiedAt` on Timeline (auto-updated on mutations).
- **FCPXMLTimecode:** Custom timecode type wrapping Fraction (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing).
- **MIME type detection:** `MIMETypeDetection` protocol with UTType + AVFoundation support (video/audio/image formats).
- **Asset validation:** `AssetValidation` protocol (existence + MIME compatibility with lanes: negative = audio only, non-negative = video/image/audio).
- **Silence detection:** `SilenceDetection` protocol (silence at start/end of audio; threshold, minimum duration).
- **Asset duration measurement:** `AssetDurationMeasurement` protocol (actual duration from AVFoundation for audio/video/images).
- **Parallel file I/O:** `ParallelFileIO` protocol for concurrent read/write operations.

### 🔧 Improvements

- **TimelineFormat:** Presets (hd720p, dci4K, hd1080i, hd720i); computed properties (aspectRatio, isHD, isUHD, isDCI4K, isStandard4K, is1080p, is720p, interlaced).
- **TimelineError:** New cases `assetNotFound`, `invalidFormat`, `invalidAssetReference`.
- **Test suite:** Expanded to 320 tests (TimelineManipulationTests, FCPXMLTimecodeTests, MIMETypeDetectionTests, AssetValidationTests, SilenceDetectionTests, AssetDurationMeasurementTests, ParallelFileIOTests).
- **CI:** Added CodeQL workflow.
- **Documentation:** Manual.md and Tests README updated with new APIs and examples.

### 🐛 Bug Fixes

- None documented in this release.

---

## [2.0.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.0.1) - 2026-02-11

### ✨ New Features

- **CLI:** `--log`, `--log-level`, `--quiet`; `--extension-type` for convert (fcpxmld | fcpxml; default fcpxmld; 1.5–1.9 always .fcpxml); `--extract-media` renamed to `--media-copy` under EXTRACTION; `--validate` (semantic + DTD; progress when not quiet). Single binary with embedded DTDs.
- **Progress bar:** TQDM-style progress for `--media-copy` and `--validate`.
- **Logging:** When `--log` is set, all CLI commands write user-visible output to the log file.

### 🔧 Improvements

- **Logging:** Seven levels (trace–critical); optional file + console; quiet mode.
- **Semantic validation:** Refs resolved against all element IDs (e.g. text-style-def in titles), not only top-level resources.
- **Library:** `FCPXMLVersion.supportsBundleFormat` (1.10+ for .fcpxmld; 1.5–1.9 .fcpxml only).
- **Scripts:** `generate_embedded_dtds.sh` / `swift run GenerateEmbeddedDTDs` regenerate EmbeddedDTDs.swift (1.5→1.14); Scripts/README; Xcode Build post-actions remove generator binary after build.
- **Service:** Logs parse, convert, save, DTD validate, media extract/copy.
- **Test suite:** 181 tests.
- **Documentation:** README, Manual, CLI README, Documentation/, Scripts, .cursorrules, AGENT.md updated.

### 🐛 Bug Fixes

- None documented in this release.

---

## [2.0.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/2.0.0) - 2026-02-09

### ✨ New Features

- **Cut detection:** Find edit points on a timeline (hard cut, transition, gap); same-clip vs different-clips.
- **Version conversion:** Convert FCPXML to another version (e.g. 1.14 → 1.10) with automatic cleanup; save as single file or bundle.
- **Document validation:** Validate against a specific FCPXML version (1.5–1.14) or against the document’s declared version.
- **Media extraction and copy:** Find all referenced media and copy to a folder (deduplicated).
- **Experimental CLI (`pipeline-neo`):** Check document version, convert to target version, extract media to folder.

### 🔧 Improvements

- **Architecture:** Full codebase rewrite with protocol-oriented design.
- **Test suite:** Expanded to 177 tests.
- **Documentation:** Manual, README, and project docs updated.

### 🐛 Bug Fixes

- None documented in this release.

---

## [1.1.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/1.1.0) - 2026-02-06

### ✨ New Features

- **FCPXML 1.14:** DTD and version support for 1.14; documentation, tests, and CI cover 1.5 through 1.14.
- **Element-type coverage:** Full DTD element-type coverage via `FCPXMLElementType` (tag names, inferred types, filtering across parser and utility).
- **Single injection point:** Extension APIs use `FCPXMLUtility.defaultForExtensions`; custom pipelines use modular API with dependency injection.

### 🔧 Improvements

- **Dependencies:** Integrated [swift-extensions](https://github.com/orchetect/swift-extensions).
- **Concurrency:** Sendable compliance across protocols and implementations; async/await APIs throughout.
- **Test suite:** Expanded to 66 tests; FCPXML time strings (valid/invalid).
- **Errors:** `FCPXMLError` and public option enums marked `Sendable`; error descriptions verified for all cases.

### 🐛 Bug Fixes

- None documented in this release.

---

## [1.0.2](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/1.0.2) - 2025-11-30

### ✨ New Features

- None in this release.

### 🔧 Improvements

- **Dependencies:** Migrated from TimecodeKit to SwiftTimecode 3.0.0. Package dependency updated to `https://github.com/orchetect/swift-timecode`. All imports updated; Timecode initializer updated to `Timecode(.realTime(seconds:), at: frameRate)`; frame rate cases updated to `.fps24`, `.fps25`, `.fps29_97`, `.fps30`, `.fps50`, `.fps59_94`, `.fps60`, `.fps23_976`. Documentation and version references updated. Task-based concurrency avoided for Foundation XML and SwiftTimecode types (Sendable limitations).

### 🐛 Bug Fixes

- None documented in this release.

---

## [1.0.1](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/1.0.1) - 2025-07-11

### ✨ New Features

- **Async/await:** Comprehensive async/await support across all major operations. All protocols, implementations, services, and utilities have async methods.

### 🔧 Improvements

- **Concurrency:** Enhanced concurrency safety with Sendable compliance; async error propagation; thread-safe implementation and resource management.
- **Test suite:** Updated to 66 comprehensive tests with async/await coverage.
- **Documentation:** Async/await usage examples added.
- **Architecture:** Protocol-oriented design with both sync and async APIs; task-based concurrency avoided for Foundation XML and TimecodeKit types; performance optimizations for async operations.

### 🐛 Bug Fixes

- None documented in this release.

---

## [1.0.0](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/1.0.0) - 2025-07-10

### ✨ New Features

- First public release of **Pipeline Neo**.

### 🔧 Improvements

- N/A

### 🐛 Bug Fixes

- N/A

