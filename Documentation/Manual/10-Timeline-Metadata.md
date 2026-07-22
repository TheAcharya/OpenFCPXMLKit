# 10 — Timeline Metadata

[← Manual Index](00-Index.md)

---

## Timestamps

Timeline and clips track **createdAt** and **modifiedAt**. Mutating operations update **modifiedAt**:

```swift
var timeline = Timeline(name: "My Timeline")
print("Created: \(timeline.createdAt), Modified: \(timeline.modifiedAt)")

// Custom timestamps
let timeline2 = Timeline(
    name: "My Timeline",
    createdAt: Date(timeIntervalSince1970: 1000),
    modifiedAt: Date(timeIntervalSince1970: 1000)
)

timeline.addMarker(Marker(start: CMTime(value: 5, timescale: 1), value: "Marker"))
// modifiedAt updated
```

---

## Markers and chapter markers

```swift
var timeline = Timeline(name: "My Timeline")

let marker = Marker(start: CMTime(value: 5, timescale: 1), value: "Important moment")
timeline.addMarker(marker)

let chapter = ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Chapter 1")
timeline.addChapterMarker(chapter)

let sortedMarkers = timeline.sortedMarkers
let sortedChapters = timeline.sortedChapterMarkers
```

When building an Excel/PDF **Markers** report, chapter markers are included by default (`includeChapterMarkersInMarkersReport`; Type = Chapter). See [20 — Reporting](20-Reporting.md#markers).

---

## Keywords and ratings

```swift
let keyword = Keyword(
    start: CMTime(value: 0, timescale: 1),
    duration: CMTime(value: 10, timescale: 1),
    value: "Action"
)
timeline.addKeyword(keyword)

let rating = Rating(
    start: CMTime(value: 0, timescale: 1),
    duration: CMTime(value: 10, timescale: 1),
    value: .favorite
)
timeline.addRating(rating)
```

---

## Custom metadata

**Metadata** supports key-value custom fields (e.g. camera name, scene):

```swift
var metadata = Metadata()
metadata.setCameraName("Camera A")
metadata.setScene("Scene 1")
timeline.metadata = metadata
```

---

## Clip metadata

Clips can have markers, keywords, ratings, and custom metadata. This metadata is included when exporting to FCPXML — see [07 — Timeline & Export](07-Timeline-Export.md).

```swift
var clip = TimelineClip(
    assetRef: "r1",
    offset: .zero,
    duration: CMTime(value: 10, timescale: 1),
    lane: 0
)
clip.addMarker(Marker(start: CMTime(value: 2, timescale: 1), value: "Clip marker"))
clip.addKeyword(keyword)
clip.addRating(rating)
```

---

## Next

- [11 — Extraction & Media](11-Extraction-Media.md) — Extraction scope/presets, media extraction and copy.
