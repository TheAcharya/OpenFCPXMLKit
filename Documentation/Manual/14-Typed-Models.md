# 14 — Typed Models

[← Manual Index](00-Index.md)

---

The codebase provides **typed FCPXML element models** under **FinalCutPro.FCPXML** (e.g. Clip, Asset, Format, Caption, Title) and in **Model/** (Adjustments, Filters, Structure, etc.). They conform to **FCPXMLElement** and integrate with **FCPXMLAnyTimeline** and element-type filtering. This chapter summarizes the main groups and gives short examples.

---

## Adjustment models

Typed models with **Clip** accessors (see **FCPXMLClip+Adjustments**):

| Model | Notes |
|-------|--------|
| **CropAdjustment** | Crop, trim, pan modes |
| **CornersAdjustment** | Four-corner pin (`adjust-corners`) |
| **TransformAdjustment** | Position, scale, rotation, anchor |
| **BlendAdjustment** | Blend amount and mode |
| **StabilizationAdjustment** | automatic, inertiaCam, smoothCam |
| **VolumeAdjustment** | Volume level |
| **PannerAdjustment** | Stereo/surround panner (`adjust-panner`) |
| **LoudnessAdjustment** | Loudness parameters |
| **NoiseReductionAdjustment** | Amount |
| **HumReductionAdjustment** | 50Hz / 60Hz |
| **EqualizationAdjustment** | Modes: flat, voiceEnhance, musicEnhance, loudness, humReduction, bassBoost, etc. |
| **MatchEqualizationAdjustment** | Match EQ with keyed data |
| **Transform360Adjustment** | 360° video; coordinate types spherical/cartesian |
| **ReorientAdjustment** (1.7+) | Reorient |
| **OrientationAdjustment** (1.7+) | Orientation mapping |
| **CinematicAdjustment** (1.10+) | Cinematic |
| **ColorConformAdjustment** (1.11+) | Color conform |
| **Stereo3DAdjustment** (1.13+) | Stereo 3D |
| **VoiceIsolationAdjustment** (1.14) | Voice isolation |
| **ConformAdjustment** | Conform type |
| **RollingShutterAdjustment** | Rolling shutter amount |

Example:

```swift
var clip = FinalCutPro.FCPXML.Clip(duration: Fraction(5, 1))
var transform360 = FinalCutPro.FCPXML.Transform360Adjustment(
    coordinateType: .spherical,
    isEnabled: true,
    autoOrient: true
)
transform360.latitude = 45.0
clip.transform360Adjustment = transform360
clip.noiseReductionAdjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.5)
```

---

## Effect and filter models

- **VideoFilter**, **AudioFilter** — Filters with **FilterParameter** list
- **VideoFilterMask** — Mask shape and isolation
- **FilterParameter** — name, value, **FadeIn**, **FadeOut**, **KeyframeAnimation**; **auxValue** (1.11+)

```swift
var filter = FinalCutPro.FCPXML.VideoFilter(name: "Color Correction")
filter.parameters = [
    FinalCutPro.FCPXML.FilterParameter(name: "Brightness", value: "1.0"),
    FinalCutPro.FCPXML.FilterParameter(name: "Contrast", value: "1.2")
]
var clip = FinalCutPro.FCPXML.Clip(duration: Fraction(5, 1))
clip.videoFilters = [filter]
```

---

## Caption and title models

- **Caption**, **Title** — With **TextStyle** and **TextStyleDefinition**
- **TextStyle** — font, fontSize, fontColor, isBold, alignment, etc.
- **TextStyleDefinition** — id, name, textStyles array

```swift
var caption = FinalCutPro.FCPXML.Caption(duration: Fraction(5, 1))
var textStyle = FinalCutPro.FCPXML.TextStyle()
textStyle.font = "Helvetica"
textStyle.fontSize = 24
textStyle.fontColor = "1.0 1.0 1.0 1.0"
textStyle.alignment = .center
let styleDef = FinalCutPro.FCPXML.TextStyleDefinition(
    id: "ts1",
    name: "Caption Style",
    textStyles: [textStyle]
)
caption.typedTextStyleDefinitions = [styleDef]
```

---

## Keyframe animation

- **KeyframeAnimation** — keyframes array
- **Keyframe** — time, value, interpolation, curve; **auxValue** (1.11+)
- **FadeIn**, **FadeOut** — type (linear, easeIn, easeOut, easeInOut), duration
- **FadeType**, **KeyframeInterpolation**, **KeyframeCurve**

```swift
let fadeIn = FinalCutPro.FCPXML.FadeIn(
    type: .easeIn,
    duration: CMTime(seconds: 1.0, preferredTimescale: 600)
)
let keyframe1 = FinalCutPro.FCPXML.Keyframe(
    time: CMTime(seconds: 0.0, preferredTimescale: 600),
    value: "0.0",
    interpolation: .linear,
    curve: .smooth
)
let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])
let parameter = FinalCutPro.FCPXML.FilterParameter(
    name: "Opacity",
    fadeIn: fadeIn,
    fadeOut: nil,
    keyframeAnimation: animation
)
```

---

## Live Drawing (FCPXML 1.11+)

**LiveDrawing** is the typed model for the `live-drawing` story element (drawn/sketch content). Attributes: **role**, **dataLocator**, **animationType**; conforms to **FCPXMLElementClipAttributes** and **FCPXMLElementMetaTimeline**. Included in **allTimelineCases** and **FCPXMLAnyTimeline** (`.liveDrawing(LiveDrawing)`).

```swift
var liveDrawing = FinalCutPro.FCPXML.LiveDrawing(
    role: "video",
    dataLocator: "r1",
    animationType: "draw",
    lane: 0,
    offset: nil,
    name: "Sketch",
    start: nil,
    duration: Fraction(5, 1),
    enabled: true,
    note: nil
)
// Round-trip via AnyTimeline
if let element = liveDrawing.element.fcpAsLiveDrawing { /* use element */ }
```

---

## Hidden clip marker (FCPXML 1.13+)

**HiddenClipMarker** — empty element, no attributes. In **fcpxAnnotations** and **addToClip(annotationElements:)**; version converter strips when converting to &lt; 1.13.

```swift
let marker = FinalCutPro.FCPXML.HiddenClipMarker()
// Add to clip via fcpxAnnotations / addToClip(annotationElements:)
```

Do **not** confuse this DTD element with the Markers **report** concept of “Hidden”: report **Hidden** means a normal `marker` / `chapter-marker` whose `start` is outside the host clip’s media range (omitted by default; opt in with `includeMarkersOutsideClipBoundaries` / `--include-markers-outside-clip-boundaries`). See [19 — Reporting](20-Reporting.md#markers).

---

## Format and Asset (1.13+)

- **Format:** **heroEye** (left | right) for stereoscopic
- **Asset:** **heroEyeOverride** (left | right), **mediaReps** (multiple **MediaRep**, each conforming to FCPXMLElement). Each **MediaRep** may contain an optional **bookmark** child (e.g. security-scoped bookmark for the media file).

Version converter strips heroEye/heroEyeOverride when converting to &lt; 1.13.

---

## Smart collection match rules

**FCPXMLSmartCollection** has typed match rules: **MatchText**, **MatchRatings**, **MatchMedia**, **MatchClip**, **MatchStabilization**, **MatchKeywords**, **MatchShot**, **MatchProperty**, **MatchTime**, **MatchTimeRange**, **MatchRoles**, **MatchUsage** (1.9+), **MatchRepresentation** (1.10+), **MatchMarkers** (1.10+), **MatchAnalysisType** (1.14). All Codable; round-trip and version stripping supported.

---

## Collection folders and keyword collections

- **CollectionFolder** — Nested folders; **collectionFolders**, **keywordCollections**
- **KeywordCollection** — name and organization

```swift
let keywords1 = FinalCutPro.FCPXML.KeywordCollection(name: "Action Scenes")
let subfolder = FinalCutPro.FCPXML.CollectionFolder(
    name: "Subfolder",
    keywordCollections: [keywords1]
)
let parentFolder = FinalCutPro.FCPXML.CollectionFolder(
    name: "My Project",
    collectionFolders: [subfolder],
    keywordCollections: []
)
```

---

## Next

- [15 — XML Extensions](15-XML-Extensions.md) — OFKXMLDocument and OFKXMLElement FCPXML APIs.

[← Manual Index](00-Index.md)

