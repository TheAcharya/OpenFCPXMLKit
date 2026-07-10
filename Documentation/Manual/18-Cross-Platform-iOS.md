# 18 — Cross-Platform XML & iOS

[← Manual Index](00-Index.md)

---

## Overview

OpenFCPXMLKit supports **macOS 26+** and **iOS 26+**. On macOS, the framework uses Foundation’s DOM XML API (`XMLDocument`, `XMLElement`). Those types are **not available on iOS** (Apple ships only the SAX-based `XMLParser` there). To support both platforms, OpenFCPXMLKit uses a **protocol-based XML abstraction layer**: all document and element access goes through protocol types, with platform-specific backends.

**Summary:**

- **Protocols:** `OFKXMLNode`, `OFKXMLElement`, `OFKXMLDocument`, `OFKXMLDTDProtocol`, `OFKXMLFactory` — platform-agnostic contracts.
- **macOS (and Linux with Foundation XML):** Foundation backend — `FoundationXMLElement`, `FoundationXMLDocument`, `FoundationXMLDTD`, `FoundationXMLFactory`. Behaviour is unchanged from the pre-abstraction implementation.
- **iOS (and other platforms without Foundation DOM XML):** AEXML backend — `AEXMLBackendElement`, `AEXMLBackendDocument`, `AEXMLBackendFactory`. The library depends on [AEXML](https://github.com/tadija/AEXML) for parsing and DOM-style access.
- **Dispatch:** `OFKXMLDefaultFactory()` returns the appropriate factory for the current platform (`FoundationXMLFactory` on macOS, `AEXMLBackendFactory` on iOS).

---

## What you use in code

- **Parsing and documents:** You work with `any OFKXMLDocument` and `any OFKXMLElement`. The concrete type (Foundation vs AEXML) is chosen at runtime based on the platform.
- **Creating elements/documents:** Use `OFKXMLDefaultFactory()` (or an injected `OFKXMLFactory`) so that on iOS the AEXML backend is used automatically.
- **Extensions:** All FCPXML extensions (e.g. `fcpxType`, `fcpxDuration`, `fcpxResources`) are defined on `OFKXMLElement` / `OFKXMLDocument`, so the same API works on both platforms.

```swift
// Works on both macOS and iOS
let factory = OFKXMLDefaultFactory()
let document = try factory.makeDocument(data: data, options: .fcpxmlDefaults)
let root = document.rootElement()
let version = root?.stringValue(forAttributeNamed: "version")
```

---

## DTD validation on iOS

`XMLDTD` and full DTD validation are **macOS-only**. On iOS:

- **FCPXMLDTDValidator** does not run the full DTD validator. It uses **FCPXMLStructuralValidator** instead and returns a result that may include a **structuralValidationOnly** warning to indicate that only structural checks were performed.
- **FCPXMLStructuralValidator** (cross-platform) checks: root element name `fcpxml`, required `version` attribute, required `resources` child, at least one content element (library/event/project), and an element-name allowlist for FCPXML 1.5–1.14. It does not replace full DTD validation but catches many malformed documents.

---

## Package and dependencies

- **Package.swift** declares `.iOS(.v26)` and adds the **AEXML** dependency for the OpenFCPXMLKit target.
- **SwiftTimecode**, **SwiftExtensions**, **swift-log**, **Foundation**, **CoreMedia** are used on both platforms. **OpenFCPXMLKitCLI** and **GenerateEmbeddedDTDs** remain macOS-only (or as currently configured).

---

## Testing

- The `OpenFCPXMLKitTests` suite (**932 tests** listed under that target: 929 XCTest + 3 Swift Testing `@Test`) runs on **macOS** and uses the Foundation backend. `swift test --list-tests` also lists **1** optional `ExcelReportTest` integration test (**933** total).
- **iOS** is supported for building the library (e.g. iOS Simulator); running the same tests on iOS is not required for CI because they depend on Foundation XML. AEXML parity and structural validation are covered by tests that run on macOS.

---

## Backward compatibility

**macOS:** No breaking changes. The Foundation backend is the default and produces the same behaviour as before the abstraction. All existing APIs that accepted or returned `XMLDocument`/`XMLElement` now use `any OFKXMLDocument`/`any OFKXMLElement`, which is source-compatible at call sites.

---

## Next

- [13 — XML Extensions](13-XML-Extensions.md) — FCPXML extensions on OFKXMLElement and OFKXMLDocument.
- [05 — Validation & Cut Detection](05-Validation-CutDetection.md) — Semantic, DTD, and structural validation.
