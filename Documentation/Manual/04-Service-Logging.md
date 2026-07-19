# 04 — Service & Logging

[← Manual Index](00-Index.md)

---

## Creating a service

**ModularUtilities** provides factory methods for default or custom OpenFCPXMLKit services:

```swift
import OpenFCPXMLKit

// Default service (parser, timecode converter, document manager, error handler, no-op logger)
let service = ModularUtilities.createService()

// Custom service with optional logger
let customService = ModularUtilities.createCustomService(
    parser: FCPXMLParser(),
    timecodeConverter: TimecodeConverter(),
    documentManager: XMLDocumentManager(),
    errorHandler: ErrorHandler(),
    logger: PrintServiceLogger(minimumLevel: .info)
)
```

---

## FCPXMLService

**FCPXMLService** is the main orchestrator. Inject components or use defaults:

```swift
let service = FCPXMLService(
    parser: FCPXMLParser(),
    timecodeConverter: TimecodeConverter(),
    documentManager: XMLDocumentManager(),
    errorHandler: ErrorHandler(),
    logger: PrintServiceLogger(minimumLevel: .info)
)

// Create document
let document = service.createFCPXMLDocument(version: "1.10")

// Parse (sync/async)
let doc = try service.parseFCPXML(from: url)
let docAsync = try await service.parseFCPXML(from: url)

// Validate
let isValid = await service.validateDocument(document)

// Save
try service.saveAsFCPXML(document, to: outputURL)
let bundleURL = try service.saveAsBundle(document, to: outputDir, bundleName: "My Project")
```

---

## Logging

**ServiceLogLevel** (most to least verbose): `trace`, `debug`, `info`, `notice`, `warning`, `error`, `critical`. Use `ServiceLogLevel.from(string:)` to parse from a string.

**Implementations:**

```swift
// Console only, info and above
let logger = PrintServiceLogger(minimumLevel: .info)
let service = FCPXMLService(logger: logger)

// File and console, debug and above
let fileLogger = FileServiceLogger(
    minimumLevel: .debug,
    fileURL: URL(fileURLWithPath: "/tmp/openfcpxmlkit.log"),
    alsoPrint: true,
    quiet: false
)
let serviceWithFile = FCPXMLService(logger: fileLogger)

// No output
let noOp = NoOpServiceLogger()
let quietService = FCPXMLService(logger: noOp)
```

The service logs parsing, version conversion, DTD validation, save, media extraction, and media copy. CLI supports `--log`, `--log-level`, `--quiet` (see [19 — CLI](19-CLI.md)).

---

## Error handling with modular components

**ModularUtilities.processFCPXML** returns `Result<any OFKXMLDocument, FCPXMLError>`:

```swift
let result = ModularUtilities.processFCPXML(from: url, using: service)

switch result {
case .success(let document):
    print("Parsed successfully")
case .failure(let error):
    print("Error: \(error.localizedDescription)")
}
```

**ErrorHandling** protocol (sync-only) and **ErrorHandler** format errors into user-facing messages.

---

## Async and concurrent operations

```swift
// Process multiple files
let results = await ModularUtilities.processMultipleFCPXML(from: urls, using: service)

// Convert timecodes for multiple elements
let timecodes = await ModularUtilities.convertTimecodes(
    for: elements,
    using: timecodeConverter,
    frameRate: .fps24
)

// Prefer sequential or async APIs over TaskGroup when holding XML documents:
// Foundation `XMLDocument` / SwiftTimecode types are not Sendable.
for url in urls {
    let document = try await service.parseFCPXML(from: url)
    let isValid = await service.validateDocument(document)
    if isValid { /* process */ }
}
```

---

## Next

- [05 — Validation & Cut Detection](05-Validation-CutDetection.md) — Semantic and DTD validation, cut detection.

