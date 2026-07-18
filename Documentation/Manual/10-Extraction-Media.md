# 10 — Extraction & Media

[← Manual Index](00-Index.md)

---

## Element extraction (presets and scope)

Extract elements from an FCPXML tree by type or using **presets**. **FinalCutPro.FCPXML.ExtractionScope** controls scope (e.g. `.mainTimeline`): constrain to a local timeline, set max container depth, filter auditions/multicam angles, include/exclude element types.

**FCPXMLExtractionPreset** defines a preset with a typed result. Built-in presets:

- **CaptionsExtractionPreset** — Captions with typed result (**ExtractedCaption**)
- **MarkersExtractionPreset** — Markers (returns e.g. **ExtractedMarker**)
- **RolesExtractionPreset** — Role-based extraction
- **FrameDataPreset** — Frame data (e.g. **ExtractedFrameData**)
- **TitlesExtractionPreset** (`.titles`) — Titles visible on the main timeline (`[ExtractedElement]`)
- **EffectsExtractionPreset** (`.effects`) — Semantic clip effects visible on the main timeline (`[ExtractedEffect]`, with `kind`, `name`, `settings`, `isAppleSupplied`)

Call **extract(types:scope:)** on an `FCPXMLElement` (or **fcpExtract(types:scope:)** on `OFKXMLElement`) for `[FinalCutPro.FCPXML.ExtractedElement]`. Call **extract(preset:scope:)** for a preset's result type. APIs are async.

Titles and Effects **extraction presets** remain useful for discovery and tests. Report sections for Titles, Effects, Markers, Keywords, and Transitions prefer **Timeline Projection** annotations when available (Extraction fallback) — see [11 — Timeline Projection](11-Timeline-Projection.md) and [19 — Reporting, Excel & PDF Export](19-Reporting.md).

```swift
let element: FCPXMLElement = // ... e.g. from document
let scope = FinalCutPro.FCPXML.ExtractionScope.mainTimeline

// Extract by element types
let extracted = await element.extract(
    types: [.marker, .chapter],
    scope: scope
)

// Extract using a preset
let markersResult = await element.extract(
    preset: FinalCutPro.FCPXML.MarkersExtractionPreset(),
    scope: scope
)
```

---

## Media extraction and copy

**Extract media references** (asset `<media-rep>` `src` and `<locator>` `url`) from a document. **copyReferencedMedia** copies referenced file URLs to a destination directory. Pass **baseURL** (e.g. document or bundle URL) to resolve relative paths. Sources are deduplicated; destination filenames are uniquified on conflict.

**MediaExtractionResult:** `references`, `baseURL`, `fileReferences`.  
**MediaCopyResult:** `entries` (copied, skipped, failed). **MediaReference** has `resourceID`, `url`, `isLocator`.

Sync and async on **FCPXMLService** and **FCPXMLUtility**:

```swift
let service = ModularUtilities.createService()
let document = try service.parseFCPXML(from: url)
let baseURL = url.deletingLastPathComponent()

// Extract references
let extraction = service.extractMediaReferences(from: document, baseURL: baseURL)
for ref in extraction.references {
    if let u = ref.url { print(ref.resourceID, u, ref.isLocator) }
}

// Copy referenced files (optional ProgressReporter for progress bar)
let destDir = URL(fileURLWithPath: "/path/to/Media")
let copyResult = service.copyReferencedMedia(
    from: document,
    to: destDir,
    baseURL: baseURL,
    progress: nil
)
for (src, dest) in copyResult.copied { print("Copied \(src.lastPathComponent)") }
for entry in copyResult.skipped { /* duplicate, missing file, not file URL */ }
for entry in copyResult.failed { /* error */ }
```

---

## Next

- [11 — Timeline Projection](11-Timeline-Projection.md) — playable media windows between Extraction and Reporting.
- [12 — Media Processing](12-Media-Processing.md) — MIME type, asset validation, silence, duration, parallel I/O.
- [19 — Reporting, Excel & PDF Export](19-Reporting.md) — build reports from Projection + Extraction and export to `.xlsx` or `.pdf`.

[← Manual Index](00-Index.md)

