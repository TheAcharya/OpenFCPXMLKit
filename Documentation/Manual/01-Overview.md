# 01 — Overview

[← Manual Index](00-Index.md)

---

## Introduction

OpenFCPXMLKit provides a comprehensive API for parsing, creating, and manipulating FCPXML files with advanced timecode operations, async/await patterns, and robust error handling. The framework is **protocol-oriented**: you inject parsers, timecode converters, document managers, and error handlers to configure a service that fits your app. All major operations are available both **synchronously** and **asynchronously**.

**Target:** macOS 26+, iOS 26+, Xcode 26+, Swift 6.3 with full concurrency support. The library uses a platform-agnostic XML layer (`OFKXMLDocument`, `OFKXMLElement`, `OFKXMLFactory`): Foundation backend on macOS, AEXML backend on iOS.

---

## Main entry points

| Type | Purpose |
|------|--------|
| **FCPXMLService** | Orchestrates parse, validate, create document, time conversion, filter, save, media extraction/copy |
| **ModularUtilities** | Helpers: `createService`, `createCustomService`, `processFCPXML`, `processMultipleFCPXML`, `validateDocument`, `convertTimecodes` |
| **FCPXMLFileLoader** | Loads `.fcpxml` files and `.fcpxmld` bundles (sync and async) |
| **FCPXMLValidator** | Semantic validation (root, resources, ref resolution) |
| **FCPXMLDTDValidator** | DTD schema validation for a given FCPXML version |
| **FCPXMLExporter** / **FCPXMLBundleExporter** | Export `Timeline` to FCPXML string or `.fcpxmld` bundle |

---

## Protocols and default implementations

All core behaviour is defined by **protocols** with both sync and async APIs. Default implementations can be swapped via dependency injection.

| Protocol | Default implementation | Role |
|----------|------------------------|------|
| `FCPXMLParsing` | `FCPXMLParser` | Parse data/URL, validate, filter elements |
| `TimecodeConversion` | `TimecodeConverter` | CMTime ↔ Timecode, FCPXML time strings, frame conforming |
| `XMLDocumentOperations` | `XMLDocumentManager` | Create document/elements, add resources/sequences, save |
| `ErrorHandling` | `ErrorHandler` | Format errors (sync-only) |
| `ServiceLogger` | `NoOpServiceLogger`, `PrintServiceLogger`, `FileServiceLogger` | Logging |
| `MIMETypeDetection` | `MIMETypeDetector` | Detect MIME type at URL (sync/async) |
| `AssetValidation` | `AssetValidator` | Validate asset existence and lane compatibility |
| `SilenceDetection` | `SilenceDetector` | Detect silence at start/end of audio |
| `AssetDurationMeasurement` | `AssetDurationMeasurer` | Measure duration of audio/video/images |
| `ParallelFileIO` | `ParallelFileIOExecutor` | Concurrent read/write of files |
| `CutDetection` | `CutDetector` | Detect edit points on spine |
| `FCPXMLVersionConverting` | `FCPXMLVersionConverter` | Convert document to target version (strip by DTD) |
| `MediaExtraction` | `MediaExtractor` | Extract media refs, copy referenced files |

---

## Logging

- **ServiceLogger** protocol; **ServiceLogLevel**: `trace`, `debug`, `info`, `notice`, `warning`, `error`, `critical`.
- **NoOpServiceLogger** — no output (default when no logger injected).
- **PrintServiceLogger** — stdout with level prefix; `minimumLevel` controls verbosity.
- **FileServiceLogger** — file (and optionally console); `minimumLevel`, `fileURL`, `alsoPrint`, `quiet`; thread-safe.

Inject a logger into `FCPXMLService` or `FCPXMLUtility` to observe parse, conversion, validation, save, and media operations.

---

## Extensions and high-level model

- **OFKXMLDocument** and **OFKXMLElement** (protocol types) have FCPXML-specific `fcpx*` properties and methods. On macOS the concrete types wrap Foundation XML; on iOS they wrap AEXML. Use modular overloads (e.g. `addResource(_:using: documentManager)`) when injecting dependencies.
- **FinalCutPro.FCPXML** wraps a document for high-level access: `root`, `version`, `allEvents()`, `allProjects()`, `allTimelines()`, `allReportTimelineSources()` (projects plus standalone compound-clip timelines for reporting).

---

## Single injection point for extensions

Extension APIs that cannot take parameters use **FCPXMLUtility.defaultForExtensions** (concurrency-safe). For custom services, use the modular API with the `using:` parameter.

---

## Next

- [02 — Loading & Parsing](02-Loading-Parsing.md) — Load files/bundles, parse, FCPXML versions, element types.
