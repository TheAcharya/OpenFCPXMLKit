# OpenFCPXMLKit — Test Suite

This directory contains the test suite for OpenFCPXMLKit, a Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration. The suite runs on **macOS** (Foundation XML backend). The library also supports **iOS 26+** (AEXML backend); CI builds for iOS Simulator; the same tests are not run on iOS because they rely on Foundation XML.

- **Test count:** **1076** tests listed in `swift test --list-tests` — **1072** in `OpenFCPXMLKitTests` (1069 XCTest `func test` methods + 3 Swift Testing `@Test` in `FCPXMLReportRoleExclusionTests`) and **4** in `ExcelReportTest` (optional integration; skips without a local fixture)
- **Scope:** Parsing, timecode, document operations, file loading, timeline export, validation (semantic, DTD, structural), timeline manipulation, media processing, typed models (adjustments, filters, captions/titles, keyframe animation), CMTime Codable, collections, Live Drawing (1.11+), HiddenClipMarker (1.13+), Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps), SmartCollection match rules, 360 video (projection, stereoscopic), auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, empty timeline creation at different sizes and frame rates, project-creation export at different sizes and frame rates (with DTD validation), FCPXMLExporter clip-level metadata export (markers, chapter-markers, keywords, ratings, metadata as asset-clip children; DTD and xmllint-compatible XML declaration), cross-platform XML (AEXML serialization parity, DTD validator behaviour, structural validator), Timeline Projection (`TimelineProjector` / `MediaUsageWindow` / `ReportProjectionContext`, project-once for report sections), Excel and PDF reporting (universal **Row** column on all tabular sheets via `ensuringRowColumn` / `allowsInjectedRowColumn`, role inventory columns, Summary sheet with project title in **B1**, Media Summary sheets, configurable `ReportTimecodeFormat` / DF·NDF notation, format-aware headers, Frames/Feet+Frames sort order, inventory-first `ReportBuildPhase` progress, global column exclusion, disabled-clip filtering, workbook export and cell formatting, PDF cover with black “About This PDF Export” header + `info.circle`, TOC with accent colour chips + content-tint washes keyed to sheet `colorIndex`, remaining columns expanded to fill A4 landscape width after exclusions, section pagination, shared `FCPXMLReportRowColorPolicy`, standalone compound-clip timelines via `allReportTimelineSources()` / `FCPXMLCompoundClipReportTests`), and all supported FCPXML versions and frame rates  
- **Layout:** Shared utilities for sample paths; file tests per sample; logic/parsing tests for model types and structure; validation and cross-platform XML tests; optional Excel/PDF report integration tests under `ExcelReportTest/`; private investigation inbox under `Submitted FCPXML/` (gitignored contents)

---

## Table of Contents

**Structure & running**

1. [Test structure](#1-test-structure)
2. [Running tests](#2-running-tests)

**Coverage**

3. [Test categories and coverage](#3-test-categories-and-coverage)
4. [File tests (per-sample)](#4-file-tests-per-sample-coverage)
5. [Logic and parsing tests](#5-logic-and-parsing-tests)
6. [Timeline, export, and validation](#6-timeline-export-and-validation-tests)
7. [API and edge case tests](#7-api-and-edge-case-tests)
8. [Performance tests](#8-performance-tests)

**Reference**

9. [Supported frame rates](#9-supported-frame-rates)
10. [FCPXML versions](#10-fcpxml-versions)
11. [Sample files](#11-sample-files)
12. [Excel and PDF report integration tests](#12-excel-and-pdf-report-integration-tests)
12a. [Submitted FCPXML (private inbox)](#12a-submitted-fcpxml-private-inbox)

**Contributing & troubleshooting**

13. [Writing and organising tests](#13-writing-and-organising-tests)
14. [Continuous integration](#14-continuous-integration)
15. [Debugging tests](#15-debugging-tests)
16. [Contributing to tests](#16-contributing-to-tests)
17. [Resources](#17-resources)
18. [Resolving common test/build messages](#18-resolving-common-testbuild-messages)
19. [Credits](#19-credits)

---

## 1. Test structure

```
Tests/
├── README.md
├── ExcelReportTest/              # Optional integration: writes real .xlsx/.pdf from local fixture
│   ├── README.md
│   ├── ExcelReportFixture.swift
│   ├── ExcelReportExportTests.swift
│   └── Output/                   # Generated workbooks (gitignored)
├── Submitted FCPXML/             # Private inbox (Inbox/ Notes/ gitignored — never commit FCPXML)
│   ├── README.md
│   ├── Inbox/
│   └── Notes/
├── FCPXML Samples/
│   └── FCPXML/                   # 59 public .fcpxml fixtures (incl. GeneralDemo)
└── OpenFCPXMLKitTests/
    ├── OpenFCPXMLKitTests.swift
    ├── FCPXMLTestResources.swift
    ├── FCPXMLTestUtilities.swift
    ├── FCPXMLSubmittedFCPXMLSmokeTests.swift
    ├── FCPXMLReportingReportFixture.swift
    ├── FCPXMLReportingReportTestSupport.swift
    ├── FileTests/
    │   ├── FCPXMLFileTest_24.swift
    │   ├── FCPXMLFileTest_360Video.swift
    │   ├── FCPXMLFileTest_AllSamples.swift
    │   ├── FCPXMLFileTest_Annotations.swift
    │   ├── FCPXMLFileTest_AuditionSample.swift
    │   ├── FCPXMLFileTest_BasicMarkers.swift
    │   ├── FCPXMLFileTest_Complex.swift
    │   ├── FCPXMLFileTest_CompoundClips.swift
    │   ├── FCPXMLFileTest_EmptyFormatProjects.swift
    │   ├── FCPXMLFileTest_FrameRates.swift
    │   ├── FCPXMLFileTest_GeneralDemo.swift
    │   ├── FCPXMLFileTest_ImageSample.swift
    │   ├── FCPXMLFileTest_Keywords.swift
    │   ├── FCPXMLFileTest_Multicam.swift
    │   ├── FCPXMLFileTest_Occlusion.swift
    │   ├── FCPXMLFileTest_Photoshop.swift
    │   ├── FCPXMLFileTest_SmartCollection.swift
    │   ├── FCPXMLFileTest_StandaloneAssetClip.swift
    │   └── FCPXMLFileTest_SyncClip.swift
    ├── LogicAndParsing/
    │   ├── FCPXMLFormatAssetTests.swift
    │   ├── FCPXMLRootVersionTests.swift
    │   └── FCPXMLStructureTests.swift
    ├── FCPXMLAEXMLSerializationParityTests.swift
    ├── FCPXMLAPIAndEdgeCaseTests.swift
    ├── FCPXMLAdjustmentTests.swift
    ├── FCPXMLAssetDurationMeasurementTests.swift
    ├── FCPXMLAssetValidationTests.swift
    ├── FCPXMLAudioEnhancementTests.swift
    ├── FCPXMLAudioKeyframeTests.swift
    ├── FCPXMLCMTimeCodableTests.swift
    ├── FCPXMLCaptionTitleTests.swift
    ├── FCPXMLClipParsingCarriesAudioTests.swift
    ├── FCPXMLCodableTests.swift
    ├── FCPXMLCollectionTests.swift
    ├── FCPXMLCutDetectionTests.swift
    ├── FCPXMLTimelineProjectionTests.swift
    ├── FCPXMLDTDValidatorTests.swift
    ├── FCPXMLDisplayClipNameTests.swift
    ├── FCPXMLEffectAppleSuppliedTests.swift
    ├── FCPXMLEffectsCollectorTests.swift
    ├── FCPXMLEffectsReportPolicyTests.swift
    ├── FCPXMLEffectsReportTests.swift
    ├── FCPXMLExtractedElementTests.swift
    ├── FCPXMLExtractionScopeTests.swift
    ├── FCPXMLExtractionNestFidelityTests.swift
    ├── FCPXMLRoleInheritanceMatrixTests.swift
    ├── FCPXMLExtractionProjectionPolicyTests.swift
    ├── FCPXMLProjectionCoverageTests.swift
    ├── FCPXMLReportObligationCorpusTests.swift
    ├── FCPXMLEngineHygieneTests.swift
    ├── FCPXMLMarkersKeywordsProjectionTests.swift
    ├── FCPXMLTitlesProjectionTests.swift
    ├── FCPXMLTransitionsProjectionTests.swift
    ├── FCPXMLEffectsProjectionTests.swift
    ├── FCPXMLParsingCoverageTests.swift
    ├── FCPXMLFilterTests.swift
    ├── FCPXMLImportOptionsTests.swift
    ├── FCPXMLKeyframeAnimationTests.swift
    ├── FCPXMLKeywordsReportTests.swift
    ├── FCPXMLMIMETypeDetectionTests.swift
    ├── FCPXMLMarkersReportTests.swift
    ├── FCPXMLMediaExtractionTests.swift
    ├── FCPXMLParallelFileIOTests.swift
    ├── FCPXMLPerformanceTests.swift
    ├── FCPXMLReportBuildPhaseTests.swift
    ├── FCPXMLReportColumnExclusionTests.swift
    ├── FCPXMLReportExcelExportTests.swift
    ├── FCPXMLReportPDFExportTests.swift
    ├── FCPXMLReportPDFSheetPlanTests.swift
    ├── FCPXMLReportPDFTableLayoutTests.swift
    ├── FCPXMLReportExcludeDisabledClipsTests.swift
    ├── FCPXMLReportFormattingTests.swift
    ├── FCPXMLReportRoleExclusionTests.swift
    ├── FCPXMLReportTimecodeFormatTests.swift
    ├── FCPXMLRoleDisplayPreferenceTests.swift
    ├── FCPXMLRoleInventoryClipCollectorTests.swift
    ├── FCPXMLRoleInventoryColumnLayoutTests.swift
    ├── FCPXMLCompoundClipReportTests.swift
    ├── FCPXMLRoleInventoryReportTests.swift
    ├── FCPXMLRoleInventoryRoleSheetOrderingTests.swift
    ├── FCPXMLRolesExtractionPresetTests.swift
    ├── FCPXMLSilenceDetectionTests.swift
    ├── FCPXMLSmartCollectionTests.swift
    ├── FCPXMLSpeedChangeEffectsReportTests.swift
    ├── FCPXMLSpeedChangeFormattingTests.swift
    ├── FCPXMLStructuralValidatorTests.swift
    ├── FCPXMLSummaryReportTests.swift
    ├── FCPXMLSummaryRoleDurationAggregatorTests.swift
    ├── FCPXMLTimecodeTests.swift
    ├── FCPXMLTimelineExportValidationTests.swift
    ├── FCPXMLTimelineManipulationTests.swift
    ├── FCPXMLTitleDisplayTests.swift
    ├── FCPXMLTitlesReportTests.swift
    ├── FCPXMLTransform360Tests.swift
    ├── FCPXMLTransformAdjustmentParsingTests.swift
    ├── FCPXMLTransitionSpinePlacementTests.swift
    ├── FCPXMLTransitionsReportTests.swift
    └── FCPXMLVersionConversionTests.swift
```

> **Naming convention:** Every test file and class (including non-test support files such as `FCPXMLTestResources`, `FCPXMLTestUtilities`, `FCPXMLReportingReportFixture`, and `FCPXMLReportingReportTestSupport`) is prefixed with **`FCPXML`** (for example `FCPXMLTimelineManipulationTests`). The sole exception is **`OpenFCPXMLKitTests`**, the module-named umbrella test class.

**Shared utilities**

- **FCPXMLTestResources.swift** — Path resolution from test file to package root and `Tests/FCPXML Samples/FCPXML/`; works from Xcode and `swift test` without bundle resources. Defines **FCPXMLSampleName** enum for known sample names.
- **FCPXMLTestUtilities.swift** — `loadFCPXMLSampleData(named:)`, `loadFCPXMLSample(named:)`; `fcpxmlFrameRateSampleNames`, `allFCPXMLSampleNames()`; throw **XCTSkip** when a sample is missing.
- **FCPXMLReportingReportFixture.swift** / **FCPXMLReportingReportTestSupport.swift** — Optional reporting integration fixture; shared assertions for timecode cell values, format-aware column headers, sort order, and checkmarks (`assertReportTimecodeValues`, `assertReportColumnHeadersMatchTimecodeFormat`).
- **OpenFCPXMLKitTests.swift** — Main test class; shared dependencies (parser, timecode converter, document manager, error handler, FCPXMLUtility, FCPXMLService) injected in `setUpWithError`. MARK sections group tests by category.

---

## 2. Running tests

### Swift Package Manager

```bash
swift test                    # All tests
swift test --verbose         # Verbose
swift test --filter testAllSupportedFrameRates   # Single test
swift test --filter OpenFCPXMLKitTests             # By pattern
```

To verify the documented test counts:

```bash
swift test --list-tests 2>/dev/null | grep -c '\.'                        # 1076
swift test --list-tests 2>/dev/null | grep -c 'OpenFCPXMLKitTests\.'   # 1072
swift test --list-tests 2>/dev/null | grep -c 'ExcelReportTest\.'       # 4
```

### Xcode

1. Open the package (folder or .swiftpm workspace).
2. Select the **OpenFCPXMLKit** scheme.
3. **⌃⌘U** (Product → Test) to run all tests.
4. Test Navigator (**⌘6**) to run individual tests.

### Linux

Tests are discovered automatically by Swift PM. Run `swift test` in an environment that provides XCTest.

---

## 3. Test categories and coverage

### 3.1 OpenFCPXMLKitTests.swift (MARK sections)

| Category | What it covers |
|----------|-----------------|
| **Setup** | `setUpWithError` / `tearDownWithError`; parser, timecodeConverter, documentManager, errorHandler, FCPXMLUtility, FCPXMLService |
| **FCPXMLUtility** | Initialisation, element filtering by `FCPXMLElementType`, CMTime ↔ FCPXML time string, time conforming |
| **FCPXMLService** | Initialisation, document creation, timecode/CMTime conversion |
| **Modular components** | Parser, TimecodeConverter, DocumentManager, ErrorHandler (parse, validate, create, add resource, message formatting) |
| **Modular utilities** | `ModularUtilities.createService()` returns configured FCPXMLService |
| **Async and concurrency** | Sendable service in TaskGroup; async parser, converter, document manager, service, utilities, element filtering, time conforming, FCPXML time string conversion, XML operations, concurrent ops |
| **Performance (basic)** | Filter elements by type; timecode conversion |
| **Frame rate** | All eight FCP frame rates (round-trip); drop-frame (29.97, 59.94) |
| **Time values** | Various/large CMTime; round-trip via converter |
| **FCPXML time strings** | Valid value/timescale formats; invalid strings → CMTime.zero |
| **Time conforming** | `conform(time:toFrameDuration:)` for all eight FCP frame durations |
| **Error handling** | ErrorHandler for FCPXMLError; parser with invalid XML |
| **Document management** | Document creation 1.5–1.14; add resources/sequences; validate structure |
| **Element filtering** | Core, extended, and all `FCPXMLElementType` coverage |
| **Modular extensions** | CMTime (timecode, fcpxmlTime, conformed); OFKXMLElement (setAttribute, getAttribute, createChild); OFKXMLDocument (addResource, addSequence, isValid) |
| **Performance (params)** | Timecode conversion all frame rates; document creation loop; element filtering large dataset |
| **Edge cases** | Edge time values; concurrent timecode conversion |
| **FCPXMLElementType** | tagName, isInferred (multicam, compound, asset, sequence, clip, none) |
| **FCPXMLError** | Every case has non-empty errorDescription |
| **ModularUtilities API** | createCustomService, validateDocument (invalid doc), processFCPXML, processMultipleFCPXML, convertTimecodes |
| **OFKXMLDocument extension** | fcpxEventNames, add(events:); resource(matchingID:), remove(resourceAtIndex:); fcpxmlString, fcpxmlVersion; load via FCPXMLFileLoader or parser |
| **OFKXMLElement extension** | fcpxType, isFCPXResource, isFCPXStoryElement; fcpxEvent, eventClips, addToEvent, removeFromEvent; fcpxDuration; eventClips throws when not event |
| **Parser filter** | Filter media by first child (multicam/compound); FCPXMLUtility.defaultForExtensions |

### 3.2 Dedicated test files (by theme)

**Cross-platform XML**

- **FCPXMLAEXMLSerializationParityTests** — AEXML round-trip (parse → serialize → re-parse, structure comparison); backend parity (Foundation vs AEXML on same FCPXML); all-samples smoke (AEXML parses every sample); root/version parity; DTD validation (AEXML throws dtdValidationUnavailable). Documents known serialization differences (attribute order, whitespace, empty elements, DOCTYPE stripping, comments).
- **FCPXMLDTDValidatorTests** — Validates document against a given FCPXML version's DTD; on macOS full DTD validation; on iOS (or when DTD unavailable) uses FCPXMLStructuralValidator and may return structuralValidationOnly warning.
- **FCPXMLStructuralValidatorTests** — Cross-platform structural validation: root name `fcpxml`, required `version`, required `resources`, at least one content element (library/event/project), element-name allowlist (1.5–1.14); unknownElementName error; structuralValidationOnly warning.

**Media & extraction**

- **FCPXMLMediaExtractionTests** — extractMediaReferences, copyReferencedMedia (sync/async); extract-then-copy flow (CLI --media-copy). MediaExtractor, MediaExtractionResult, MediaCopyResult.

**Timeline & manipulation**

- **FCPXMLTimelineManipulationTests** — Ripple insert (immutable/mutating, lane options); auto lane (findAvailableLane, insertingClipAutoLane, insertClipAutoLane); clip queries (onLane, inRange, withAssetRef, laneRange); metadata (markers, chapters, keywords, ratings); timestamps (createdAt, modifiedAt); file tests for TimelineSample, TimelineWithSecondaryStoryline, TimelineWithSecondaryStorylineWithAudioKeyframes. Timeline, TimelineClip, RippleInsertResult, ClipPlacement, TimelineError.

**Timecode & timing**

- **FCPXMLTimecodeTests** — FCPXMLTimecode: init (seconds, value/timescale, CMTime, frames, FCPXML string); value, timescale, seconds, fcpxmlString; arithmetic (+, -, *); comparison; toCMTime; frame alignment; Hashable, Codable.

**Media processing**

- **FCPXMLMIMETypeDetectionTests** — Sync/async detection (UTType, AVFoundation, extension fallback); video/audio/image formats. MIMETypeDetector.
- **FCPXMLAssetValidationTests** — Existence; lane compatibility (negative = audio only); sync/async; TimelineClip (validateAsset, isAudioAsset, isVideoAsset, isImageAsset). AssetValidator, AssetValidationResult.
- **FCPXMLSilenceDetectionTests** — Silence at start/end; threshold, minimumDuration; sync/async. SilenceDetector, SilenceDetectionResult.
- **FCPXMLAssetDurationMeasurementTests** — Duration for audio/video/images; media type; sync/async; image (no duration). AssetDurationMeasurer, DurationMeasurementResult, MediaType.
- **FCPXMLParallelFileIOTests** — Parallel read/write; success/failure counts; maxConcurrentOperations, useFileHandleOptimization. ParallelFileIOExecutor, ParallelFileIOResult.

**Analysis & detection**

- **FCPXMLCutDetectionTests** — Edit points (hardCut, transition, gapCut); source relationship (sameClip, differentClips); empty spine; single clip; same ref transitions; different refs; CutSample.fcpxml file test. EditPoint, CutDetectionResult.
- **FCPXMLTimelineProjectionTests** — Timeline Projection: identity/`timeMap`; nested lanes; J/L cuts; multicam active/all + split angles; ref-clip unfold; audition mask; video/audio leaves; SyncClip/24 sample regression; Role Inventory / Markers / Keywords / Titles / Transitions / Effects / Speed Change / Media Summary / Summary project-once; occupancy index; disabled filtering; streaming parity.

**Typed models**

- **FCPXMLAdjustmentTests** — Crop, Transform, Blend, Stabilization, Volume, Loudness; init, properties, Codable, Clip integration; XML round-trip.
- **FCPXMLAudioEnhancementTests** — NoiseReduction, HumReduction, Equalization, MatchEqualization; init, Codable, Clip integration.
- **FCPXMLTransform360Tests** — Transform360Adjustment (spherical/cartesian, auto-orient, convergence, interaxial); Codable, Clip integration.
- **FCPXMLFilterTests** — VideoFilter, AudioFilter, VideoFilterMask, FilterParameter (keyframe animation, param auxValue 1.11+); Codable, clip integration.
- **FCPXMLCaptionTitleTests** — Caption, Title, TextStyle, TextStyleDefinition; typedTextStyleDefinitions; XML parse/serialization; CaptionSample.fcpxml file test.
- **FCPXMLKeyframeAnimationTests** — KeyframeAnimation, Keyframe (interpolation), FadeIn/FadeOut (fade types); FilterParameter integration; CMTime Codable.
- **FCPXMLAudioKeyframeTests** — Audio keyframes in adjust-volume (param name="amount" with keyframeAnimation); parsing from FCPXML samples; decibel values (-3dB, -37dB); time values (FCPXML fractional format); fadeIn/fadeOut integration; multiple keyframes in sequence; secondary storyline and nested clips; TimelineWithSecondaryStorylineWithAudioKeyframes, TimelineSample file tests.
- **FCPXMLCMTimeCodableTests** — CMTime encode/decode as FCPXML time strings; round-trip; edge cases.
- **FCPXMLCollectionTests** — CollectionFolder, KeywordCollection; nested folders; Codable.

**Reporting & Excel/PDF export** (see [19 — Reporting, Excel & PDF Export](../Documentation/Manual/19-Reporting.md))

- **FCPXMLCompoundClipReportTests** — Standalone compound-clip FCPXML (event `ref-clip` → `media`/`sequence`, no `<project>`): `allReportTimelineSources()`, role inventory / markers / summary via `buildReport`, project-name filter, and regression that normal project reports still resolve.
- **FCPXMLRoleInventoryReportTests** — Role inventory section: Selected Roles Inventory rows and per-role sheets, categories, columns.
- **FCPXMLRoleInventoryColumnLayoutTests** — Inventory column order (Row + 23 fixed columns), dynamic metadata key discovery, row index values, audio rate display.
- **FCPXMLMarkersReportTests** — Markers report rows (type, position, clip name, role ▸ subrole), chapter-marker inclusion.
- **FCPXMLKeywordsReportTests** — Keywords report rows (keyword, timeline in/out, duration, role ▸ subrole).
- **FCPXMLTitlesReportTests** — Titles & Generators rows (clip name, Apple flag, role ▸ subrole, font, title text).
- **FCPXMLTransitionsReportTests** — Transitions rows (transition, category, Apple flag, timeline in/out, duration).
- **FCPXMLEffectsReportTests** / **FCPXMLSpeedChangeEffectsReportTests** — Video & Audio Effects and Speed Change Effects rows.
- **FCPXMLSummaryReportTests** — Summary sheet: project metrics, per-role duration rows, percentage of total; Media Summary sheet: missing media paths; `.summaryOnly` and `.mediaSummaryOnly` presets.
- **FCPXMLReportExcelExportTests** — XLKit workbook export: Title Case sheet names, sheet ordering, sheet-name sanitisation, **Row** on section sheets (Markers … Media Summary) and Summary role table; Media Summary sheet (red missing-media paths); Summary sheet (project title in **B1**, narrow Row column A, black role-duration data, numeric `% of Total` cells); inventory/marker/section-sheet colour rules (role category, marker type, sheet-specific inference for Keywords/Effects/Titles/Transitions); cover sheet styling (including optional `copyrightLabel` in **A2**); black/white table headers.
- **FCPXMLReportPDFTableLayoutTests** — PDF column sizing: remaining columns expand to fill A4 landscape content width after exclusions / short content; pinned `Row` stays packed-width; `allowInjectedRowColumn: false` suppresses multi-page Row injection; wide tables still chunk horizontally with each part filling the page.
- **FCPXMLReportPDFSheetPlanTests** — ordered sheet titles share sequential `colorIndex` values used by TOC colour chips and content-page tints; TOC entries preserve those indices when page numbers are filled in.
- **FCPXMLReportPDFExportTests** — CoreGraphics PDF export: `%PDF` header, cover page (black “About This PDF Export” band + white `info.circle`, cover notes mentioning default/excludable Row) and custom branding, optional `copyrightLabel` on cover and centred running footer, table of contents for multi-section reports (TOC rows use sheet colour chips + tint washes), synthetic section content, wide-table multi-page pagination, full-workbook section parity (all nine sections in TOC/content), markers/media-summary/summary-only exports.
- **FCPXMLReportFormattingTests** — Timecode string formats (SMPTE DF/NDF, Frames, Feet+Frames, HH:MM:SS); `compareTimelinePositions` numeric order for Frames and Feet+Frames vs lexicographic string order; role ▸ subrole field formatting, `<Blank>` handling, channel-ordered role fields.
- **FCPXMLReportTimecodeFormatTests** — Integration: DF/NDF sample reports; all four `ReportTimecodeFormat` modes; full-report cell/header shape assertions; workbook header suffixes; Keywords Frames-mode numeric row order.
- **FCPXMLReportBuildPhaseTests** — `ReportBuildPhase.enabledPhases(for:)` product order (Selected Roles Inventory first); `onPhaseStarted` callback order matches enabled phases for `.full`.
- **FCPXMLReportRoleExclusionTests** — `excludedRoles` filtering (excluding a main role also excludes subroles).
- **FCPXMLReportColumnExclusionTests** — `ReportColumn` alias resolution; `ensuringRowColumn` / `allowsInjectedRowColumn`; header/value filtering; format-suffixed timeline headers still match exclusion; workbook export omits excluded columns on inventory and markers sheets; `--exclude-column Row` removes Row from all tabular Excel/PDF sheets including PDF injection; Selected Roles vs per-role sheets: Row renumbers per sheet, shared `--exclude-column` headers, and matching dynamic metadata cells.
- **FCPXMLReportExcludeDisabledClipsTests** — `excludeDisabledClips` omits `enabled="0"` clips from role inventory and titles sections (uses `DisabledClips` sample).
- **FCPXMLRoleDisplayPreferenceTests** — RoleDisplayPreference priority tables and preferred-role selection per context.
- **FCPXMLRoleInventoryClipCollectorTests** / **FCPXMLRoleInventoryRoleSheetOrderingTests** — Clip collection into role entries; role-sheet ordering.
- **FCPXMLSummaryRoleDurationAggregatorTests** — Per-role duration aggregation and percentage calculation.
- **FCPXMLEffectsReportPolicyTests** / **FCPXMLSpeedChangeFormattingTests** — Effect inclusion policy; speed-change value formatting.
- **FCPXMLDisplayClipNameTests** / **FCPXMLTitleDisplayTests** — Display clip-name resolution (including multicam angles); title display text.

**Extraction & parsing internals**

- **FCPXMLExtractionScopeTests** — ExtractionScope behaviour (main-timeline visibility, occlusion, depth/type filters).
- **FCPXMLExtractionNestFidelityTests** / **FCPXMLRoleInheritanceMatrixTests** / **FCPXMLExtractionProjectionPolicyTests** — Extraction fidelity (preset nests, role inheritance matrix, Extraction↔Projection occlusion/`excludeDisabledClips` policy).
- **FCPXMLProjectionCoverageTests** — Projection geometry (annotations, per-src, nested retiming compose, sync-in-mc, Photoshop multi-src, Summary overlap-aware durations).
- **FCPXMLReportObligationCorpusTests** — Reporting contracts: fail-soft vs fail-loud (`ReportMediaResolutionPolicy`), Media Summary proxy/original distinction, near-zero-miss obligation corpus on in-repo samples (BasicMarkers, Keywords, TitlesRoles, RolesList, TransitionMarkers1, Complex). Sheet obligation contracts are documented in Manual 19.
- **FCPXMLEngineHygieneTests** — Engine hygiene: ReportBuilder project-once, version-strip honesty (1.13+ attrs omitted on 1.5 convert), Complex projection soft 30s smoke budget.
- **FCPXMLMarkersKeywordsProjectionTests** — Markers/Keywords report builders prefer Projection `ProjectedClipAnnotations` (BasicMarkers title markers, Keywords sample); Extraction fallback when annotations absent.
- **FCPXMLTitlesProjectionTests** — Titles & Generators report builder prefers Projection `WindowTitleAnnotation` (TitlesRoles, BasicMarkers, DisabledClips); Extraction fallback when annotations absent.
- **FCPXMLTransitionsProjectionTests** — Transitions report builder prefers Projection `WindowTransitionAnnotation` (TransitionMarkers1/2); Extraction fallback when annotations absent.
- **FCPXMLEffectsProjectionTests** — Effects report builder prefers Projection `WindowReportEffectAnnotation` (CompoundClipSample, Occlusion3, secondary storyline); Extraction fallback when annotations absent.
- **FCPXMLParsingCoverageTests** — Parsing/Model coverage (mute, analysis markers, TextStyle, tracking-shape, smart collections).
- **FCPXMLExtractedElementTests** — ExtractedElement/model wrappers and value access.
- **FCPXMLEffectsCollectorTests** / **FCPXMLRolesExtractionPresetTests** — Semantic effect collection; roles/effects/titles extraction presets.
- **FCPXMLEffectAppleSuppliedTests** — Detection of Apple-supplied vs third-party effects.
- **FCPXMLClipParsingCarriesAudioTests** / **FCPXMLTransformAdjustmentParsingTests** / **FCPXMLTransitionSpinePlacementTests** — Clip audio-carry parsing; transform adjustment parsing; transition spine placement.

**Format, Asset, version & structure**

- **FCPXMLFormatAssetTests** — Format heroEye (get/set/init/parse); Asset heroEyeOverride; Asset mediaReps (single/multiple, round-trip). FCPXMLVersionConversionTests: heroEye/heroEyeOverride stripped when converting to &lt; 1.13.
- **Live Drawing (1.11+)** — **FCPXMLAPIAndEdgeCaseTests**: testLiveDrawingModelInitAndAttributes (init, role, dataLocator, animationType, name, duration); testLiveDrawingFromElementAndAnyTimelineRoundTrip (from element, AnyTimeline.liveDrawing).
- **HiddenClipMarker (1.13+)** — **FCPXMLAPIAndEdgeCaseTests**: testHiddenClipMarkerModelAndAnnotationElements (model from element, create new, fcpxAnnotations). FCPXMLVersionConversionTests: hidden-clip-marker stripped when converting to &lt; 1.13.
- **FCPXMLSmartCollectionTests** — SmartCollection; MatchUsage, MatchRepresentation, MatchMarkers, MatchAnalysisType; round-trip; version stripping.
- **FCPXMLVersionConversionTests** — Version conversion; save .fcpxml/.fcpxmld; DTD-based stripping (heroEye, hidden-clip-marker, etc.).
- **FCPXMLImportOptionsTests** — import-options element (get/set); setShouldCopyAssetsOnImport, setShouldSuppressWarningsOnImport, setLibraryLocationForImport; removeChildren(where:) behaviour with import-options.

---

## 4. File tests (per-sample coverage)

File tests live under **OpenFCPXMLKitTests/FileTests/** and use samples from **Tests/FCPXML Samples/FCPXML/**. Each class loads one or more samples and asserts parse success, version, root, events, projects, resources, or spine as appropriate.

| Test class | Sample(s) | Asserts |
|------------|-----------|---------|
| **FCPXMLFileTest_24** | 24.fcpxml | Root, version ver1_11, events, project, sequence format "r1", spine story elements; load via FCPXMLFileLoader + FCPXMLService |
| **FCPXMLFileTest_360Video** | 360Video.fcpxml | Root, ver1_13, format projection/stereoscopic, adjust-colorConform, bookmarks, smart collections, round-trip |
| **FCPXMLFileTest_AllSamples** | All .fcpxml in dir | Each loads via FCPXMLFileLoader and as FinalCutPro.FCPXML; root name "fcpxml"; skips if dir missing/empty |
| **FCPXMLFileTest_Annotations** | Annotations.fcpxml | Root, events, projects |
| **FCPXMLFileTest_AuditionSample** | AuditionSample.fcpxml | Root, ver1_13, audition element, active/inactive clips, adjust-colorConform, conform-rate, keywords |
| **FCPXMLFileTest_BasicMarkers** | BasicMarkers.fcpxml | Root, ver1_9, root equality, resources, library; allEvents, allProjects |
| **FCPXMLFileTest_Complex** | Complex.fcpxml | Root, ver1_11, events, projects; version attribute; resources exist |
| **FCPXMLFileTest_GeneralDemo** | GeneralDemo.fcpxml | ver1_14, multicam resources/clips, titles, filter-video; anonymized media paths |
| **FCPXMLFileTest_CompoundClips** | CompoundClips.fcpxml, CompoundClipSample.fcpxml | Root, non-empty projects; compound clip resources |
| **FCPXMLFileTest_FrameRates** | Frame-rate samples | Each existing frame-rate sample parses; root, version ≥ 1.5; 24, 29.97, 60 called out |
| **FCPXMLFileTest_ImageSample** | ImageSample.fcpxml | Root, ver1_13, still image asset (duration=0s), video element references still |
| **FCPXMLFileTest_Keywords** | Keywords.fcpxml, EventsWithKeywords.fcpxml, KeywordsWithinFolders.fcpxml | Root name; keywords in events; keyword collections and folders in events |
| **FCPXMLFileTest_Multicam** | MulticamSample.fcpxml, MulticamSampleWithCuts.fcpxml | Root, ver1_13, multicam resources, multicam clips in timeline |
| **FCPXMLFileTest_Occlusion** | Occlusion, Occlusion2, Occlusion3 | Root name for each |
| **FCPXMLFileTest_Photoshop** | PhotoshopSample1.fcpxml, PhotoshopSample2.fcpxml | Root, ver1_13, events, projects |
| **FCPXMLFileTest_SmartCollection** | Multiple samples (360Video, TimelineSample, etc.) | Smart collections parsing, match-clip, match-media, match-ratings, match attributes (all/any), library integration, round-trip |
| **FCPXMLFileTest_StandaloneAssetClip** | StandaloneAssetClip.fcpxml | Root, ≥1 resource |
| **FCPXMLFileTest_SyncClip** | SyncClip.fcpxml | Root, non-empty projects |

Tests that require a sample use `loadFCPXMLSample(named:)` or `loadFCPXMLSampleData(named:)`, which throw **XCTSkip** when the file is missing so the suite can run with a subset of samples.

---

## 5. Logic and parsing tests

**LogicAndParsing/** holds tests for model types and parsing rules rather than a single file.

**FCPXMLRootVersionTests** — `FinalCutPro.FCPXML.Version`: init(major, minor) and (major, minor, patch), rawValue; Equatable, Comparable; rawValue edge cases ("2" → major 2); invalid strings → nil; init(rawValue:) round-trip; static members (ver1_11, ver1_14, latest, allCases).

**FCPXMLStructureTests** — Structure sample: allEvents() → "Test Event", "Test Event 2"; allProjects() → "Test Project", "Test Project 2", "Test Project 3"; root has resources or library; version ≥ 1.5.

**FCPXMLFormatAssetTests** — Format heroEye (get/set/init/parse, round-trip); Asset heroEyeOverride (get/set/init/parse); Asset mediaReps (single/multiple, count, order, init, round-trip with two reps). FCPXMLVersionConversionTests cover stripping to 1.5.

---

## 6. Timeline, export, and validation tests

**FCPXMLTimelineExportValidationTests** covers timeline model, exporters, validators, and file loader.

**Timeline & TimelineClip** — endTime; duration from primary lane; sortedClips order; TimelineFormat (hd1080p, uhd4K, presets, computed properties, equality); helpers on Timeline; **empty timeline creation** — testEmptyTimelineCreationAtDifferentSizesAndFrameRates: barebone `Timeline(name:format:clips: [])` at multiple sizes (720p, 1080p, 4K UHD, DCI 4K, custom 640×480) and frame rates (24, 25, 30); asserts name, clips empty, duration zero, format dimensions and frame duration, aspectRatio.

**FCPXMLExporter** — Export minimal timeline (fcpxml, resources, refs); missingAsset throws when clips present; empty timeline (zero clips) succeeds with empty spine, event/project uid, modDate; optional eventUid, projectUid, libraryLocation; **clip-level metadata export** — testFCPXMLExporterExportsClipMarkers, testFCPXMLExporterExportsClipChapterMarkers, testFCPXMLExporterExportsClipKeywords, testFCPXMLExporterExportsClipRatings, testFCPXMLExporterExportsClipMetadata (markers, chapter-markers, keywords, ratings, metadata as children of asset-clip per FCPXML DTD); testFCPXMLExporterClipMetadataAllTypesValidatesAgainstDTD (one clip with all metadata types, export then parse and validate against DTD); **XML declaration** — testFCPXMLExporterXmlDeclarationStandaloneNo (exported FCPXML uses standalone="no" for xmllint/DTD compatibility); **project-creation style** — testProjectCreationStyleExportValidatesAgainstDTD: empty timeline with custom format (e.g. 1920×1080@25p), export with includeDefaultSmartCollections: true, assert output contains DOCTYPE, colorSpace, smart-collection; parse with FCPXMLService and validate against DTD (same flow as CLI --create-project); **project creation at different sizes and frame rates** — testProjectCreationAtDifferentSizesAndFrameRates: export empty timeline at multiple sizes (720p, 1080p, 4K, custom 640×480) and frame rates (24, 25, 30, 60), then parse and validate against DTD; **FCPXMLUID** — random() and isValid() for FCPXML-style UIDs.

**FCPXMLBundleExporter** — Creates bundle (Out.fcpxmld, Info.fcpxml, Info.plist); with includeMedia copies files and references in Info.fcpxml.

**FCPXMLValidator** — Valid structure → valid; non-fcpxml root → invalid; unresolved ref → invalid with error.

**FCPXMLDTDValidator** — **FCPXMLDTDValidatorTests**: returns ValidationResult; valid document → isValid true; on macOS uses full DTD; on iOS uses FCPXMLStructuralValidator (structuralValidationOnly warning when DTD unavailable).

**FCPXMLStructuralValidator** — **FCPXMLStructuralValidatorTests**: cross-platform checks (root name, version, resources, content element, element allowlist); unknownElementName error; structuralValidationOnly warning.

**FCPXMLFileLoader** — Loads single file (root, name); loads .fcpxmld bundle (resolved URL Info.fcpxml, root exists); missing URL throws FCPXMLLoadError.

---

## 7. API and edge case tests

**FCPXMLAPIAndEdgeCaseTests** — Async load API; optional logging (NoOp, Print, createCustomService); edge cases (parse empty/invalid/malformed data; invalid path, resolveFCPXMLFileURL); validation types (ValidationResult with errors, ValidationWarning); FCPXML creation (all versions); **Live Drawing (1.11+)** model and AnyTimeline round-trip; **HiddenClipMarker (1.13+)** model and fcpxAnnotations.

**Other files** (see [§3.2](#32-dedicated-test-files-by-theme)) — FCPXMLAEXMLSerializationParityTests, FCPXMLDTDValidatorTests, FCPXMLStructuralValidatorTests, FCPXMLTimelineManipulationTests, FCPXMLTimecodeTests, FCPXMLMIMETypeDetectionTests, FCPXMLAssetValidationTests, FCPXMLSilenceDetectionTests, FCPXMLAssetDurationMeasurementTests, FCPXMLParallelFileIOTests, FCPXMLAdjustmentTests, FCPXMLAudioEnhancementTests, FCPXMLTransform360Tests, FCPXMLFilterTests, FCPXMLCaptionTitleTests, FCPXMLKeyframeAnimationTests, FCPXMLAudioKeyframeTests, FCPXMLCMTimeCodableTests, FCPXMLCollectionTests.

**FCPXMLFileLoader async** — testFCPXMLFileLoaderAsyncLoadFromURL (temp file, root/name); testFCPXMLFileLoaderAsyncLoadThrowsForMissingFile (FCPXMLLoadError).

**ServiceLogger** — NoOpLogger, PrintLogger parse successfully; createCustomService with logger; ServiceLogLevel (Comparable, from(string:), label).

**Edge cases** — Parse empty data, invalid XML, malformed XML throw; load from invalid path, resolve nonexistent path throw.

**Validation** — ValidationResult with ValidationError (missingAssetReference); ValidationWarning message.

---

## 8. Performance tests

Performance is measured with **measure { }** (XCTest); results show duration and relative standard deviation.

**OpenFCPXMLKitTests.swift** — testPerformanceFilterElements; testPerformanceTimecodeConversion; testPerformanceTimecodeConversionAllFrameRates; testPerformanceDocumentCreation; testPerformanceElementFilteringLargeDataset.

**FCPXMLPerformanceTests** — testPerformanceParseFCPXMLDataRepeatedly (50× per iteration); testPerformanceLoadSampleFileWhenAvailable (Structure.fcpxml 20×; skips if missing).

**Guidelines** — Keep tests fast; avoid heavy I/O or very large documents unless the test is for that; use the same dependency injection as the rest of the suite.

---

## 9. Supported frame rates

Eight frame rates supported by Final Cut Pro: **23.976** (`.fps23_976`), **24** (`.fps24`), **25** (`.fps25`), **29.97** (`.fps29_97`, drop-frame), **30** (`.fps30`), **50** (`.fps50`), **59.94** (`.fps59_94`, drop-frame), **60** (`.fps60`). Collected in **fcpSupportedFrameRates**; used in testAllSupportedFrameRates, testCMTimeModularExtensionsWithAllFrameRates, testTimeConformingWithDifferentFrameDurations, testPerformanceTimecodeConversionAllFrameRates. Suite focuses on these eight.

---

## 10. FCPXML versions

Document manager tests create documents for **FCPXML 1.5 through 1.14** and assert valid structure and resource/sequence handling. Parsing and validation use samples valid for their declared version; invalid XML is covered in testParserWithInvalidXML. DTDs live under **Sources/OpenFCPXMLKit/FCPXML DTDs/**; the suite does not exhaustively test every version-specific DTD attribute.

---

## 11. Sample files

- **Location:** `Tests/FCPXML Samples/FCPXML/` (sibling of OpenFCPXMLKitTests).
- **Path resolution:** At runtime via **packageRoot(relativeToFile: #file)** so tests work from Xcode and `swift test` without bundle resources.
- **FCPXMLTestResources.swift** — `packageRoot`, `fcpxmlSamplesDirectory()`, `urlForFCPXMLSample(named:)`.
- **FCPXMLTestUtilities** — `loadFCPXMLSampleData(named:)`, `loadFCPXMLSample(named:)`; throw **XCTSkip** when the file is missing.

---

## 12. Excel and PDF report integration tests

The **`ExcelReportTest`** target (separate from `OpenFCPXMLKitTests`) builds real `.xlsx` and `.pdf` reports from a **local** FCPXML fixture (a normal project **or** a standalone compound-clip export). It is optional: without a fixture, tests skip and CI stays green.

| Item | Detail |
|------|--------|
| **Location** | `Tests/ExcelReportTest/` |
| **Test class** | `ExcelReportExportTests` (4 tests) — writes `Output/OFK-Default.xlsx`, `Output/OFK-Full.xlsx`, `Output/OFK-Default.pdf`, `Output/OFK-ExcludedColumns.pdf`, `Output/OFK-Copyright.xlsx`, and `Output/OFK-Copyright.pdf` |
| **Fixture** | Preferred `Sample.fcpxmld` / `Sample.fcpxml` under this folder or under `Output/`; else `OFK_REPORTING_FCPXML_BUNDLE`; else auto-discovery |
| **Run** | `swift test --filter ExcelReportExportTests` |

Full setup, output description, and CI notes: **[ExcelReportTest/README.md](ExcelReportTest/README.md)**.

Use this target for end-to-end workbook/PDF generation on a real fixture (open `Output/OFK-Full.xlsx`, `OFK-Default.pdf`, `OFK-ExcludedColumns.pdf`, or `OFK-Copyright.xlsx` / `OFK-Copyright.pdf` to visually verify layout and `--label-copyright` branding). Standalone compound-clip reporting (no `<project>`) is covered in unit form by **`FCPXMLCompoundClipReportTests`** in `OpenFCPXMLKitTests`. Use **`FCPXMLReportPDFExportTests`**, **`FCPXMLReportPDFSheetPlanTests`**, **`FCPXMLReportPDFTableLayoutTests`**, and other **`OpenFCPXMLKitTests`** reporting files (listed under **Reporting & Excel/PDF export** in [§3.2](#32-dedicated-test-files-by-theme)) for unit and integration tests against bundled FCPXML samples and synthetic report structure.

---

## 12a. Submitted FCPXML (private inbox)

Local-only drop zone for **private user FCPXML** used when investigating parsing or reporting edge cases. Contents of `Inbox/` and `Notes/` are **gitignored**; only the README is tracked.

| Item | Detail |
|------|--------|
| **Location** | `Tests/Submitted FCPXML/` |
| **Drop files** | `Inbox/*.fcpxml` or `Inbox/*.fcpxmld/` |
| **Smoke test** | `FCPXMLSubmittedFCPXMLSmokeTests` — parses inbox files when present; **XCTSkip** when empty (CI-safe) |
| **Promote** | After fixing: add a **minimal anonymised** fixture under `FCPXML Samples/FCPXML/` + a public regression test |

Full workflow (anonymise → reproduce → fix → promote): **[Submitted FCPXML/README.md](Submitted%20FCPXML/README.md)**.

**Never** commit private paths, bookmarks, or client names. Do **not** add inbox files to `Package.swift` resources.

---

## 13. Writing and organising tests

**Naming** — Prefix every test file and class with **`FCPXML`** (e.g. `FCPXMLTimelineManipulationTests`, `FCPXMLFileTest_<Name>`), including non-test support files (`FCPXMLTestResources`, `FCPXMLTestUtilities`, `FCPXMLReportingReportFixture`, `FCPXMLReportingReportTestSupport`); the only exception is the module-named umbrella `OpenFCPXMLKitTests`. Name test methods `test<FeatureOrBehaviour>` (e.g. testAllSupportedFrameRates, testParserWithInvalidXML). Put new tests under the right MARK section and keep this README updated.

**Structure** — Arrange–act–assert. Async tests: `async throws` and `await`. Performance: `measure { }`; avoid blocking/heavy I/O unless the test is for that. Concurrency: main test class is @unchecked Sendable; shared properties in setUpWithError/tearDownWithError; prefer async/await; use withTaskGroup or async let where appropriate.

**Adding a file test** — New class under FileTests/ (e.g. FCPXMLFileTest_<Name>.swift). Use loadFCPXMLSample(named:) when the sample must exist, or urlForFCPXMLSample(named:) with FileManager.fileExists and XCTSkip when optional. Assert on root, version, allEvents(), allProjects(), resources, etc.

**Adding logic/parsing tests** — Under LogicAndParsing/ for model types (Version, structure, parsing rules).

**Adding feature tests** — New file for major features (e.g. FCPXMLTimelineManipulationTests). Group related tests; descriptive names; sync and async where applicable; edge cases, errors, protocol conformance.

---

## 14. Continuous integration

GitHub Actions (e.g. `.github/workflows/build.yml`) run on push and pull requests: **macOS** — build and full unit test suite (Xcode workspace, xcodebuild); Swift 6 and strict concurrency job; **iOS** — build for iOS Simulator (orchetect/setup-xcode-simulator); tests are not run on iOS because they require Foundation XML. All macOS tests must pass with no regressions.

---

## 15. Debugging tests

- Run a single test: `swift test --filter testMethodName` or run in Xcode (diamond next to the method).
- Use print or breakpoints as needed; avoid leaving noisy prints in committed code.
- Async tests that hang: check for missing await or blocking work on the main actor.
- Prefer deterministic data and injected dependencies to avoid flakiness.

---

## 16. Contributing to tests

Add tests for new behaviour or edge cases; place them in the right file and MARK section; keep names descriptive. Update this README when adding a category or changing what a section covers. For “all FCP frame rates” use **fcpSupportedFrameRates**. Prefer minimal in-memory FCPXML or small fixtures; document assumptions (e.g. temp URL) in a comment or here.

---

## 17. Resources

- **XCTest** (Apple documentation)
- **Testing in Xcode** (Apple documentation)
- **OpenFCPXMLKit README** (project root) — overview and API usage
- **Documentation/Manual** — full manual; [19 — Reporting, Excel & PDF Export](../Documentation/Manual/19-Reporting.md) for report API; [18 — Cross-Platform & iOS](../Documentation/Manual/18-Cross-Platform-iOS.md) for XML abstraction and iOS support
- **Final Cut Pro XML (FCPXML)** — [fcp.cafe](https://fcp.cafe) for format reference
- **SwiftTimecode** (GitHub) — timecode and frame rate types

---

## 18. Resolving common test/build messages

**Swift PM cache warnings** — “configuration is not accessible or not writable” / “Caches is not accessible or not writable”: Swift PM cannot write to `~/Library/org.swift.swiftpm/` or `~/Library/Caches/org.swift.swiftpm/`. Fix: ensure directories exist and your user has write permission (e.g. `mkdir -p ~/Library/org.swift.swiftpm ~/Library/Caches/org.swift.swiftpm`). In CI/sandbox these warnings are harmless; Swift PM falls back to process-local cache.

**Invalid connection: com.apple.coresymbolicationd** — macOS symbolication daemon message; not from OpenFCPXMLKit; does not affect test results. Can be ignored.

**Couldn't find the DTD file / Error setting the DTD** — Validator looks for DTDs in (1) OpenFCPXMLKit module bundle (root and “FCPXML DTDs”), (2) all loaded bundles, (3) frameworks with “DTDs” subdirectory. DTDs are in `Sources/OpenFCPXMLKit/FCPXML DTDs/` and declared in Package.swift with `.process("FCPXML DTDs")`. If messages persist, build and run from package root (`swift build && swift test`). When the DTD is not found, the validator returns a result with a dtdValidation error; tests accept either success or that error.

**Performance test relative standard deviation** — XCTest prints average and RSD for each `measure { }` run; informational. High RSD is common for very fast ops. To reduce variation: record a baseline in Xcode (Editor → Add Baseline) or increase iterations. The suite does not fail on RSD unless a baseline is set and exceeded.

---

## 19. Credits

Inspired and modeled after [swift-daw-file-tools](https://github.com/orchetect/swift-daw-file-tools)'s Test Suites.
