# 09 — Timeline Manipulation

[← Manual Index](00-Index.md)

---

## Ripple insert

Insert a clip and shift subsequent clips forward. Use **insertingClipWithRipple** (returns new timeline + result) or **insertClipWithRipple** (mutating).

```swift
var timeline = Timeline(name: "My Timeline")

let clip1 = TimelineClip(
    assetRef: "r1",
    offset: CMTime(value: 0, timescale: 1),
    duration: CMTime(value: 10, timescale: 1),
    lane: 0
)
let clip2 = TimelineClip(
    assetRef: "r2",
    offset: CMTime(value: 10, timescale: 1),
    duration: CMTime(value: 10, timescale: 1),
    lane: 0
)
timeline.clips = [clip1, clip2]

let newClip = TimelineClip(
    assetRef: "r3",
    offset: .zero,
    duration: CMTime(value: 5, timescale: 1),
    lane: 0
)

// Immutable
let (updatedTimeline, result) = timeline.insertingClipWithRipple(
    newClip,
    at: CMTime(value: 5, timescale: 1),
    lane: 0,
    rippleLanes: .primaryOnly
)

// Mutating
timeline.insertClipWithRipple(
    newClip,
    at: CMTime(value: 5, timescale: 1),
    lane: 0,
    rippleLanes: .primaryOnly
)

print("Inserted at: \(result.insertedClip.offset)")
print("Shifted \(result.shiftedClips.count) clips")
for shift in result.shiftedClips {
    print("Clip \(shift.clipIndex): \(shift.originalOffset) → \(shift.newOffset)")
}
```

**RippleLaneOption:** `.all`, `.single(Int)`, `.range(ClosedRange<Int>)`, `.primaryOnly` (lane 0 only).

---

## Auto lane assignment

Find an available lane when inserting:

```swift
// Immutable
let (updatedTimeline, placement) = try timeline.insertingClipAutoLane(
    newClip,
    at: CMTime(value: 0, timescale: 1),
    preferredLane: 0,
    autoAssignLane: true
)

// Mutating
try timeline.insertClipAutoLane(
    newClip,
    at: CMTime(value: 0, timescale: 1),
    preferredLane: 0,
    autoAssignLane: true
)

print("Clip placed on lane: \(placement.lane)")

// Manual: find available lane
let availableLane = timeline.findAvailableLane(
    at: CMTime(value: 0, timescale: 1),
    duration: CMTime(value: 5, timescale: 1),
    startingFrom: 0
)
```

**TimelineError** cases: `noAvailableLane`, `assetNotFound`, `invalidFormat`, `invalidAssetReference`.

---

## Clip queries

```swift
// Clips on a lane
let lane0Clips = timeline.clips(onLane: 0)

// Clips in time range
let clipsInRange = timeline.clips(
    inRange: start: CMTime(value: 10, timescale: 1),
    end: CMTime(value: 20, timescale: 1)
)

// Clips referencing an asset
let assetClips = timeline.clips(withAssetRef: "r1")

// Lane range (min/max lanes used)
if let laneRange = timeline.laneRange {
    print("Lanes: \(laneRange.lowerBound)...\(laneRange.upperBound)")
}
```

**Note:** Gap clips do not support the lane attribute; setting `lane` on a gap has no effect (the property is deprecated on ``FinalCutPro/FCPXML/Gap``).

---

## Next

- [10 — Timeline Metadata](10-Timeline-Metadata.md) — Markers, chapters, keywords, ratings, timestamps.
