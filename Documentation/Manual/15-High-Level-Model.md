# 15 — High-Level Model

[← Manual Index](00-Index.md)

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

For building Excel or PDF reports from either a project or a standalone compound clip, see [19 — Reporting, Excel & PDF Export](19-Reporting.md).

---

## Next

- [16 — Cross-Platform & iOS](16-Cross-Platform-iOS.md) — OFKXML abstraction, Foundation vs AEXML, iOS support.

[← Manual Index](00-Index.md)
