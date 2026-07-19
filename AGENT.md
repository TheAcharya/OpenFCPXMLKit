# OpenFCPXMLKit — AI Agent Development Guide

OpenFCPXMLKit is a modern, fully modular Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration. The codebase underwent a complete rewrite and refactor: it is now 100% protocol-oriented, with all major operations defined as protocols and implemented via dependency injection for maximum flexibility, testability, and future-proofing. This guide is for AI agents and contributors working on the project.

Keep this file in sync with `.cursorrules`. Both should describe the same overview, architecture, test structure, and conventions. When you update one, update the other.

**Hard constraints:** [GUARDRAILS.md](GUARDRAILS.md) — must / must-not for layers, naming, FCPXML compatibility, reporting honesty, and fixtures. Prefer GUARDRAILS for “what not to do”; [ARCHITECTURE.md](ARCHITECTURE.md) for structure and diagrams; [Documentation/Coverage.md](Documentation/Coverage.md) for element / layer inventory matrices.

**Naming:** Use OpenFCPXMLKit naming exclusively in all code, documentation, comments, and agent files (`ServiceLogger`, `createService()`, `OFKXML*` types). Do not use legacy project names or identifiers from prior forks. Never use the terms "PBF" or "Production's Best Friend" in source code, code comments, symbol names, or CLI/log output; describe the reporting feature neutrally (e.g. "Excel report", "PDF report", "role inventory report", "workbook export"). Those terms may appear only in prose documentation (README, CHANGELOG, Manual, and these agent guides) — never in the codebase itself.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Codebase Rewrite and Refactor](#codebase-rewrite-and-refactor)
- [Architecture Guidelines](#architecture-guidelines)
- [Modularity and Safety](#modularity-and-safety)
- [Development Patterns](#development-patterns)
- [Code Style and Formatting](#code-style-and-formatting)
- [File Organisation](#file-organisation)
- [Test Structure](#test-structure)
- [Dependencies](#dependencies)
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

OpenFCPXMLKit targets macOS 26+, iOS 26+, Xcode 26+, and Swift 6.3 with full concurrency support. It provides FCPXML parsing, creation, and manipulation with timecode operations via SwiftTimecode. All core behaviour is behind protocols with both synchronous and async/await APIs; default implementations exist but any component can be swapped or extended via dependency injection.

**Backward compatibility:** The entire codebase must remain backward compatible with FCPXML 1.5. Optional attributes and elements introduced in later versions (e.g. 1.11, 1.13) must be omitted or ignored when reading/writing or converting to 1.5; mark such features in code comments with the minimum FCPXML version (e.g. `FCPXML 1.13+`).

Current status: **1114** tests listed in `swift test list` (**1108** in `OpenFCPXMLKitTests` + **6** optional `ExcelReportTest`; all Swift Testing `@Test`); FCPXML versions 1.5–1.14 supported (DTDs included, full parsing, typed element-type coverage for all DTD elements via FCPXMLElementType); Final Cut Pro frame rates (23.976, 24, 25, 29.97, 30, 50, 59.94, 60); thread-safe and concurrency-compliant with comprehensive async/await support; no known security vulnerabilities. Version conversion automatically drops elements not in the target version’s DTD (e.g. adjust-colorConform, adjust-stereo-3D); DTD validation runs per version (validateDocumentAgainstDTD, validateDocumentAgainstDeclaredVersion) and after CLI convert. FCPXMLVersion.supportsBundleFormat is true for 1.10+ (.fcpxmld bundle); 1.5–1.9 support only single-file .fcpxml. FCPXML creation: create FCPXML documents from scratch with events, projects, resources, and clips via XMLDocumentManager, XMLDocument initializers, or FCPXMLService. Timeline manipulation: ripple insert (shifts subsequent clips), auto lane assignment, clip queries (by lane, time range, asset ID), lane range computation, secondary storylines. Timeline metadata: markers, chapter markers, keywords, ratings, custom metadata, timestamps (createdAt, modifiedAt). FCPXMLTimecode: custom timecode type (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing). MIME type detection, asset validation, silence detection, asset duration measurement, parallel file I/O, still image asset support. TimelineFormat enhancements: presets (hd720p, dci4K, hd1080i, hd720i), computed properties (aspectRatio, isHD, isUHD, interlaced). Typed adjustment models: Crop, Corners, Transform, Blend, Stabilization, Volume, Panner, Loudness, NoiseReduction, HumReduction, Equalization, MatchEqualization, Transform360, ColorConform, Stereo3D, VoiceIsolation with full clip integration. Typed effect/filter models: VideoFilter, AudioFilter, VideoFilterMask with FilterParameter support and keyframe animation (auxValue support FCPXML 1.11+). Typed caption/title models: Caption and Title with TextStyle and TextStyleDefinition for full text formatting. SmartCollection models: SmartCollection with match-clip, match-media, match-ratings, match-text, match-usage (1.9+), match-representation (1.10+), match-markers (1.10+), match-analysis-type (1.14). Keyframe animation: KeyframeAnimation, Keyframe with interpolation types, FadeIn/FadeOut with fade types, integrated with FilterParameter. CMTime Codable extension: Direct CMTime encoding/decoding as FCPXML time strings. Collection organization: CollectionFolder and KeywordCollection models for organizing clips and media. Live Drawing (FCPXML 1.11+): LiveDrawing model for live-drawing story elements. HiddenClipMarker (FCPXML 1.13+): HiddenClipMarker model for hidden clip markers. Format/Asset 1.13+: Format heroEye, Asset heroEyeOverride, Asset mediaReps (multiple media-rep). Cross-platform XML abstraction: protocol layer (OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLFactory); Foundation backend on macOS (unchanged behaviour); AEXML backend on iOS; OFKXMLDefaultFactory() for platform dispatch; FCPXMLStructuralValidator for cross-platform structural validation; FCPXMLDTDValidator is platform-conditional (full DTD on macOS, structural fallback on iOS). Comprehensive test coverage: **1108** tests across 60 FCPXML sample files including 360 video, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes (FCPXMLAudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration, secondary storyline detection), keyword collections/folders, Photoshop integration, smart collections, and reporting column layout/exclusion/disabled-clip/workbook/PDF formatting tests. Excel and PDF reporting: multi-sheet `.xlsx` workbooks via `FinalCutPro.FCPXML.buildReport(options:)` (ReportBuilder, ReportOptions presets, ReportExcelExport on XLKit) and optional `.pdf` via `ReportPDFExport` (CoreGraphics; cover page with black “About This PDF Export” + `info.circle`, TOC with accent colour chips + content-tint washes, per-sheet tints, column-width expansion after exclusions, section pagination; same Report configuration as Excel); sheets for Role Inventory (**Selected Roles Inventory** + per-role sheets with expanded column layout and dynamic metadata keys), Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, **Summary** (project title in **B1**, narrow Row column A, black role-duration data), and **Media Summary** (Row + red missing-media paths); 1-based **Row** on all tabular Excel/PDF sheets by default (`ensuringRowColumn` / `allowsInjectedRowColumn`); inventory and section-sheet cell formatting, role exclusions, global column exclusion (`ReportColumn` / `excludedColumns`, including `ReportColumn.row`), disabled-clip filtering (`excludeDisabledClips`), project-name / compound-clip-name filtering (`allReportTimelineSources()`; standalone compound-clip exports without `<project>`), `ReportTimecodeFormat` / `--timecode-format`, inventory-first `ReportBuildPhase` progress callbacks; optional `copyrightLabel` / CLI `--label-copyright` (Excel cover **A2**; PDF cover + footer centre). Extraction presets: Captions, Effects, FrameData, Markers, Roles, Titles. Experimental CLI (OpenFCPXMLKit-CLI): single binary with embedded DTDs; --check-version, --convert-version (stripping + DTD validation), --extension-type (fcpxmld | fcpxml; default fcpxmld; 1.5–1.9 always .fcpxml), --validate, --media-copy, --create-project (new empty FCPXML project: --width, --height, --rate, --project-version, output-dir; DTD validation before write; FCP-style output with DOCTYPE, colorSpace, default smart collections), --report (Excel report: role inventory by default; --report-full, per-section flags including --report-markers, --report-keywords, --report-titles-generators, --report-transitions, --report-effects, --report-speed-change-effects, --report-summary, --report-media-summary, --media-resolution, --media-summary-distinguish-proxy, --exclude-role, --exclude-column, --exclude-disabled-clips, --include-markers-outside-clip-boundaries, --protect-sheets, --timecode-format, --report-project, --label-copyright, --create-pdf); --log writes user-visible output for all commands to the log file; see Sources/OpenFCPXMLKitCLI/README.md.

Xcode 26 dynamic linking compatibility: `swift-log` (`Logging`) is an explicit direct dependency in `Package.swift` to satisfy stricter transitive dylib linking rules when building OpenFCPXMLKit as a dynamic framework.

---

## Codebase Rewrite and Refactor

The project was fully rewritten and refactored to achieve:

- A protocol-oriented design: parsing, timecode conversion, XML manipulation, error handling, MIME type detection, asset validation, silence detection, asset duration measurement, and parallel file I/O are defined as protocols (e.g. FCPXMLParsing, TimecodeConversion, XMLDocumentOperations, ErrorHandling, MIMETypeDetection, AssetValidation, SilenceDetection, AssetDurationMeasurement, ParallelFileIO) with sync and async/await methods.
- A single injection point for extension APIs that cannot take parameters: `FCPXMLUtility.defaultForExtensions` (concurrency-safe). No hidden concrete types in extensions; for custom services use the modular API with the `using:` parameter.
- Consistent source layout: Analysis, Classes, Delegates, Errors, Extensions (including +Modular and +Codable), Implementations, Protocols, Services, Utilities, Annotations, Export, Timeline, Timing, Validation, FileIO, Logging, Format, Model (with subfolders), Parsing, Extraction, Projection (TimelineProjector / MulticamProjection / RefClipProjection), Authoring (detached `FinalCutPro.FCPXML.Authoring` value graph), **Reporting** (including **Excel/** for XLKit workbook export and **PDF/** for CoreGraphics PDF export), **XML** (Protocols: OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLDTDProtocol, OFKXMLFactory; Foundation/: Foundation backends; AEXML/: AEXML backends; OFKXMLDefaultFactory), and FCPXML DTDs.
- A structured test suite: shared resources, file tests per sample, logic/parsing tests, timeline/export/validation tests, API and edge-case tests, and performance tests, all documented in Tests/README.md.

Foundation XML types (XMLDocument, XMLElement) and the protocol types that wrap them (OFKXMLDocument, OFKXMLElement) and SwiftTimecode types are not Sendable. The codebase avoids Task-based concurrency for these types but provides async/await APIs that are concurrency-safe for Swift 6. If these dependencies become Sendable in the future, further parallelisation can be introduced.

---

## Architecture Guidelines

- Protocols: Core operations are defined as protocols with both sync and async/await methods. Default implementations are provided; components can be swapped via dependency injection. Protocols include: FCPXMLParsing, TimecodeConversion, XMLDocumentOperations, ErrorHandling (sync-only, pure formatting), MIMETypeDetection, AssetValidation, SilenceDetection, AssetDurationMeasurement, ParallelFileIO, CutDetection, FCPXMLVersionConverting, MediaExtraction.
- Implementations: FCPXMLParser, TimecodeConverter, XMLDocumentManager, ErrorHandler, CutDetector, FCPXMLVersionConverter, MediaExtractor, MIMETypeDetector, AssetValidator, SilenceDetector, AssetDurationMeasurer, ParallelFileIOExecutor implement the protocols.
- Analysis: Cut detection (CutDetection protocol, CutDetector implementation) produces EditPoint and CutDetectionResult; classifies edit points by boundary type (hard cut, transition, gap) and source relationship (same-clip vs different-clips). FCPXMLService and FCPXMLUtility expose detectCuts(in:) and detectCuts(inSpine:) (sync and async).
- Version conversion: FCPXMLVersionConverting protocol and FCPXMLVersionConverter; convertToVersion(_:targetVersion:) sets root version, strips elements not in the target version’s DTD (e.g. adjust-colorConform, adjust-stereo-3D), and returns a copy; saveAsFCPXML(_:to:) saves as .fcpxml; saveAsBundle(_:to:bundleName:) saves as .fcpxmld (FCPXMLBundleExporter.saveDocumentAsBundle; only for document version 1.10 or higher; FCPXMLVersion.supportsBundleFormat is true for 1.10+). DTD validation: FCPXMLService.validateDocumentAgainstDTD(_:version:) and validateDocumentAgainstDeclaredVersion(_:); FCPXMLDTDValidator injectable; CLI convert runs validation after conversion and fails if invalid. CLI --extension-type (fcpxmld | fcpxml; default fcpxmld) controls convert output format; 1.5–1.9 always output .fcpxml. Async methods are concurrency-safe; Task-based concurrency is avoided for non-Sendable types. FCPXMLParser delegates URL loading to FCPXMLFileLoader for unified file/bundle handling and consistent parse options. TimecodeConverter guards against invalid/non-finite CMTime inputs.
- Media extraction: MediaExtraction protocol and MediaExtractor; extractMediaReferences(from:baseURL:) returns MediaExtractionResult (references from asset media-rep and locator resources; fileReferences for file URLs); copyReferencedMedia(from:to:baseURL:) copies file references to a directory with deduplication and unique filenames, returning MediaCopyResult (copied, skipped, failed). FCPXMLService and FCPXMLUtility expose both (sync and async).
- Extensions: Modular extensions for CMTime, XMLElement, and XMLDocument support dependency-injected operations and async/await. Extension APIs that cannot take parameters use FCPXMLUtility.defaultForExtensions (e.g. CMTime.fcpxmlString delegates to FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime:)).
- Service: FCPXMLService orchestrates modular components for high-level workflows (sync and async). FCPXMLUtility is the legacy/convenience facade; FCPXMLService is the modern DI facade. Both delegate timecode operations to TimecodeConverter.
- Utilities: ModularUtilities provides service creation (createService, createCustomService), validation (validateDocument delegates to FCPXMLValidator for semantic checks; the `parser:` parameter is deprecated), and helpers (processFCPXML, processMultipleFCPXML — the `errorHandler:` parameter is deprecated — and convertTimecodes using TimecodeConversion and FCPXMLTimeStringConversion protocols). For per-version DTD validation use FCPXMLService.validateDocumentAgainstDTD(_:version:) or validateDocumentAgainstDeclaredVersion(_:).
- Logging: ServiceLogger protocol with levels trace, debug, info, notice, warning, error, critical (ServiceLogLevel); NoOpServiceLogger, PrintServiceLogger, FileServiceLogger (file + optional console, quiet). FCPXMLUtility and FCPXMLService use injected logger for parse, conversion, validation, save, and media operations. CLI: --log, --log-level, --quiet; when --log is set, all CLI commands (check-version, convert-version, validate, media-copy, create-project) write their user-visible messages to the log file. Extension types use #if canImport(Logging) as fallback where DI is not available.
- Versioning: FCPXMLVersion (DTD validation, 1.5-1.14) and FinalCutPro.FCPXML.Version (parsing, 1.0-1.14) are bridged via .fcpxmlVersion, .dtdVersion, and init(from:) converters. init(from:) uses safe fallback to `.latest` instead of force unwrap.
- Errors: Module-scoped error types (FCPXMLError for parsing, FCPXMLLoadError for file I/O, FCPXMLExportError/FCPXMLBundleExportError for export, FinalCutPro.FCPXML.ParseError with LocalizedError). Parse failures from FCPXMLFileLoader surface as FCPXMLError.parsingFailed so consumers handle a single parse-error type. FCPXMLElementError uses String element names for Sendable compliance.
- Reporting: Excel and PDF report builders in `Reporting/` consume Extraction/Model and **Projection**; they map facts to row/section models and serialise to XLKit workbooks (`Reporting/Excel/` via `ReportExcelExport`) and CoreGraphics PDFs (`Reporting/PDF/` via `ReportPDFExport`). Build `Report` once with `FinalCutPro.FCPXML.buildReport(options:)`; export to Excel, PDF, or both with the same section flags, `excludedColumns`, `timecodeFormat`, `copyrightLabel`, and role/disabled-clip filtering. Timeline resolution: `allReportTimelineSources()` / `ReportTimelineSource`; `ReportOptions.projectName` / CLI `--report-project`. Build / progress order: `ReportBuildPhase.enabledPhases(for:)` (inventory-first). Shared row colours: `FCPXMLReportRowColorPolicy` (Excel and PDF). PDF presentation: black cover header band with white `info.circle` + “About This PDF Export” (`FCPXMLReportPDFCoverNotes`); TOC accent colour chips + content-tint washes keyed to `FCPXMLReportPDFSheetPlan` sequential `colorIndex`; remaining table columns expand to fill A4 landscape `contentWidth` via `FCPXMLReportPDFTableLayout` after packing/`excludedColumns` (pinned/injected **Row** honors `allowsInjectedRowColumn`). Support: `RoleInventoryColumnLayout`, `ReportColumnExclusion`, `ReportFormatting`, `FCPXMLReportWorkbookExporter` (Excel cell formatting). Extend Model/Parsing → Extraction → **Projection** before Reporting presentation. See ARCHITECTURE.md §2.7.
- **Timeline Projection:** Mid-layer under `Sources/OpenFCPXMLKit/Projection/` projecting sequences into playable `MediaUsageWindow`s (media channels, `LanePath`, `RetimingSegment` from identity or `timeMap` segments including reverse; conform-rate scale via shared table; nested spines / anchored children; J/L cuts; multicam / ref-clip / audition unfold; video/audio leaves with channel filtering). Role Inventory, Markers, Keywords, Titles & Generators, Transitions, Effects, Speed Change, Media Summary, and Summary consume shared `ReportProjectionContext` windows (projected once per timeline); `TimelineOccupancyIndex` supports overlap queries. Excel/PDF stay presentation-thin. Markers/Keywords/Titles/Transitions/Effects are Projection-first with Extraction fallback. See ARCHITECTURE.md §2.7 and Manual 12.

---

## Modularity and Safety

- All major functionality is protocol-based and dependency-injected, with both sync and async/await APIs.
- Code is Sendable where appropriate; `@unchecked Sendable` removed from delegates (AttributeParserDelegate, FCPXMLParserDelegate) since they are internal-only and used synchronously. The project builds and tests with Swift 6 strict concurrency (`-strict-concurrency=complete`). CI runs a job that enforces this.
- No known vulnerabilities in dependencies (including SwiftTimecode 3.1.2) as of July 2025. No unsafe pointers, dynamic code execution, or C APIs; concurrency is structured and type-safe.

---

## Development Patterns

Use Swift 6.3 syntax and features. Use async/await for asynchronous operations; all major operations have async/await APIs. Use structured concurrency (Task, TaskGroup) only where types are Sendable; for Foundation XML and SwiftTimecode types, provide async APIs without Task-based concurrency. Use @unchecked Sendable for classes that cannot be made final; avoid capturing non-Sendable types in concurrent contexts.

Error handling: use Swift Result for operations that can fail; provide meaningful errors; use do-catch for sync and propagate FCPXMLError in async. Use strongly typed enums for FCPXML elements (FCPXMLElementType) and type-safe timecode operations; avoid force unwrapping.

---

## Code Style and Formatting

Follow Swift API Design Guidelines. Use camelCase for variables and functions, PascalCase for types and protocols, descriptive names for all identifiers. Include comprehensive /// doc comments for all public APIs; document parameters, return values, and exceptions; provide usage examples. Group related functionality in extensions; keep files focused on single responsibilities; use clear file names and logical imports.

### File Header

All new Swift files must use this exact header format:

```
//
//  FileName.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
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
- Do not add `//  OpenFCPXMLKit`, `Created by`, or `Copyright ©` lines.

---

## File Organisation

Source layout under Sources/OpenFCPXMLKit/:

- Analysis: EditPoint (edit type, source relationship), CutDetectionResult (edit points and counts).
- Classes: FinalCutPro (namespace enum), FCPXML (core struct, init, properties including `allProjects`, `allTimelines`, `allReportTimelineSources` / `ReportTimelineSource` for project + standalone compound-clip report timelines), FCPXMLRoot, FCPXMLRootVersion, FCPXMLElementType, FCPXMLUtility, FCPXMLVersion, FCPXMLVersionFeatureGate (shared DTD feature introductions; Authoring omit-on-write + converter fallback).
- Authoring: Detached (non-live) document value graph under `FinalCutPro.FCPXML.Authoring` — `Document`, `Resources` (Format/Asset/Effect/Media), story (`Library`→`Spine`), `SpineItem` (asset-clip, gap, title, transition, video, audio, caption, sync-clip, ref-clip, mc-clip, audition), `VersionAvailability` omit-on-write. Parallel to live Model/ and Timeline Export; do not use inside Reporting. See Manual 08.
- XML: Platform-agnostic XML layer — Protocols (OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLDTDProtocol, OFKXMLFactory), Foundation/ (FoundationXMLElement, FoundationXMLDocument, FoundationXMLDTD, FoundationXMLFactory), AEXML/ (AEXMLBackendElement, AEXMLBackendDocument, AEXMLBackendFactory), OFKXMLDefaultFactory (platform dispatch: Foundation on macOS, AEXML on iOS).
- Delegates: AttributeParserDelegate (property: `values`), FCPXMLParserDelegate (properties: `roles`, `resourceIDs`, `textStyleIDs`; O(1) deduplication via Set).
- Errors: FCPXMLError, FCPXMLParseError, TimelineError.
- Extensions: CMTime+Modular, CMTimeExtension, CMTime+Codable, XMLDocument+Modular, XMLDocumentExtension, XMLElement+Modular, XMLElementExtension (FCPXML extensions operate on OFKXMLDocument/OFKXMLElement protocol types).
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
- Media: MediaReference, MediaExtractionResult, MediaCopyResult.
- Logging: ServiceLogger, ServiceLogLevel (trace–critical), NoOpServiceLogger, PrintServiceLogger, FileServiceLogger.
- Format: ColorSpace.
- Model: FCPXML element models for the parsing layer (previously nested under FinalCutPro/FCPXML/). Subfolders: Adjustments (CropAdjustment, CornersAdjustment, TransformAdjustment, BlendAdjustment, StabilizationAdjustment, VolumeAdjustment, PannerAdjustment, LoudnessAdjustment, NoiseReductionAdjustment, HumReductionAdjustment, EqualizationAdjustment, MatchEqualizationAdjustment, Transform360Adjustment, ColorConformAdjustment, Stereo3DAdjustment, VoiceIsolationAdjustment), Animations (KeyframeAnimation, Keyframe, FadeIn, FadeOut, FadeType), Attributes (AudioLayout, AudioRate, ClipSourceEnable, FrameSampling, TimecodeFormat), Clips (AssetClip, Audio, Audition, Clip including Clip+Adjustments, Gap, MCClip, MulticamSource, RefClip, SyncClip, SyncSource, Title including Title+Typed, Transition, Video), CommonElements (AudioChannelSource, AudioRoleSource, ConformRate, MediaRep, Metadata, Text, TextStyle, TextStyleDefinition, TimeMap), ElementTypes (AnyElementModelType, ElementModelType, ElementType, protocols), Filters (VideoFilter, AudioFilter, VideoFilterMask, FilterParameter), Occlusion (ElementOcclusion, Element Occlusion), Protocols (FCPXMLElement, FCPXMLAttribute, element attribute/children/story protocols), Resources (Asset, Effect, Format, Locator, Media, MediaMulticam, ObjectTracker), Roles (AudioRole, CaptionRole, VideoRole, AncestorRoles, AnyRole, RoleType, FCPXMLRole), Structure (Event, Library, Project, CollectionFolder, KeywordCollection, SmartCollection). Root files: AnyTimeline, Caption including Caption+Typed, Keyword, Marker, Sequence, Spine.
- Parsing: XML parsing extensions (Attributes, Clip Parsing, Elements Parsing, Metadata Parsing, Resources Parsing, Roles Parsing, Root Parsing, Time and Frame Rate Parsing).
- Extraction: Element extraction logic. Subfolders: Context (DisplayClipName, ElementContext, ElementContextItems, ElementContextTools, FrameRateSource), Effects (EffectsCollector, ExtractedEffect), Presets (CaptionsExtractionPreset, EffectsExtractionPreset, FrameDataPreset, MarkersExtractionPreset, RolesExtractionPreset, TitlesExtractionPreset, FCPXMLExtractionPreset). Root files: Extract, ExtractableChildren, ExtractedElement, ExtractedElementStruct, ExtractedModelElement, Extraction, ExtractionScope.
- Projection: Timeline analysis mid-layer. `TimelineProjecting`, `TimelineProjector`, `TimelineProjectionOptions` (incl. `.trackAnalysis`), `MediaChannel`, `MediaUsageWindow`, `LanePath`, `RetimingSegment` (`clipped`, `composing`), `TimelineOccupancyIndex` (start-sorted overlap); Retiming/`TimeMap+RetimingSegments`, `ConformRate+Retiming`, `ClipRetiming`, `AudioSplitRetiming`; Walk/`AssetChannelExpansion`, `SpineProjection`, `ProjectionTiming`, `MulticamProjection`, `RefClipProjection`, `ChannelKindFilter`. Nested/multicam/ref/audition unfold + channel filtering. Reporting: `ReportProjectionContext` / `ReportBuilder` project-once for inventory, markers, keywords, titles, transitions, effects, speed-change, media summary, and summary. See ARCHITECTURE.md §2.7 and Manual 12.
- Authoring: Detached document value graph (`FinalCutPro.FCPXML.Authoring`) — `Document`, resources/story structs, `Element` encode protocol, `VersionAvailability` omit-on-write; parallel to live Model wrappers; not for Reporting.
- Reporting: Excel and PDF report export. Top-level: Report, ReportOptions (including `copyrightLabel`), ReportBuilder (resolves timelines via `allReportTimelineSources()` / `ReportTimelineSource`), ReportTimecodeFormat, ReportBuildProgress (`ReportBuildPhase.enabledPhases(for:)` — inventory-first). Subfolders: Builders (RoleInventory, Markers, Keywords, Titles, Transitions, Effects, SpeedChangeEffects, Summary, MediaSummary), Sections and Rows (typed section/row models with `columnHeaders(timecodeFormat:)`), Support (RoleInventoryClipCollector, RoleInventoryRowBuilder, RoleInventoryColumnLayout, RoleInventoryRoleSheetOrdering, RoleInventoryTimelineBounds, ReportFormatting, ReportRoleExclusion, ReportColumnExclusion (`ensuringRowColumn` / `allowsInjectedRowColumn`), ReportClipCategory, FCPXMLReportRowColorPolicy, EffectsReportPolicy, SpeedChangeFormatting, SummaryRoleDurationAggregator), Excel (ReportExcelExport, FCPXMLReportWorkbookExporter with Summary title in **B1**, cover **A1** branding / **A2** `copyrightLabel`, ReportWorkbookColumnAutoFit via XLKit — narrow Row column), PDF (ReportPDFExport, FCPXMLReportPDFExporter, FCPXMLReportPDFCanvas (cover black header + info.circle; branding + optional `copyrightLabel`; TOC accent chips + content-tint washes; footer centre copyright), FCPXMLReportPDFSheetPlan sequential `colorIndex` per sheet title, FCPXMLReportPDFTableLayout pack + expand columns to fill `contentWidth` after exclusions, FCPXMLReportPDFStyle, FCPXMLReportPDFCoverNotes). `Report.exportBrandingText` and `Report.copyrightLabel` for Excel cover and PDF cover/footer. Consumes Extraction and Projection; owns presentation only; see ARCHITECTURE.md §2.7.
- FCPXML DTDs: version 1.5-1.14 and README.

Maintain this structure; do not introduce new top-level categories without aligning both AGENT.md and .cursorrules.

---

## Test Structure

Tests live under Tests/. The suite is organised as follows.

- Tests/README.md: Full description of test categories, how to run tests (Swift PM, Xcode, Linux), sample files, frame rates, FCPXML versions, and contributing. Keep it current when adding or changing tests.

- Tests/FCPXML Samples/FCPXML/: Sample .fcpxml files (60 samples, e.g. 24.fcpxml, GeneralDemo.fcpxml, Structure.fcpxml, frame-rate samples). File tests and logic tests load these via `FCPXMLTestSampleLoading` / `FCPXMLTestingSampleSupport`; missing **bundled** samples **fail**; optional fixtures use `Test.cancel`.

- Tests/ExcelReportTest/: Optional Swift Testing integration target (**6** `@Test` methods). Writes `Output/OFK-Default.xlsx`, `Output/OFK-Full.xlsx`, `Output/OFK-Default.pdf`, `Output/OFK-ExcludedColumns.pdf`, `Output/OFK-Copyright.xlsx`, `Output/OFK-Copyright.pdf`, `Output/OFK-OutsideClipBoundaries.xlsx` / `.pdf`, and `Output/OFK-ProtectedSheets.xlsx` from a local `.fcpxml`/`.fcpxmld` fixture (`Sample.fcpxmld`, `OFK_REPORTING_FCPXML_BUNDLE`, or auto-discovery including under `Output/`). **Cancels** via `Test.cancel` when no fixture is present. See Tests/ExcelReportTest/README.md.

- Tests/Submitted FCPXML/: Private local inbox for user-supplied FCPXML (`Inbox/`, `Notes/`). Contents are **gitignored** (never commit or push to GitHub); only `README.md` and `.gitkeep` placeholders are tracked. Workflow: drop private export → anonymise → reproduce → fix Parsing/Projection/Reporting → promote a **minimal anonymised** fixture into `FCPXML Samples/` when useful. Optional smoke: `FCPXMLSubmittedFCPXMLSmokeTests` (Test.cancel when Inbox empty). See Tests/Submitted FCPXML/README.md and Tests/README.md.

- Tests/OpenFCPXMLKitTests/: Test code.
  - FCPXMLTestResources.swift: Path resolution (packageRoot, fcpxmlSamplesDirectory, urlForFCPXMLSample, FCPXMLSampleName) so samples work from Xcode and `swift test`.
  - FCPXMLTestSampleLoading.swift / FCPXMLTestingSampleSupport.swift: tryLoad* / require*; fcpxmlFrameRateSampleNames, allFCPXMLSampleNames(); bundled samples fail if missing; optional fixtures use Test.cancel.
  - FCPXMLReportingReportFixture.swift, FCPXMLReportingReportTestSupport.swift: Optional reporting integration fixture (loads a .fcpxmld via OFK_REPORTING_FCPXML_BUNDLE, Test.cancel when unset) and shared structural assertions (timecode values / format-aware headers / sort / checkmark).
  - FCPXMLCutDetectionTests.swift: Cut detection (same-clip vs different-clips, boundary types, Example FCPXML Cut 1/Cut 2, 24.fcpxml, empty spine, async, CutSample file test).
  - FCPXMLTimelineProjectionTests.swift: Timeline Projection (identity + `timeMap`; nested lanes; J/L cuts; multicam / ref-clip / audition; video/audio leaves; SyncClip/24 sample regression; report project-once for inventory/markers/keywords/titles/transitions/effects/speed/media summary/summary; disabled filtering; streaming parity).
  - FCPXMLProjectionCoverageTests.swift / FCPXMLParsingCoverageTests.swift / FCPXMLEngineHygieneTests.swift / FCPXMLReportObligationCorpusTests.swift / FCPXMLExtractionNestFidelityTests.swift / FCPXMLMarkersKeywordsProjectionTests.swift / FCPXMLTitlesProjectionTests.swift / FCPXMLTransitionsProjectionTests.swift / FCPXMLEffectsProjectionTests.swift: Projection geometry, parsing coverage, engine hygiene, reporting contracts, Extraction↔Projection policy, Projection-first report sections.
  - FCPXMLVersionConversionTests.swift: Version conversion (convert to target version, element stripping for 1.10/1.12, save as .fcpxml, save as .fcpxmld with 1.10+ check, bundle error when < 1.10, async).
  - FCPXMLTimelineManipulationTests.swift: Timeline manipulation (ripple insert, auto lane assignment, clip queries, lane range, timestamps, metadata).
  - FCPXMLTimecodeTests.swift: FCPXMLTimecode (initialization, arithmetic, comparison, CMTime conversion, frame alignment, hashing, codable).
  - FCPXMLMIMETypeDetectionTests.swift: MIME type detection (sync and async detection for various file types).
  - FCPXMLAssetValidationTests.swift: Asset validation (asset existence, lane compatibility, TimelineClip integration).
  - FCPXMLSilenceDetectionTests.swift: Silence detection (silence detection at start/end of audio files).
  - FCPXMLAssetDurationMeasurementTests.swift: Asset duration measurement (duration measurement for audio/video/images).
  - FCPXMLParallelFileIOTests.swift: Parallel file I/O (concurrent read/write operations).
  - FCPXMLAudioEnhancementTests.swift: Audio enhancement models (NoiseReduction, HumReduction, Equalization, MatchEqualization, Clip integration).
  - FCPXMLTransform360Tests.swift: Transform360 adjustment (coordinate types, spherical/cartesian, clip integration).
  - FCPXMLCaptionTitleTests.swift: Caption and Title models (TextStyle, TextStyleDefinition, Caption/Title integration).
  - FCPXMLKeyframeAnimationTests.swift: Keyframe animation (FadeIn, FadeOut, Keyframe, KeyframeAnimation, FilterParameter integration).
  - FCPXMLCMTimeCodableTests.swift: CMTime Codable extension (encoding/decoding FCPXML time strings).
  - FCPXMLCollectionTests.swift: Collection organization (CollectionFolder, KeywordCollection, nested structures).
  - FCPXMLSmartCollectionTests.swift: SmartCollection models, match rules (MatchUsage, MatchRepresentation, MatchMarkers, MatchAnalysisType), round-trip, version stripping.
  - FCPXMLAdjustmentTests.swift: Typed adjustment models (Crop, Transform, Volume, ColorConform, Stereo3D, VoiceIsolation, etc.) and clip integration.
  - FCPXMLFilterTests.swift: VideoFilter, AudioFilter, VideoFilterMask, FilterParameter parsing and integration.
  - FCPXMLImportOptionsTests.swift: Import options and library location parsing.
  - FCPXMLCodableTests.swift: Codable round-trip for FCPXML model types.
  - FCPXMLMediaExtractionTests.swift: Media reference extraction and copy (CLI --media-copy flow).
  - FCPXMLDTDValidatorTests.swift: Per-version DTD validation.
  - FCPXMLStructuralValidatorTests.swift: Cross-platform structural validation (iOS fallback path).
  - FCPXMLAEXMLSerializationParityTests.swift: AEXML vs Foundation XML serialization parity.
  - Report and extraction tests (FCPXML-prefixed): FCPXMLCompoundClipReportTests, FCPXMLRoleInventoryReportTests, FCPXMLRoleInventoryColumnLayoutTests, FCPXMLMarkersReportTests, FCPXMLKeywordsReportTests, FCPXMLTitlesReportTests, FCPXMLTransitionsReportTests, FCPXMLEffectsReportTests, FCPXMLSpeedChangeEffectsReportTests, FCPXMLSummaryReportTests, FCPXMLReportExcelExportTests, FCPXMLReportPDFExportTests, FCPXMLReportPDFSheetPlanTests, FCPXMLReportPDFTableLayoutTests, FCPXMLReportFormattingTests, FCPXMLReportRoleExclusionTests, FCPXMLReportTimecodeFormatTests, FCPXMLReportBuildPhaseTests, FCPXMLReportColumnExclusionTests, FCPXMLReportExcludeDisabledClipsTests, FCPXMLRoleDisplayPreferenceTests, FCPXMLRoleInventoryClipCollectorTests, FCPXMLRoleInventoryRoleSheetOrderingTests, FCPXMLSummaryRoleDurationAggregatorTests, FCPXMLEffectsReportPolicyTests, FCPXMLSpeedChangeFormattingTests, FCPXMLDisplayClipNameTests, FCPXMLTitleDisplayTests, FCPXMLExtractionScopeTests, FCPXMLExtractedElementTests, FCPXMLEffectsCollectorTests, FCPXMLRolesExtractionPresetTests, FCPXMLEffectAppleSuppliedTests, FCPXMLClipParsingCarriesAudioTests, FCPXMLTransformAdjustmentParsingTests, FCPXMLTransitionSpinePlacementTests.
  - OpenFCPXMLKitTests.swift: Main `@Suite("OpenFCPXMLKit")`; dependencies (parser, timecodeConverter, documentManager, errorHandler, FCPXMLUtility, FCPXMLService) created in `init()`. MARK comments group tests (FCPXMLUtility, FCPXMLService, modular components, async/concurrency, performance, frame rates, time values, FCPXML time strings, time conforming, error handling, document management, element filtering, modular extensions, edge cases, FCPXMLElementType, FCPXMLError, ModularUtilities API, XMLDocument extension, XMLElement extension, parser filter).
  - FileTests/: One test class per sample or category (e.g. FCPXMLFileTest_24, FCPXMLFileTest_AllSamples, FCPXMLFileTest_FrameRates, FCPXMLFileTest_GeneralDemo, FCPXMLFileTest_HiddenMarkers, FCPXMLFileTest_360Video, FCPXMLFileTest_AuditionSample, FCPXMLFileTest_ImageSample, FCPXMLFileTest_Multicam, FCPXMLFileTest_Photoshop, FCPXMLFileTest_SmartCollection). Each loads one or more samples and asserts parse success, root, version, events, projects, or resources as appropriate.
  - FCPXMLSubmittedFCPXMLSmokeTests: Optional parse smoke for private files in `Tests/Submitted FCPXML/Inbox/` (Test.cancel when empty; CI-safe).
  - FCPXMLAudioKeyframeTests: Audio keyframes in adjust-volume (param name="amount" with keyframeAnimation); parsing from FCPXML samples; decibel values (-3dB, -37dB); time values (FCPXML fractional format); fadeIn/fadeOut integration; multiple keyframes in sequence; secondary storyline and nested clip detection; TimelineWithSecondaryStorylineWithAudioKeyframes, TimelineSample file tests.
  - LogicAndParsing/: FCPXMLRootVersionTests (Version init, rawValue, Equatable, Comparable, invalid strings), FCPXMLStructureTests (Structure sample, allEvents/allProjects, root structure), FCPXMLFormatAssetTests (Format heroEye, Asset heroEyeOverride, Asset mediaReps).
  - FCPXMLTimelineManipulationTests: Ripple insert, auto lane assignment, clip queries, lane range, timestamps, metadata, secondary storylines, audio keyframes; injectable "now" for timestamp tests via lock-based NowBox (no DispatchSemaphore); do-catch for insertClipAutoLane/insertingClipAutoLane to verify success.
  - FCPXMLTimelineExportValidationTests: Timeline and TimelineClip, FCPXMLExporter (empty timeline creation and project-creation export at different sizes and frame rates; includeDefaultSmartCollections and DTD validation; clip-level metadata export tests; XML declaration standalone="no"), FCPXMLBundleExporter, FCPXMLValidator, FCPXMLDTDValidator, FCPXMLService.validateDocumentAgainstDTD/validateDocumentAgainstDeclaredVersion (per-version), FCPXMLFileLoader.
  - FCPXMLAPIAndEdgeCaseTests: FCPXMLFileLoader async load(from:), ServiceLogger injection (NoOp, Print), edge cases (empty/invalid/malformed XML, invalid paths), validation types, Live Drawing (1.11+), HiddenClipMarker (1.13+).
  - FCPXMLPerformanceTests: Performance smoke (`ContinuousClock` sanity budgets for parse / load / project — hang guards, not XCTest baselines).

Test organisation: use descriptive `@Test` names; group related tests in `@Suite`s; use meaningful `#expect` / `#require` assertions. The suite is **Swift Testing only** (no XCTest). Test all supported frame rates (Final Cut Pro compatible). Use realistic FCPXML samples and edge cases; validate against actual FCP behaviour where applicable. Current total: **1114** tests listed in `swift test list` (**1108** in `OpenFCPXMLKitTests` + **6** optional `ExcelReportTest`) covering all functionality including async/await, timeline manipulation, metadata, timestamps, FCPXMLTimecode, MIME type detection, asset validation, silence detection, asset duration measurement, parallel file I/O, cut detection, version conversion stripping, per-version DTD validation, extract-then-copy (CLI --media-copy flow), synchronized clip matching, secondary storyline traversal, clip identification, URL resolution, version conversion edge cases, typed adjustment models (including Transform360, ColorConform, Stereo3D, VoiceIsolation), typed effect/filter models, typed caption/title models, smart collections (match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type), keyframe animation, audio keyframes (FCPXMLAudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration), CMTime Codable extension, collection organization, Live Drawing (1.11+), HiddenClipMarker (1.13+), Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps), FCPXMLExporter clip-level metadata export and XML declaration standalone="no", FCPXMLTimelineManipulationTests refactor (lock-based NowBox, do-catch for throwing APIs), Excel reporting (Selected Roles Inventory column layout, Summary/Media Summary split, ReportTimecodeFormat / format-aware headers, inventory-first ReportBuildPhase progress, global column exclusion, disabled-clip filtering, workbook cell formatting via FCPXMLReportWorkbookExporter), 360 video features, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, and Photoshop integration.

---

## Dependencies

- SwiftTimecode 3.1.2+ for timecode operations.
- SwiftExtensions 3.0.0+ (orchetect/swift-extensions) for String, Collection, Optional, and `LazyCompactMapSequence` helpers where useful.
- SwiftSemanticVersion 1.0.0+ (orchetect/swift-semantic-version) for `FinalCutPro.FCPXML.Version` / `SemanticVersion` (extracted from SwiftExtensions in 3.0.0).
- swift-log 1.14.0+ (`Logging`) as an explicit direct dependency for Xcode 26 dynamic framework linking compatibility.
- AEXML 4.7.0+ (tadija/AEXML) for cross-platform XML parsing on iOS (OpenFCPXMLKit target only).
- Foundation for XML and data; CoreMedia for CMTime.

Swift 6.3+, Xcode 26.0+, macOS 26.0+, iOS 26.0+.

SwiftTimecode usage: use `Timecode(.realTime(seconds: seconds), at: frameRate)` (not the old realTime: at: initialiser). Use frame rate cases `.fps23_976`, `.fps24`, `.fps25`, `.fps29_97`, `.fps30`, `.fps50`, `.fps59_94`, `.fps60` (not the old ._24, ._25, etc.).

---

## Testing Requirements

Test coverage: unit tests for all public APIs; integration tests for complex workflows; performance tests for time-critical operations; concurrency tests for async operations; test all supported frame rates (Final Cut Pro compatible). Current: **1114** tests listed in `swift test list` (including AEXML serialization parity, FCPXMLDTDValidatorTests, FCPXMLStructuralValidatorTests, FCPXMLReportTimecodeFormatTests, FCPXMLReportBuildPhaseTests, FCPXMLReportColumnExclusionTests, FCPXMLReportExcludeDisabledClipsTests, FCPXMLRoleInventoryColumnLayoutTests, FCPXMLReportExcelExportTests workbook cell formatting, FCPXMLReportPDFExportTests PDF export, FCPXMLReportPDFSheetPlanTests TOC colour-index parity, FCPXMLReportPDFTableLayoutTests column-width expansion, optional ExcelReportTest integration) covering all functionality including async/await, timeline manipulation, metadata, timestamps, FCPXMLTimecode, MIME type detection, asset validation, silence detection, asset duration measurement, parallel file I/O, version conversion, DTD validation, extract-then-copy flow, synchronized clip matching, secondary storyline traversal, clip identification, URL resolution, version conversion edge cases, typed adjustment models (including Transform360, ColorConform, Stereo3D, VoiceIsolation), typed effect/filter models, typed caption/title models, smart collections (match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type), keyframe animation, audio keyframes (FCPXMLAudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration), CMTime Codable extension, collection organization, Live Drawing (1.11+), HiddenClipMarker (1.13+), Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps), FCPXMLExporter clip-level metadata export and XML declaration standalone="no", FCPXMLTimelineManipulationTests (lock-based NowBox, do-catch), Excel reporting enhancements, PDF report export (TOC colour chips, column expansion after exclusions), 360 video features, auditions, conform-rate, still images, multicam, secondary storylines, audio keyframes, keyword collections/folders, and Photoshop integration.

Test data: use realistic FCPXML samples; include edge cases and error conditions; test all supported frame rates; validate against actual Final Cut Pro output where applicable.

Test organisation: descriptive `@Test` / `@Suite` names; group related tests logically; meaningful `#expect` / `#require` assertions.

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

- **Version heading:** `## [X.Y.Z](https://github.com/TheAcharya/OpenFCPXMLKit/releases/tag/X.Y.Z) - YYYY-MM-DD` — version number links to the GitHub release tag.
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

FCPXML handling: support FCPXML versions 1.5 through 1.14 (DTDs included; full parsing; typed element-type coverage via FCPXMLElementType for all DTD elements); validate against DTD schemas (FCPXMLDTDValidator, FCPXMLService.validateDocumentAgainstDTD/validateDocumentAgainstDeclaredVersion); version conversion (FCPXMLVersionConverter) sets root version and automatically strips elements not in the target version’s DTD (e.g. adjust-colorConform, adjust-stereo-3D); FCPXMLVersion.supportsBundleFormat is true for 1.10+ (save as .fcpxmld bundle); 1.5–1.9 support only .fcpxml; handle all supported frame rates (Final Cut Pro compatible); implement proper XML formatting. Media extraction: extract media references (asset media-rep src, locator url) and copy referenced file URLs to a destination directory (MediaExtraction protocol, MediaExtractor). Timeline manipulation: ripple insert (shifts subsequent clips), auto lane assignment (finds available lanes), clip queries (by lane, time range, asset ID), lane range computation, secondary storylines. Timeline metadata: markers, chapter markers, keywords, ratings, custom metadata on timeline and clips; timestamps (createdAt, modifiedAt) updated on all mutating operations. TimelineFormat: presets (hd720p, dci4K, hd1080i, hd720i), computed properties (aspectRatio, isHD, isUHD, interlaced). FCPXMLTimecode: custom timecode type wrapping Fraction (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing). MIME type detection: MIMETypeDetection protocol and MIMETypeDetector implementation (UTType, AVFoundation, file extension fallback). Asset validation: AssetValidation protocol and AssetValidator implementation (existence check, MIME type compatibility, lane rules: negative = audio only, non-negative = video/image/audio); still image asset support (duration=0s). Silence detection: SilenceDetection protocol and SilenceDetector implementation (configurable threshold and minimum duration). Asset duration measurement: AssetDurationMeasurement protocol and AssetDurationMeasurer implementation (AVFoundation-based for audio/video/images). Parallel file I/O: ParallelFileIO protocol and ParallelFileIOExecutor implementation (concurrent read/write operations). SmartCollection: SmartCollection model with match-clip, match-media, match-ratings, match-text, match-usage (1.9+), match-representation (1.10+), match-markers (1.10+), match-analysis-type (1.14); library and event integration. Live Drawing (1.11+): LiveDrawing model for live-drawing story elements. HiddenClipMarker (1.13+): HiddenClipMarker model for hidden clip markers. Format/Asset 1.13+: Format heroEye (left|right), Asset heroEyeOverride, Asset mediaReps (multiple media-rep). Excel and PDF reporting: multi-sheet `.xlsx` workbooks (`FinalCutPro.FCPXML.buildReport(options:)`, ReportBuilder, ReportOptions presets, ReportExcelExport on XLKit) with Role Inventory (**Selected Roles Inventory** + per-role sheets), Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, Summary (project title in **B1**, role durations), and Media Summary (missing media paths); universal **Row** via `ensuringRowColumn` / `allowsInjectedRowColumn`; role exclusions, global column exclusion (`excludedColumns` / `ReportColumn`), disabled-clip filtering (`excludeDisabledClips`), `ReportTimecodeFormat` / `--timecode-format` (SMPTE frames with DF/NDF, Frames, Feet+Frames, HH:MM:SS; format-aware headers; numeric sort for Frames/Feet+Frames), inventory-first `ReportBuildPhase.enabledPhases(for:)` progress, project-name filtering, and optional `copyrightLabel` / `--label-copyright` (Excel cover **A2**; PDF cover + footer centre); builders consume Extraction/Model and own presentation only (see ARCHITECTURE.md §2.7). Experimental CLI: OpenFCPXMLKit-CLI single binary (embedded DTDs) with --check-version, --convert-version (stripping + DTD validation), --extension-type fcpxml|fcpxmld (default fcpxmld; 1.5–1.9 always .fcpxml), --validate, --media-copy, --create-project (width, height, rate, project-version, output-dir; mandatory DTD validation; FCP-style DOCTYPE, format colorSpace, default smart collections), --report (Excel report: role inventory by default; --report-full, per-section flags including --report-summary and --report-media-summary, --media-resolution, --media-summary-distinguish-proxy, --exclude-role, --exclude-column, --exclude-disabled-clips, --include-markers-outside-clip-boundaries, --protect-sheets, --timecode-format, --report-project, --label-copyright, --create-pdf), and LOG options (--log, --log-level, --quiet; --log records user-visible output for all commands); see Sources/OpenFCPXMLKitCLI/README.md.

Timecode operations: use SwiftTimecode for all timecode operations; support all FCPXML frame rates (Final Cut Pro compatible); implement proper frame rate conversions; handle drop frame and non-drop frame timecode. FCPXMLTimecode provides a custom timecode type for FCPXML-specific operations (arithmetic, frame alignment, CMTime conversion, FCPXML string parsing).

Platform support: target macOS 26.0+ and iOS 26.0+; use Xcode 26.0+ features; implement Swift 6.3 concurrency; follow Apple platform guidelines. Use the OFKXML protocol layer (OFKXMLDocument, OFKXMLElement, OFKXMLDefaultFactory) so code compiles and runs on both platforms; DTD validation is macOS-only (FCPXMLStructuralValidator used on iOS).

---

## Common Tasks

Adding new features: create feature branch; implement functionality with tests; update documentation; ensure all tests pass; create pull request.

Bug fixes: create bugfix branch; implement fix with regression tests; update documentation if needed; ensure all tests pass; create pull request.

Performance improvements: measure current performance; implement improvements; add performance tests; measure improvement; document changes.

---

## Code Generation Guidelines

When generating code: follow existing patterns and conventions; include comprehensive tests; add proper documentation; ensure concurrency compliance; validate against project requirements.

Code review process: review for Swift 6.3 compliance; check concurrency implementation; validate error handling; ensure test coverage; verify documentation quality.

---

## Documentation Sync

Keep AGENT.md and .cursorrules in sync. Both must reflect: changelog styling (CHANGELOG.md: Keep a Changelog format, version links to release tags, ✨ New Features / 🔧 Improvements / 🐛 Bug Fixes). Hard must / must-not constraints live in **GUARDRAILS.md** (update Signs when a design lock or regression is learned — Sign: `swift-testing-only`; keep ARCHITECTURE.md for structure and mermaid).

- Project overview and codebase rewrite/refactor.
- Architecture (protocols, implementations, extensions, service, utilities) and single injection point (FCPXMLUtility.defaultForExtensions).
- Source layout (Analysis, Classes, Delegates, Errors, Extensions including +Modular and +Codable, Implementations, Protocols, Services, Utilities, Annotations, Export, Timeline, Timing, Validation, FileIO, Logging, Format, Model including Adjustments, Animations, Filters, Clips with +Adjustments and +Typed, CommonElements with TextStyle/TextStyleDefinition, Structure with CollectionFolder/KeywordCollection/SmartCollection, Parsing, Extraction, Projection (TimelineProjector / MulticamProjection / RefClipProjection / ChannelKindFilter), Reporting including Excel/ and PDF/, XML with Protocols/Foundation/AEXML/OFKXMLDefaultFactory, FCPXML DTDs; reporting vs core layers in ARCHITECTURE.md §2.7).
- Test structure (Tests/ layout — **Swift Testing only**, no XCTest; harness `FCPXMLTestResources` / `FCPXMLTestSampleLoading` / `FCPXMLTestingSampleSupport`; FileTests/ including FCPXMLFileTest_GeneralDemo, FCPXMLFileTest_HiddenMarkers, FCPXMLFileTest_360Video, FCPXMLFileTest_AuditionSample, FCPXMLFileTest_ImageSample, FCPXMLFileTest_Multicam, FCPXMLFileTest_Photoshop, FCPXMLFileTest_SmartCollection, LogicAndParsing/ including FCPXMLFormatAssetTests, FCPXMLCutDetectionTests, FCPXMLVersionConversionTests, FCPXMLMediaExtractionTests, FCPXMLTimelineManipulationTests, FCPXMLTimecodeTests, FCPXMLMIMETypeDetectionTests, FCPXMLAssetValidationTests, FCPXMLSilenceDetectionTests, FCPXMLAssetDurationMeasurementTests, FCPXMLParallelFileIOTests, FCPXMLAudioEnhancementTests, FCPXMLTransform360Tests, FCPXMLCaptionTitleTests, FCPXMLKeyframeAnimationTests, FCPXMLAudioKeyframeTests, FCPXMLCMTimeCodableTests, FCPXMLCollectionTests, FCPXMLSmartCollectionTests, FCPXMLAdjustmentTests, FCPXMLFilterTests, FCPXMLImportOptionsTests, FCPXMLCodableTests, FCPXMLAEXMLSerializationParityTests, FCPXMLDTDValidatorTests, FCPXMLStructuralValidatorTests, OpenFCPXMLKitTests.swift, FCPXMLTimelineExportValidationTests, FCPXMLAPIAndEdgeCaseTests, FCPXMLPerformanceTests (`ContinuousClock` budgets), FCPXMLTimelineProjectionTests, FCPXMLProjectionCoverageTests, FCPXMLParsingCoverageTests, FCPXMLEngineHygieneTests, FCPXMLReportObligationCorpusTests, FCPXMLExtractionNestFidelityTests, FCPXMLRoleInheritanceMatrixTests, FCPXMLExtractionProjectionPolicyTests, FCPXMLMarkersKeywordsProjectionTests, FCPXMLTitlesProjectionTests, FCPXMLTransitionsProjectionTests, FCPXMLEffectsProjectionTests, FCPXMLSubmittedFCPXMLSmokeTests, and report/extraction tests (FCPXMLRoleInventoryReportTests, FCPXMLMarkersReportTests, FCPXMLKeywordsReportTests, FCPXMLTitlesReportTests, FCPXMLTransitionsReportTests, FCPXMLEffectsReportTests, FCPXMLSpeedChangeEffectsReportTests, FCPXMLSummaryReportTests, FCPXMLReportExcelExportTests, FCPXMLReportPDFExportTests, FCPXMLReportPDFSheetPlanTests, FCPXMLReportPDFTableLayoutTests, FCPXMLReportFormattingTests, FCPXMLReportRoleExclusionTests, FCPXMLReportTimecodeFormatTests, FCPXMLReportBuildPhaseTests, FCPXMLRoleDisplayPreferenceTests, FCPXMLRoleInventoryClipCollectorTests, FCPXMLRoleInventoryRoleSheetOrderingTests, FCPXMLSummaryRoleDurationAggregatorTests, FCPXMLEffectsReportPolicyTests, FCPXMLSpeedChangeFormattingTests, FCPXMLDisplayClipNameTests, FCPXMLTitleDisplayTests, FCPXMLExtractionScopeTests, FCPXMLExtractedElementTests, FCPXMLEffectsCollectorTests, FCPXMLRolesExtractionPresetTests, FCPXMLEffectAppleSuppliedTests, FCPXMLClipParsingCarriesAudioTests, FCPXMLTransformAdjustmentParsingTests, FCPXMLTransitionSpinePlacementTests); every test-case class is FCPXML-prefixed except the module-named umbrella OpenFCPXMLKitTests; empty timeline creation and project-creation export at different sizes and frame rates in FCPXMLTimelineExportValidationTests (clip-level metadata export, XML declaration standalone="no")). Cross-platform XML (OFKXML*, Foundation vs AEXML, FCPXMLStructuralValidator, iOS). Private `Tests/Submitted FCPXML/` inbox (gitignored contents; never commit private FCPXML to GitHub).
- FCPXML 1.5–1.14 and FCPXMLElementType; FCPXMLVersion.supportsBundleFormat (1.10+); version conversion with element stripping and per-version DTD validation; FCPXML creation from scratch; timeline manipulation (ripple insert, auto lane assignment, clip queries, lane range, secondary storylines); timeline metadata (markers, chapter markers, keywords, ratings, timestamps); FCPXMLTimecode custom type; MIME type detection; asset validation (including still images); silence detection; asset duration measurement; parallel file I/O; TimelineFormat enhancements; typed adjustment models (Crop, Corners, Transform, Blend, Stabilization, Volume, Panner, Loudness, NoiseReduction, HumReduction, Equalization, MatchEqualization, Transform360, ColorConform, Stereo3D, VoiceIsolation); typed effect/filter models (VideoFilter, AudioFilter, VideoFilterMask, FilterParameter with keyframe animation and auxValue 1.11+); typed caption/title models (Caption, Title with TextStyle, TextStyleDefinition); smart collections (SmartCollection with match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type); keyframe animation (KeyframeAnimation, Keyframe, FadeIn, FadeOut); audio keyframes (FCPXMLAudioKeyframeTests: adjust-volume param keyframeAnimation parsing, decibel/time validation, fadeIn/fadeOut integration); CMTime Codable extension; collection organization (CollectionFolder, KeywordCollection); Live Drawing (1.11+); HiddenClipMarker (1.13+); Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps); **Timeline Projection** (`TimelineProjecting` / `TimelineProjector` / `MediaUsageWindow` / `ReportProjectionContext`; project-once; Projection-first Markers/Keywords/Titles/Transitions/Effects); experimental CLI (OpenFCPXMLKit-CLI, single binary, embedded DTDs, --check-version, --convert-version, --extension-type fcpxml|fcpxmld, --validate, --media-copy, --create-project with DTD validation and FCP-style output, --report Excel/PDF report with --report-full/per-section flags/--report-summary/--report-media-summary/--media-resolution/--media-summary-distinguish-proxy/--exclude-role/--exclude-column/--exclude-disabled-clips/--include-markers-outside-clip-boundaries/--protect-sheets/--timecode-format/--report-project/--label-copyright/--create-pdf, --log/--log-level/--quiet with log file capturing all command output); Excel and PDF reporting subsystem (`allReportTimelineSources` / compound-clip timelines) (Reporting/ builders, Sections/Rows, Support including ReportProjectionContext, RoleInventoryColumnLayout, ReportColumnExclusion, ReportFormatting, ReportTimecodeFormat, ReportBuildProgress, ReportMediaResolutionPolicy; Excel/ via XLKit; buildReport/ReportExcelExport/ReportPDFExport; Summary and Media Summary sheets; excludeDisabledClips/excludedColumns/timecodeFormat/copyrightLabel/includeMarkersOutsideClipBoundaries/protectSheets/mediaResolutionPolicy; `--label-copyright`; inventory-first enabledPhases with `.projecting`; PDF cover notes + TOC colour chips / SheetPlan colorIndex; TableLayout column expansion to contentWidth and Row inject); extraction presets (Captions, Effects, FrameData, Markers, Roles, Titles); Manual chapters including [08 — Detached Authoring](Documentation/Manual/08-Detached-Authoring.md), [12 — Timeline Projection](Documentation/Manual/12-Timeline-Projection.md), [17 — Cross-Platform & iOS](Documentation/Manual/17-Cross-Platform-iOS.md), [19 — CLI](Documentation/Manual/19-CLI.md), [20 — Reporting](Documentation/Manual/20-Reporting.md), [21 — Examples](Documentation/Manual/21-Examples.md); Tests/ExcelReportTest optional integration; Tests/Submitted FCPXML private inbox (gitignored; never commit private FCPXML); Final Cut Pro frame rates; Swift 6 concurrency (Sendable, async/await, CI strict-concurrency job); Xcode 26 dynamic framework linking compatibility via explicit `swift-log` (`Logging`) dependency in `Package.swift`; SwiftExtensions 3.0.0+ and SwiftSemanticVersion 1.0.0+ (`SemanticVersion` for `FinalCutPro.FCPXML.Version`). Current test count: **1114** listed in `swift test list` (`1108` OpenFCPXMLKitTests + `6` ExcelReportTest; **all Swift Testing**).

When updating either file, apply the same information to both and keep terminology and examples consistent.

---

## External References

External: Final Cut Pro XML (fcp.cafe/developers/fcpxml/), SwiftTimecode (github.com/orchetect/swift-timecode), Swift Concurrency (docs.swift.org). Internal: Package.swift, README.md, .cursorrules, CHANGELOG.md, Tests/README.md, Documentation/Manual.md.

---

## Maintenance

Regular tasks: update dependencies as needed; review and update documentation; monitor test coverage; address warnings or deprecations; keep build configuration current.

Long-term: plan for future Swift versions; consider new FCPXML versions; monitor SwiftTimecode updates; plan for platform changes; maintain backward compatibility where possible.

