# 12 — Timeline Projection

[← Manual Index](00-Index.md)

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
options.expandAllSourceChannels = true   // one window per video/audio src (default)

// Preset aligned with main-timeline Extraction visibility
let main = FinalCutPro.FCPXML.TimelineProjectionOptions.mainTimeline

// Preset for playable “active mix” track analysis (active audition/angles; all source channels)
let track = FinalCutPro.FCPXML.TimelineProjectionOptions.trackAnalysis
```

Report builds use `TimelineProjectionOptions.forReport(...)` so `excludeDisabledClips` and annotation needs stay consistent across sections.

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
---

## Reporting integration

When Role Inventory, Markers, Keywords, Titles & Generators, Transitions, Effects, Speed Change, Media Summary, or Summary is enabled, `ReportBuilder`:

1. Emits progress phase **`.projecting`**
2. Projects the timeline **once**
3. Shares **`ReportProjectionContext`** with section builders

Markers / Keywords / Titles / Transitions / Effects are **Projection-first**. Extraction fallback runs when annotations are absent **or** when Projection annotations filter to zero report rows (e.g. formatting failure). Inventory / Speed Change / Media Summary / Summary overlay or prefer window geometry.

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
- [21 — Examples](21-Examples.md) — end-to-end workflows.

[← Manual Index](00-Index.md)

