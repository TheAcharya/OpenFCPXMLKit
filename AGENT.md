# Pipeline Neo — AI Agent Development Guide

Pipeline Neo is a modern, fully modular Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration. The codebase underwent a complete rewrite and refactor: it is now 100% protocol-oriented, with all major operations defined as protocols and implemented via dependency injection for maximum flexibility, testability, and future-proofing. This guide is for AI agents and contributors working on the project.

Keep this file in sync with `.cursorrules`. Both should describe the same overview, architecture, test structure, and conventions. When you update one, update the other.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Codebase Rewrite and Refactor](#codebase-rewrite-and-refactor)
- [Architecture Guidelines](#architecture-guidelines)
- [Modularity and Safety](#modularity-and-safety)
- [Code Style and Formatting](#code-style-and-formatting)
- [File Organisation](#file-organisation)
- [Test Structure](#test-structure)
- [Dependencies](#dependencies)
- [Development Patterns](#development-patterns)
- [Testing Requirements](#testing-requirements)
- [Error Handling](#error-handling)
- [Performance Considerations](#performance-considerations)
- [Documentation Standards](#documentation-standards)
- [Changelog](#changelog)
- [Git Workflow](#git-workflow)
- [Quality Assurance](#quality-assurance)
- [Project-Specific Rules](#project-specific-rules)
- [Common Tasks](#common-tasks)
- [Code Generation Guidelines](#code-generation-guidelines)
- [Documentation Sync](#documentation-sync)
- [External References](#external-references)
- [Maintenance](#maintenance)

---

## Project Overview

Pipeline Neo targets macOS 12+, iOS 15+, Xcode 16+, and Swift 6.0 with full concurrency support. It provides FCPXML parsing, creation, and manipulation with timecode operations via SwiftTimecode. All core behaviour is behind protocols with both synchronous and async/await APIs; default implementations exist but any component can be swapped or extended via dependency injection.

**Backward compatibility:** The entire codebase must remain backward compatible with FCPXML 1.5. Optional attributes and elements introduced in later versions (e.g. 1.11, 1.13) must be omitted or ignored when reading/writing or converting to 1.5; mark such features in code comments with the minimum FCPXML version (e.g. `FCPXML 1.13+`).

Current status: 686 tests passing; FCPXML versions 1.5–1.14 supported (DTDs included, full parsing, typed element-type coverage for all DTD elements via FCPXMLElementType); Final Cut Pro frame rates (23.976, 24, 25, 29.97, 30, 50, 59.94, 60); thread-safe and concurrency-compliant with comprehensive async/await support; no known security vulnerabilities. Version conversion automatically drops elements not in the target version’s DTD (e.g. adjust-colorConform, adjust-stereo-3D); DTD validation runs per version (validateDocumentAgainstDTD, validateDocumentAgainstDeclaredVersion) and after CLI convert. FCPXMLVersion.supportsBundleFormat is true for 1.10+ (.fcpxmld bundle); 1.5–1.9 support only single-file .fcpxml. FCPXML creation: create FCPXML documents from scratch with events, projects, resources, and clips via XMLDocumentManager, XMLDocument initializers, or FCPXMLService. Timeline manipulation: ripple insert (shifts subsequent clips), auto lane assignment, clip queries (by lane, time range, asset ID), lane range computation, secondary storylines. Timeline metadata: markers, chapter markers, keywords, ratings, custom metadata, timestamps (createdAt, modifiedAt). FCPXMLTimecode: custom timecode type (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing). MIME type detection, asset validation, silence detection, asset duration measurement, parallel file I/O, still image asset support. TimelineFormat enhancements: presets (hd720p, dci4K, hd1080i, hd720i), computed properties (aspectRatio, isHD, isUHD, interlaced). Typed adjustment models: Crop, Transform, Blend, Stabilization, Volume, Loudness, NoiseReduction, HumReduction, Equalization, MatchEqualization, Transform360, ColorConform, Stereo3D, VoiceIsolation with full clip integration. Typed effect/filter models: VideoFilter, AudioFilter, VideoFilterMask with FilterParameter support and keyframe animation (auxValue support FCPXML 1.11+). Typed caption/title models: Caption and Title with TextStyle and TextStyleDefinition for full text formatting. SmartCollection models: SmartCollection with match-clip, match-media, match-ratings, match-text, match-usage (1.9+), match-representation (1.10+), match-markers (1.10+), match-analysis-type (1.14). Keyframe animation: KeyframeAnimation, Keyframe with interpolation types, FadeIn/FadeOut with fade types, integrated with FilterParameter. CMTime Codable extension: Direct CMTime encoding/decoding as FCPXML time strings. Collection organization: CollectionFolder and KeywordCollection models for organizing clips and media. Live Drawing (FCPXML 1.11+): LiveDrawing model for live-drawing story elements. HiddenClipMarker (FCPXML 1.13+): HiddenClipMarker model for hidden clip markers. Format/Asset 1.13+: Format heroEye, Asset heroEyeOverride, Asset mediaReps (multiple media-rep). Cross-platform XML abstraction: protocol layer (PNXMLNode, PNXMLElement, PNXMLDocument, PNXMLFactory); Foundation backend on macOS (unchanged behaviour); AEXML backend on iOS; PNXMLDefaultFactory() for platform dispatch; FCPXMLStructuralValidator for cross-platform structural validation; FCPXMLDTDValidator is platform-conditional (full DTD on macOS, structural fallback on iOS). Comprehensive test coverage: 686 tests across 15+ FCPXML sample files including 360 video, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes (AudioKeyframeTests: 10 tests for adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration, secondary storyline detection), keyword collections/folders, Photoshop integration, smart collections. Experimental CLI (pipeline-neo): single binary with embedded DTDs; --check-version, --convert-version (stripping + DTD validation), --extension-type (fcpxmld | fcpxml; default fcpxmld; 1.5–1.9 always .fcpxml), --validate, --media-copy, --create-project (new empty FCPXML project: --width, --height, --rate, --version, output-dir; DTD validation before write; FCP-style output with DOCTYPE, colorSpace, default smart collections); --log writes user-visible output for all commands to the log file; see Sources/PipelineNeoCLI/README.md.

Xcode 26 dynamic linking compatibility: `swift-log` (`Logging`) is an explicit direct dependency in `Package.swift` to satisfy stricter transitive dylib linking rules when building Pipeline Neo as a dynamic framework.

---

## Codebase Rewrite and Refactor

The project was fully rewritten and refactored to achieve:

- A protocol-oriented design: parsing, timecode conversion, XML manipulation, error handling, MIME type detection, asset validation, silence detection, asset duration measurement, and parallel file I/O are defined as protocols (e.g. FCPXMLParsing, TimecodeConversion, XMLDocumentOperations, ErrorHandling, MIMETypeDetection, AssetValidation, SilenceDetection, AssetDurationMeasurement, ParallelFileIO) with sync and async/await methods.
- A single injection point for extension APIs that cannot take parameters: `FCPXMLUtility.defaultForExtensions` (concurrency-safe). No hidden concrete types in extensions; for custom pipelines use the modular API with the `using:` parameter.
- Consistent source layout: Analysis, Classes, Delegates, Errors, Extensions (including +Modular and +Codable), Implementations, Protocols, Services, Utilities, Annotations, Export, Timeline, Timing, Validation, FileIO, Logging, Format, Model (with subfolders), Parsing, Extraction, **XML** (Protocols: PNXMLNode, PNXMLElement, PNXMLDocument, PNXMLDTDProtocol, PNXMLFactory; Foundation/: Foundation backends; AEXML/: AEXML backends; PNXMLDefaultFactory), and FCPXML DTDs.
- A structured test suite: shared resources, file tests per sample, logic/parsing tests, timeline/export/validation tests, API and edge-case tests, and performance tests, all documented in Tests/README.md.

Foundation XML types (XMLDocument, XMLElement) and the protocol types that wrap them (PNXMLDocument, PNXMLElement) and SwiftTimecode types are not Sendable. The codebase avoids Task-based concurrency for these types but provides async/await APIs that are concurrency-safe for Swift 6. If these dependencies become Sendable in the future, further parallelisation can be introduced.

---

## Architecture Guidelines

- Protocols: Core operations are defined as protocols with both sync and async/await methods. Default implementations are provided; components can be swapped via dependency injection. Protocols include: FCPXMLParsing, TimecodeConversion, XMLDocumentOperations, ErrorHandling (sync-only, pure formatting), MIMETypeDetection, AssetValidation, SilenceDetection, AssetDurationMeasurement, ParallelFileIO, CutDetection, FCPXMLVersionConverting, MediaExtraction.
- Implementations: FCPXMLParser, TimecodeConverter, XMLDocumentManager, ErrorHandler, CutDetector, FCPXMLVersionConverter, MediaExtractor, MIMETypeDetector, AssetValidator, SilenceDetector, AssetDurationMeasurer, ParallelFileIOExecutor implement the protocols.
- Analysis: Cut detection (CutDetection protocol, CutDetector implementation) produces EditPoint and CutDetectionResult; classifies edit points by boundary type (hard cut, transition, gap) and source relationship (same-clip vs different-clips). FCPXMLService and FCPXMLUtility expose detectCuts(in:) and detectCuts(inSpine:) (sync and async).
- Version conversion: FCPXMLVersionConverting protocol and FCPXMLVersionConverter; convertToVersion(_:targetVersion:) sets root version, strips elements not in the target version’s DTD (e.g. adjust-colorConform, adjust-stereo-3D), and returns a copy; saveAsFCPXML(_:to:) saves as .fcpxml; saveAsBundle(_:to:bundleName:) saves as .fcpxmld (FCPXMLBundleExporter.saveDocumentAsBundle; only for document version 1.10 or higher; FCPXMLVersion.supportsBundleFormat is true for 1.10+). DTD validation: FCPXMLService.validateDocumentAgainstDTD(_:version:) and validateDocumentAgainstDeclaredVersion(_:); FCPXMLDTDValidator injectable; CLI convert runs validation after conversion and fails if invalid. CLI --extension-type (fcpxmld | fcpxml; default fcpxmld) controls convert output format; 1.5–1.9 always output .fcpxml. Async methods are concurrency-safe; Task-based concurrency is avoided for non-Sendable types. FCPXMLParser delegates URL loading to FCPXMLFileLoader for unified file/bundle handling and consistent parse options. TimecodeConverter guards against invalid/non-finite CMTime inputs.
- Media extraction: MediaExtraction protocol and MediaExtractor; extractMediaReferences(from:baseURL:) returns MediaExtractionResult (references from asset media-rep and locator resources; fileReferences for file URLs); copyReferencedMedia(from:to:baseURL:) copies file references to a directory with deduplication and unique filenames, returning MediaCopyResult (copied, skipped, failed). FCPXMLService and FCPXMLUtility expose both (sync and async).
- Extensions: Modular extensions for CMTime, XMLElement, and XMLDocument support dependency-injected operations and async/await. Extension APIs that cannot take parameters use FCPXMLUtility.defaultForExtensions (e.g. CMTime.fcpxmlString delegates to FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime:)).
- Service: FCPXMLService orchestrates modular components for high-level workflows (sync and async). FCPXMLUtility is the legacy/convenience facade; FCPXMLService is the modern DI facade. Both delegate timecode operations to TimecodeConverter.
- Utilities: ModularUtilities provides pipeline creation (createPipeline, createCustomPipeline), validation (validateDocument delegates to FCPXMLValidator for semantic checks; the `parser:` parameter is deprecated), and helpers (processFCPXML, processMultipleFCPXML — the `errorHandler:` parameter is deprecated — and convertTimecodes using TimecodeConversion and FCPXMLTimeStringConversion protocols). For per-version DTD validation use FCPXMLService.validateDocumentAgainstDTD(_:version:) or validateDocumentAgainstDeclaredVersion(_:).
- Logging: PipelineLogger protocol with levels trace, debug, info, notice, warning, error, critical (PipelineLogLevel); NoOpPipelineLogger, PrintPipelineLogger, FilePipelineLogger (file + optional console, quiet). FCPXMLUtility and FCPXMLService use injected logger for parse, conversion, validation, save, and media operations. CLI: --log, --log-level, --quiet; when --log is set, all CLI commands (check-version, convert-version, validate, media-copy, create-project) write their user-visible messages to the log file. Extension types use #if canImport(Logging) as fallback where DI is not available.
- Versioning: FCPXMLVersion (DTD validation, 1.5-1.14) and FinalCutPro.FCPXML.Version (parsing, 1.0-1.14) are bridged via .fcpxmlVersion, .dtdVersion, and init(from:) converters. init(from:) uses safe fallback to `.latest` instead of force unwrap.
- Errors: Module-scoped error types (FCPXMLError for parsing, FCPXMLLoadError for file I/O, FCPXMLExportError/FCPXMLBundleExportError for export, FinalCutPro.FCPXML.ParseError with LocalizedError). Parse failures from FCPXMLFileLoader surface as FCPXMLError.parsingFailed so consumers handle a single parse-error type. FCPXMLElementError uses String element names for Sendable compliance.

---

## Modularity and Safety

- All major functionality is protocol-based and dependency-injected, with both sync and async/await APIs.
- Code is Sendable where appropriate; `@unchecked Sendable` removed from delegates (AttributeParserDelegate, FCPXMLParserDelegate) since they are internal-only and used synchronously. The project builds and tests with Swift 6 strict concurrency (`-strict-concurrency=complete`). CI runs a job that enforces this.
- No known vulnerabilities in dependencies (including SwiftTimecode 3.0.0) as of July 2025. No unsafe pointers, dynamic code execution, or C APIs; concurrency is structured and type-safe.

---

## Development Patterns

Use Swift 6.0 syntax and features. Use async/await for asynchronous operations; all major operations have async/await APIs. Use structured concurrency (Task, TaskGroup) only where types are Sendable; for Foundation XML and SwiftTimecode types, provide async APIs without Task-based concurrency. Use @unchecked Sendable for classes that cannot be made final; avoid capturing non-Sendable types in concurrent contexts.

Error handling: use Swift Result for operations that can fail; provide meaningful errors; use do-catch for sync and propagate FCPXMLError in async. Use strongly typed enums for FCPXML elements (FCPXMLElementType) and type-safe timecode operations; avoid force unwrapping.

---

## Code Style and Formatting

Follow Swift API Design Guidelines. Use camelCase for variables and functions, PascalCase for types and protocols, descriptive names for all identifiers. Include comprehensive /// doc comments for all public APIs; document parameters, return values, and exceptions; provide usage examples. Group related functionality in extensions; keep files focused on single responsibilities; use clear file names and logical imports.

### File Header

All new Swift files must use this exact header format:

```
//
//  FileName.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Brief description of the file's purpose.
//
```

Rules:
- Replace `FileName.swift` with the actual file name.
- Replace the purpose line with a concise description of what the file contains.
- The purpose block uses a tab character after `//`, not spaces.
- Two blank lines separate the header block from the purpose block.
- Do not add `//  PipelineNeo`, `Created by`, or `Copyright ©` lines.

---

## File Organisation

Source layout under Sources/PipelineNeo/:

- Analysis: EditPoint (edit type, source relationship), CutDetectionResult (edit points and counts).
- Classes: FinalCutPro (namespace enum), FCPXML (core struct, init, properties), FCPXMLRoot, FCPXMLRootVersion, FCPXMLElementType, FCPXMLUtility, FCPXMLVersion.
- XML: Platform-agnostic XML layer — Protocols (PNXMLNode, PNXMLElement, PNXMLDocument, PNXMLDTDProtocol, PNXMLFactory), Foundation/ (FoundationXMLElement, FoundationXMLDocument, FoundationXMLDTD, FoundationXMLFactory), AEXML/ (AEXMLBackendElement, AEXMLBackendDocument, AEXMLBackendFactory), PNXMLDefaultFactory (platform dispatch: Foundation on macOS, AEXML on iOS).
- Delegates: AttributeParserDelegate (property: `values`), FCPXMLParserDelegate (properties: `roles`, `resourceIDs`, `textStyleIDs`; O(1) deduplication via Set).
- Errors: FCPXMLError, FCPXMLParseError, TimelineError.
- Extensions: CMTime+Modular, CMTimeExtension, CMTime+Codable, XMLDocument+Modular, XMLDocumentExtension, XMLElement+Modular, XMLElementExtension (FCPXML extensions operate on PNXMLDocument/PNXMLElement protocol types).
- Implementations: FCPXMLParser, TimecodeConverter, XMLDocumentManager, ErrorHandler, CutDetector, FCPXMLVersionConverter, MediaExtractor, MIMETypeDetector, AssetValidator, SilenceDetector, AssetDurationMeasurer, ParallelFileIOExecutor.
- Protocols: FCPXMLParsing, TimecodeConversion, XMLDocumentOperations, ErrorHandling, CutDetection, FCPXMLVersionConverting, MediaExtraction, MIMETypeDetection, AssetValidation, SilenceDetection, AssetDurationMeasurement, ParallelFileIO.
- Services: FCPXMLService.
- Utilities: ModularUtilities, FCPXMLTimeUtilities, SequencePlusAnySequence, XMLElementAncestorWalking, XMLElementSequenceAttributes.
- Annotations: ChapterMarker, Keyword, Marker, Metadata, Rating (creation-oriented value types; for parsing models see Model/).
- Export: FCPXMLExporter, FCPXMLBundleExporter, FCPXMLExportAsset.
- Timeline: Timeline (with manipulation methods: ripple insert, auto lane assignment, clip queries, lane range, metadata, timestamps), TimelineClip (with asset validation methods), TimelineFormat (with presets and computed properties).
- Timing: FCPXMLTimecode (custom timecode type wrapping Fraction).
- Validation: FCPXMLValidator, FCPXMLDTDValidator, FCPXMLStructuralValidator (cross-platform; used on iOS when DTD is unavailable), ValidationResult, ValidationError/Warning, DocumentValidationReport.
- FileIO: FCPXMLFileLoader.
- Logging: PipelineLogger, PipelineLogLevel (trace–critical), NoOpPipelineLogger, PrintPipelineLogger, FilePipelineLogger.
- Format: ColorSpace.
- Model: FCPXML element models for the parsing layer (previously nested under FinalCutPro/FCPXML/). Subfolders: Adjustments (CropAdjustment, TransformAdjustment, BlendAdjustment, StabilizationAdjustment, VolumeAdjustment, LoudnessAdjustment, NoiseReductionAdjustment, HumReductionAdjustment, EqualizationAdjustment, MatchEqualizationAdjustment, Transform360Adjustment, ColorConformAdjustment, Stereo3DAdjustment, VoiceIsolationAdjustment), Animations (KeyframeAnimation, Keyframe, FadeIn, FadeOut, FadeType), Attributes (AudioLayout, AudioRate, ClipSourceEnable, FrameSampling, TimecodeFormat), Clips (AssetClip, Audio, Audition, Clip including Clip+Adjustments, Gap, MCClip, MulticamSource, RefClip, SyncClip, SyncSource, Title including Title+Typed, Transition, Video), CommonElements (AudioChannelSource, AudioRoleSource, ConformRate, MediaRep, Metadata, Text, TextStyle, TextStyleDefinition, TimeMap), ElementTypes (AnyElementModelType, ElementModelType, ElementType, protocols), Filters (VideoFilter, AudioFilter, VideoFilterMask, FilterParameter), Occlusion (ElementOcclusion, Element Occlusion), Protocols (FCPXMLElement, FCPXMLAttribute, element attribute/children/story protocols), Resources (Asset, Effect, Format, Locator, Media, MediaMulticam, ObjectTracker), Roles (AudioRole, CaptionRole, VideoRole, AncestorRoles, AnyRole, RoleType, FCPXMLRole), Structure (Event, Library, Project, CollectionFolder, KeywordCollection, SmartCollection). Root files: AnyTimeline, Caption including Caption+Typed, Keyword, Marker, Sequence, Spine.
- Parsing: XML parsing extensions (Attributes, Clip Parsing, Elements Parsing, Metadata Parsing, Resources Parsing, Roles Parsing, Root Parsing, Time and Frame Rate Parsing).
- Extraction: Element extraction logic. Subfolders: Context (ElementContext, FrameRateSource), Presets (CaptionsExtractionPreset, FrameDataPreset, MarkersExtractionPreset, RolesExtractionPreset, FCPXMLExtractionPreset). Root files: Extract, ExtractableChildren, ExtractedElement, Extraction, ExtractionScope, FCPXMLExtractedElement, FCPXMLExtractedModelElement.
- FCPXML DTDs: version 1.5-1.14 and README.

Maintain this structure; do not introduce new top-level categories without aligning both AGENT.md and .cursorrules.

---

## Test Structure

Tests live under Tests/. The suite is organised as follows.

- Tests/README.md: Full description of test categories, how to run tests (Swift PM, Xcode, Linux), sample files, frame rates, FCPXML versions, and contributing. Keep it current when adding or changing tests.

- Tests/FCPXML Samples/FCPXML/: Sample .fcpxml files (e.g. 24.fcpxml, Structure.fcpxml, frame-rate samples). File tests and logic tests load these via shared utilities; tests that require a missing sample use XCTSkip.

- Tests/PipelineNeoTests/: Test code.
  - TestResources.swift: Path resolution (packageRoot, fcpxmlSamplesDirectory, urlForFCPXMLSample, FCPXMLSampleName) so samples work from Xcode and `swift test`.
  - FCPXMLTestUtilities.swift: loadFCPXMLSampleData(named:), loadFCPXMLSample(named:), fcpxmlFrameRateSampleNames, allFCPXMLSampleNames(); throws XCTSkip when a sample is missing.
  - CutDetectionTests.swift: Cut detection (same-clip vs different-clips, boundary types, Example FCPXML Cut 1/Cut 2, 24.fcpxml, empty spine, async, CutSample file test).
  - VersionConversionTests.swift: Version conversion (convert to target version, element stripping for 1.10/1.12, save as .fcpxml, save as .fcpxmld with 1.10+ check, bundle error when < 1.10, async).
  - TimelineManipulationTests.swift: Timeline manipulation (ripple insert, auto lane assignment, clip queries, lane range, timestamps, metadata).
  - FCPXMLTimecodeTests.swift: FCPXMLTimecode (initialization, arithmetic, comparison, CMTime conversion, frame alignment, hashing, codable).
  - MIMETypeDetectionTests.swift: MIME type detection (sync and async detection for various file types).
  - AssetValidationTests.swift: Asset validation (asset existence, lane compatibility, TimelineClip integration).
  - SilenceDetectionTests.swift: Silence detection (silence detection at start/end of audio files).
  - AssetDurationMeasurementTests.swift: Asset duration measurement (duration measurement for audio/video/images).
  - ParallelFileIOTests.swift: Parallel file I/O (concurrent read/write operations).
  - AudioEnhancementTests.swift: Audio enhancement models (NoiseReduction, HumReduction, Equalization, MatchEqualization, Clip integration).
  - Transform360Tests.swift: Transform360 adjustment (coordinate types, spherical/cartesian, clip integration).
  - CaptionTitleTests.swift: Caption and Title models (TextStyle, TextStyleDefinition, Caption/Title integration).
  - KeyframeAnimationTests.swift: Keyframe animation (FadeIn, FadeOut, Keyframe, KeyframeAnimation, FilterParameter integration).
  - CMTimeCodableTests.swift: CMTime Codable extension (encoding/decoding FCPXML time strings).
  - CollectionTests.swift: Collection organization (CollectionFolder, KeywordCollection, nested structures).
  - PipelineNeoTests.swift: Main test class; setUpWithError injects parser, timecodeConverter, documentManager, errorHandler, FCPXMLUtility, FCPXMLService. MARK sections group tests (FCPXMLUtility, FCPXMLService, modular components, async/concurrency, performance, frame rates, time values, FCPXML time strings, time conforming, error handling, document management, element filtering, modular extensions, edge cases, FCPXMLElementType, FCPXMLError, ModularUtilities API, XMLDocument extension, XMLElement extension, parser filter).
  - FileTests/: One test class per sample or category (e.g. FCPXMLFileTest_24, FCPXMLFileTest_AllSamples, FCPXMLFileTest_FrameRates, FCPXMLFileTest_360Video, FCPXMLFileTest_AuditionSample, FCPXMLFileTest_ImageSample, FCPXMLFileTest_Multicam, FCPXMLFileTest_Photoshop, FCPXMLFileTest_SmartCollection). Each loads one or more samples and asserts parse success, root, version, events, projects, or resources as appropriate.
  - AudioKeyframeTests: Audio keyframes in adjust-volume (param name="amount" with keyframeAnimation); parsing from FCPXML samples; decibel values (-3dB, -37dB); time values (FCPXML fractional format); fadeIn/fadeOut integration; multiple keyframes in sequence; secondary storyline and nested clip detection; TimelineWithSecondaryStorylineWithAudioKeyframes, TimelineSample file tests.
  - LogicAndParsing/: FCPXMLRootVersionTests (Version init, rawValue, Equatable, Comparable, invalid strings), FCPXMLStructureTests (Structure sample, allEvents/allProjects, root structure), FCPXMLFormatAssetTests (Format heroEye, Asset heroEyeOverride, Asset mediaReps).
  - TimelineManipulationTests: Ripple insert, auto lane assignment, clip queries, lane range, timestamps, metadata, secondary storylines, audio keyframes; injectable "now" for timestamp tests via lock-based NowBox (no DispatchSemaphore); do-catch for insertClipAutoLane/insertingClipAutoLane to verify success.
  - TimelineExportValidationTests: Timeline and TimelineClip, FCPXMLExporter (empty timeline creation and project-creation export at different sizes and frame rates; includeDefaultSmartCollections and DTD validation; clip-level metadata export tests; XML declaration standalone="no"), FCPXMLBundleExporter, FCPXMLValidator, FCPXMLDTDValidator, FCPXMLService.validateDocumentAgainstDTD/validateDocumentAgainstDeclaredVersion (per-version), FCPXMLFileLoader.
  - APIAndEdgeCaseTests: FCPXMLFileLoader async load(from:), PipelineLogger injection (NoOp, Print), edge cases (empty/invalid/malformed XML, invalid paths), validation types, Live Drawing (1.11+), HiddenClipMarker (1.13+).
  - FCPXMLPerformanceTests: Parameterised and basic performance tests (timecode conversion, document creation, element filtering).

Test organisation: use descriptive test method names; group related tests logically; include setup and teardown; use meaningful assertions. Test all supported frame rates (Final Cut Pro compatible). Use realistic FCPXML samples and edge cases; validate against actual FCP behaviour where applicable. Current total: 686 comprehensive tests covering all functionality including async/await, timeline manipulation, metadata, timestamps, FCPXMLTimecode, MIME type detection, asset validation, silence detection, asset duration measurement, parallel file I/O, cut detection, version conversion stripping, per-version DTD validation, extract-then-copy (CLI --media-copy flow), synchronized clip matching, secondary storyline traversal, clip identification, URL resolution, version conversion edge cases, typed adjustment models (including Transform360, ColorConform, Stereo3D, VoiceIsolation), typed effect/filter models, typed caption/title models, smart collections (match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type), keyframe animation, audio keyframes (AudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration), CMTime Codable extension, collection organization, Live Drawing (1.11+), HiddenClipMarker (1.13+), Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps), FCPXMLExporter clip-level metadata export and XML declaration standalone="no", TimelineManipulationTests refactor (lock-based NowBox, do-catch for throwing APIs), 360 video features, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, and Photoshop integration.

---

## Dependencies

- SwiftTimecode 3.0.0+ for timecode operations.
- SwiftExtensions 2.0.0+ (orchetect/swift-extensions) for String, Collection, Optional, XML helpers where useful.
- swift-log 1.0.0+ (`Logging`) as an explicit direct dependency for Xcode 26 dynamic framework linking compatibility.
- AEXML 4.0.0+ (tadija/AEXML) for cross-platform XML parsing on iOS (PipelineNeo target only).
- Foundation for XML and data; CoreMedia for CMTime.

Swift 6.0+, Xcode 16.0+, macOS 12.0+, iOS 15.0+.

SwiftTimecode usage: use `Timecode(.realTime(seconds: seconds), at: frameRate)` (not the old realTime: at: initialiser). Use frame rate cases `.fps23_976`, `.fps24`, `.fps25`, `.fps29_97`, `.fps30`, `.fps50`, `.fps59_94`, `.fps60` (not the old ._24, ._25, etc.).

---

## Testing Requirements

Test coverage: unit tests for all public APIs; integration tests for complex workflows; performance tests for time-critical operations; concurrency tests for async operations; test all supported frame rates (Final Cut Pro compatible). Current: 686 comprehensive tests (including AEXML serialization parity, FCPXMLDTDValidatorTests, FCPXMLStructuralValidatorTests) covering all functionality including async/await, timeline manipulation, metadata, timestamps, FCPXMLTimecode, MIME type detection, asset validation, silence detection, asset duration measurement, parallel file I/O, version conversion, DTD validation, extract-then-copy flow, synchronized clip matching, secondary storyline traversal, clip identification, URL resolution, version conversion edge cases, typed adjustment models (including Transform360, ColorConform, Stereo3D, VoiceIsolation), typed effect/filter models, typed caption/title models, smart collections (match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type), keyframe animation, audio keyframes (AudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration), CMTime Codable extension, collection organization, Live Drawing (1.11+), HiddenClipMarker (1.13+), Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps), FCPXMLExporter clip-level metadata export and XML declaration standalone="no", TimelineManipulationTests (lock-based NowBox, do-catch), 360 video features, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, and Photoshop integration.

Test data: use realistic FCPXML samples; include edge cases and error conditions; test all supported frame rates; validate against actual Final Cut Pro output where applicable.

Test organisation: descriptive test method names; group related tests logically; proper setup and teardown; meaningful assertions.

Supported frame rates for testing: 23.976, 24, 25, 29.97, 30, 50, 59.94, 60 fps only.

---

## Error Handling

Use Swift Result for sync; do-catch and throw for async. Provide meaningful messages and context. Implement graceful degradation where possible; proper cleanup on error. FCPXMLError is Sendable; use it for all public failure cases.

---

## Performance Considerations

Use value types where appropriate; avoid retain cycles; use weak references for delegates. Use appropriate concurrency levels and task cancellation; avoid blocking the main thread. For XML: stream when possible, use efficient parsing, cache frequently accessed data.

---

## Documentation Standards

Public APIs: comprehensive header comments, ///, parameters/return values/exceptions, usage examples. README: project overview, installation, usage, API/modularity notes. Inline comments: explain non-obvious logic and reference external specs. Update README and Tests/README.md when adding features or changing test layout.

---

## Changelog

CHANGELOG.md follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with a consistent structure:

- **Version heading:** `## [X.Y.Z](https://github.com/TheAcharya/pipeline-neo/releases/tag/X.Y.Z) - YYYY-MM-DD` — version number links to the GitHub release tag.
- **Three sections per release:** **✨ New Features** (new functionality), **🔧 Improvements** (enhancements, refactors, docs, tests), **🐛 Bug Fixes** (fixes). Use these headings with emojis.
- **Content:** Bullet lists under each section. For empty sections use: "None in this release."
- **Adding a release:** Insert at the top below the intro; classify changes into New Features, Improvements, or Bug Fixes; keep bullets concise.

---

## Git Workflow

Branches: main (production-ready), dev, feature/*, bugfix/*. Commits: clear, descriptive, imperative; reference issues when applicable; separate subject and body with a blank line. Pull requests: descriptive title and description; ensure all tests pass.

---

## Quality Assurance

Code review checklist: all tests passing; documentation updated; error handling implemented; performance considerations addressed; concurrency requirements met.

Build requirements: Swift build successful; all tests passing; no warnings or errors; proper dependency resolution.

---

## Project-Specific Rules

FCPXML handling: support FCPXML versions 1.5 through 1.14 (DTDs included; full parsing; typed element-type coverage via FCPXMLElementType for all DTD elements); validate against DTD schemas (FCPXMLDTDValidator, FCPXMLService.validateDocumentAgainstDTD/validateDocumentAgainstDeclaredVersion); version conversion (FCPXMLVersionConverter) sets root version and automatically strips elements not in the target version’s DTD (e.g. adjust-colorConform, adjust-stereo-3D); FCPXMLVersion.supportsBundleFormat is true for 1.10+ (save as .fcpxmld bundle); 1.5–1.9 support only .fcpxml; handle all supported frame rates (Final Cut Pro compatible); implement proper XML formatting. Media extraction: extract media references (asset media-rep src, locator url) and copy referenced file URLs to a destination directory (MediaExtraction protocol, MediaExtractor). Timeline manipulation: ripple insert (shifts subsequent clips), auto lane assignment (finds available lanes), clip queries (by lane, time range, asset ID), lane range computation, secondary storylines. Timeline metadata: markers, chapter markers, keywords, ratings, custom metadata on timeline and clips; timestamps (createdAt, modifiedAt) updated on all mutating operations. TimelineFormat: presets (hd720p, dci4K, hd1080i, hd720i), computed properties (aspectRatio, isHD, isUHD, interlaced). FCPXMLTimecode: custom timecode type wrapping Fraction (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing). MIME type detection: MIMETypeDetection protocol and MIMETypeDetector implementation (UTType, AVFoundation, file extension fallback). Asset validation: AssetValidation protocol and AssetValidator implementation (existence check, MIME type compatibility, lane rules: negative = audio only, non-negative = video/image/audio); still image asset support (duration=0s). Silence detection: SilenceDetection protocol and SilenceDetector implementation (configurable threshold and minimum duration). Asset duration measurement: AssetDurationMeasurement protocol and AssetDurationMeasurer implementation (AVFoundation-based for audio/video/images). Parallel file I/O: ParallelFileIO protocol and ParallelFileIOExecutor implementation (concurrent read/write operations). SmartCollection: SmartCollection model with match-clip, match-media, match-ratings, match-text, match-usage (1.9+), match-representation (1.10+), match-markers (1.10+), match-analysis-type (1.14); library and event integration. Live Drawing (1.11+): LiveDrawing model for live-drawing story elements. HiddenClipMarker (1.13+): HiddenClipMarker model for hidden clip markers. Format/Asset 1.13+: Format heroEye (left|right), Asset heroEyeOverride, Asset mediaReps (multiple media-rep). Experimental CLI: pipeline-neo single binary (embedded DTDs) with --check-version, --convert-version (stripping + DTD validation), --extension-type fcpxml|fcpxmld (default fcpxmld; 1.5–1.9 always .fcpxml), --validate, --media-copy, --create-project (width, height, rate, version, output-dir; mandatory DTD validation; FCP-style DOCTYPE, format colorSpace, default smart collections), and LOG options (--log, --log-level, --quiet; --log records user-visible output for all commands); see Sources/PipelineNeoCLI/README.md.

Timecode operations: use SwiftTimecode for all timecode operations; support all FCPXML frame rates (Final Cut Pro compatible); implement proper frame rate conversions; handle drop frame and non-drop frame timecode. FCPXMLTimecode provides a custom timecode type for FCPXML-specific operations (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing).

Platform support: target macOS 12.0+ and iOS 15.0+; use Xcode 16.0+ features; implement Swift 6.0 concurrency; follow Apple platform guidelines. Use the PNXML protocol layer (PNXMLDocument, PNXMLElement, PNXMLDefaultFactory) so code compiles and runs on both platforms; DTD validation is macOS-only (FCPXMLStructuralValidator used on iOS).

---

## Common Tasks

Adding new features: create feature branch; implement functionality with tests; update documentation; ensure all tests pass; create pull request.

Bug fixes: create bugfix branch; implement fix with regression tests; update documentation if needed; ensure all tests pass; create pull request.

Performance improvements: measure current performance; implement improvements; add performance tests; measure improvement; document changes.

---

## Code Generation Guidelines

When generating code: follow existing patterns and conventions; include comprehensive tests; add proper documentation; ensure concurrency compliance; validate against project requirements.

Code review process: review for Swift 6.0 compliance; check concurrency implementation; validate error handling; ensure test coverage; verify documentation quality.

---

## Documentation Sync

Keep AGENT.md and .cursorrules in sync. Both must reflect: changelog styling (CHANGELOG.md: Keep a Changelog format, version links to release tags, ✨ New Features / 🔧 Improvements / 🐛 Bug Fixes).

- Project overview and codebase rewrite/refactor.
- Architecture (protocols, implementations, extensions, service, utilities) and single injection point (FCPXMLUtility.defaultForExtensions).
- Source layout (Analysis, Classes, Delegates, Errors, Extensions including +Modular and +Codable, Implementations, Protocols, Services, Utilities, Annotations, Export, Timeline, Timing, Validation, FileIO, Logging, Format, Model including Adjustments, Animations, Filters, Clips with +Adjustments and +Typed, CommonElements with TextStyle/TextStyleDefinition, Structure with CollectionFolder/KeywordCollection/SmartCollection, Parsing, Extraction, FCPXML DTDs).
- Test structure (Tests/ layout, TestResources, FCPXMLTestUtilities, FileTests/ including FCPXMLFileTest_360Video, FCPXMLFileTest_AuditionSample, FCPXMLFileTest_ImageSample, FCPXMLFileTest_Multicam, FCPXMLFileTest_Photoshop, FCPXMLFileTest_SmartCollection, LogicAndParsing/ including FCPXMLFormatAssetTests, CutDetectionTests, VersionConversionTests, MediaExtractionTests, TimelineManipulationTests, FCPXMLTimecodeTests, MIMETypeDetectionTests, AssetValidationTests, SilenceDetectionTests, AssetDurationMeasurementTests, ParallelFileIOTests, AudioEnhancementTests, Transform360Tests, CaptionTitleTests, KeyframeAnimationTests, AudioKeyframeTests, CMTimeCodableTests, CollectionTests, SmartCollectionTests, PipelineNeoTests.swift, TimelineExportValidationTests, APIAndEdgeCaseTests, FCPXMLPerformanceTests; empty timeline creation and project-creation export at different sizes and frame rates in TimelineExportValidationTests (clip-level metadata export, XML declaration standalone="no"); 686 tests). Cross-platform XML (PNXML*, Foundation vs AEXML, FCPXMLStructuralValidator, iOS).
- FCPXML 1.5–1.14 and FCPXMLElementType; FCPXMLVersion.supportsBundleFormat (1.10+); version conversion with element stripping and per-version DTD validation; FCPXML creation from scratch; timeline manipulation (ripple insert, auto lane assignment, clip queries, lane range, secondary storylines); timeline metadata (markers, chapter markers, keywords, ratings, timestamps); FCPXMLTimecode custom type; MIME type detection; asset validation (including still images); silence detection; asset duration measurement; parallel file I/O; TimelineFormat enhancements; typed adjustment models (Crop, Transform, Blend, Stabilization, Volume, Loudness, NoiseReduction, HumReduction, Equalization, MatchEqualization, Transform360, ColorConform, Stereo3D, VoiceIsolation); typed effect/filter models (VideoFilter, AudioFilter, VideoFilterMask, FilterParameter with keyframe animation and auxValue 1.11+); typed caption/title models (Caption, Title with TextStyle, TextStyleDefinition); smart collections (SmartCollection with match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type); keyframe animation (KeyframeAnimation, Keyframe, FadeIn, FadeOut); audio keyframes (AudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration); CMTime Codable extension; collection organization (CollectionFolder, KeywordCollection); Live Drawing (1.11+); HiddenClipMarker (1.13+); Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps); experimental CLI (pipeline-neo, single binary, embedded DTDs, --check-version, --convert-version, --extension-type fcpxml|fcpxmld, --validate, --media-copy, --create-project with DTD validation and FCP-style output, --log/--log-level/--quiet with log file capturing all command output); Final Cut Pro frame rates; Swift 6 concurrency (Sendable, async/await, CI strict-concurrency job); Xcode 26 dynamic framework linking compatibility via explicit `swift-log` (`Logging`) dependency in `Package.swift`.

When updating either file, apply the same information to both and keep terminology and examples consistent.

---

## External References

External: Final Cut Pro XML (fcp.cafe/developers/fcpxml/), SwiftTimecode (github.com/orchetect/swift-timecode), Swift Concurrency (docs.swift.org). Internal: Package.swift, README.md, .cursorrules, CHANGELOG.md, Tests/README.md, Documentation/Manual.md.

---

## Maintenance

Regular tasks: update dependencies as needed; review and update documentation; monitor test coverage; address warnings or deprecations; keep build configuration current.

Long-term: plan for future Swift versions; consider new FCPXML versions; monitor SwiftTimecode updates; plan for platform changes; maintain backward compatibility where possible.
