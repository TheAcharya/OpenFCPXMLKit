# FCPXML DTD Version History (1.5 – 1.14)

This document is a **version-by-version comparison** of the Final Cut Pro XML (FCPXML) DTDs from 1.5 through 1.14. It is intended for contributors and implementors who need to understand schema evolution, version conversion, and compatibility.

**Source:** DTD files in this directory: `Final_Cut_Pro_XML_DTD_version_1.5.dtd` … `Final_Cut_Pro_XML_DTD_version_1.14.dtd`.

**Copyright:** DTDs are © 2011–2026 Apple Inc. This version history is documentation only and is not part of the official FCPXML specification.

---

## Table of Contents

1. [Document structure and root element](#1-document-structure-and-root-element)
2. [Resources: content model and resource types](#2-resources-content-model-and-resource-types)
3. [Asset model: from single `src` to `media-rep+`](#3-asset-model-from-single-src-to-media-rep)
4. [New elements by version](#4-new-elements-by-version)
5. [New attributes by version](#5-new-attributes-by-version)
6. [Removed or replaced entities / content models](#6-removed-or-replaced-entities--content-models)
7. [Intrinsic video/audio params evolution](#7-intrinsic-videoaudio-params-evolution)
8. [Smart collection rules](#8-smart-collection-rules)
9. [Version conversion notes (OpenFCPXMLKit)](#9-version-conversion-notes-OpenFCPXMLKit-CLI)
10. [Summary matrix](#10-summary-matrix)

---

## 1. Document structure and root element

| Version | Root `fcpxml` content model |
|---------|-----------------------------|
| **1.5** | `(import-options?, resources?, library)` — library required; no top-level events without library. |
| **1.6–1.14** | `(import-options?, resources?, (library \| event* \| (%event_item;)*))` — allows library, or events/event items (clips, projects, etc.) at top level. |

**Event content (`event` children):**

| Version | Event may contain |
|---------|-------------------|
| **1.5** | `clip \| audition \| mc-clip \| ref-clip \| %collection_item; \| project` |
| **1.6–1.14** | `clip \| audition \| mc-clip \| ref-clip \| sync-clip \| asset-clip \| %collection_item; \| project` |

So **1.6+** add **sync-clip** and **asset-clip** as direct event children.

---

## 2. Resources: content model and resource types

| Version | `resources` content model | New resource type |
|---------|----------------------------|-------------------|
| 1.5 | `(asset \| effect \| format \| media)*` | — |
| 1.6–1.9 | `(asset \| effect \| format \| media)*` | — |
| **1.10–1.14** | `(asset \| effect \| format \| media \| locator)*` | **locator** |

**Locator** (1.10+): `<!ELEMENT locator (bookmark?)>` with `id` (ID #REQUIRED), `url` (CDATA #REQUIRED). Used for URL-based references (e.g. linked media).

---

## 3. Asset model: from single `src` to `media-rep+`

| Version | `asset` content model | Asset source model |
|---------|------------------------|--------------------|
| **1.5–1.8** | `(bookmark?, metadata?)` | Single `src` attribute on `asset` (file URL). |
| **1.9–1.14** | `(media-rep+, metadata?)` | **media-rep** elements (one or more); each has `src`, optional `kind` (original-media \| proxy-media), `sig`, `suggestedFilename`. Asset no longer has `src`; `videoSources` added 1.9+. |

**Attribute changes on `asset`:**

| Version | Removed from asset | Added on asset |
|---------|--------------------|----------------|
| 1.5 | — | `colorOverride` (1.5 only) |
| 1.6 | `colorOverride` | `customLogOverride`, `colorSpaceOverride`, project/modDate on project, media modDate, library colorProcessing, effect src, clip_attrs_with_optional_duration, renderColorSpace (sequence, multicam), text-style baselineOffset, audition modDate, ref-clip useAudioSubroles, asset-clip audioRole/videoRole, etc. |
| 1.7 | — | format colorSpace, projection, stereoscopic; asset customLUTOverride, projectionOverride, stereoscopicOverride; timeMap/conform-rate nearest-neighbor; format projection "fisheye", "back-to-back fisheye"; **adjust-360-transform**, **adjust-reorient**, **adjust-orientation**; multicam no renderColorSpace in 1.7 |
| 1.8 | — | **caption**; clip/sync-clip content allows caption; anchor_item includes caption; text/text-style caption attrs (display-style, roll-up-height, position, placement, alignment, backgroundColor, underline) |
| 1.9 | asset `src` | **media-rep**; asset **videoSources**; smart-collection **match-usage** |
| 1.10 | — | **locator**; resources include locator; asset **auxVideoFlags**; format projection "fisheye" \| "back-to-back fisheye" (in 1.7+ already); **object-tracker**, **adjust-cinematic**; smart-collection **match-representation**, **match-markers** |
| 1.11 | — | keyframe **auxValue**; param **auxValue** |
| 1.12 | — | **adjust-colorConform** in intrinsic-params-video; smart-collection same as 1.11 |
| 1.13 | — | format **heroEye**; asset **heroEyeOverride**; **adjust-stereo-3D** in intrinsic-params-video |
| 1.14 | — | smart-collection **match-analysis-type** |

---

## 4. New elements by version

Elements introduced in each version (first appearance in DTD).

| Version | New element(s) |
|---------|----------------|
| **1.6** | **sync-clip**, **asset-clip**, **sync-source**; **audio-channel-source**, **audio-role-source** (replacing audio-source / audio-aux-source in content models). |
| **1.7** | **adjust-360-transform**, **adjust-reorient**, **adjust-orientation**. |
| **1.8** | **caption**. |
| **1.9** | **media-rep**. |
| **1.10** | **locator**; **object-tracker**, **tracking-shape**; **adjust-cinematic**. |
| **1.11** | (no new top-level elements; keyframe/param auxValue) |
| **1.12** | (adjust-colorConform already present as element in 1.12; **adjust-colorConform** in content model) |
| **1.13** | **adjust-stereo-3D** (element + in intrinsic-params-video). |
| **1.14** | (match-analysis-type in smart-collection; **intrinsic-params-live-drawing** entity) |

**Removed / replaced elements (when downgrading from 1.6+ to 1.5):**

- **1.5 only:** `audio-source`, `audio-aux-source` (replaced in 1.6 by audio-channel-source, audio-role-source).
- **1.5 sequence:** sequence contains `%audio_comp_items;` (audio-source*, audio-aux-source*); **1.6+** sequence is `(note?, spine, metadata?)` and clip-level audio uses audio-channel-source / audio-role-source.

---

## 5. New attributes by version

Selected attribute additions by version.

| Version | Element(s) | New attribute(s) |
|---------|------------|------------------|
| 1.6 | library | **colorProcessing** (standard \| wide) |
| 1.6 | project, media, clip, ref-clip, sync-clip, asset-clip, audition | **modDate** |
| 1.6 | effect | **src** |
| 1.6 | asset | **customLogOverride**, **colorSpaceOverride** (replacing colorOverride) |
| 1.6 | sequence, multicam | **renderColorSpace** |
| 1.6 | ref-clip | **useAudioSubroles** |
| 1.6 | asset-clip | **audioRole**, **videoRole** |
| 1.6 | text-style | **baselineOffset** |
| 1.7 | library | colorProcessing: **wide-hdr** |
| 1.7 | format | **colorSpace**, **projection**, **stereoscopic** |
| 1.7 | asset | **customLUTOverride**, **colorSpaceOverride**, **projectionOverride**, **stereoscopicOverride** |
| 1.7 | timeMap, conform-rate | **nearest-neighbor** in frameSampling |
| 1.8 | text | **display-style**, **roll-up-height**, **position**, **placement**, **alignment** (caption-related) |
| 1.8 | text-style | **backgroundColor**, **underline** (caption-related) |
| 1.9 | asset | **videoSources** (media-rep model) |
| 1.9 | media-rep | **kind**, **sig**, **src**, **suggestedFilename** |
| 1.10 | asset | **auxVideoFlags** |
| 1.10 | locator | **id**, **url** |
| 1.11 | keyframe | **auxValue** |
| 1.11 | param | **auxValue** |
| 1.13 | format | **heroEye** (left \| right) |
| 1.13 | asset | **heroEyeOverride** |
| 1.14 | (same as 1.13 for these; adjust-colorConform, adjust-stereo-3D present) | — |

---

## 6. Removed or replaced entities / content models

| Change | Versions |
|--------|----------|
| **%timelist%** entity | Declared in 1.5–1.9; **not** declared in 1.10–1.14. |
| **%event_item%** | 1.5: event content inlined (no event_item). 1.6+: `event_item` includes sync-clip, asset-clip. |
| **%audio_comp_items%** | 1.5 only: `(audio-source*, audio-aux-source*)`. Removed in 1.6; replaced by audio-channel-source*, audio-role-source* in clip/ref-clip/etc. |
| **%clip_item%** | 1.5: no sync-clip, asset-clip. 1.6+: includes sync-clip, asset-clip. |
| **%anchor_item%** | 1.5: no sync-clip, asset-clip. 1.6+: includes them. 1.8+: includes **caption**. |
| **sequence** | 1.5: `(note?, spine, %audio_comp_items;, metadata?)`. 1.6+: `(note?, spine, metadata?)`. |
| **mc-angle** | 1.5: `((%clip_item; \| transition)*, %audio_comp_items;)`. 1.6+: `((%clip_item; \| transition)*)` (no audio_comp_items). |
| **mc-source** | 1.5: `(%audio_comp_items;, %intrinsic-params-video;, …)`. 1.6+: `(audio-role-source*, %intrinsic-params-video;, …)`. |
| **clip** | 1.5: … `%audio_comp_items;` …. 1.6+: … `audio-channel-source*` …. 1.8+: content may include **caption**. |
| **ref-clip** | 1.5: … `%audio_comp_items;` …. 1.6+: … `audio-role-source*` …. |

---

## 7. Intrinsic video/audio params evolution

**%intrinsic-params-video%** (order and additions by version):

| Version | Contents |
|---------|----------|
| 1.5 | adjust-crop?, adjust-corners?, adjust-conform?, adjust-transform?, adjust-blend?, adjust-stabilization?, adjust-rollingShutter? |
| 1.6 | (same as 1.5) |
| 1.7, 1.8 | + adjust-360-transform?, adjust-reorient?, adjust-orientation? |
| 1.9 | (same as 1.7/1.8) |
| 1.10 | + **object-tracker?**, **adjust-cinematic?** |
| 1.11, 1.12 | + **adjust-colorConform?** |
| 1.13, 1.14 | + **adjust-stereo-3D?** |

**%intrinsic-params-audio%** (1.5 vs 1.6+):

| Version | Contents |
|---------|----------|
| 1.5 | adjust-loudness?, adjust-noiseReduction?, adjust-humReduction?, (adjust-EQ \| adjust-matchEQ)?, adjust-volume?, adjust-panner? |
| 1.6–1.14 | adjust-volume?, adjust-panner? (audio enhancements moved to %adjust-audio-enhancements% used inside audio-channel-source / audio-role-source) |

**%adjust-audio-enhancements%** (1.6+):  
`(adjust-loudness?, adjust-noiseReduction?, adjust-humReduction?, (adjust-EQ | adjust-matchEQ)?)` — used in audio-channel-source and audio-role-source.

---

## 8. Smart collection rules

**smart-collection** child rules (match-* elements):

| Version | Match rules included |
|---------|----------------------|
| 1.5–1.8 | match-text, match-ratings, match-media, match-clip, match-stabilization, match-keywords, match-shot, match-property, match-time, match-timeRange, match-roles |
| 1.9 | + **match-usage** |
| 1.10–1.11 | + **match-representation**, **match-markers** |
| 1.12 | (same as 1.11) |
| 1.13 | (same as 1.12) |
| 1.14 | + **match-analysis-type** |

**match-usage** (1.9+): `rule (used | unused) "used"`, `enabled (0 | 1) "1"`.

---

## 9. Version conversion notes (OpenFCPXMLKit)

When **converting to an older FCPXML version**, the OpenFCPXMLKit version converter:

- Sets the root `version` attribute to the target version.
- **Strips elements and attributes** that are not in the target version’s DTD. Examples:
  - **adjust-colorConform**, **adjust-stereo-3D**: present in 1.12+ (colorConform) and 1.13+ (stereo-3D); stripped when target &lt; 1.12 or &lt; 1.13 respectively.
  - **caption**, **object-tracker**, **adjust-cinematic**, **adjust-360-transform**, **adjust-reorient**, **adjust-orientation**: stripped when target is 1.5 or 1.6 where not defined.
  - **sync-clip**, **asset-clip**, **sync-source**, **locator**, **media-rep**: stripped or rewritten when target does not support them (e.g. 1.5).
  - **match-usage**, **match-representation**, **match-markers**, **match-analysis-type**: stripped when target smart-collection content model does not include them.

Validation is **per-version**: use `FCPXMLService.validateDocumentAgainstDTD(_:version:)` or `validateDocumentAgainstDeclaredVersion(_:)` with the appropriate DTD.

---

## 10. Summary matrix

| Feature | 1.5 | 1.6 | 1.7 | 1.8 | 1.9 | 1.10 | 1.11 | 1.12 | 1.13 | 1.14 |
|--------|-----|-----|-----|-----|-----|------|------|------|------|------|
| Root: library \| event* \| event_item | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| sync-clip, asset-clip | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| audio-channel-source, audio-role-source | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| audio-source, audio-aux-source | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| library colorProcessing | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| format colorSpace, projection, stereoscopic | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| adjust-360-transform, reorient, orientation | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| caption | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| media-rep (asset) | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| locator resource | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| object-tracker, adjust-cinematic | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| match-usage | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| match-representation, match-markers | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| adjust-colorConform | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| adjust-stereo-3D | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| format heroEye, asset heroEyeOverride | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| match-analysis-type | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| %timelist% entity | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

*End of version history. For DTD file naming and usage, see [README.md](README.md).*
