# 08 — Detached Authoring

[← Manual Index](00-Index.md)

---

## Overview

**`FinalCutPro.FCPXML.Authoring`** is a **detached** (non-live) document value graph for building and round-tripping FCPXML without wrapping live XML nodes.

| Layer | Ownership | Use when |
|-------|-----------|----------|
| **`Model/`** | Live `OFKXMLElement` wrappers | Parse / inspect / mutate an existing document |
| **`Timeline/` + `Export/`** | In-memory timeline → exporter | Build timelines programmatically for empty projects / clip export |
| **`Authoring/`** | Independent `Sendable` value types | Compose a document graph, encode to XML, decode a limited subset back |

Authoring does **not** replace Model or Timeline export. Do **not** use Authoring inside **Reporting** — reports consume Extraction → Projection only (see [20 — Reporting](20-Reporting.md) and [ARCHITECTURE.md](../../ARCHITECTURE.md) §2.7).

Coverage is intentional and **incremental**: story spine compounds and common resources are supported; markers, most filters, metadata, and generic `<clip>` are not yet modeled in Authoring.

---

## Version availability & feature gate

Every Authoring `Element` exposes `availability: VersionAvailability`. Encoding uses `encodeIfAvailable(into:context:)` so unavailable features are **omitted** for the document’s target version (omit-on-write).

```swift
let availability = FinalCutPro.FCPXML.VersionAvailability.from(.v1_10)
availability.contains(.v1_09) // false
availability.contains(.v1_14) // true
```

**`FinalCutPro.FCPXML.VersionFeatureGate`** is the shared registry of DTD feature introductions (elements and attributes). Authoring (e.g. `CinematicAdjustment` → `adjust-cinematic`, 1.10+) and **`FCPXMLVersionConverter`** fallback strip lists both consult it. Prefer DTD allowlist stripping when DTDs are present; the gate is the explicit API + converter fallback. See [06 — Version Conversion & Export](06-Version-Conversion-Export.md).

---

## Document entry points

```swift
typealias Authoring = FinalCutPro.FCPXML.Authoring

let format = Authoring.Format(
    id: "r1",
    frameDuration: "100/2400s",
    width: 1920,
    height: 1080,
    name: "FFVideoFormat1080p24"
)
let asset = Authoring.Asset(
    id: "r2",
    name: "Clip",
    hasVideo: true,
    hasAudio: true,
    duration: "10s",
    formatID: "r1",
    mediaReps: [Authoring.MediaRep(src: "file:///tmp/clip.mov")]
)
var clip = Authoring.AssetClip(
    ref: "r2",
    offset: "0s",
    duration: "5s",
    name: "Clip",
    start: "0s"
)
clip.cinematic = Authoring.CinematicAdjustment(aperture: "wide") // omitted below 1.10
clip.volume = Authoring.VolumeAdjustment(amount: "-3dB")

let document = Authoring.Document.simpleProject(
    version: .v1_14,
    format: format,
    asset: asset,
    clip: clip,
    sequenceDuration: "5s"
)

let xml = try document.xmlString()
let ofkDoc = try document.makeXMLDocument()

// Decode a limited Authoring subset back from live XML
let live = try OFKXMLDefaultFactory().makeDocument(xmlString: xml, options: .fcpxmlDefaults)
let roundTrip = try Authoring.Document(xmlDocument: live)
```

For richer graphs, build `Document(version:resources:library:)` with nested `Library` → `Event` → `Project` → `Sequence` → `Spine(items:)`.

---

## Resources

`Authoring.Resources` holds:

| Property | Element |
|----------|---------|
| `formats` | `<format>` |
| `assets` | `<asset>` (+ `MediaRep`) |
| `effects` | `<effect>` (titles, transitions, filters) |
| `media` | `<media>` — compound `MediaSequence` or `Multicam` (`MCAngle`) |

---

## Spine items

`Authoring.SpineItem` (indirect enum):

| Case | Element |
|------|---------|
| `.assetClip` | `<asset-clip>` (optional volume / cinematic) |
| `.gap` | `<gap>` |
| `.title` | `<title>` |
| `.transition` | `<transition>` |
| `.video` / `.audio` | `<video>` / `<audio>` leaves |
| `.caption` | `<caption>` |
| `.syncClip` | `<sync-clip>` (+ nested contents, `SyncSource`) |
| `.refClip` | `<ref-clip>` → compound `<media>` |
| `.mcClip` | `<mc-clip>` (+ `MCSource`) → multicam `<media>` |
| `.audition` | `<audition>` (first candidate active) |

Example (compound + caption):

```swift
let compound = Authoring.Media(
    id: "r3",
    name: "Compound",
    content: .sequence(
        Authoring.MediaSequence(
            formatID: "r1",
            duration: "4s",
            spine: Authoring.Spine(items: [
                .assetClip(Authoring.AssetClip(ref: "r2", offset: "0s", duration: "4s", start: "0s"))
            ])
        )
    )
)

let spine = Authoring.Spine(items: [
    .refClip(Authoring.RefClip(ref: "r3", offset: "0s", duration: "4s", start: "0s")),
    .caption(Authoring.Caption(offset: "0s", duration: "2s", lane: 1, role: "iTT?caption")),
])
```

---

## Related chapters

- [07 — Timeline & Export](07-Timeline-Export.md) — live `Timeline` path (parallel creation style)
- [12 — Timeline Projection](12-Timeline-Projection.md) — analyse authored or parsed timelines
- [14 — Typed Models](14-Typed-Models.md) — live Model adjustments (Corners, Panner, …)
- [16 — High-Level Model](16-High-Level-Model.md) — `FinalCutPro.FCPXML` live document API
- [21 — Shot Extraction](21-Shot-Extraction.md) — primary-timeline stills → PNG + CSV/Notion JSON
- [22 — Examples](22-Examples.md) — end-to-end workflows

---

## Next

- [09 — Timeline Manipulation](09-Timeline-Manipulation.md) — ripple insert, auto lane, clip queries.
