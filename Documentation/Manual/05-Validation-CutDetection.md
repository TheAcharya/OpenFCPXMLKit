# 05 — Validation & Cut Detection

[← Manual Index](00-Index.md)

---

## Validation API

### Semantic validation (FCPXMLValidator)

**FCPXMLValidator** checks root element, resources, and reference resolution. Refs are resolved against all element IDs in the document (including e.g. `text-style-def` inside titles/captions).

```swift
let validator = FCPXMLValidator()
let result = validator.validate(document)

if result.isValid {
    // Proceed
} else {
    for err in result.errors { print(err.message) }
}
```

**ValidationResult** has `errors`, `warnings`, `isValid`. **ValidationError** and **ValidationWarning** have `type`, `message`, `context`; warning types include `negativeTimeAttribute`.

---

### DTD validation (FCPXMLDTDValidator)

**FCPXMLDTDValidator** validates the document against a specific FCPXML version's DTD. On **macOS** (and Linux with Foundation XML) it performs full DTD validation. On **iOS** (where DTD is not available) it uses **FCPXMLStructuralValidator** instead and the result may include a `structuralValidationOnly` warning.

```swift
let dtdValidator = FCPXMLDTDValidator()
let dtdResult = dtdValidator.validate(document, version: .default)

if dtdResult.isValid { /* valid */ }
else {
    for err in dtdResult.errors { print(err.message) }
}
```

---

### Structural validation (FCPXMLStructuralValidator, cross-platform)

**FCPXMLStructuralValidator** works on all platforms (including iOS). It checks: root element name `fcpxml`, required `version` attribute, required `resources` child, at least one content element (library/event/project), and an element-name allowlist for FCPXML 1.5–1.14. Use it when full DTD validation is not available (e.g. on iOS).

---

### Per-version validation via FCPXMLService

- **validateDocumentAgainstDTD(_:version:)** — Validate against a given version (1.5–1.14).
- **validateDocumentAgainstDeclaredVersion(_:)** — Read the document's root `version` and validate against that DTD (errors if version missing or unsupported).
- **performValidation(_:)** — Combines semantic and DTD validation; returns **DocumentValidationReport** with `isValid`, `summary`, `detailedDescription`. Use for a single robust check.

```swift
let service = FCPXMLService()

let resultFor1_10 = service.validateDocumentAgainstDTD(document, version: .v1_10)
let resultDeclared = service.validateDocumentAgainstDeclaredVersion(document)

let report = service.performValidation(document)
if report.isValid { /* proceed */ }
else {
    print(report.summary)
    print(report.detailedDescription)
}
```

---

## Cut detection API

Detect edit points (cuts) on the first project spine: boundary type (hard cut, transition, gap) and source relationship (same-clip vs different-clips).

**CutDetectionResult** includes:
- `editPoints: [EditPoint]`
- `totalEditPoints`, `sameClipCutCount`, `differentClipsCutCount`
- `hardCutCount`, `transitionCount`, `gapCutCount`

**EditPoint** has `index`, `timelineOffset` (FCPXML time string), `editType`, `sourceRelationship`, `transitionName`, clip names and refs.

```swift
let service = ModularUtilities.createService()
let document = try service.parseFCPXML(from: data)
let result = service.detectCuts(in: document)

for point in result.editPoints {
    print("Edit \(point.index): \(point.editType) at \(point.timelineOffset), \(point.sourceRelationship)")
}
```

Sync and async: `detectCuts(in:)`, `detectCuts(inSpine:)`.

---

## Next

- [06 — Version Conversion & Export](06-Version-Conversion-Export.md) — Convert version, save as .fcpxml / .fcpxmld.
