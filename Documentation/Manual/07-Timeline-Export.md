# 07 — Timeline & Export

[← Manual Index](00-Index.md)

---

## Timeline and TimelineClip

Build a **Timeline** with **TimelineClip** instances and an optional **TimelineFormat**:

```swift
import OpenFCPXMLKit
import CoreMedia

let clip = TimelineClip(
    assetRef: "r2",
    offset: CMTime(value: 0, timescale: 1),
    duration: CMTime(value: 1001, timescale: 24000),
    start: .zero,
    lane: 0
)

let format = TimelineFormat.hd1080p(
    frameDuration: CMTime(value: 1001, timescale: 24000),
    colorSpace: .rec709
)

let timeline = Timeline(name: "My Timeline", format: format, clips: [clip])
```

**TimelineFormat** supports any width, height, and frame rate. Use the initializer for custom dimensions and frame duration, or presets for standard resolutions:

- **Custom format:** `TimelineFormat(width:height:frameDuration:colorSpace:interlaced:)` — any positive width/height; frame rate is set via `frameDuration` (e.g. 25 fps = `CMTime(value: 1, timescale: 25)`).
- **Presets:** `hd1080p`, `hd720p`, `uhd4K`, `dci4K`, `hd1080i`, `hd720i` — each takes `frameDuration` (and optional `colorSpace`), so you choose the frame rate (23.976, 24, 25, 29.97, 30, 50, 59.94, 60 fps, etc.).
- **Computed properties:** `aspectRatio`, `isHD`, `isUHD`, `interlaced`, `is1080p`, `is720p`, etc.

You can create valid projects (timelines) with **zero clips** (empty spine); export supports both empty and non-empty timelines.

---

## Export assets

**FCPXMLExportAsset** describes each asset referenced by clips. `id` must match `TimelineClip.assetRef`:

```swift
let asset = FCPXMLExportAsset(
    id: "r2",
    name: "Clip1",
    src: URL(fileURLWithPath: "/path/to/media.mov"),
    duration: CMTime(value: 1001, timescale: 24000),
    hasVideo: true,
    hasAudio: true
)
```

---

## Export to FCPXML string

**FCPXMLExporter** produces an FCPXML string. Supports timelines with **zero clips** (empty spine) or with clips; when clips are present, every `assetRef` must match an asset `id`. The output includes a **DOCTYPE** declaration, **format** `colorSpace` (e.g. `1-1-1 (Rec. 709)`), and optionally FCP-style default smart collections. **Timeline-level and clip-level metadata** (markers, chapter markers, keywords, ratings, custom metadata) are included when present — see [09 — Timeline Metadata](09-Timeline-Metadata.md) for setting metadata on timelines and clips. The XML declaration uses `standalone="no"` for compatibility with external DTD validation (e.g. xmllint).

```swift
let exporter = FCPXMLExporter(version: .default)
let xmlString = try exporter.export(timeline: timeline, assets: [asset])
```

Optional parameters for FCP-style document identity and library location:

- **eventUid** — Event `uid` attribute; if `nil`, a new UID is generated (see **FCPXMLUID** in [15 — Errors & Utilities](15-Errors-Utilities.md)).
- **projectUid** — Project `uid` attribute; if `nil`, a new UID is generated.
- **libraryLocation** — Library `location` attribute (e.g. file URL of the library bundle).
- **includeDefaultSmartCollections** — If `true`, adds FCP-style default smart collections under the library (Projects, All Video, Audio Only, Stills, Favorites). Default: `false`. Set to `true` when creating new projects for FCP import.

The exporter always writes **project** `modDate` (FCP-style date string), sequence **tcFormat**, **audioLayout**, **audioRate**, format **colorSpace**, and a document **DOCTYPE** so output matches FCP export.

```swift
// Empty project with custom format, optional UIDs/location, and default smart collections (e.g. for FCP import)
let format = TimelineFormat(width: 500, height: 500, frameDuration: CMTime(value: 1, timescale: 25), colorSpace: .rec709)
let timeline = Timeline(name: "Custom 500×500 25fps", format: format, clips: [])
let xmlString = try exporter.export(
    timeline: timeline,
    assets: [],
    eventUid: FCPXMLUID.random(),
    projectUid: FCPXMLUID.random(),
    libraryLocation: "file:///Users/user/Movies/MyLibrary.fcpbundle/",
    includeDefaultSmartCollections: true
)
```

---

## Export to .fcpxmld bundle

**FCPXMLBundleExporter** creates a `.fcpxmld` bundle on disk:

```swift
let bundleExporter = FCPXMLBundleExporter(version: .default, includeMedia: false)
let bundleURL = try bundleExporter.exportBundle(
    timeline: timeline,
    assets: [asset],
    to: outputDirectoryURL,
    bundleName: "My Project"
)
```

**FCPXMLExportError** and **FCPXMLBundleExportError** cover missing assets, invalid timeline, invalid format, and bundle version requirements.

---

## Next

- [08 — Timeline Manipulation](08-Timeline-Manipulation.md) — Ripple insert, auto lane, clip queries.
