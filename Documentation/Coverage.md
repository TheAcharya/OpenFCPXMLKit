# OpenFCPXMLKit — FCPXML Coverage

Living inventory of how OpenFCPXMLKit covers Final Cut Pro FCPXML across layers. Prefer this file when asking “is element *X* typed / authored / projected / reported?” Prefer [GUARDRAILS.md](../GUARDRAILS.md) for must / must-not, and [ARCHITECTURE.md](../ARCHITECTURE.md) §2.7 for where new work belongs.

**Keep in sync** when adding Model types, Authoring encode/decode, Extraction presets, Projection walks, or Reporting sheets. Suite context: **1137** tests listed (`swift test list`); FCPXML **1.5–1.14**.

**Related Manual:** [08 — Detached Authoring](Manual/08-Detached-Authoring.md) · [11 — Extraction](Manual/11-Extraction-Media.md) · [12 — Projection](Manual/12-Timeline-Projection.md) · [14 — Typed Models](Manual/14-Typed-Models.md) · [20 — Reporting](Manual/20-Reporting.md)

---

## Table of Contents

- [1. Legend & how to read this matrix](#1-legend--how-to-read-this-matrix)
- [2. Layer overview](#2-layer-overview)
- [3. Resources](#3-resources)
- [4. Structure (library → sequence)](#4-structure-library--sequence)
- [5. Story / spine items](#5-story--spine-items)
- [6. Adjustments](#6-adjustments)
- [7. Filters, masks & parameters](#7-filters-masks--parameters)
- [8. Animations & keyframes](#8-animations--keyframes)
- [9. Annotations (markers, keywords, text)](#9-annotations-markers-keywords-text)
- [10. Smart collections](#10-smart-collections)
- [11. Retiming & channels](#11-retiming--channels)
- [12. Version-gated features](#12-version-gated-features)
- [13. Extraction presets](#13-extraction-presets)
- [14. Projection walk](#14-projection-walk)
- [15. Reporting sheets](#15-reporting-sheets)
- [16. Authoring intentional gaps](#16-authoring-intentional-gaps)
- [17. Capability summary matrix](#17-capability-summary-matrix)
- [18. Appendix — full `FCPXMLElementType` catalogue](#18-appendix--full-fcpxmlelementtype-catalogue)

---

## 1. Legend & how to read this matrix

| Token | Meaning |
|-------|---------|
| **yes** | First-class typed API or full walk/export in that layer |
| **partial** | Some attributes / children / hosts only |
| **name** | Present in `FCPXMLElementType` (and usually in the live XML tree) but no dedicated typed Model wrapper beyond the enum / generic access |
| **—** | Not applicable, or not implemented in that layer |

**Layer columns**

| Column | Meaning |
|--------|---------|
| **Type** | `FCPXMLElementType` case (DTD inventory) |
| **Model** | Live typed wrapper under `Model/` (or Annotations creation twin) |
| **Auth** | Detached `FinalCutPro.FCPXML.Authoring` encode/decode |
| **Ext** | Extraction (`fcpExtract` / presets) |
| **Proj** | Timeline Projection (`TimelineProjector` walk / annotations) |
| **Rep** | Excel/PDF Reporting consumes the fact (sheet or inventory) |
| **Export** | `Timeline` / `FCPXMLExporter` path (creation-oriented) |

**Two element enums**

| Enum | Role |
|------|------|
| `FCPXMLElementType` | Full DTD inventory (~**115** named cases + `none`; **113** unique DTD tags + 2 inferred `media@*` kinds) |
| `FinalCutPro.FCPXML.ElementType` | Smaller live-model filter set — does **not** list every DTD name |

**Important:** Every DTD element name is **identifiable** via `FCPXMLElementType`. That is not the same as a typed Model struct, Authoring support, or a report sheet.

---

## 2. Layer overview

```text
XML / DTD  →  Parsing  →  Model  →  Extraction  →  Projection  →  Reporting
                              ↘
                         Authoring   (parallel create; omit-on-write)
                              ↘
                         Timeline / Export   (parallel create)
```

| Layer | Owns | Must not |
|-------|------|----------|
| **Model / Parsing** | Typed facts, attributes, children | Report presentation |
| **Authoring** | Detached value graph → XML | Live wrappers; Reporting imports |
| **Extraction** | Discovery + context (roles, occlusion, presets) | Sheet layout |
| **Projection** | Playable occupancy, retiming, unfold | Excel/PDF styling |
| **Reporting** | Rows, columns, colours, workbooks/PDFs | New FCPXML semantics |
| **Timeline Export** | In-memory `Timeline` → FCPXML | Authoring types |

---

## 3. Resources

| Element | Type case | Model | Auth | Ext | Proj | Rep | Notes |
|---------|-----------|-------|------|-----|------|-----|-------|
| `fcpxml` | `fcpxml` | `Root` | **yes** `Document` | — | — | — | Root + version |
| `resources` | `resourceList` | via root | **yes** `Resources` | — | resolve | — | |
| `asset` | `assetResource` | `Asset` | **yes** `Asset` | — | resolve | Media Summary | Model: `heroEyeOverride` 1.13+, `mediaReps`; Auth: **partial** (no `heroEyeOverride`) |
| `format` | `formatResource` | `Format` | **yes** `Format` | — | — | — | Model: `heroEye` 1.13+; Auth: **partial** (no `heroEye`) |
| `media` | `mediaResource` | `Media` | **yes** `Media` | — | unfold | — | |
| `media`+`<multicam>` | `multicamResource` (`media@multicam`) | `Media.Multicam` | **yes** `Multicam` | — | **yes** | — | Inferred kind |
| `media`+`<sequence>` | `compoundResource` (`media@sequence`) | `Media` + sequence | **yes** `MediaSequence` | — | **yes** | — | Inferred kind |
| `effect` | `effectResource` | `Effect` | **yes** `Effect` | partial | partial | Effects names | Titles / transitions / filters `ref` |
| `locator` | `locator` | `Locator` | — | — | — | — | FCPXML 1.14+ |
| `media-rep` | `mediaRep` | `MediaRep` | **yes** `MediaRep` | — | URLs | Media Summary | |
| `metadata` / `md` | `metadata` / `md` | `Metadata` / `Metadatum` | — | — | — | Inventory dynamic keys | |
| `bookmark` | `bookmark` | protocol child | — | — | — | — | |
| `object-tracker` | `objectTracker` | `ObjectTracker` | — | — | — | — | Gate **1.10+** |
| `tracking-shape` | `trackingShape` | `TrackingShape` | — | — | — | — | |
| `import-options` / `option` | `importOptions` / `option` | `ImportOption` (value) | — | — | — | — | 1.14+ |
| `multicam` | `multicam` | `Media.Multicam` | **yes** | — | **yes** | — | Inside `media` |
| `mc-angle` | `mcAngle` | `Media.Multicam.Angle` | **yes** `MCAngle` | — | **yes** | — | |

---

## 4. Structure (library → sequence)

| Element | Type case | Model | Auth | Export | Notes |
|---------|-----------|-------|------|--------|-------|
| `library` | `library` | `Library` | **yes** | **yes** | |
| `event` | `event` | `Event` | **yes** | **yes** | |
| `project` | `project` | `Project` | **yes** | **yes** | Report timeline source |
| `sequence` | `sequence` | `Sequence` | **yes** | **yes** | Also inside compound `media` |
| `spine` | `spine` | `Spine` | **yes** | **yes** | Primary + nested |
| `collection-folder` | `folder` | `CollectionFolder` | — | — | |
| `keyword-collection` | `keywordCollection` | `KeywordCollection` | — | — | |
| `smart-collection` | `smartCollection` | `SmartCollection` | — | **yes** (optional defaults) | See §10 |

---

## 5. Story / spine items

| Element | Type case | Model | Auth | Ext | Proj | Rep | Notes |
|---------|-----------|-------|------|-----|------|-----|-------|
| `asset-clip` | `assetClip` | `AssetClip` | **yes** (+ volume / cinematic) | **yes** | **yes** leaf | Inventory / sections | |
| `clip` | `clip` | `Clip` (+ adj/filters) | — | **yes** | **yes** shell | via windows | Auth intentional gap |
| `ref-clip` | `compoundClip` | `RefClip` | **yes** | **yes** | **yes** unfold | Inventory | |
| `sync-clip` | `synchronizedClip` | `SyncClip` | **yes** | **yes** | **yes** shell | Inventory | |
| `sync-source` | `syncSource` | `SyncClip.SyncSource` | **yes** | — | — | — | |
| `mc-clip` | `multicamClip` | `MCClip` | **yes** | **yes** | **yes** unfold | Inventory | |
| `mc-source` | `mcSource` | `MulticamSource` | **yes** | — | **yes** | — | |
| `video` | `video` | `Video` | **yes** | **yes** | **yes** leaf | Inventory | |
| `audio` | `audio` | `Audio` | **yes** | **yes** | **yes** leaf | Inventory | |
| `audition` | `audition` | `Audition` | **yes** | **yes** | **yes** | Inventory | `.active` / `.all` options |
| `gap` | `gap` | `Gap` | **yes** | — | **yes** shell | — | No media windows |
| `title` | `title` | `Title` (+ typed) | **partial** attrs | **yes** Titles | **yes** annot | Titles sheet | Auth: no text styles |
| `transition` | `transition` | `Transition` | **partial** attrs | **yes** | **yes** annot | Transitions sheet | |
| `caption` | `caption` | `Caption` | **yes** (+ note) | **yes** Captions | skip leaf* | — | *Proj: not a media channel |
| `live-drawing` | `liveDrawing` | `LiveDrawing` | — | ? | — | — | Gate **1.11+** |

### Authoring `SpineItem` cases

| Case | Element |
|------|---------|
| `.assetClip` | `asset-clip` |
| `.gap` | `gap` |
| `.title` | `title` |
| `.transition` | `transition` |
| `.video` / `.audio` | `video` / `audio` |
| `.caption` | `caption` |
| `.syncClip` | `sync-clip` |
| `.refClip` | `ref-clip` |
| `.mcClip` | `mc-clip` |
| `.audition` | `audition` |

**Not in Authoring `SpineItem`:** generic `clip`, `live-drawing`, markers/keywords, filter instances, most adjustments, `timeMap` / `conform-rate`.

---

## 6. Adjustments

All live models live under `Model/Adjustments/` and integrate via `Clip+Adjustments` (and related clip types) unless noted.

| Element | Model | Auth | Ext / Effects collector | Proj annot | Gate |
|---------|-------|------|---------------------------|------------|------|
| `adjust-crop` | `CropAdjustment` (+ `crop-rect` / `trim-rect` / `pan-rect`) | — | **yes** | **yes** | — |
| `adjust-corners` | `CornersAdjustment` | — | **yes** | **yes** | — |
| `adjust-conform` | `ConformAdjustment` | — | **yes** | **yes** | — |
| `adjust-transform` | `TransformAdjustment` | — | **yes** | **yes** | — |
| `adjust-blend` | `BlendAdjustment` | — | **yes** | **yes** | — |
| `adjust-stabilization` | `StabilizationAdjustment` | — | **yes** | **yes** | — |
| `adjust-rollingShutter` | `RollingShutterAdjustment` | — | **yes** | **yes** | — |
| `adjust-360-transform` | `Transform360Adjustment` | — | **yes** | **yes** | — |
| `adjust-reorient` | `ReorientAdjustment` | — | **yes** | **yes** | — |
| `adjust-orientation` | `OrientationAdjustment` | — | **yes** | **yes** | — |
| `adjust-cinematic` | `CinematicAdjustment` | **yes** (on `AssetClip`) | **yes** | **yes** | **1.10+** |
| `adjust-colorConform` | `ColorConformAdjustment` | — | **yes** | **yes** | **1.11+** |
| `adjust-stereo-3D` | `Stereo3DAdjustment` | — | **yes** | **yes** | **1.13+** |
| `adjust-loudness` | `LoudnessAdjustment` | — | **yes** | **yes** | — |
| `adjust-noiseReduction` | `NoiseReductionAdjustment` | — | **yes** | **yes** | — |
| `adjust-humReduction` | `HumReductionAdjustment` | — | **yes** | **yes** | — |
| `adjust-EQ` | `EqualizationAdjustment` | — | **yes** | **yes** | — |
| `adjust-matchEQ` | `MatchEqualizationAdjustment` | — | **yes** | **yes** | — |
| `adjust-voiceIsolation` | `VoiceIsolationAdjustment` | — | **yes** | **yes** | **1.11+** (gate; also 1.14 docs elsewhere) |
| `adjust-volume` | `VolumeAdjustment` | **yes** | **yes** | **yes** | — |
| `adjust-panner` | `PannerAdjustment` | — | **yes** | **yes** | — |

**Count:** 20 typed adjustments (+ nested crop rects / `Point` helper).  
**Authoring:** only `adjust-volume` + `adjust-cinematic`.

---

## 7. Filters, masks & parameters

| Element | Model | Auth | Ext | Proj | Rep |
|---------|-------|------|-----|------|-----|
| `filter-video` | `VideoFilter` | — | **yes** Effects | **yes** annot | Effects sheet |
| `filter-audio` | `AudioFilter` | — | **yes** | **yes** | Effects sheet |
| `filter-video-mask` | `VideoFilterMask` | — | partial | partial | via Effects |
| `mask-shape` | `MaskShape` | — | — | — | — |
| `mask-isolation` | `MaskIsolation` | — | — | — | — |
| `param` | `FilterParameter` | — | **yes** | **yes** | — |
| `data` | keyed data on filters | — | — | — | — |
| `mute` | `Mute` | — | — | — | — |

**EffectsCollector hosts (collection):** `title`, `asset-clip`, `sync-clip`, `ref-clip`, `mc-clip`, `clip`, `audio`, `video`  
**EffectsExtractionPreset top-level hosts:** `title`, `asset-clip`, `sync-clip` (narrower than collector)

---

## 8. Animations & keyframes

| Element | Model | Auth | Notes |
|---------|-------|------|-------|
| `keyframeAnimation` | `KeyframeAnimation` | — | Under params / volume |
| `keyframe` | `Keyframe` | — | `auxValue` gated **1.11+** |
| `fadeIn` / `fadeOut` | `FadeIn` / `FadeOut` | — | |
| `param` + nested animation | `FilterParameter` | — | `auxValue` gated **1.11+** |

Authoring does **not** encode keyframes or fades. Projection **retiming** (`timeMap` / conform) is separate from parameter keyframes (see §11).

---

## 9. Annotations (markers, keywords, text)

| Element | Model / Annotations | Auth | Ext | Proj | Rep |
|---------|---------------------|------|-----|------|-----|
| `marker` | `Marker` | — | **yes** Markers preset | **yes** | Markers (Proj-first) |
| `chapter-marker` | `Marker` / `ChapterMarker` | — | **yes** | **yes** | Markers (default on; Type = Chapter) |
| `analysis-marker` | `AnalysisMarker` | — | **yes** (Markers preset) | partial? | Markers? |
| `hidden-clip-marker` | `HiddenClipMarker` | — | — | — | — | Gate **1.13+**; ≠ Markers **Hidden** column |
| `keyword` | `Keyword` | — | context / Keywords | **yes** | Keywords (Proj-first) |
| `rating` | creation `Rating`; Model **name** | — | — | — | — | No dedicated sheet |
| `note` | child / attrs | **partial** (Caption) | — | — | — |
| `text` | `Text` | — | — | partial (title) | Titles |
| `text-style` / `text-style-def` | `TextStyle` / `TextStyleDefinition` | — | — | — | — |

**Reporting vs DTD:** Markers sheet **Hidden** (✓/✗) means *start outside host media range* (`includeMarkersOutsideClipBoundaries`). It is **not** `hidden-clip-marker`.

---

## 10. Smart collections

| Element | Model | Auth | Min version |
|---------|-------|------|-------------|
| `smart-collection` | `SmartCollection` | — | — |
| `match-text` | `MatchText` | — | always |
| `match-ratings` | `MatchRatings` | — | always |
| `match-media` | `MatchMedia` | — | always |
| `match-clip` | `MatchClip` | — | always |
| `match-stabilization` | `MatchStabilization` | — | always |
| `match-keywords` / `keyword-name` | `MatchKeywords` / `KeywordName` | — | always |
| `match-shot` / `shot-type` | `MatchShot` / `ShotType` | — | always |
| `stabilization-type` | `StabilizationType` | — | always |
| `match-property` | `MatchProperty` | — | keys + `isSet`/`isNotSet` **1.11+** |
| `match-time` / `match-timeRange` | `MatchTime` / `MatchTimeRange` | — | always |
| `match-roles` / `role` | `MatchRoles` / `Role` | — | always |
| `match-usage` | `MatchUsage` | — | **1.9+** |
| `match-representation` | `MatchRepresentation` | — | **1.10+** |
| `match-markers` | `MatchMarkers` | — | **1.10+** |
| `match-analysis-type` | `MatchAnalysisType` | — | **1.14+** |

`SmartCollectionRule` operators include includes / includesAny / includesAll / doesNotInclude* / is / isNot / isAfter / isBefore / isInLast / isNotInLast / startsWith / endsWith / **isSet** / **isNotSet**.

---

## 11. Retiming & channels

| Element | Model | Auth | Proj | Rep |
|---------|-------|------|------|-----|
| `conform-rate` | `ConformRate` | — | **yes** scale | Speed / Summary |
| `timeMap` / `timept` | `TimeMap` / `TimePoint` | — | **yes** segments | Speed Change sheet |
| `audio-channel-source` | `AudioChannelSource` | — | partial (expand) | Inventory channels |
| `audio-role-source` | `AudioRoleSource` | — | — | roles |

**Projection APIs (not elements):** `RetimingSegment` (`clipped`, `composing`), `TimelineOccupancyIndex`, `AudioSplitRetiming` (J/L via `audioStart` / `audioDuration`), `TimelineProjectionOptions.trackAnalysis`.

---

## 12. Version-gated features

From `FinalCutPro.FCPXML.VersionFeatureGate` (Authoring omit-on-write + converter fallback when DTD allowlists unavailable). Prefer DTD allowlist stripping when DTDs are present.

### Elements

| Element | Min version |
|---------|-------------|
| `match-usage` | 1.9 |
| `object-tracker` | 1.10 |
| `adjust-cinematic` | 1.10 |
| `match-representation` | 1.10 |
| `match-markers` | 1.10 |
| `adjust-colorConform` | 1.11 |
| `adjust-voiceIsolation` | 1.11 |
| `live-drawing` | 1.11 |
| `adjust-stereo-3D` | 1.13 |
| `hidden-clip-marker` | 1.13 |
| `match-analysis-type` | 1.14 |

### Attributes

| Element | Attribute | Min version |
|---------|-----------|-------------|
| `param` | `auxValue` | 1.11 |
| `keyframe` | `auxValue` | 1.11 |
| `format` | `heroEye` | 1.13 |
| `asset` | `heroEyeOverride` | 1.13 |

**Floor:** Entire codebase remains compatible with FCPXML **1.5** (omit or ignore newer optional features when targeting 1.5).

---

## 13. Extraction presets

| Preset | Extracts |
|--------|----------|
| `MarkersExtractionPreset` | `marker`, `chapter-marker`, `analysis-marker` → `ExtractedMarker` |
| `EffectsExtractionPreset` | effects on `title` / `asset-clip` / `sync-clip` → `ExtractedEffect` |
| `TitlesExtractionPreset` | `title` (main-timeline visibility rules) |
| `CaptionsExtractionPreset` | `caption` → `ExtractedCaption` |
| `RolesExtractionPreset` | inherited roles by `RoleType` |
| `FrameDataPreset` | clip occupancy / frame data |

Scope flags (`ExtractionScope`, occlusion, audition/MC masks, `includeDisabled`) apply across presets. See Manual 11.

---

## 14. Projection walk

`SpineProjection` (and helpers) walk:

| Story kind | Behaviour |
|------------|-----------|
| `asset-clip` / `video` / `audio` | Media leaves → `MediaUsageWindow` |
| Nested `spine` | Recurse |
| `audition` | Active or all (`TimelineProjectionOptions`) |
| `mc-clip` | Angle unfold (`MulticamProjection`) |
| `ref-clip` | Compound sequence unfold (`RefClipProjection`) |
| `title` / `transition` | Annotations (no media channel) |
| `clip` / `sync-clip` / `gap` | Shells: children + annotations |
| Bare markers / keywords / captions as top-level leaves | Skipped as media; annotations attached via hosts |

Options presets: `.mainTimeline`, `.trackAnalysis`, `.forReport(...)`.

---

## 15. Reporting sheets

| Sheet | `ReportOptions` | Primary source | Fallback |
|-------|-----------------|----------------|----------|
| Selected Roles Inventory (+ per-role) | `includeRoleInventory` | **Projection** windows | Extraction clip walk |
| Markers | `includeMarkers` | **Projection** annotations (incl. occluded hosts; `mc-clip`/`ref-clip` hosts; chapter markers default on) | MarkersExtractionPreset (also keeps occluded-host markers) |
| Keywords | `includeKeywords` | **Projection** (same host/occlusion policy; range clamp) | Extraction keyword walk |
| Titles & Generators | `includeTitlesAndGenerators` | **Projection** | TitlesExtractionPreset |
| Transitions | `includeTransitions` | **Projection** | Extraction |
| Non-Std Effects & Templates | `includeNonStandardEffectsTemplates` | Document `<effect>` resources (non-Apple / missing `src`) | — |
| Video & Audio Effects | `includeEffects` | **Projection** annot | EffectsExtractionPreset |
| Speed Change Effects | `includeSpeedChangeEffects` | **Projection** retiming | Extraction `timeMap` |
| Summary | `includeSummary` | **Projection** + inventory agg | — |
| Media Summary | `includeMediaSummary` | **Projection** / media-reps | Document fallback |

Cover / TOC are presentation-only (Excel XLKit / PDF CoreGraphics). Build once via `buildReport(options:)`; project-once when any consuming section is enabled (`ReportBuildPhase` includes `.projecting`). Role inventory fixed columns after **Row**: **26** (includes Duplicate Frames, Frame Size / Audio Config, Codecs, Ingest Date). Per-role sheets may append an optimistic **Total:** Clip Duration footer. Non-Std Effects & Templates has no injected Row (Kind/UID row colours). Markers: `includeChapterMarkersInMarkersReport` defaults **`true`**; out-of-bounds markers remain opt-in via `includeMarkersOutsideClipBoundaries`. Summary presentation (Excel/PDF): B1 title banner, visual-section subtotal banner, `% of Total` as fraction with `0.0%` / `formattedPercentOfTotal` display. Effects Role ▸ Subrole uses type-filtered `RoleDisplayPreference`. Row-colour / subtotal / `%` formatting details: Manual 20.

---

## 16. Authoring intentional gaps

Detached Authoring is **incremental**. Documented non-goals / not-yet:

| Area | Status |
|------|--------|
| Markers / chapter markers / keywords / ratings | **not modeled** |
| Most filters / masks | **not modeled** |
| Metadata / `md` / bookmark | **not modeled** |
| Generic `<clip>` | **not modeled** (prefer `asset-clip` / compounds) |
| Adjustments beyond volume + cinematic | **not modeled** |
| Keyframes / fades / `timeMap` / `conform-rate` | **not modeled** |
| Smart collections / `match-*` | **not modeled** |
| `live-drawing`, `locator`, `object-tracker` | **not modeled** |
| `format.heroEye`, `asset.heroEyeOverride` | Model **yes**; Auth **no** |
| Decode | **limited subset** round-trip |
| Use inside Reporting | **forbidden** (Sign: `authoring-not-in-reporting`) |

---

## 17. Capability summary matrix

| Capability | Auth | Model | Ext | Proj | Rep | Timeline Export |
|------------|------|-------|-----|------|-----|-----------------|
| Resources (format/asset/effect/media) | **yes** (no locator) | **yes** | — | resolve | Media Summary | **yes** |
| Library → spine | **yes** | **yes** | walk | walk | timeline sources | **yes** |
| Generic `<clip>` | — | **yes** | **yes** | **yes** shell | via windows | **yes** |
| Compounds / multicam / audition | **yes** | **yes** | **yes** | **yes** unfold | Inventory | partial |
| Captions | **yes** | **yes** | **yes** | skip leaf | — | ? |
| Titles / transitions | **partial** | **yes** | **yes** | **yes** annot | Titles / Transitions | **yes** |
| Adjustments | volume + cinematic | **all 20** | Effects | annot | Effects | — |
| Filters / masks | — | **yes** | Effects | annot | Effects | — |
| Parameter keyframes | — | **yes** | via params | ≠ retiming | — | — |
| `timeMap` / conform retiming | — | **yes** | partial | **yes** | Speed | — |
| Markers / keywords | — | **yes** | **yes** | **yes** | Markers / Keywords | **yes** on Timeline |
| Smart collections | — | **yes** | — | — | — | default set |
| Version omit-on-write / strip | **yes** gate | convert | — | — | — | — |

---

## 18. Appendix — full `FCPXMLElementType` catalogue

Cases from `Sources/OpenFCPXMLKit/Classes/FCPXMLElementType.swift` (plus `none` with no raw value).

| Case | rawValue |
|------|----------|
| `none` | *(none)* |
| `fcpxml` | `fcpxml` |
| `importOptions` | `import-options` |
| `option` | `option` |
| `resourceList` | `resources` |
| `library` | `library` |
| `event` | `event` |
| `project` | `project` |
| `assetResource` | `asset` |
| `formatResource` | `format` |
| `mediaResource` | `media` |
| `effectResource` | `effect` |
| `locator` | `locator` |
| `multicamResource` | `media@multicam` *(inferred; tag `media`)* |
| `compoundResource` | `media@sequence` *(inferred)* |
| `mediaRep` | `media-rep` |
| `metadata` | `metadata` |
| `md` | `md` |
| `bookmark` | `bookmark` |
| `fadeIn` | `fadeIn` |
| `fadeOut` | `fadeOut` |
| `keyframeAnimation` | `keyframeAnimation` |
| `keyframe` | `keyframe` |
| `mute` | `mute` |
| `param` | `param` |
| `data` | `data` |
| `cropRect` | `crop-rect` |
| `trimRect` | `trim-rect` |
| `panRect` | `pan-rect` |
| `adjustCrop` | `adjust-crop` |
| `adjustCorners` | `adjust-corners` |
| `adjustConform` | `adjust-conform` |
| `adjustTransform` | `adjust-transform` |
| `adjustBlend` | `adjust-blend` |
| `adjustStabilization` | `adjust-stabilization` |
| `adjustRollingShutter` | `adjust-rollingShutter` |
| `adjust360Transform` | `adjust-360-transform` |
| `adjustReorient` | `adjust-reorient` |
| `adjustOrientation` | `adjust-orientation` |
| `adjustCinematic` | `adjust-cinematic` |
| `adjustColorConform` | `adjust-colorConform` |
| `adjustStereo3D` | `adjust-stereo-3D` |
| `adjustLoudness` | `adjust-loudness` |
| `adjustNoiseReduction` | `adjust-noiseReduction` |
| `adjustHumReduction` | `adjust-humReduction` |
| `adjustEQ` | `adjust-EQ` |
| `adjustMatchEQ` | `adjust-matchEQ` |
| `adjustVoiceIsolation` | `adjust-voiceIsolation` |
| `adjustVolume` | `adjust-volume` |
| `adjustPanner` | `adjust-panner` |
| `trackingShape` | `tracking-shape` |
| `objectTracker` | `object-tracker` |
| `audioChannelSource` | `audio-channel-source` |
| `audioRoleSource` | `audio-role-source` |
| `sequence` | `sequence` |
| `spine` | `spine` |
| `multicam` | `multicam` |
| `mcAngle` | `mc-angle` |
| `multicamClip` | `mc-clip` |
| `mcSource` | `mc-source` |
| `clip` | `clip` |
| `compoundClip` | `ref-clip` |
| `synchronizedClip` | `sync-clip` |
| `syncSource` | `sync-source` |
| `assetClip` | `asset-clip` |
| `audio` | `audio` |
| `video` | `video` |
| `liveDrawing` | `live-drawing` |
| `audition` | `audition` |
| `caption` | `caption` |
| `gap` | `gap` |
| `title` | `title` |
| `transition` | `transition` |
| `text` | `text` |
| `textStyleDef` | `text-style-def` |
| `textStyle` | `text-style` |
| `filterVideo` | `filter-video` |
| `filterVideoMask` | `filter-video-mask` |
| `maskShape` | `mask-shape` |
| `maskIsolation` | `mask-isolation` |
| `filterAudio` | `filter-audio` |
| `conformRate` | `conform-rate` |
| `timeMap` | `timeMap` |
| `timept` | `timept` |
| `marker` | `marker` |
| `rating` | `rating` |
| `keyword` | `keyword` |
| `analysisMarker` | `analysis-marker` |
| `hiddenClipMarker` | `hidden-clip-marker` |
| `chapterMarker` | `chapter-marker` |
| `note` | `note` |
| `keywordCollection` | `keyword-collection` |
| `folder` | `collection-folder` |
| `smartCollection` | `smart-collection` |
| `matchText` | `match-text` |
| `matchRatings` | `match-ratings` |
| `matchMedia` | `match-media` |
| `matchClip` | `match-clip` |
| `matchStabilization` | `match-stabilization` |
| `matchKeywords` | `match-keywords` |
| `keywordName` | `keyword-name` |
| `matchShot` | `match-shot` |
| `shotType` | `shot-type` |
| `stabilizationType` | `stabilization-type` |
| `matchProperty` | `match-property` |
| `matchTime` | `match-time` |
| `matchTimeRange` | `match-timeRange` |
| `matchRoles` | `match-roles` |
| `role` | `role` |
| `matchUsage` | `match-usage` |
| `matchRepresentation` | `match-representation` |
| `matchMarkers` | `match-markers` |
| `matchAnalysisType` | `match-analysis-type` |
| `reserved` | `reserved` |
| `array` | `array` |
| `string` | `string` |

### Authoring types → XML (quick index)

| Type | Encodes |
|------|---------|
| `Document` | `fcpxml` |
| `Resources` / `Format` / `Asset` / `MediaRep` / `Effect` / `Media` | matching resource tags |
| `MediaSequence` / `Multicam` / `MCAngle` | `sequence` / `multicam` / `mc-angle` |
| `Library` / `Event` / `Project` / `Sequence` / `Spine` | matching |
| Spine story structs | see §5 |
| `VolumeAdjustment` / `CinematicAdjustment` | `adjust-volume` / `adjust-cinematic` |
| Enums | `SpineItem`, `SyncClipContent`, `AuditionCandidate`, `MediaContent` |

Infrastructure (no element): `Authoring` namespace, `Context`, `Element` protocol, `VersionAvailability`, `Error`.

---

## Maintenance

When coverage changes:

1. Update the relevant section table(s) in this file.
2. If Authoring gains types, update §5 / §16 and Manual 08.
3. If Reporting gains sheets, update §15 and Manual 20.
4. Mention material coverage shifts in `CHANGELOG.md` under Improvements.

