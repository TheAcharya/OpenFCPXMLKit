# 06 — Version Conversion & Export

[← Manual Index](00-Index.md)

---

## Table of Contents

- [Version conversion](#version-conversion)
  - [Write honesty vs report reads](#write-honesty-vs-report-reads)
- [Save as .fcpxml or .fcpxmld](#save-as-fcpxml-or-fcpxmld)

---

## Version conversion

**FCPXMLVersionConverter** converts a document to a target FCPXML version (e.g. 1.15 → 1.10). It sets the root `version` attribute and **automatically removes elements and attributes not in the target version's DTD** (e.g. `adjust-colorConform`, `adjust-stereo-3D`, `hidden-clip-marker` for &lt; 1.13; `adjust-natural-motion-blur`, `mask-semantic`, anchorable `flags`, and pan-rect `interp` for &lt; 1.15). Keyframe `interp` tokens `hold` / `bezier` / `passthrough` and `frameSampling` `vsa-motion-blur` are dropped below 1.15 so those attributes return to their older defaults. `conform-rate` `srcFrameRate` tokens `90`, `100`, `119.88`, and `120` (added in 1.13) are removed below 1.13. Output validates and imports in Final Cut Pro.

```swift
let service = ModularUtilities.createService()
let document = try service.parseFCPXML(from: url)

// Convert to 1.10 (strips elements not in 1.10 DTD)
let converted = try service.convertToVersion(document, targetVersion: .v1_10)

// Optionally validate against target DTD before save
let validation = service.validateDocumentAgainstDTD(converted, version: .v1_10)
guard validation.isValid else { /* handle errors */ }
```

Allowlists are derived at runtime from the target DTD (**EmbeddedDTDProvider** in CLI, bundle in library). When DTD data is unavailable, the converter falls back to **`FinalCutPro.FCPXML.VersionFeatureGate`** (`elementNamesToOmit(at:)` / `attributeNamesToOmit(onElement:at:)`), the same registry used by detached Authoring omit-on-write (see [08 — Detached Authoring](08-Detached-Authoring.md)).

```swift
let omit = FinalCutPro.FCPXML.VersionFeatureGate.elementNamesToOmit(at: .v1_09)
// includes e.g. adjust-cinematic (introduced in 1.10)
```

### Write honesty vs report reads

**Writers** (`convertToVersion`, exporters, create-project) must not invent or re-emit facts that the **target** DTD cannot express (for example Format `heroEye` / Asset `heroEyeOverride` / `hidden-clip-marker` when targeting &lt; 1.13).

**Readers** (parse → Extraction → Projection → `buildReport`) may still describe every fact present in the **as-loaded** document. Building a report from a 1.14 file is allowed to surface 1.13+ fields; building a report from a document already converted to 1.5 must not claim those fields were retained.

The same rule applies to FCPXML 1.15 anchorable `flags`. A reader of the as-loaded document may treat bit 0 (`OFKXMLElement.fcpIsDisconnectedFromAnchor`) as a clip disconnected from the primary storyline, and Role Inventory then labels that row **Unconnected**. `convertToVersion` below 1.15 deletes `flags`. After that conversion the lane remains and the clip reads as an ordinary anchored clip (**Connected**). Do not write `flags` into a document whose target version is older than 1.15. See [02 — Loading & Parsing](02-Loading-Parsing.md#disconnected-anchors-fcpxml-115).

---

## Save as .fcpxml or .fcpxmld

- **Save as single .fcpxml:** `saveAsFCPXML(_:to:)` — any supported version.
- **Save as .fcpxmld bundle:** `saveAsBundle(_:to:bundleName:)` — **only when document version is 1.10 or higher**. Otherwise **FCPXMLBundleExportError.bundleRequiresVersion1_10OrHigher** is thrown.

```swift
// Save as single file
try service.saveAsFCPXML(converted, to: URL(fileURLWithPath: "/path/to/Project.fcpxml"))

// Save as bundle (converted is 1.10+)
let bundleURL = try service.saveAsBundle(
    converted,
    to: outputDirectory,
    bundleName: "My Project"
)
```

All of `convertToVersion`, `saveAsFCPXML`, and `saveAsBundle` are available sync and async.

---

## Next

- [07 — Timeline & Export](07-Timeline-Export.md) — Timeline, TimelineClip, exporters.
