# 16 — High-Level Model

[← Manual Index](00-Index.md)

---

## Table of Contents

- [FinalCutPro.FCPXML](#finalcutprofcpxml)
- [Library exports and timeline exports](#library-exports-and-timeline-exports)

---

## FinalCutPro.FCPXML

For quick inspection and high-level access without walking the XML tree, use **FinalCutPro.FCPXML**. It wraps the document and exposes a **Root** and version, plus convenience accessors.

**Initialization:**

- `init(fileContent: Data)` — from raw FCPXML data
- `init(fileContent: any OFKXMLDocument)` — from an existing document

**Properties and methods:**

- **root** — Root wrapper
- **version** — Version (FinalCutPro.FCPXML.Version)
- **allEvents()** — All events in the document
- **allProjects()** — All projects in the document
- **allTimelines()** — Top-level timelines (sequences, clips, etc.) in document order
- **allReportTimelineSources()** — Timelines suitable for reporting (Excel/PDF): every project sequence, plus event-level compound clips (`ref-clip` → `media`/`sequence`) when FCP exported a compound clip without a `<project>`

```swift
let data = try loader.loadData(from: url)
let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

let eventNames = fcpxml.allEvents()
let projectNames = fcpxml.allProjects()
let reportSources = fcpxml.allReportTimelineSources()
let root = fcpxml.root
let version = fcpxml.version
```

Bridging with **FCPXMLVersion** (DTD/validation): use `.fcpxmlVersion` and `.dtdVersion` and `init(from:)` converters where provided.

For building Excel or PDF reports from either a project or a standalone compound clip, see [20 — Reporting, Excel & PDF Export](20-Reporting.md).

**Roles:** `FinalCutPro.FCPXML.AncestorRoles` describes interpolated inherited roles for an element. Nested secondary-storyline `<spine>` children and connected (`lane != 0`) clips isolate from the parent clip host — see [02 — Loading & Parsing](02-Loading-Parsing.md#inherited-roles).

---

## Library exports and timeline exports

A library export and a project export are the same `<fcpxml>` document. `root.library` is the library. `allEvents()` and `allProjects()` walk every event and project, including when several events sit under that library. `Event.storyElements` is the browser clips on an event (clips that are not inside a project sequence). `Event.smartCollections` and `Library.smartCollections` are the collections Final Cut wrote at those levels.

The loader accepts `.fcpxml` and `.fcpxmld` (`Info.fcpxml`). It does not open a live Final Cut library (`.fcpbundle`).

Reporting, Projection, and Shot Extraction follow timelines: each project sequence, and a compound clip exported with no `<project>` (`allReportTimelineSources()`). Browser clips that never appear on a timeline stay available on the event and are not inventoried by those features.

---

## Next

- [17 — Cross-Platform & iOS](17-Cross-Platform-iOS.md) — OFKXML abstraction, Foundation vs AEXML, iOS support.

[← Manual Index](00-Index.md)

