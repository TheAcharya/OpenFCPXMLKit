# 02 — Loading & Parsing

[← Manual Index](00-Index.md)

---

## File loader API

**FCPXMLFileLoader** supports single `.fcpxml` files and `.fcpxmld` bundles. One code path for loading; prefer **async** for I/O.

```swift
import OpenFCPXMLKit

let loader = FCPXMLFileLoader()

// Resolve URL (for .fcpxmld returns bundle's Info.fcpxml path)
let fileURL = try loader.resolveFCPXMLFileURL(from: url)

// Async load (preferred)
let document = try await loader.load(from: url)

// Sync alternatives
let data = try loader.loadData(from: url)
let doc = try loader.loadDocument(from: url)
let fcpxmlDoc = try loader.loadFCPXMLDocument(from: url)
```

**Loading a bundle:**

```swift
let bundleURL = URL(fileURLWithPath: "/path/to/Project.fcpxmld")
let loader = FCPXMLFileLoader()
let fileURL = try loader.resolveFCPXMLFileURL(from: bundleURL)
let document = try await loader.load(from: bundleURL)
```

---

## Parsing

Use **FCPXMLService** (or **FCPXMLParser** directly) to parse data or URL into an `any OFKXMLDocument` (platform-agnostic; Foundation-backed on macOS, AEXML-backed on iOS):

```swift
let service = ModularUtilities.createService()

// From URL (async preferred)
let document = try await service.parseFCPXML(from: fileURL)

// From Data
let document = try service.parseFCPXML(data)

// Parser directly
let parser = FCPXMLParser()
let document = try parser.parse(data)
let documentAsync = try await parser.parse(data)
```

---

## FCPXML version and element types

- **FCPXMLVersion** — Document version 1.5–1.14. `FCPXMLVersion.supportsBundleFormat` is `true` for 1.10+ (`.fcpxmld`); 1.5–1.9 support only single-file `.fcpxml`.
- **FCPXMLElementType** — Every DTD element has a corresponding case (e.g. `asset`, `sequence`, `clip`, `liveDrawing`, `hiddenClipMarker`). Use for typed filtering.

```swift
let version = FCPXMLVersion.default  // e.g. .v1_14
let doc = service.createFCPXMLDocument(version: version.stringValue)
try document.validateFCPXMLAgainst(version: .v1_14)
if version.supportsBundleFormat { /* can save as .fcpxmld */ }

// Filter elements by type
let types: [FCPXMLElementType] = [.assetResource, .sequence, .event]
let filtered = service.filterElements(elements, ofTypes: types)
let elementType = someElement.fcpxType  // OFKXMLElement extension
```

Public test samples live under `Tests/FCPXML Samples/FCPXML/` (e.g. `GeneralDemo.fcpxml`). For private user exports used only locally while fixing parsing or reporting edge cases, see [Submitted FCPXML](../../Tests/Submitted%20FCPXML/README.md) — contents are gitignored and must never be committed to GitHub.

---

## Basic modular operations

Create documents and add resources/sequences using **XMLDocumentManager** and modular extensions:

```swift
let service = ModularUtilities.createService()
let document = service.createFCPXMLDocument(version: "1.10")

let documentManager = XMLDocumentManager()
let resource = XMLElement(name: "asset")
resource.setAttribute(name: "id", value: "asset1", using: documentManager)
document.addResource(resource, using: documentManager)

let sequence = XMLElement(name: "sequence")
sequence.setAttribute(name: "id", value: "seq1", using: documentManager)
document.addSequence(sequence, using: documentManager)
```

---

## Next

- [03 — Timecode & Timing](03-Timecode-Timing.md) — SwiftTimecode, FCPXMLTimecode, CMTime, conversions.
