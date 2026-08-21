# 12 — Timeline Projection

[← Manual Index](00-Index.md)

---

## Table of Contents

- [Overview](#overview)
- [Public API](#public-api)
- [Options](#options)
- [Project a timeline](#project-a-timeline)
- [What Projection walks](#what-projection-walks)
- [Occupancy index](#occupancy-index)
- [Large timelines](#large-timelines)
- [Reporting integration](#reporting-integration)

---

## Overview

**Timeline Projection** sits between **Extraction** and **Reporting**. It walks a report timeline (`ReportTimelineSource` — a `<project>` sequence or a standalone compound-clip sequence) and emits Sendable **`MediaUsageWindow`** values: one playable media channel occupancy with timeline/media bounds, lane path, and retiming.

```text
Parsing → Model → Extraction → Projection → Reporting (Excel / PDF)
```

| Layer | Responsibility |
|-------|----------------|
| **Extraction** | Discover elements and context (roles, occlusion, presets). |
| **Projection** | Compose playable occupancy: channels, lanes, retiming, multicam/ref/audition unfold. |
| **Reporting** | Map windows + extraction facts into sheet rows; presentation only. |

Use Projection directly when you need timeline geometry. Prefer `buildReport` when you want Excel/PDF — `ReportBuilder` projects **once** per timeline and shares `ReportProjectionContext` across consuming sections.

Related: [03 — Timecode & Timing](03-Timecode-Timing.md) (Double-safe composition), [11 — Extraction & Media](11-Extraction-Media.md), [20 — Reporting](20-Reporting.md), [ARCHITECTURE.md](../../ARCHITECTURE.md) §2.7.

---

## Public API

| Type | Role |
|------|------|
| **`TimelineProjecting`** | Protocol: `project(from:fcpxml:options:)` → `[MediaUsageWindow]`, plus streaming overload |
| **`TimelineProjector`** | Default implementation |
| **`TimelineProjectionOptions`** | Visibility and annotation knobs |
| **`MediaUsageWindow`** | One channel occupancy (`channel`, `lanePath`, `retiming`, optional annotations) |
| **`MediaChannel`** | Video/audio channel identity (`kind`, `sourceIndex`, asset refs, media URLs) |
| **`LanePath`** | Nested lane stack for connected storylines |
| **`RetimingSegment`** | Timeline ↔ media mapping (`scale`, `isReversed`) |
| **`TimelineOccupancyIndex`** | Overlap / union queries over windows |
| **`ReportProjectionContext`** | Shared report payload: windows + clip annotations + occupancy |

---

## Options

```swift
var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
options.includeDisabled = false          // omit enabled="0"
options.auditions = .active              // or .all
options.mcClipAngles = .active           // or .all
options.excludeFullyOccluded = true      // match main-timeline report visibility
options.includeAnnotations = true        // roles / effects / breadcrumbs / report annotations
options.includeMarkerAnnotations = true  // collect host markers (only when includeAnnotations)
options.includeKeywordAnnotations = true // collect host keywords (only when includeAnnotations)
options.expandAllSourceChannels = true   // one window per video/audio src (default)

// Preset aligned with main-timeline Extraction visibility
let main = FinalCutPro.FCPXML.TimelineProjectionOptions.mainTimeline

// Preset for playable “active mix” track analysis (active audition/angles; all source channels)
let track = FinalCutPro.FCPXML.TimelineProjectionOptions.trackAnalysis
```

`includeMarkerAnnotations` and `includeKeywordAnnotations` only apply when `includeAnnotations` is on, and both default to `true` on the initialiser. Turn one off when the consumer does not need it: a clip stamped with thousands of keywords otherwise costs O(keywords × clip-children) per host.

Report builds use `TimelineProjectionOptions.forReport(...)` so `excludeDisabledClips` and annotation needs stay consistent across sections. That factory defaults both annotation kinds to `false` and `ReportBuilder` enables each from `ReportOptions.includeMarkers` / `includeKeywords`, so a Role-Inventory-only export never collects marker or keyword annotations:

```swift
let projectionOptions = FinalCutPro.FCPXML.TimelineProjectionOptions.forReport(
    excludeDisabledClips: reportOptions.excludeDisabledClips,
    auditions: .all,
    mcClipAngles: .all,
    includeAnnotations: true,
    includeMarkerAnnotations: reportOptions.includeMarkers,
    includeKeywordAnnotations: reportOptions.includeKeywords
)
```

---

## Project a timeline

```swift
import OpenFCPXMLKit

let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
let source = try fcpxml.allReportTimelineSources().first
    ?? { throw NSError(domain: "demo", code: 1) }()

let projector = FinalCutPro.FCPXML.TimelineProjector()
var options = FinalCutPro.FCPXML.TimelineProjectionOptions.mainTimeline
options.includeAnnotations = true

let windows = try await projector.project(
    from: source,
    fcpxml: fcpxml,
    options: options
)

for window in windows {
    print(
        window.channel.kind,
        "src", window.channel.sourceIndex,
        "in", window.timelineIn.doubleValue,
        "out", window.timelineOut.doubleValue,
        "scale", window.retiming.scale,
        "reversed", window.retiming.isReversed
    )
}

// Streaming (memory-friendly for long timelines)
try await projector.project(from: source, fcpxml: fcpxml, options: options) { window in
    // process one window
    _ = window
}
```

---

## What Projection walks

- Spine `asset-clip` usages with identity or `timeMap` retiming (multi-segment, reverse)
- `conform-rate` scale via shared `fcpConformRateScalingFactor`
- Nested spines / anchored children and J/L cuts (`audioStart` / `audioDuration`)
- Container spans: descending into a `clip` / `sync-clip` / `gap` composes an identity segment over the container's own span for children that carry **no** `lane`, so contained media is clipped to what the container shows. Children with a `lane` are connected clips and keep their own extent. Final Cut Pro routinely writes the full source length on the `<audio>` inside a trimmed `<clip>`, so a contained child's own `duration` is not trustworthy — see Sign `containers-bound-their-content-not-their-anchors`.
- `mc-clip` angles (active or all; split video/audio), `ref-clip` media sequences, auditions
- Host-level annotations on `mc-clip` / `ref-clip` (and other clip hosts) via `emitHostAnnotationsIfNeeded` — markers/keywords on the clip element itself are not skipped
- `video` / `audio` leaves with `ChannelKindFilter` / `srcEnable`
- Optional annotations when `includeAnnotations` is on (roles, volume/effects breadcrumbs, markers/keywords/titles/transitions/effects for reporting). Marker annotations include **`isOutsideClipBoundaries`** (start outside host media range) for Markers report filtering / the opt-in **Hidden** column — see [20 — Reporting](20-Reporting.md#markers).

**Annotation occupancy policy:** Visible hosts emit full clip annotations (`.all`). Fully occluded hosts (e.g. covered connected clips) still emit **markers and keywords only** (`.markersAndKeywordsOnly`) so Tags-visible notes remain reportable; Titles / Transitions / Effects stay gated to visible occupancy. Keyword ranges clamp to the host media in-point so `start="0s"` keywords on clips with a later media `start` stay placeable. Sequences that omit `tcFormat` default to **NDF** when resolving absolute times for formatting.

Timing composition uses **`ProjectionTiming`** (Double intermediates → `Fraction` at 12 decimal places). Do not use SwiftTimecode `Fraction.+` / `.-` for absolute timeline placement when mixing conform-scaled values with literal FCPXML rationals — see [03 — Timecode & Timing](03-Timecode-Timing.md).

---

## Occupancy index

```swift
let index = FinalCutPro.FCPXML.TimelineOccupancyIndex(windows: windows)
let occupiedSeconds = index.occupiedDuration() // union of window intervals in seconds
let overlapping = index.windows(overlapping: start, end: end) // start-sorted binary-search overlap

// Retiming algebra (compose nested warps; clip to a timeline range)
let composed = FinalCutPro.FCPXML.RetimingSegment.composing(
    parents: parentSegments,
    children: childSegments
)
if let first = composed.first,
   let clipped = first.clipped(toTimelineStart: inPoint, timelineEnd: outPoint) {
    _ = clipped
}
```

Overlap-aware Summary uses this path when `ReportOptions.summaryOverlapAwareDurations == true` (API-only; default off).

**Half-open spans:** `RetimingSegment` timeline / media bounds are half-open (`[start, end)` — exclusive end). Report Out columns convert exclusive ends to the **last visible frame** in Reporting only (`ReportFormatting.outTimecodeString`); Duration stays `end − start`. See [20 — Reporting](20-Reporting.md) and Sign `report-out-is-last-visible-frame`.

---

## Large timelines

Projection is the hot path on big exports, so it avoids re-deriving facts it already knows:

- A projection installs a **scoped timing cache** for its walk, so each element resolves its `conform-rate` factor once instead of on every attribute read. See [02 — Loading & Parsing](02-Loading-Parsing.md#large-documents).
- Story traversal uses `fcpProjectableStoryElements`, which skips annotation leaves (`keyword`, `marker`, …). Annotations are still collected — from the host, once — when `includeAnnotations` is on.
- Turn off `includeMarkerAnnotations` / `includeKeywordAnnotations` when the consumer does not read them.
- Use the streaming overload (`project(from:fcpxml:options:) { window in … }`) when you only need to fold windows into a result; it avoids holding the full array.

A 28 MB FCPXML with a few thousand clips projects in seconds on an 8 GB machine; if a projection appears to hang, check for a mutation happening mid-walk before assuming a geometry problem.

---

## Reporting integration

When Role Inventory, Markers, Keywords, Titles & Generators, Transitions, Effects, Speed Change, Media Summary, or Summary is enabled, `ReportBuilder`:

1. Emits progress phase **`.projecting`**
2. Projects the timeline **once**
3. Shares **`ReportProjectionContext`** with section builders

Markers / Keywords / Titles / Transitions / Effects are **Projection-first**. Extraction fallback runs when annotations are absent **or** when Projection annotations filter to zero report rows (e.g. formatting failure). Inventory / Speed Change / Media Summary / Summary overlay or prefer window geometry.

Role Inventory host inclusion for nested / fully occluded connected clips (own `audioRole` / `videoRole` / channel-source / first-gen child `role`) is Reporting + Parsing policy — see [20 — Reporting](20-Reporting.md#role-inventory). Projection occupancy for those clips was already correct.

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.mediaResolutionPolicy = .failSoft   // or .failLoud → throw on projection failure
options.mediaSummaryDistinguishProxyAndOriginal = true
options.summaryOverlapAwareDurations = false // API-only
options.emitPerSourceInventoryRows = false   // API-only hook

let report = try await fcpxml.buildReport(options: options) { phase in
    print(phase.rawValue) // includes "Projecting Timeline" when needed
}
```

CLI: `--media-resolution fail-soft|fail-loud`, `--media-summary-distinguish-proxy`. Overlap-aware Summary and per-source inventory rows are library options only.

See [20 — Reporting, Excel & PDF Export](20-Reporting.md).

For private complex exports used only while debugging Projection/reporting, use [Submitted FCPXML](../../Tests/Submitted%20FCPXML/README.md) (gitignored; never commit to GitHub).

---

## Next

- [13 — Media Processing](13-Media-Processing.md) — MIME type, asset validation, silence, duration, parallel I/O.
- [20 — Reporting, Excel & PDF Export](20-Reporting.md) — build Excel/PDF from Projection + Extraction.
- [21 — Shot Extraction](21-Shot-Extraction.md) — still-image shots from primary timeline.
- [22 — Examples](22-Examples.md) — end-to-end workflows.

[← Manual Index](00-Index.md)

