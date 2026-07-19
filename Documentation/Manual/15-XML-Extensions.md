# 15 — XML Extensions

[← Manual Index](00-Index.md)

---

## Platform-agnostic XML layer

FCPXML document and element APIs are defined on **protocol types** so the same code works on macOS and iOS:

- **OFKXMLDocument** — document protocol (parse, root, metadata, serialization). On macOS the default implementation wraps Foundation `XMLDocument`; on iOS it wraps AEXML.
- **OFKXMLElement** — element protocol (attributes, children, serialization). On macOS the default wraps Foundation `XMLElement`; on iOS it wraps AEXML.
- **OFKXMLFactory** — factory for creating documents and elements. Use **OFKXMLDefaultFactory()** to get the correct backend for the current platform.

All `fcpx*` extensions below apply to `OFKXMLDocument` and `OFKXMLElement`; the concrete type is chosen at runtime. See [17 — Cross-Platform & iOS](17-Cross-Platform-iOS.md) for details.

---

## OFKXMLDocument extension API

**OFKXMLDocument** (and thus any conforming type) gains FCPXML-specific properties and methods. Prefer modular overloads (e.g. `addResource(_:using: documentManager)`) when injecting dependencies.

| Property / method | Purpose |
|-------------------|--------|
| `fcpxmlString` | Serialised FCPXML string |
| `fcpxmlVersion` | Document version |
| `fcpxEventNames` | Event names |
| `fcpxEvents` | Event elements |
| `fcpxResources` | Resource elements |
| `fcpxLibraryElement` | Library element |
| `fcpxAllProjects` | All projects |
| `fcpxAllClips` | All clips |
| `add(events:)` | Add event elements |
| `add(resourceElements:)` | Add resource elements |
| `resource(matchingID:)` | Find resource by ID |
| `remove(resourceAtIndex:)` | Remove resource |
| `validateFCPXMLAgainst(version:)` | Validate against version |
| `init(contentsOfFCPXML:)` | Load from URL |

```swift
// Load via loader or parser (returns any OFKXMLDocument)
let document = try await FCPXMLFileLoader().load(from: url)
let version = document.fcpxmlVersion
let eventNames = document.fcpxEventNames
document.add(events: [newEvent])
if let resource = document.resource(matchingID: "r1") { /* use */ }
document.remove(resourceAtIndex: 0)
// validateFCPXMLAgainst is available on macOS (Foundation backend)
try document.validateFCPXMLAgainst(version: .v1_14)
```

---

## OFKXMLElement extension API

**OFKXMLElement** gains `fcpx*` attribute accessors and structural helpers. Use `element.setAttribute(name:value:using: documentManager)` and `element.getAttribute(name:using: documentManager)` for modular attribute access.

| Property / method | Purpose |
|-------------------|--------|
| `fcpxType` | FCPXMLElementType |
| `fcpxName`, `fcpxDuration`, `fcpxOffset`, `fcpxStart` | Clip/timing |
| `fcpxRef`, `fcpxID`, `fcpxLane`, `fcpxRole`, `fcpxFormatRef` | Refs and metadata |
| `fcpxEvent(name:)` | Event by name |
| `fcpxProject(...)` | Project access |
| `eventClips`, `eventClips(forResourceID:)` | Clips in event |
| `addToEvent(items:)`, `removeFromEvent(items:)` | Modify event |
| `fcpxResource`, `fcpxParentEvent`, `fcpxSequenceClips` | Parent/children |
| `fcpxAnnotations` | Annotation elements (markers, keywords, hidden-clip-marker, etc.) |
| `createChild(name:attributes:using:)` | Create child (modular) |

```swift
let elementType = element.fcpxType
let name = element.fcpxName
let duration = element.fcpxDuration
let event = element.fcpxEvent(name: "My Event")
let clips = event.eventClips
let clipsForResource = event.eventClips(forResourceID: "r1")
event.addToEvent(items: [clip])
let annotations = element.fcpxAnnotations
```

---

## Next

- [16 — High-Level Model](16-High-Level-Model.md) — FinalCutPro.FCPXML wrapper.
- [17 — Cross-Platform & iOS](17-Cross-Platform-iOS.md) — XML abstraction, Foundation vs AEXML, iOS support.

[← Manual Index](00-Index.md)

