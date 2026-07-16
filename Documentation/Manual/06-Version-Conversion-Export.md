# 06 — Version Conversion & Export

[← Manual Index](00-Index.md)

---

## Version conversion

**FCPXMLVersionConverter** converts a document to a target FCPXML version (e.g. 1.14 → 1.10). It sets the root `version` attribute and **automatically removes elements and attributes not in the target version's DTD** (e.g. `adjust-colorConform`, `adjust-stereo-3D`, `hidden-clip-marker` for &lt; 1.13). Output validates and imports in Final Cut Pro.

```swift
let service = ModularUtilities.createService()
let document = try service.parseFCPXML(from: url)

// Convert to 1.10 (strips elements not in 1.10 DTD)
let converted = try service.convertToVersion(document, targetVersion: .v1_10)

// Optionally validate against target DTD before save
let validation = service.validateDocumentAgainstDTD(converted, version: .v1_10)
guard validation.isValid else { /* handle errors */ }
```

Allowlists are derived at runtime from the target DTD (**EmbeddedDTDProvider** in CLI, bundle in library). Fallback to hand-maintained lists when DTD data is unavailable.

### Write honesty vs report reads

**Writers** (`convertToVersion`, exporters, create-project) must not invent or re-emit facts that the **target** DTD cannot express (for example Format `heroEye` / Asset `heroEyeOverride` / `hidden-clip-marker` when targeting &lt; 1.13).

**Readers** (parse → Extraction → Projection → `buildReport`) may still describe every fact present in the **as-loaded** document. Building a report from a 1.14 file is allowed to surface 1.13+ fields; building a report from a document already converted to 1.5 must not claim those fields were retained.

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
