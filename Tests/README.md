# Pipeline Neo — Test Suite

This directory contains the test suite for Pipeline Neo, a Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration. The suite runs on **macOS** (Foundation XML backend). The library also supports **iOS 15+** (AEXML backend); CI builds for iOS Simulator; the same tests are not run on iOS because they rely on Foundation XML.

- **Test count:** 686 tests  
- **Scope:** Parsing, timecode, document operations, file loading, timeline export, validation (semantic, DTD, structural), timeline manipulation, media processing, typed models (adjustments, filters, captions/titles, keyframe animation), CMTime Codable, collections, Live Drawing (1.11+), HiddenClipMarker (1.13+), Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps), SmartCollection match rules, 360 video (projection, stereoscopic), auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, empty timeline creation at different sizes and frame rates, project-creation export at different sizes and frame rates (with DTD validation), FCPXMLExporter clip-level metadata export (markers, chapter-markers, keywords, ratings, metadata as asset-clip children; DTD and xmllint-compatible XML declaration), cross-platform XML (AEXML serialization parity, DTD validator behaviour, structural validator), and all supported FCPXML versions and frame rates  
- **Layout:** Shared utilities for sample paths; file tests per sample; logic/parsing tests for model types and structure; validation and cross-platform XML tests  

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

**Contributing & troubleshooting**

12. [Writing and organising tests](#12-writing-and-organising-tests)
13. [Continuous integration](#13-continuous-integration)
14. [Debugging tests](#14-debugging-tests)
15. [Contributing to tests](#15-contributing-to-tests)
16. [Resources](#16-resources)
17. [Resolving common test/build messages](#17-resolving-common-testbuild-messages)
18. [Credits](#18-credits)

---

## 1. Test structure

```
Tests/
├── README.md
├── FCPXML Samples/
│   └── FCPXML/
└── PipelineNeoTests/
    ├── TestResources.swift
    ├── FCPXMLTestUtilities.swift
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
    ├── AEXMLSerializationParityTests.swift
    ├── APIAndEdgeCaseTests.swift
    ├── AdjustmentTests.swift
    ├── AssetDurationMeasurementTests.swift
    ├── AssetValidationTests.swift
    ├── AudioEnhancementTests.swift
    ├── AudioKeyframeTests.swift
    ├── CaptionTitleTests.swift
    ├── CMTimeCodableTests.swift
    ├── CodableTests.swift
    ├── CollectionTests.swift
    ├── CutDetectionTests.swift
    ├── FCPXMLDTDValidatorTests.swift
    ├── FCPXMLPerformanceTests.swift
    ├── FCPXMLStructuralValidatorTests.swift
    ├── FCPXMLTimecodeTests.swift
    ├── FilterTests.swift
    ├── ImportOptionsTests.swift
    ├── KeyframeAnimationTests.swift
    ├── MediaExtractionTests.swift
    ├── MIMETypeDetectionTests.swift
    ├── ParallelFileIOTests.swift
    ├── PipelineNeoTests.swift
    ├── SilenceDetectionTests.swift
    ├── SmartCollectionTests.swift
    ├── TimelineExportValidationTests.swift
    ├── TimelineManipulationTests.swift
    ├── Transform360Tests.swift
    └── VersionConversionTests.swift
```

**Shared utilities**

- **TestResources.swift** — Path resolution from test file to package root and `Tests/FCPXML Samples/FCPXML/`; works from Xcode and `swift test` without bundle resources. Defines **FCPXMLSampleName** enum for known sample names.
- **FCPXMLTestUtilities.swift** — `loadFCPXMLSampleData(named:)`, `loadFCPXMLSample(named:)`; `fcpxmlFrameRateSampleNames`, `allFCPXMLSampleNames()`; throw **XCTSkip** when a sample is missing.
- **PipelineNeoTests.swift** — Main test class; shared dependencies (parser, timecode converter, document manager, error handler, FCPXMLUtility, FCPXMLService) injected in `setUpWithError`. MARK sections group tests by category.

---

## 2. Running tests

### Swift Package Manager

```bash
swift test                    # All tests
swift test --verbose         # Verbose
swift test --filter testAllSupportedFrameRates   # Single test
swift test --filter PipelineNeoTests             # By pattern
```

### Xcode

1. Open the package (folder or .swiftpm workspace).
2. Select the **PipelineNeo** scheme.
3. **⌃⌘U** (Product → Test) to run all tests.
4. Test Navigator (**⌘6**) to run individual tests.

### Linux

Tests are discovered automatically by Swift PM. Run `swift test` in an environment that provides XCTest.

---

## 3. Test categories and coverage

### 3.1 PipelineNeoTests.swift (MARK sections)

| Category | What it covers |
|----------|-----------------|
| **Setup** | `setUpWithError` / `tearDownWithError`; parser, timecodeConverter, documentManager, errorHandler, FCPXMLUtility, FCPXMLService |
| **FCPXMLUtility** | Initialisation, element filtering by `FCPXMLElementType`, CMTime ↔ FCPXML time string, time conforming |
| **FCPXMLService** | Initialisation, document creation, timecode/CMTime conversion |
| **Modular components** | Parser, TimecodeConverter, DocumentManager, ErrorHandler (parse, validate, create, add resource, message formatting) |
| **Modular utilities** | `ModularUtilities.createPipeline()` returns configured FCPXMLService |
| **Async and concurrency** | Sendable service in TaskGroup; async parser, converter, document manager, service, utilities, element filtering, time conforming, FCPXML time string conversion, XML operations, concurrent ops |
| **Performance (basic)** | Filter elements by type; timecode conversion |
| **Frame rate** | All eight FCP frame rates (round-trip); drop-frame (29.97, 59.94) |
| **Time values** | Various/large CMTime; round-trip via converter |
| **FCPXML time strings** | Valid value/timescale formats; invalid strings → CMTime.zero |
| **Time conforming** | `conform(time:toFrameDuration:)` for all eight FCP frame durations |
| **Error handling** | ErrorHandler for FCPXMLError; parser with invalid XML |
| **Document management** | Document creation 1.5–1.14; add resources/sequences; validate structure |
| **Element filtering** | Core, extended, and all `FCPXMLElementType` coverage |
| **Modular extensions** | CMTime (timecode, fcpxmlTime, conformed); PNXMLElement (setAttribute, getAttribute, createChild); PNXMLDocument (addResource, addSequence, isValid) |
| **Performance (params)** | Timecode conversion all frame rates; document creation loop; element filtering large dataset |
| **Edge cases** | Edge time values; concurrent timecode conversion |
| **FCPXMLElementType** | tagName, isInferred (multicam, compound, asset, sequence, clip, none) |
| **FCPXMLError** | Every case has non-empty errorDescription |
| **ModularUtilities API** | createCustomPipeline, validateDocument (invalid doc), processFCPXML, processMultipleFCPXML, convertTimecodes |
| **PNXMLDocument extension** | fcpxEventNames, add(events:); resource(matchingID:), remove(resourceAtIndex:); fcpxmlString, fcpxmlVersion; load via FCPXMLFileLoader or parser |
| **PNXMLElement extension** | fcpxType, isFCPXResource, isFCPXStoryElement; fcpxEvent, eventClips, addToEvent, removeFromEvent; fcpxDuration; eventClips throws when not event |
| **Parser filter** | Filter media by first child (multicam/compound); FCPXMLUtility.defaultForExtensions |

### 3.2 Dedicated test files (by theme)

**Cross-platform XML**

- **AEXMLSerializationParityTests** — AEXML round-trip (parse → serialize → re-parse, structure comparison); backend parity (Foundation vs AEXML on same FCPXML); all-samples smoke (AEXML parses every sample); root/version parity; DTD validation (AEXML throws dtdValidationUnavailable). Documents known serialization differences (attribute order, whitespace, empty elements, DOCTYPE stripping, comments).
- **FCPXMLDTDValidatorTests** — Validates document against a given FCPXML version's DTD; on macOS full DTD validation; on iOS (or when DTD unavailable) uses FCPXMLStructuralValidator and may return structuralValidationOnly warning.
- **FCPXMLStructuralValidatorTests** — Cross-platform structural validation: root name `fcpxml`, required `version`, required `resources`, at least one content element (library/event/project), element-name allowlist (1.5–1.14); unknownElementName error; structuralValidationOnly warning.

**Media & extraction**

- **MediaExtractionTests** — extractMediaReferences, copyReferencedMedia (sync/async); extract-then-copy flow (CLI --media-copy). MediaExtractor, MediaExtractionResult, MediaCopyResult.

**Timeline & manipulation**

- **TimelineManipulationTests** — Ripple insert (immutable/mutating, lane options); auto lane (findAvailableLane, insertingClipAutoLane, insertClipAutoLane); clip queries (onLane, inRange, withAssetRef, laneRange); metadata (markers, chapters, keywords, ratings); timestamps (createdAt, modifiedAt); file tests for TimelineSample, TimelineWithSecondaryStoryline, TimelineWithSecondaryStorylineWithAudioKeyframes. Timeline, TimelineClip, RippleInsertResult, ClipPlacement, TimelineError.

**Timecode & timing**

- **FCPXMLTimecodeTests** — FCPXMLTimecode: init (seconds, value/timescale, CMTime, frames, FCPXML string); value, timescale, seconds, fcpxmlString; arithmetic (+, -, *); comparison; toCMTime; frame alignment; Hashable, Codable.

**Media processing**

- **MIMETypeDetectionTests** — Sync/async detection (UTType, AVFoundation, extension fallback); video/audio/image formats. MIMETypeDetector.
- **AssetValidationTests** — Existence; lane compatibility (negative = audio only); sync/async; TimelineClip (validateAsset, isAudioAsset, isVideoAsset, isImageAsset). AssetValidator, AssetValidationResult.
- **SilenceDetectionTests** — Silence at start/end; threshold, minimumDuration; sync/async. SilenceDetector, SilenceDetectionResult.
- **AssetDurationMeasurementTests** — Duration for audio/video/images; media type; sync/async; image (no duration). AssetDurationMeasurer, DurationMeasurementResult, MediaType.
- **ParallelFileIOTests** — Parallel read/write; success/failure counts; maxConcurrentOperations, useFileHandleOptimization. ParallelFileIOExecutor, ParallelFileIOResult.

**Analysis & detection**

- **CutDetectionTests** — Edit points (hardCut, transition, gapCut); source relationship (sameClip, differentClips); empty spine; single clip; same ref transitions; different refs; CutSample.fcpxml file test. EditPoint, CutDetectionResult.

**Typed models**

- **AdjustmentTests** — Crop, Transform, Blend, Stabilization, Volume, Loudness; init, properties, Codable, Clip integration; XML round-trip.
- **AudioEnhancementTests** — NoiseReduction, HumReduction, Equalization, MatchEqualization; init, Codable, Clip integration.
- **Transform360Tests** — Transform360Adjustment (spherical/cartesian, auto-orient, convergence, interaxial); Codable, Clip integration.
- **FilterTests** — VideoFilter, AudioFilter, VideoFilterMask, FilterParameter (keyframe animation, param auxValue 1.11+); Codable, clip integration.
- **CaptionTitleTests** — Caption, Title, TextStyle, TextStyleDefinition; typedTextStyleDefinitions; XML parse/serialization; CaptionSample.fcpxml file test.
- **KeyframeAnimationTests** — KeyframeAnimation, Keyframe (interpolation), FadeIn/FadeOut (fade types); FilterParameter integration; CMTime Codable.
- **AudioKeyframeTests** — Audio keyframes in adjust-volume (param name="amount" with keyframeAnimation); parsing from FCPXML samples; decibel values (-3dB, -37dB); time values (FCPXML fractional format); fadeIn/fadeOut integration; multiple keyframes in sequence; secondary storyline and nested clips; TimelineWithSecondaryStorylineWithAudioKeyframes, TimelineSample file tests.
- **CMTimeCodableTests** — CMTime encode/decode as FCPXML time strings; round-trip; edge cases.
- **CollectionTests** — CollectionFolder, KeywordCollection; nested folders; Codable.

**Format, Asset, version & structure**

- **FCPXMLFormatAssetTests** — Format heroEye (get/set/init/parse); Asset heroEyeOverride; Asset mediaReps (single/multiple, round-trip). VersionConversionTests: heroEye/heroEyeOverride stripped when converting to &lt; 1.13.
- **Live Drawing (1.11+)** — **APIAndEdgeCaseTests**: testLiveDrawingModelInitAndAttributes (init, role, dataLocator, animationType, name, duration); testLiveDrawingFromElementAndAnyTimelineRoundTrip (from element, AnyTimeline.liveDrawing).
- **HiddenClipMarker (1.13+)** — **APIAndEdgeCaseTests**: testHiddenClipMarkerModelAndAnnotationElements (model from element, create new, fcpxAnnotations). VersionConversionTests: hidden-clip-marker stripped when converting to &lt; 1.13.
- **SmartCollectionTests** — SmartCollection; MatchUsage, MatchRepresentation, MatchMarkers, MatchAnalysisType; round-trip; version stripping.
- **VersionConversionTests** — Version conversion; save .fcpxml/.fcpxmld; DTD-based stripping (heroEye, hidden-clip-marker, etc.).
- **ImportOptionsTests** — import-options element (get/set); setShouldCopyAssetsOnImport, setShouldSuppressWarningsOnImport, setLibraryLocationForImport; removeChildren(where:) behaviour with import-options.

---

## 4. File tests (per-sample coverage)

File tests live under **PipelineNeoTests/FileTests/** and use samples from **Tests/FCPXML Samples/FCPXML/**. Each class loads one or more samples and asserts parse success, version, root, events, projects, resources, or spine as appropriate.

| Test class | Sample(s) | Asserts |
|------------|-----------|---------|
| **FCPXMLFileTest_24** | 24.fcpxml | Root, version ver1_11, events, project, sequence format "r1", spine story elements; load via FCPXMLFileLoader + FCPXMLService |
| **FCPXMLFileTest_360Video** | 360Video.fcpxml | Root, ver1_13, format projection/stereoscopic, adjust-colorConform, bookmarks, smart collections, round-trip |
| **FCPXMLFileTest_AllSamples** | All .fcpxml in dir | Each loads via FCPXMLFileLoader and as FinalCutPro.FCPXML; root name "fcpxml"; skips if dir missing/empty |
| **FCPXMLFileTest_Annotations** | Annotations.fcpxml | Root, events, projects |
| **FCPXMLFileTest_AuditionSample** | AuditionSample.fcpxml | Root, ver1_13, audition element, active/inactive clips, adjust-colorConform, conform-rate, keywords |
| **FCPXMLFileTest_BasicMarkers** | BasicMarkers.fcpxml | Root, ver1_9, root equality, resources, library; allEvents, allProjects |
| **FCPXMLFileTest_Complex** | Complex.fcpxml | Root, ver1_11, events, projects; version attribute; resources exist |
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

**FCPXMLFormatAssetTests** — Format heroEye (get/set/init/parse, round-trip); Asset heroEyeOverride (get/set/init/parse); Asset mediaReps (single/multiple, count, order, init, round-trip with two reps). VersionConversionTests cover stripping to 1.5.

---

## 6. Timeline, export, and validation tests

**TimelineExportValidationTests** covers timeline model, exporters, validators, and file loader.

**Timeline & TimelineClip** — endTime; duration from primary lane; sortedClips order; TimelineFormat (hd1080p, uhd4K, presets, computed properties, equality); helpers on Timeline; **empty timeline creation** — testEmptyTimelineCreationAtDifferentSizesAndFrameRates: barebone `Timeline(name:format:clips: [])` at multiple sizes (720p, 1080p, 4K UHD, DCI 4K, custom 640×480) and frame rates (24, 25, 30); asserts name, clips empty, duration zero, format dimensions and frame duration, aspectRatio.

**FCPXMLExporter** — Export minimal timeline (fcpxml, resources, refs); missingAsset throws when clips present; empty timeline (zero clips) succeeds with empty spine, event/project uid, modDate; optional eventUid, projectUid, libraryLocation; **clip-level metadata export** — testFCPXMLExporterExportsClipMarkers, testFCPXMLExporterExportsClipChapterMarkers, testFCPXMLExporterExportsClipKeywords, testFCPXMLExporterExportsClipRatings, testFCPXMLExporterExportsClipMetadata (markers, chapter-markers, keywords, ratings, metadata as children of asset-clip per FCPXML DTD); testFCPXMLExporterClipMetadataAllTypesValidatesAgainstDTD (one clip with all metadata types, export then parse and validate against DTD); **XML declaration** — testFCPXMLExporterXmlDeclarationStandaloneNo (exported FCPXML uses standalone="no" for xmllint/DTD compatibility); **project-creation style** — testProjectCreationStyleExportValidatesAgainstDTD: empty timeline with custom format (e.g. 1920×1080@25p), export with includeDefaultSmartCollections: true, assert output contains DOCTYPE, colorSpace, smart-collection; parse with FCPXMLService and validate against DTD (same flow as CLI --create-project); **project creation at different sizes and frame rates** — testProjectCreationAtDifferentSizesAndFrameRates: export empty timeline at multiple sizes (720p, 1080p, 4K, custom 640×480) and frame rates (24, 25, 30, 60), then parse and validate against DTD; **FCPXMLUID** — random() and isValid() for FCPXML-style UIDs.

**FCPXMLBundleExporter** — Creates bundle (Out.fcpxmld, Info.fcpxml, Info.plist); with includeMedia copies files and references in Info.fcpxml.

**FCPXMLValidator** — Valid structure → valid; non-fcpxml root → invalid; unresolved ref → invalid with error.

**FCPXMLDTDValidator** — **FCPXMLDTDValidatorTests**: returns ValidationResult; valid document → isValid true; on macOS uses full DTD; on iOS uses FCPXMLStructuralValidator (structuralValidationOnly warning when DTD unavailable).

**FCPXMLStructuralValidator** — **FCPXMLStructuralValidatorTests**: cross-platform checks (root name, version, resources, content element, element allowlist); unknownElementName error; structuralValidationOnly warning.

**FCPXMLFileLoader** — Loads single file (root, name); loads .fcpxmld bundle (resolved URL Info.fcpxml, root exists); missing URL throws FCPXMLLoadError.

---

## 7. API and edge case tests

**APIAndEdgeCaseTests** — Async load API; optional logging (NoOp, Print, createCustomPipeline); edge cases (parse empty/invalid/malformed data; invalid path, resolveFCPXMLFileURL); validation types (ValidationResult with errors, ValidationWarning); FCPXML creation (all versions); **Live Drawing (1.11+)** model and AnyTimeline round-trip; **HiddenClipMarker (1.13+)** model and fcpxAnnotations.

**Other files** (see [§3.2](#32-dedicated-test-files-by-theme)) — AEXMLSerializationParityTests, FCPXMLDTDValidatorTests, FCPXMLStructuralValidatorTests, TimelineManipulationTests, FCPXMLTimecodeTests, MIMETypeDetectionTests, AssetValidationTests, SilenceDetectionTests, AssetDurationMeasurementTests, ParallelFileIOTests, AdjustmentTests, AudioEnhancementTests, Transform360Tests, FilterTests, CaptionTitleTests, KeyframeAnimationTests, AudioKeyframeTests, CMTimeCodableTests, CollectionTests.

**FCPXMLFileLoader async** — testFCPXMLFileLoaderAsyncLoadFromURL (temp file, root/name); testFCPXMLFileLoaderAsyncLoadThrowsForMissingFile (FCPXMLLoadError).

**PipelineLogger** — NoOpLogger, PrintLogger parse successfully; createCustomPipeline with logger; PipelineLogLevel (Comparable, from(string:), label).

**Edge cases** — Parse empty data, invalid XML, malformed XML throw; load from invalid path, resolve nonexistent path throw.

**Validation** — ValidationResult with ValidationError (missingAssetReference); ValidationWarning message.

---

## 8. Performance tests

Performance is measured with **measure { }** (XCTest); results show duration and relative standard deviation.

**PipelineNeoTests.swift** — testPerformanceFilterElements; testPerformanceTimecodeConversion; testPerformanceTimecodeConversionAllFrameRates; testPerformanceDocumentCreation; testPerformanceElementFilteringLargeDataset.

**FCPXMLPerformanceTests** — testPerformanceParseFCPXMLDataRepeatedly (50× per iteration); testPerformanceLoadSampleFileWhenAvailable (Structure.fcpxml 20×; skips if missing).

**Guidelines** — Keep tests fast; avoid heavy I/O or very large documents unless the test is for that; use the same dependency injection as the rest of the suite.

---

## 9. Supported frame rates

Eight frame rates supported by Final Cut Pro: **23.976** (`.fps23_976`), **24** (`.fps24`), **25** (`.fps25`), **29.97** (`.fps29_97`, drop-frame), **30** (`.fps30`), **50** (`.fps50`), **59.94** (`.fps59_94`, drop-frame), **60** (`.fps60`). Collected in **fcpSupportedFrameRates**; used in testAllSupportedFrameRates, testCMTimeModularExtensionsWithAllFrameRates, testTimeConformingWithDifferentFrameDurations, testPerformanceTimecodeConversionAllFrameRates. Suite focuses on these eight.

---

## 10. FCPXML versions

Document manager tests create documents for **FCPXML 1.5 through 1.14** and assert valid structure and resource/sequence handling. Parsing and validation use samples valid for their declared version; invalid XML is covered in testParserWithInvalidXML. DTDs live under **Sources/PipelineNeo/FCPXML DTDs/**; the suite does not exhaustively test every version-specific DTD attribute.

---

## 11. Sample files

- **Location:** `Tests/FCPXML Samples/FCPXML/` (sibling of PipelineNeoTests).
- **Path resolution:** At runtime via **packageRoot(relativeToFile: #file)** so tests work from Xcode and `swift test` without bundle resources.
- **TestResources.swift** — `packageRoot`, `fcpxmlSamplesDirectory()`, `urlForFCPXMLSample(named:)`.
- **FCPXMLTestUtilities** — `loadFCPXMLSampleData(named:)`, `loadFCPXMLSample(named:)`; throw **XCTSkip** when the file is missing.

---

## 12. Writing and organising tests

**Naming** — Use `test<FeatureOrBehaviour>` (e.g. testAllSupportedFrameRates, testParserWithInvalidXML). Put new tests under the right MARK section and keep this README updated.

**Structure** — Arrange–act–assert. Async tests: `async throws` and `await`. Performance: `measure { }`; avoid blocking/heavy I/O unless the test is for that. Concurrency: main test class is @unchecked Sendable; shared properties in setUpWithError/tearDownWithError; prefer async/await; use withTaskGroup or async let where appropriate.

**Adding a file test** — New class under FileTests/ (e.g. FCPXMLFileTest_<Name>.swift). Use loadFCPXMLSample(named:) when the sample must exist, or urlForFCPXMLSample(named:) with FileManager.fileExists and XCTSkip when optional. Assert on root, version, allEvents(), allProjects(), resources, etc.

**Adding logic/parsing tests** — Under LogicAndParsing/ for model types (Version, structure, parsing rules).

**Adding feature tests** — New file for major features (e.g. TimelineManipulationTests). Group related tests; descriptive names; sync and async where applicable; edge cases, errors, protocol conformance.

---

## 13. Continuous integration

GitHub Actions (e.g. `.github/workflows/build.yml`) run on push and pull requests: **macOS** — build and full unit test suite (Xcode workspace, xcodebuild); Swift 6 and strict concurrency job; **iOS** — build for iOS Simulator (orchetect/setup-xcode-simulator); tests are not run on iOS because they require Foundation XML. All macOS tests must pass with no regressions.

---

## 14. Debugging tests

- Run a single test: `swift test --filter testMethodName` or run in Xcode (diamond next to the method).
- Use print or breakpoints as needed; avoid leaving noisy prints in committed code.
- Async tests that hang: check for missing await or blocking work on the main actor.
- Prefer deterministic data and injected dependencies to avoid flakiness.

---

## 15. Contributing to tests

Add tests for new behaviour or edge cases; place them in the right file and MARK section; keep names descriptive. Update this README when adding a category or changing what a section covers. For “all FCP frame rates” use **fcpSupportedFrameRates**. Prefer minimal in-memory FCPXML or small fixtures; document assumptions (e.g. temp URL) in a comment or here.

---

## 16. Resources

- **XCTest** (Apple documentation)
- **Testing in Xcode** (Apple documentation)
- **Pipeline Neo README** (project root) — overview and API usage
- **Documentation/Manual** — full manual; [18 — Cross-Platform & iOS](../Documentation/Manual/18-Cross-Platform-iOS.md) for XML abstraction and iOS support
- **Final Cut Pro XML (FCPXML)** — [fcp.cafe](https://fcp.cafe) for format reference
- **SwiftTimecode** (GitHub) — timecode and frame rate types

---

## 17. Resolving common test/build messages

**Swift PM cache warnings** — “configuration is not accessible or not writable” / “Caches is not accessible or not writable”: Swift PM cannot write to `~/Library/org.swift.swiftpm/` or `~/Library/Caches/org.swift.swiftpm/`. Fix: ensure directories exist and your user has write permission (e.g. `mkdir -p ~/Library/org.swift.swiftpm ~/Library/Caches/org.swift.swiftpm`). In CI/sandbox these warnings are harmless; Swift PM falls back to process-local cache.

**Invalid connection: com.apple.coresymbolicationd** — macOS symbolication daemon message; not from Pipeline Neo; does not affect test results. Can be ignored.

**Couldn't find the DTD file / Error setting the DTD** — Validator looks for DTDs in (1) PipelineNeo module bundle (root and “FCPXML DTDs”), (2) all loaded bundles, (3) frameworks with “DTDs” subdirectory. DTDs are in `Sources/PipelineNeo/FCPXML DTDs/` and declared in Package.swift with `.process("FCPXML DTDs")`. If messages persist, build and run from package root (`swift build && swift test`). When the DTD is not found, the validator returns a result with a dtdValidation error; tests accept either success or that error.

**Performance test relative standard deviation** — XCTest prints average and RSD for each `measure { }` run; informational. High RSD is common for very fast ops. To reduce variation: record a baseline in Xcode (Editor → Add Baseline) or increase iterations. The suite does not fail on RSD unless a baseline is set and exceeded.

---

## 18. Credits

Inspired and modeled after [swift-daw-file-tools](https://github.com/orchetect/swift-daw-file-tools)'s Test Suites.
