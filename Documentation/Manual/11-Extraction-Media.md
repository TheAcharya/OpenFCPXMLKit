# 11 — Extraction & Media

[← Manual Index](00-Index.md)

---

## Table of Contents

- [Element extraction (presets and scope)](#element-extraction-presets-and-scope)
- [Inherited roles](#inherited-roles)
- [Media URL resolution (Parsing)](#media-url-resolution-parsing)
- [Media extraction and copy](#media-extraction-and-copy)

---

## Element extraction (presets and scope)

Extract elements from an FCPXML tree by type or using **presets**. **FinalCutPro.FCPXML.ExtractionScope** controls scope (e.g. `.mainTimeline`): constrain to a local timeline, set max container depth, filter auditions/multicam angles, include/exclude element types.

**FCPXMLExtractionPreset** defines a preset with a typed result. Built-in presets:

- **CaptionsExtractionPreset** — Captions with typed result (**ExtractedCaption**)
- **MarkersExtractionPreset** — Markers and chapter markers (returns e.g. **ExtractedMarker**). Does **not** drop markers solely because the host is fully occluded for media occupancy; outside-media-range “Hidden” filtering stays on the report option `includeMarkersOutsideClipBoundaries`.
- **RolesExtractionPreset** — Role-based extraction
- **FrameDataPreset** — Frame data (e.g. **ExtractedFrameData**)
- **TitlesExtractionPreset** (`.titles`) — Titles visible on the main timeline (`[ExtractedElement]`)
- **EffectsExtractionPreset** (`.effects`) — Semantic clip effects visible on the main timeline (`[ExtractedEffect]`, with `kind`, `name`, `settings`, `isAppleSupplied`). Transform settings come from `TransformAdjustment.componentSamples`; blend amount stays a 0.0–1.0 fraction (reports format Opacity percent). Filter `settings` are inspector `param` name/value pairs (Motion blobs omitted).

Call **extract(types:scope:)** on an `FCPXMLElement` (or **fcpExtract(types:scope:)** on `OFKXMLElement`) for `[FinalCutPro.FCPXML.ExtractedElement]`. Call **extract(preset:scope:)** for a preset's result type. APIs are async.

Story traversal uses `fcpProjectableStoryElements`, which skips annotation leaves (`keyword`, `marker`, `chapter-marker`, `analysis-marker`, `hidden-clip-marker` — `FCPXMLElementType.isLeafAnnotation`). Keyword and marker presets still return every child; they are collected from the host, not by treating each annotation as a nested container. Extraction walks also install the scoped timing cache described in [02 — Loading & Parsing](02-Loading-Parsing.md#large-documents).

Titles and Effects **extraction presets** remain useful for discovery and tests. Report sections for Titles, Effects, Markers, Keywords, and Transitions prefer **Timeline Projection** annotations when available (Extraction fallback) — see [12 — Timeline Projection](12-Timeline-Projection.md) and [20 — Reporting, Excel & PDF Export](20-Reporting.md).

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

## Inherited roles

**RolesExtractionPreset** and Extraction context resolve inherited roles through Parsing (`AncestorRoles` / `_fcpInheritedRoles`). Nested secondary-storyline `<spine>` children and connected (`lane != 0`) story clips keep their **own** roles; they do not inherit the parent clip host. Unassigned children default to **Video**. Markers and keywords still inherit from their clip.

Role Inventory may still walk `mcClipAngles = .all` for discovery; unfolded `mc-angle` / `multicam` interiors are dropped later as inventory rows (`ReportClipCategory.isUnfoldedMulticamInterior`) because their local times are multicam-timeline, not project timeline. See [02 — Loading & Parsing](02-Loading-Parsing.md#inherited-roles), [20 — Reporting](20-Reporting.md#role-inventory), and Sign `secondary-storyline-clips-keep-own-roles`.

---

## Media URL resolution (Parsing)

Timeline elements resolve a **leaf** media file through Parsing — not Extraction. Use these on any `OFKXMLElement` (asset-clip, mc-clip, sync-clip, ref-clip, audition, and so on):

| API | Returns |
|-----|---------|
| `fcpMediaURL(in:preferAudioAngle:)` | `original-media` URL, or `proxy-media` when no original is declared |
| `fcpMediaURL(in:kind:preferAudioAngle:)` | That `MediaRep.Kind` only (`nil` if undeclared) |
| `fcpMediaRepresentationURLs(in:preferAudioAngle:)` | `(original: URL?, proxy: URL?)` from the **same** unfolded leaf |

Unfold rules: `mc-clip` uses the active video angle (or the active audio angle when `preferAudioAngle` is `true`); `sync-clip` / `clip` use the first non-gap child leaf; `ref-clip` walks the compound `media` sequence. Source File Name / Path stay original-first. Role Inventory screenshots use the same pair and prefer original, falling back to proxy only when the original is missing or cannot be decoded — see [20 — Reporting](20-Reporting.md#role-inventory-screenshots).

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

- [12 — Timeline Projection](12-Timeline-Projection.md) — playable media windows between Extraction and Reporting.
- [13 — Media Processing](13-Media-Processing.md) — MIME type, asset validation, silence, duration, parallel I/O.
- [20 — Reporting, Excel & PDF Export](20-Reporting.md) — build reports from Projection + Extraction and export to `.xlsx` or `.pdf`.
- [21 — Shot Extraction](21-Shot-Extraction.md) — primary-timeline stills → PNG + CSV / Notion JSON.

[← Manual Index](00-Index.md)

