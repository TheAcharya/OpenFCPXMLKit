# 02 — Loading & Parsing

[← Manual Index](00-Index.md)

---

## Table of Contents

- [File loader API](#file-loader-api)
- [Parsing](#parsing)
- [FCPXML version and element types](#fcpxml-version-and-element-types)
- [Inherited roles](#inherited-roles)
- [Large documents](#large-documents)
- [Basic modular operations](#basic-modular-operations)

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

## Inherited roles

Role facts live in Parsing (`FinalCutPro.FCPXML.AncestorRoles`, `_fcpInheritedRoles`). Extraction and Role Inventory consume those facts; they must not re-walk ancestors in Reporting.

- A nested secondary-storyline `<spine>` (`lane` and/or `offset`) stops the ancestor walk (`_fcpRoleInheritanceContributingElements`). Children inside that spine do **not** inherit the parent storyline clip’s video or audio roles.
- Connected (`lane != 0`) story clips similarly isolate from their parent clip host.
- Unassigned children use Final Cut Pro defaults (**Video**), not the host’s assigned role.
- Markers and keywords still inherit from the clip they attach to.

See GUARDRAILS Sign `secondary-storyline-clips-keep-own-roles`, [11 — Extraction & Media](11-Extraction-Media.md), and [20 — Reporting, Excel & PDF Export](20-Reporting.md#role-inventory).

---

## Large documents

Parsing and walking are tuned for real editorial exports (tens of MB, thousands of clips, keyword-dense clips). Nothing here needs to be enabled — it describes what the library already does, and the assumptions it relies on:

| Behaviour | Detail |
|-----------|--------|
| **Time strings** | `start` / `offset` / `duration` / `tcStart` values (`N/Ds`, `Ns`) are scanned directly into a `Fraction`. No `NSRegularExpression` is used on this path — a walk reads these attributes millions of times. |
| **Scoped timing cache** | Resolving a `conform-rate` scaling factor walks an element's ancestors and then that container's children. Read-only entry points (Extraction, Projection, report builds) install a per-walk cache so each element resolves once. The cache lives only for the duration of that walk and is never consulted by writes, so it cannot report stale geometry after a mutation. |
| **Resource lookup** | `OFKXMLElement.firstChildElement(withID:)` / `firstChildElement(named:)` resolve a `ref` to its `<asset>` / `<format>` / `<media>` in constant time instead of filtering the whole `<resources>` list. See [15 — XML Extensions](15-XML-Extensions.md). |
| **Annotation leaves** | `FCPXMLElementType.isLeafAnnotation` marks `keyword`, `marker`, `chapter-marker`, `analysis-marker`, and `hidden-clip-marker` as terminal, and `fcpProjectableStoryElements` filters them out of story traversal. A clip carrying thousands of keywords is no longer walked as thousands of nested containers; keyword and marker extraction still returns every child. |

If you mutate a document, do so outside a read-only walk (parse → mutate → re-walk) rather than editing elements while an extraction or projection is in flight.

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
- [11 — Extraction & Media](11-Extraction-Media.md) — inherited roles consumed by presets.
- [20 — Reporting, Excel & PDF Export](20-Reporting.md) — Role Inventory uses Parsing role facts.
