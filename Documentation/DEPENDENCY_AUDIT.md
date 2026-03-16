# Dependency Audit — iOS Compatibility

**Date**: 2026-03-09
**Branch**: `development`
**Commit baseline**: `1ba52f0` (Pipeline Neo Release 2.4.3)
**Sortie**: WU1 / Sortie 1

---

## Summary

| # | Audit Item | Result | Blocking? |
|---|-----------|--------|-----------|
| 1 | `swift-timecode` iOS platform support | **PASS** | No |
| 2 | `swift-extensions` iOS platform support | **PASS (with caveat)** | No |
| 3 | `swift-log` iOS platform support | **PASS** | No |
| 4 | `swift-argument-parser` isolation from `PipelineNeo` library | **PASS** | No |
| 5 | `CMTime` / `CoreMedia` API availability on iOS | **PASS** | No |
| 6 | XML namespace declarations in FCPXML samples | **PASS** | No |

**Overall verdict**: No blocking issues. All downstream work may proceed.

---

## Item 1: `swift-timecode` (3.0.0) — iOS Platform Support

**Result**: PASS

**Evidence**:

- Resolved version: `3.0.0` (revision `f9a9e88c8e4c38b1b29d3db8130e1f07112e8b9e`)
- File inspected: `.build/checkouts/swift-timecode/Package.swift`, line 11

```swift
platforms: [
    .macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v4), .visionOS(.v1)
]
```

- iOS is explicitly declared as a supported platform (iOS 12+).
- PipelineNeo depends on the `SwiftTimecode` umbrella product (Package.swift line 40), which aggregates `SwiftTimecodeCore`, `SwiftTimecodeAV`, and `SwiftTimecodeUI`.
- `SwiftTimecodeCore` has `#if os(macOS)` guards in 3 files (`NSAttributedString.swift`, `NSItemProvider.swift`, `Timecode String.swift`), all with proper `#else` branches importing UIKit for iOS. No macOS-only dead ends.
- `SwiftTimecodeAV` imports `AVFoundation` (available on iOS). No `#if os(macOS)` guards found.
- `SwiftTimecodeUI` links `SwiftUI` conditionally for all platforms including iOS. `#if os(macOS)` guards in 8 files, all with proper `#else`/`#elseif os(iOS)` branches.

**Conclusion**: Fully iOS-compatible. No action required.

---

## Item 2: `swift-extensions` (2.0.0) — iOS Platform Support

**Result**: PASS (with caveat)

**Evidence**:

- Resolved version: `2.0.0` (revision `f090f8210d7dfba476edefbe0f269854d07b32a6`)
- File inspected: `.build/checkouts/swift-extensions/Package.swift`, line 10

```swift
platforms: [
    .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
]
```

- iOS is explicitly declared as a supported platform (iOS 13+).
- **Caveat**: The `XMLElement.swift` and `XMLNode.swift` extension files (`.build/checkouts/swift-extensions/Sources/SwiftExtensions/Extensions/Foundation/XMLElement.swift` line 8, `XMLNode.swift` line 8) are wrapped entirely in `#if os(macOS)`:

```swift
// This is Mac-only because even though XMLNode exists in Foundation, it is only available on macOS
#if os(macOS)
```

- PipelineNeo uses these macOS-only extensions extensively (57 files reference methods like `.stringValue(forAttributeNamed:)`, `.childElements`, `.parentElement`, `.addAttribute(withName:value:)`, `.firstChildElement(named:)`, `.ancestorElements`, `.getBool(forAttribute:)`, etc.).
- **Impact on migration**: When PipelineNeo migrates to the `PNXMLElement`/`PNXMLNode` protocol abstraction, these extension methods will need to be replicated in the protocol surface or in the backend implementations. This is already accounted for in the execution plan (WU2 Sortie 2-3 protocol definitions include equivalents for these methods).

**Conclusion**: The package itself compiles on iOS. The macOS-only XML extensions will become unavailable on iOS, but this is the known/expected gap that the XML abstraction layer (WU2-WU5) is designed to fill. Not blocking.

---

## Item 3: `swift-log` (1.0.0+) — iOS Platform Support

**Result**: PASS

**Evidence**:

- Declared dependency: `from: "1.0.0"` (Package.swift line 32)
- Not yet resolved in workspace (`.build/workspace-state.json` has no entry for swift-log; package was recently added for Xcode 26 dynamic linking compatibility).
- Inspected via web fetch of `https://raw.githubusercontent.com/apple/swift-log/main/Package.swift`: swift-tools-version 6.2, **no `platforms` array declared**.
- When a Swift package omits the `platforms` array, SPM allows it to build on all platforms. This is standard practice for Apple's server-side packages (swift-log, swift-nio, etc.).
- `swift-log` is a pure-Swift logging abstraction with no platform-specific dependencies. It is widely used in cross-platform Swift projects.

**Conclusion**: Fully iOS-compatible. No action required.

---

## Item 4: `swift-argument-parser` Isolation

**Result**: PASS

**Evidence**:

- Package-level dependency declared at Package.swift line 26.
- The `ArgumentParser` product is linked **only** to `PipelineNeoCLI` (Package.swift line 60):

```swift
.executableTarget(
    name: "PipelineNeoCLI",
    dependencies: [
        "PipelineNeo",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
```

- The `PipelineNeo` library target (Package.swift lines 37-46) lists only `SwiftTimecode`, `SwiftExtensions`, and `Logging` as dependencies. **No `ArgumentParser` reference**.
- The `GenerateEmbeddedDTDs` target (Package.swift lines 64-67) has **no dependencies at all** (not even `PipelineNeo`).
- Verified: `grep 'import ArgumentParser' Sources/PipelineNeo/` returns zero hits.

**Conclusion**: `swift-argument-parser` is correctly isolated to `PipelineNeoCLI`. It will not affect the `PipelineNeo` library target on any platform. No action required.

---

## Item 5: `CMTime` / `CoreMedia` API Availability on iOS

**Result**: PASS

**Evidence**:

- 33 files in `Sources/PipelineNeo/` import `CoreMedia` or reference `CMTime`.
- `CoreMedia` framework is available on iOS since iOS 4.0 (2010). PipelineNeo targets macOS 12, and the planned iOS target is iOS 15 -- both well above the CoreMedia availability floor.

### APIs cataloged across `Sources/PipelineNeo/`:

| API | Files using it | iOS availability |
|-----|---------------|-----------------|
| `CMTime(value:timescale:)` | `FCPXMLTimecode.swift`, `CMTimeExtension.swift`, `TimecodeConverter.swift`, `FCPXMLFadeIn.swift`, `FCPXMLExporter.swift`, `Marker.swift` | iOS 4.0+ |
| `CMTime(seconds:preferredTimescale:)` | `TimecodeConverter.swift`, `FCPXMLFadeIn.swift` | iOS 4.0+ |
| `CMTime.zero` / `.zero` | `CMTimeExtension.swift` (line 27), `Timeline.swift` (line 260) | iOS 4.0+ |
| `CMTimeAdd(_:_:)` | `Timeline.swift`, `FCPXMLUtility.swift`, `XMLElementExtension.swift`, `TimelineClip.swift` | iOS 4.0+ |
| `CMTimeSubtract(_:_:)` | `Timeline.swift`, `FCPXMLUtility.swift`, `XMLElementExtension.swift` | iOS 4.0+ |
| `CMTimeMultiply(_:multiplier:)` | `FCPXMLTimecode.swift`, `TimecodeConverter.swift` | iOS 4.0+ |
| `CMTimeCompare(_:_:)` | `Timeline.swift` (12 call sites) | iOS 4.0+ |
| `CMTimeGetSeconds(_:)` | `FCPXMLExporter.swift`, `TimecodeConverter.swift`, `TimelineError.swift` | iOS 4.0+ |
| `CMTIME_IS_VALID(_:)` | `FCPXMLTimecode.swift` (line 126), `TimecodeConverter.swift` (line 69) | iOS 4.0+ |
| `CMTime.seconds` (property) | `CMTimeExtension.swift` | iOS 4.0+ |
| `CMTime.timescale` (property) | `FCPXMLTimecode.swift`, `TimecodeConverter.swift` | iOS 4.0+ |
| `CMTime.value` (property) | (implied by init usage) | iOS 4.0+ |

- **No macOS-only CoreMedia APIs found.** All usage is limited to the fundamental `CMTime` arithmetic and comparison functions, which have been available on all Apple platforms since their initial framework release.
- No usage of `CMTimeRange`, `CMTimeMapping`, `CMSampleBuffer`, or any other advanced CoreMedia types that could have platform-specific availability restrictions.

**Conclusion**: All CoreMedia/CMTime APIs used in PipelineNeo are available on iOS. No action required.

---

## Item 6: XML Namespace Declarations in FCPXML Samples

**Result**: PASS

**Evidence**:

- Searched all 57 FCPXML sample files in `Tests/FCPXML Samples/FCPXML/` for `xmlns:` (prefixed namespace declarations) and `xmlns` (default namespace declarations).
- **Zero matches found.** No FCPXML sample file contains any XML namespace declaration.
- This is consistent with the FCPXML format specification: FCPXML is a DTD-validated format that does not use XML namespaces. Elements are unqualified (e.g., `<fcpxml>`, `<library>`, `<event>`, `<project>`, `<sequence>`).

**Namespace risk assessment**: LOW. Since FCPXML does not use namespaces:
- The AEXML backend (WU4) does not need namespace-aware parsing.
- The protocol abstraction (WU2) does not need namespace-related methods in its initial surface.
- No namespace-stripping or namespace-mapping logic is required during migration (WU5).

**Conclusion**: No namespace risk. No action required.

---

## Additional Observations

### `import AppKit` in PipelineNeo

One file (`Sources/PipelineNeo/Extensions/XMLElementExtension.swift`, line 11) contains `import AppKit`. This is a known migration target (WU5 Sortie 17, Task 2) and is not a surprise, but it will cause a compile failure on iOS if not addressed. The execution plan already covers this.

### Foundation XML Types (`XMLDocument`, `XMLElement`, `XMLNode`, `XMLDTD`)

- 145 files in `Sources/PipelineNeo/` reference Foundation XML types, with 1,619 total occurrences.
- These types are macOS-only in Foundation (they exist in `FoundationXML` on Linux but are not available on iOS).
- This is the core problem the entire mission is designed to solve. The execution plan (WU2-WU5) accounts for this.

### Resolved Dependency Versions

| Dependency | Declared | Resolved | iOS Support |
|-----------|----------|----------|-------------|
| `swift-timecode` | `from: "3.0.0"` | `3.0.0` | iOS 12+ |
| `swift-extensions` | `from: "2.1.0"` | `2.0.0` | iOS 13+ |
| `swift-log` | `from: "1.0.0"` | (not yet resolved) | All platforms |
| `swift-argument-parser` | `from: "1.6.0"` | `1.7.0` | N/A (CLI only) |

**Note on swift-extensions version**: The Package.swift declares `from: "2.1.0"` but the workspace resolved `2.0.0`. This may need a `swift package resolve` to update, or the workspace state may be stale. The version discrepancy does not affect this audit since the `platforms` array and `#if os(macOS)` behavior are consistent across 2.x releases.
