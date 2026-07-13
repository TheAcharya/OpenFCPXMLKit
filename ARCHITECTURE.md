# OpenFCPXMLKit — Architecture & Conventions

A guide for contributors: project structure, architecture, naming, styling, and design decisions.

**See also:** [.cursorrules](.cursorrules), [AGENT.md](AGENT.md), [Tests/README.md](Tests/README.md).

---

## 1. Project overview

OpenFCPXMLKit is a **Swift 6** framework for Final Cut Pro FCPXML: parsing, creation, manipulation, and timecode operations (via SwiftTimecode). It is **protocol-oriented** and **dependency-injected**: core behaviour is behind protocols; default implementations are injectable; extension APIs that cannot take parameters use a single shared instance.

- **Package:** `OpenFCPXMLKit` (`swift-tools-version: 6.3`)
- **Products:** `OpenFCPXMLKit` (library, includes XLKit Excel export), `OpenFCPXMLKit-CLI` (executable), `GenerateEmbeddedDTDs` (internal build tool)
- **Targets:** macOS 26+, iOS 26+, Xcode 26+, Swift 6.3+
- **Repository:** https://github.com/TheAcharya/OpenFCPXMLKit
- **Dependencies:** SwiftTimecode 3.1.2+, SwiftExtensions 2.2.0+, swift-log 1.14.0+, AEXML 4.7.0+, swift-argument-parser 1.8.2+ (CLI only), Foundation, CoreMedia.
- **FCPXML:** Versions 1.5–1.14 (DTDs included); Final Cut Pro frame rates (23.976, 24, 25, 29.97, 30, 50, 59.94, 60).
- **Tests:** **944** tests listed in `swift test --list-tests` — **942** in `OpenFCPXMLKitTests` (939 XCTest `func test` + 3 Swift Testing `@Test`) and **2** optional `ExcelReportTest` integration tests; **58** sample `.fcpxml` files under `Tests/FCPXML Samples/FCPXML/`.

---

## 2. Architecture

### 2.1 Protocol-oriented design

All major operations are defined as **protocols** with both **sync** and **async/await** methods. Default implementations live in `Implementations/`; callers inject dependencies into `FCPXMLUtility` or `FCPXMLService`.

| Protocol(s) | Implementation |
|-------------|----------------|
| FCPXMLParsing, FCPXMLElementFiltering | FCPXMLParser |
| TimecodeConversion, FCPXMLTimeStringConversion, TimeConforming | TimecodeConverter |
| XMLDocumentOperations, XMLElementOperations | XMLDocumentManager |
| ErrorHandling | ErrorHandler |
| CutDetection | CutDetector |
| FCPXMLVersionConverting | FCPXMLVersionConverter |
| MediaExtraction | MediaExtractor |
| MIMETypeDetection | MIMETypeDetector |
| AssetValidation | AssetValidator |
| SilenceDetection | SilenceDetector |
| AssetDurationMeasurement | AssetDurationMeasurer |
| ParallelFileIO | ParallelFileIOExecutor |
| ServiceLogger | NoOpServiceLogger, PrintServiceLogger, FileServiceLogger |

Semantic and DTD validation use **concrete structs** (`FCPXMLValidator`, `FCPXMLDTDValidator`, `FCPXMLStructuralValidator`) that are injected; they are not behind protocols.

### 2.2 Single injection point for extensions

Extension APIs that **cannot take parameters** (e.g. `CMTime.fcpxmlString`, `XMLElement.fcpxDuration`) use **`FCPXMLUtility.defaultForExtensions`** (concurrency-safe). For custom services, use the **modular API** with the `using:` parameter (e.g. `CMTime+Modular`, `XMLElement+Modular`, `XMLDocument+Modular`).

- **Rule:** No hidden concrete types in extension APIs; use `defaultForExtensions` or inject via `using:`.

### 2.3 Facades

- **FCPXMLService** — Preferred facade: inject dependencies and call service methods (parse, convert, validate, save, media operations). Sync and async.
- **FCPXMLUtility** — Legacy/convenience facade; same dependencies and behaviour. Holds `defaultForExtensions`.
- **ModularUtilities** — `createService()` / `createCustomService()` for building a default or custom `FCPXMLService`; `validateDocument(_:)`; `processFCPXML(from:using:)`; `convertTimecodes(...)`.

### 2.4 Concurrency

- **Sendable** where appropriate; Swift 6 strict concurrency (`-strict-concurrency=complete`) in CI.
- **Foundation XML** (XMLDocument, XMLElement), the **OFKXML** protocol types (OFKXMLDocument, OFKXMLElement) that wrap them, and **SwiftTimecode** types are not Sendable. The codebase provides **async/await** APIs but avoids Task-based concurrency over these types.
- Use `async/await` for asynchronous operations; use `Task`/`TaskGroup` only where types are Sendable.

### 2.5 Cross-platform XML (iOS support)

- **XML abstraction:** All document/element access goes through **protocols** (OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLFactory). On **macOS** the default backend is Foundation (FoundationXMLElement, FoundationXMLDocument, FoundationXMLFactory). On **iOS** the backend is AEXML (AEXMLBackendElement, AEXMLBackendDocument, AEXMLBackendFactory). Use **OFKXMLDefaultFactory()** so the correct backend is used for the current platform.
- **DTD validation:** Full DTD validation is macOS-only. **FCPXMLDTDValidator** on iOS uses **FCPXMLStructuralValidator** (root, version, resources, element allowlist) and may add a `structuralValidationOnly` warning.

### 2.6 Error handling

- **Sync:** `Result<T, FCPXMLError>` or `do`/`catch`.
- **Async:** `throw` and propagate `FCPXMLError` (e.g. `parsingFailed(Error)`).
- **Module errors:** `FCPXMLError`, `FCPXMLLoadError`, `FCPXMLExportError`, `FCPXMLBundleExportError`, `FinalCutPro.FCPXML.ParseError`, `TimelineError`. Parse failures from all layers surface as `FCPXMLError.parsingFailed`.

### 2.7 Reporting and core layers

Workbook **reporting** (`Reporting/`) sits at the top of the stack. It maps already-extracted FCPXML facts into row models and sheet sections. It is **not** where new FCPXML semantics should first be implemented.

When FCPXML grows more complex (nested sync-clips, compound clips, richer adjustments, role inheritance, occlusion, per-span metadata), extend the engine **bottom-up** so CLI, extraction presets, timeline tools, and reports share one foundation:

```text
XML/              OFKXML protocols and platform backends (Foundation, AEXML)
    ↓
Parsing/          Attribute and structure parsing (time, roles, clips, metadata)
    ↓
Model/            Typed elements, adjustments, filters, roles, occlusion
    ↓
Extraction/       fcpExtract, ExtractionScope, timeline/role context
    ↓
Reporting/        Row models, builders, sheet-specific presentation rules
```

**1. Model and Parsing** — Add or extend typed coverage first:

- New element types in `FCPXMLElementType` and `Model/` (clips, adjustments, filters, resources).
- Attribute parsing in `Parsing/` and element extensions on `OFKXMLElement`.
- Shared value types (e.g. transform adjustments, volume spans) that any consumer can reuse.

**2. Extraction** — Expose consistent context for callers:

- Timeline absolute start/end via extraction context (`ExtractedElement`, `ElementContext`).
- Inherited roles, occlusion, sync/mc/ref-clip traversal rules in `Extraction/`.
- Presets and scope flags (`ExtractionScope`, `includeDisabled`, `occlusions`) rather than ad hoc XML walks.

**3. Reporting** — Keep thin:

- Builders call `fcpExtract` and shared context helpers (`ElementContext`, effect/title contexts).
- Sheet-specific **presentation policy** only: column order, string formatting (including `ReportTimecodeFormat`), sort order (numeric for Frames / Feet+Frames), inclusion allowlists (e.g. which custom filters appear on an effects sheet), global column exclusion (`ReportColumn`, `ReportColumnExclusion`), format-aware timecode column headers, shared row text colours (`FCPXMLReportRowColorPolicy` — used by Excel and PDF), workbook/PDF cell colours (`FCPXMLReportWorkbookExporter`, `RoleRowColorContext` on Excel; PDF applies the same policy via CoreGraphics), and optional cover-sheet / cover-page branding (`Report.exportBrandingText`).
- `ReportOptions.excludeDisabledClips` flows into `ExtractionScope.includeDisabled` at build time so disabled clips are omitted consistently across all timeline-based sections.
- `ReportOptions.timecodeFormat` is stored on `Report.timecodeFormat` and drives cell strings plus Excel/PDF header suffixes (e.g. `Timeline In (frames)`).
- Build / progress order is **`ReportBuildPhase.enabledPhases(for:)`** (product / workbook order: Selected Roles Inventory first, then Markers … Media Summary). `ReportBuilder` and CLI/GUI progress share this list.
- **Timeline resolution** for `buildReport` / `ReportBuilder` uses **`FinalCutPro.FCPXML.allReportTimelineSources()`** (defined on `FCPXMLProperties`): every `<project>` sequence, plus event-level compound clips (`ref-clip` → `media`/`sequence`) when FCP exported a compound clip with no `<project>`. Prefer a real project when both exist. `ReportOptions.projectName` / CLI `--report-project` match project or compound-clip display names. Discovery belongs on `FCPXML` (Classes); Reporting only consumes `ReportTimelineSource`.
- Do **not** duplicate timeline math, role resolution, or element traversal that belongs in Extraction/Model.

**Where to put a change**

| Concern | Layer |
|--------|--------|
| New `adjust-*` or `filter-*` element understood from XML | Model, Parsing |
| Correct absolute timeline for a nested clip or effect span | Extraction |
| Discover project vs standalone compound-clip report timelines | Classes (`allReportTimelineSources` / `ReportTimelineSource`); Reporting resolves via that API |
| Which rows appear on a given workbook sheet | Reporting |
| Column labels, timecode strings, enabled checkmarks | Reporting |
| Timecode display mode (SMPTE / Frames / Feet+Frames / HH:MM:SS) and header suffixes | `ReportOptions.timecodeFormat` → `Report.timecodeFormat` → Formatting + Excel/PDF export |
| Build / progress / GUI section order | `ReportBuildPhase.enabledPhases(for:)` |
| Omit `enabled="0"` clips from all timeline sections | `ReportOptions.excludeDisabledClips` → Extraction scope |
| Omit named columns from every applicable sheet | `ReportOptions.excludedColumns` → `Report.excludedColumns` → Excel and PDF export |
| Workbook/PDF row text colours (inventory role category; section-sheet inference; Summary header-style title + black data; Media Summary red paths; marker-type colours) | `FCPXMLReportRowColorPolicy` (+ `FCPXMLReportWorkbookExporter` on Excel; PDF renderer applies same policy) |
| Missing media path list | Media Summary builder (`mediaBaseURL` for relative paths) |

**Workflow when a report gap appears**

1. Confirm whether the fact already exists in Model or Extraction; use it if so.
2. If the fact is missing, implement it in Model/Parsing, then wire it through Extraction.
3. Only then add or adjust Reporting builders to map that fact to rows.
4. Add **core** tests (parsing, extraction, occlusion, roles) alongside **report** integration tests that assert row shape against an optional local FCPXML fixture.

**Excel export** lives under **`Reporting/Excel/`** and serialises `Report` to XLKit workbooks via `ReportExcelExport` and `FCPXMLReportWorkbookExporter`; it applies column exclusion (including format-suffixed timecode headers), `Report.timecodeFormat` header suffixes, tabular header styling (black fill, white bold text), and sheet-specific row text colours but should not introduce new FCPXML interpretation.

**PDF export** lives under **`Reporting/PDF/`** and serialises the **same** `Report` to a multi-page A4 landscape PDF via `ReportPDFExport` and `FCPXMLReportPDFExporter` (CoreGraphics). Build the report once; export to Excel, PDF, or both. PDF respects the same section flags, `excludedColumns`, `timecodeFormat`, role/disabled-clip filtering, and row colours. PDF-only presentation: cover page, dynamic table of contents (two-pass page numbering), per-sheet tinted content zones, horizontal/vertical table pagination, and ellipsis truncation. CLI: `--create-pdf` (with `--report`).

---

## 3. Project structure

### 3.1 Codebase map

The package builds one library, one CLI executable, and one internal build tool. The diagrams below read **top to bottom**. The library is layered bottom-up (see §2.7): **FCPXML DTDs** and the platform-agnostic **XML** layer feed **Parsing**, which builds the typed **Model**, which **Extraction** exposes with timeline/role context, which **Reporting** maps into workbook sheets. Cross-cutting subsystems (Classes, Implementations, Protocols, Services, Timeline, Export, Validation, etc.) sit alongside that pipeline.

#### Package layout

```mermaid
flowchart TB
    Pkg["OpenFCPXMLKit — Swift Package"]

    Pkg --> SRC["Sources/"]
    Pkg --> TST["Tests/"]
    Pkg --> DOC["Documentation/"]

    SRC --> LIB["OpenFCPXMLKit library"]
    SRC --> CLI["OpenFCPXMLKitCLI → OpenFCPXMLKit-CLI"]
    SRC --> GEN["GenerateEmbeddedDTDs"]

    TST --> OKT["OpenFCPXMLKitTests — 942 tests"]
    TST --> ERT["ExcelReportTest — 2 optional integration tests"]
    TST --> SMP["FCPXML Samples/ — 58 .fcpxml files"]
```

#### Library layer stack (bottom → top)

```mermaid
flowchart TB
    DTD["FCPXML DTDs 1.5–1.14"]
    XML["XML/ — OFKXML protocols · Foundation · AEXML"]
    PRS["Parsing/ — attributes, clips, roles, time"]
    MDL["Model/ — typed elements, adjustments, filters, roles"]
    EXT["Extraction/ — fcpExtract · Context · Presets"]
    REP["Reporting/ — Report builders · Sections · Excel · PDF export"]

    DTD --> XML --> PRS --> MDL --> EXT --> REP
```

#### Reporting and CLI detail

```mermaid
flowchart TB
    subgraph REP_DETAIL["Reporting/"]
        direction TB
        R_TOP["Report · ReportOptions · ReportBuilder · ReportTimecodeFormat · ReportBuildProgress"]
        R_BLD["Builders/ — RoleInventory · Markers · Keywords · Titles · Transitions · Effects · SpeedChange · Summary · MediaSummary"]
        R_SEC["Sections/ + Rows/ — typed sheet models · format-aware columnHeaders"]
        R_SUP["Support/ — RoleInventoryClipCollector · RoleInventoryColumnLayout · ReportColumnExclusion · ReportFormatting · FCPXMLReportRowColorPolicy · …"]
        R_XLS["Excel/ — ReportExcelExport · FCPXMLReportWorkbookExporter · ColumnAutoFit"]
        R_PDF["PDF/ — ReportPDFExport · FCPXMLReportPDFExporter · Canvas · SheetPlan · TableLayout · Style"]
        R_TOP --> R_BLD --> R_SEC
        R_BLD --> R_SUP
        R_SUP --> R_XLS
        R_SUP --> R_PDF
    end

    subgraph CLI_DETAIL["OpenFCPXMLKitCLI/"]
        direction TB
        C_ROOT["OpenFCPXMLKitCLI.swift"]
        C_OPT["Options/ — General · Timeline · Report · Log"]
        C_CMD["Commands/ — CheckVersion · ConvertVersion · Validate · ExtractMedia · CreateProject · ExportReport"]
        C_GEN["Generated/EmbeddedDTDs.swift"]
        C_ROOT --> C_OPT --> C_CMD
        C_ROOT --> C_GEN
    end
```

#### Model, Extraction, and XML subfolders

```mermaid
flowchart TB
    subgraph MDL_SUB["Model/ subfolders"]
        direction TB
        M1["Adjustments · Animations · Attributes"]
        M2["Clips · CommonElements · ElementTypes"]
        M3["Filters · Occlusion · Protocols"]
        M4["Resources · Roles · Structure"]
        M1 --> M2 --> M3 --> M4
    end

    subgraph EXT_SUB["Extraction/ subfolders"]
        direction TB
        E1["Context/ — ElementContext · DisplayClipName"]
        E2["Effects/ — EffectsCollector"]
        E3["Presets/ — Captions · Effects · Markers · Roles · Titles · FrameData"]
        E1 --> E2 --> E3
    end

    subgraph XML_SUB["XML/ subfolders"]
        direction TB
        X1["Protocols/ — OFKXMLNode · OFKXMLElement · OFKXMLDocument · OFKXMLFactory"]
        X2["Foundation/ — macOS backend"]
        X3["AEXML/ — iOS backend"]
        X1 --> X2
        X1 --> X3
    end
```

**Cross-cutting library folders** (alongside the layer stack): Analysis, Annotations, Classes, Delegates, Errors, Extensions (+Modular, +Codable), Implementations, Protocols, Services, Utilities, Export, Timeline, Timing, Validation, FileIO, Media, Logging, Format.

### 3.2 Library folders

Source layout under **`Sources/OpenFCPXMLKit/`**:

| Folder | Purpose |
|--------|---------|
| **Analysis** | EditPoint, CutDetectionResult (cut detection). |
| **Classes** | FinalCutPro, FCPXML, FCPXMLElementType, FCPXMLUtility, FCPXMLVersion, FCPXMLRoot, FCPXMLRootVersion, FCPXMLInit, FCPXMLProperties (`allProjects`, `allTimelines`, `allReportTimelineSources` / `ReportTimelineSource` for project + standalone compound-clip report timelines). |
| **Delegates** | AttributeParserDelegate, FCPXMLParserDelegate (internal). |
| **Errors** | FCPXMLError, FCPXMLParseError, TimelineError. |
| **Extensions** | CMTime, XMLElement, XMLDocument (+Modular, +Codable, and non-modular). FCPXML extensions operate on OFKXMLElement/OFKXMLDocument protocol types. |
| **Implementations** | Default implementations of all protocols above. |
| **Protocols** | All operation protocols. |
| **Services** | FCPXMLService. |
| **Utilities** | ModularUtilities, FCPXMLTimeUtilities, FCPXMLUID, FCPXMLCodableConverter, EmbeddedDTDProvider, FCPXMLDTDAllowlistGenerator, ProgressBar, ProgressBarStyle, SequencePlusAnySequence, XMLElementAncestorWalking, XMLElementSequenceAttributes. |
| **Annotations** | Marker, ChapterMarker, Keyword, Rating, Metadata (creation-oriented). |
| **Export** | FCPXMLExporter, FCPXMLBundleExporter, FCPXMLExportAsset. |
| **Timeline** | Timeline, TimelineClip (TimelineFormat presets live in Timeline.swift). |
| **Timing** | FCPXMLTimecode. |
| **Validation** | FCPXMLValidator, FCPXMLDTDValidator, FCPXMLStructuralValidator (cross-platform; used on iOS when DTD unavailable), ValidationResult, ValidationError/Warning, DocumentValidationReport. |
| **FileIO** | FCPXMLFileLoader. |
| **Logging** | ServiceLogger, ServiceLogLevel, NoOp/Print/FileServiceLogger. |
| **Media** | MediaReference, MediaExtractionResult, MediaCopyResult. |
| **Format** | ColorSpace. |
| **Model** | FCPXML element models: Adjustments, Animations, Attributes, Clips, CommonElements, ElementTypes, Filters, Occlusion, Protocols, Resources, Roles, Structure (CollectionFolder, KeywordCollection, etc.). |
| **Parsing** | XML parsing extensions (Attributes, Clip, Elements, Metadata, Resources, Roles, Root, Time and Frame Rate). |
| **Extraction** | `fcpExtract`, ExtractedElement, ExtractionScope, ExtractableChildren. **Context/** (DisplayClipName, ElementContext, ElementContextItems/Tools, FrameRateSource), **Effects/** (EffectsCollector, ExtractedEffect), **Presets/** (Captions, Effects, FrameData, Markers, Roles, Titles, plus the base ExtractionPreset). |
| **Reporting** | Excel and PDF report export. Top-level: `Report`, `ReportOptions`, `ReportBuilder`, `ReportTimecodeFormat` (`.smpteFrames` / `.frames` / `.feetAndFrames` / `.smpteNoFrames`), `ReportBuildProgress` (`ReportBuildPhase.enabledPhases(for:)` — inventory-first product order shared by builder, CLI, and GUI progress). **Builders/** — per-sheet builders including `MediaSummaryReportBuilder` (missing media paths) and `SummaryReportBuilder` (project metrics + role durations). **Sections/** and **Rows/** — typed section/row models with `columnHeaders(timecodeFormat:)`. **Support/** — `RoleInventoryClipCollector`, `RoleInventoryRowBuilder`, `RoleInventoryColumnLayout`, `RoleInventoryRoleSheetOrdering`, `RoleInventoryTimelineBounds`, `ReportFormatting`, `ReportRoleExclusion`, `ReportColumnExclusion`, `ReportClipCategory`, `FCPXMLReportRowColorPolicy` (shared Excel/PDF row colours), `EffectsReportPolicy`, `SpeedChangeFormatting`, `SummaryRoleDurationAggregator`. **Excel/** — `ReportExcelExport`, `FCPXMLReportWorkbookExporter`, `ReportWorkbookColumnAutoFit`. **PDF/** — `ReportPDFExport`, `FCPXMLReportPDFExporter`, `FCPXMLReportPDFCanvas`, `FCPXMLReportPDFSheetPlan`, `FCPXMLReportPDFTableLayout`, `FCPXMLReportPDFStyle`, `FCPXMLReportPDFCoverNotes`. `ReportOptions`: `excludeDisabledClips`, `excludedColumns`, `timecodeFormat`, `includeMediaSummary`, `mediaBaseURL`, `projectName`. `Report.exportBrandingText` for Excel cover and PDF cover/footer. Timeline pick via `allReportTimelineSources()` (see §2.7). Consumes Extraction; owns presentation only. |
| **XML** | Platform-agnostic XML layer: Protocols (OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLDTDProtocol, OFKXMLFactory), Foundation/ (Foundation backends), AEXML/ (AEXML backends), OFKXMLDefaultFactory. |
| **FCPXML DTDs** | Version 1.5–1.14 DTDs. |

**CLI:** `Sources/OpenFCPXMLKitCLI/` — commands (`CheckVersion`, `ConvertVersion`, `Validate`, `ExtractMedia`, `CreateProject`, `ExportReport`), option groups (`GeneralOptions`, `TimelineOptions`, `ExtractionOptions`, `ReportCLIOptions`, `LogOptions`), embedded DTDs (`Generated/EmbeddedDTDs.swift`).

**Internal tool:** `Sources/GenerateEmbeddedDTDs/` — generates embedded DTD source for the CLI.

**Root:** `Version.swift` — package version constant at target root.

---

## 4. Naming conventions

### 4.1 Swift identifiers

- **Types & protocols:** PascalCase (e.g. `FCPXMLParser`, `FCPXMLParsing`).
- **Variables & functions:** camelCase.
- **Descriptive names** for all public APIs; avoid abbreviations except common ones (e.g. URL, ID).
- **No marketing terms in code:** Never use "PBF" or "Production's Best Friend" in source code, code comments, symbol names, or CLI/log output. Name the reporting feature neutrally (e.g. `Report`, `RoleInventoryReportBuilder`, "Excel report", "workbook export"). Those terms may appear only in prose documentation (README, CHANGELOG, Manual, and these agent guides) — never in the codebase itself.

### 4.2 File names

- **No spaces** in `.swift` file names. Use PascalCase-style names (e.g. `FCPXMLRoot.swift`, `FCPXMLTimeUtilities.swift`, `FCPXMLTimeAndFrameRateParsing.swift`).
- **Extension files:** Keep the `+` suffix (e.g. `CMTime+Modular.swift`, `XMLElement+Modular.swift`).
- **One primary type or concern per file** where practical; file name usually matches the main type or topic.

### 4.3 Special file names (collision avoidance)

- `FCPXMLElementOcclusionCalculation.swift` — occlusion calculation utility (distinct from `FCPXMLElementOcclusion.swift`).
- `FCPXMLExtractedElementStruct.swift` — struct `ExtractedElement` (protocol in `FCPXMLExtractedElement.swift`).
- `FCPXMLElementTypeModel.swift` — parsing-layer `FinalCutPro.FCPXML.ElementType` (Classes/`FCPXMLElementType.swift` is the DTD enum).

---

## 5. Code style & file header

### 5.1 Swift style

- Swift 6.3 syntax and features; follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- Use value types where appropriate; avoid force unwrapping; use optionals and `Result`/`throw` for failure.

### 5.2 File header (required for new Swift files)

```swift
//
//  FileName.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Brief description of the file's purpose.
//
```

- Replace `FileName.swift` with the **actual** file name.
- Purpose block: **tab** after `//`, not spaces.
- Two blank lines between header block and purpose block.
- Do **not** add `Created by`, extra `Copyright ©` lines, or legacy project names.

### 5.3 Documentation

- **Public APIs:** `///` doc comments; document parameters, return values, and thrown errors; include usage examples where helpful.
- **README / Manual:** Update when adding features or changing behaviour.

---

## 6. Design decisions

- **FCPXMLParser** delegates URL loading to **FCPXMLFileLoader** (one code path for .fcpxml and .fcpxmld).
- **FCPXMLVersion** (1.5–1.14, DTD) and **FinalCutPro.FCPXML.Version** (1.0–1.14, parsing) are bridged via `.fcpxmlVersion`, `.dtdVersion`, and `init(from:)`.
- **Version conversion** sets root version and **strips elements** not in the target DTD (e.g. adjust-colorConform, adjust-stereo-3D). Per-version DTD validation via `FCPXMLService.validateDocumentAgainstDTD(_:version:)` and `validateDocumentAgainstDeclaredVersion(_:)`.
- **Timeline** is a value type; manipulation methods (e.g. ripple insert, auto lane) return new instances or results; timestamps (`createdAt`, `modifiedAt`) are updated on mutating operations.
- **SwiftTimecode:** Use `Timecode(.realTime(seconds:), at: frameRate)` and frame rate cases `.fps23_976`, `.fps24`, `.fps25`, etc. (not the old `._24`, `._25`).
- **Cross-platform XML:** Use `OFKXMLDefaultFactory()` when creating documents/elements so iOS gets the AEXML backend. All parsing and model code uses `any OFKXMLDocument` / `any OFKXMLElement`; the concrete type is chosen at runtime.
- **Logging:** `ServiceLogger` protocol with `ServiceLogLevel`; inject via `FCPXMLService` / `FCPXMLUtility` or build from CLI `LogOptions.makeLogger()`.
- **Service factory:** `ModularUtilities.createService()` returns a fully configured `FCPXMLService`; `createCustomService(...)` accepts custom protocol implementations.
- **Report timeline sources:** `allReportTimelineSources()` discovers project sequences and event-level compound-clip sequences so Excel and PDF reporting work for FCP “Export XML” of a compound clip (no `<project>`).

---

## 7. CLI

Binary name: **`OpenFCPXMLKit-CLI`**. Mutually exclusive modes: `--check-version`, `--convert-version`, `--extension-type` (fcpxmld | fcpxml), `--validate`, `--media-copy`, `--report`, `--create-project` (requires `--width`, `--height`, `--rate`, `--project-version`, output-dir).

**`--report`** builds an Excel workbook from a normal project **or** a standalone compound-clip export (role inventory by default — **Selected Roles Inventory** + per-role sheets). `--report-full` adds every optional sheet. Per-section flags: `--report-markers`, `--report-keywords`, `--report-titles-generators`, `--report-transitions`, `--report-effects`, `--report-speed-change-effects`, `--report-summary`, `--report-media-summary`. **`--create-pdf`** also writes a `.pdf` from the same built `Report` (sections, column exclusions, timecode format). Filtering: `--exclude-role` (repeatable), `--exclude-column` (repeatable; global column omission), `--exclude-disabled-clips` (omit `enabled="0"` clips), `--report-project` (project or compound-clip name). Timecode cells: `--timecode-format` (`HH:MM:SS:FF` default, `Frames`, `Feet+Frames`, `HH:MM:SS`). Progress labels follow `ReportBuildPhase.enabledPhases(for:)` (inventory first), then Saving workbook, then Saving PDF when `--create-pdf` is set. Log options: `--log`, `--log-level`, `--quiet`. See `Sources/OpenFCPXMLKitCLI/README.md` and `Documentation/Manual/16-CLI.md`.

---

## 8. Tests

- **Count:** **944** listed in `swift test --list-tests` — **942** in `OpenFCPXMLKitTests` (939 XCTest + 3 Swift Testing `@Test` in `FCPXMLReportRoleExclusionTests`) and **2** in optional `ExcelReportTest` (skips without a local `.fcpxml`/`.fcpxmld` fixture).
- **Location:** `Tests/OpenFCPXMLKitTests/`; samples in `Tests/FCPXML Samples/FCPXML/` (58 files); optional integration under `Tests/ExcelReportTest/`.
- **Utilities:** `FCPXMLTestResources.swift`, `FCPXMLTestUtilities.swift` (path resolution, sample loading; `XCTSkip` when a sample is missing); `FCPXMLReportingReportFixture.swift` / `FCPXMLReportingReportTestSupport.swift` for optional reporting fixtures.
- **Reporting tests:** `FCPXMLCompoundClipReportTests` (standalone compound-clip FCPXML / `allReportTimelineSources()`), `FCPXMLReportTimecodeFormatTests` (DF/NDF, all four formats, format-aware headers, full-report shape), `FCPXMLReportBuildPhaseTests` (inventory-first `enabledPhases` / `onPhaseStarted` order), `FCPXMLRoleInventoryColumnLayoutTests`, `FCPXMLReportColumnExclusionTests` (including suffixed Timeline In headers), `FCPXMLReportExcludeDisabledClipsTests`, `FCPXMLReportExcelExportTests` (workbook cell formatting), `FCPXMLReportPDFExportTests` (cover, TOC, section parity, pagination, branding), `FCPXMLReportFormattingTests` (SMPTE / Frames / Feet+Frames / HH:MM:SS formatting and numeric sort guardrails), plus role inventory, section, and related support tests. See **Tests/README.md** §1 for the full file tree.
- **Coverage:** Unit, integration, and performance tests; sync and async; all supported frame rates and FCPXML versions. See **Tests/README.md** for categories and how to run tests.

---

## 9. Git & quality

- **Branches:** main, dev, feature/*, bugfix/*.
- **Commits:** Clear, imperative subject; optional body; reference issues when applicable.
- **Before merge:** All tests passing, docs updated, no new warnings; concurrency and error handling reviewed.

---

## 10. References

- **Internal:** [.cursorrules](.cursorrules), [AGENT.md](AGENT.md), [Documentation/Manual.md](Documentation/Manual.md), [Tests/README.md](Tests/README.md).
- **External:** [Final Cut Pro XML](https://fcp.cafe/developers/fcpxml/), [SwiftTimecode](https://github.com/orchetect/swift-timecode), [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/), [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/).
