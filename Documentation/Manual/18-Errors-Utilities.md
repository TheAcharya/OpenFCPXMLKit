# 18 — Errors & Utilities

[← Manual Index](00-Index.md)

---

## Table of Contents

- [Error types](#error-types)
- [FCPXMLProgressReporter and ProgressBar](#fcpxmlprogressreporter-and-progressbar)
- [FCPXML-style UIDs](#fcpxml-style-uids)

---

## Error types

OpenFCPXMLKit uses explicit, typed errors. All conform to **LocalizedError** where applicable.

| Type | Cases / use |
|------|-------------|
| **FCPXMLError** | e.g. `parsingFailed(Error)` |
| **FCPXMLLoadError** | `notAFile`, `readFailed` (file I/O) |
| **FinalCutPro.FCPXML.ParseError** | General parse errors with LocalizedError |
| **FCPXMLExportError** | `missingAsset`, `invalidTimeline`, etc. |
| **FCPXMLBundleExportError** | e.g. `bundleRequiresVersion1_10OrHigher` |
| **TimelineError** | `noAvailableLane(offset, duration)`, `assetNotFound(URL)`, `invalidFormat(reason)`, `invalidAssetReference(assetRef, reason)` |
| **ValidationError** / **ValidationWarning** | type, message, context; warning types include `negativeTimeAttribute` |
| **FCPXMLDocumentError** | e.g. `dtdResourceNotFound`, `dtdResourceUnreadable` (camelCase cases) |

**ErrorHandling** protocol (sync-only) and **ErrorHandler** turn errors into formatted messages. Use in services or switch on error types in your code:

```swift
do {
    let document = try service.parseFCPXML(from: url)
} catch let error as FCPXMLError {
    switch error {
    case .parsingFailed(let underlyingError):
        print("Parse failed: \(underlyingError.localizedDescription)")
    default:
        print("FCPXML error: \(error.localizedDescription)")
    }
} catch let error as TimelineError {
    switch error {
    case .noAvailableLane(let offset, let duration):
        print("No lane at \(offset) for duration \(duration)")
    case .assetNotFound(let url):
        print("Asset not found: \(url.path)")
    case .invalidFormat(let reason), .invalidAssetReference(_, let reason):
        print("Invalid: \(reason)")
    }
} catch {
    print("Unknown: \(error.localizedDescription)")
}
```

---

## FCPXMLProgressReporter and ProgressBar

**`FCPXMLProgressReporter`** is the public progress protocol: `advance(by:)`, `finish()`. The name is unique on purpose so it does **not** collide with Foundation’s `ProgressReporter` (macOS 27 / iOS 27, Xcode 27). The same source builds on **Xcode 26.6 / macOS 26** (no Foundation type of that name) and on Xcode 27. There is **no** `ProgressReporter` typealias — an alias would keep the ambiguity in any client that imports Foundation. Sign `fcpxml-progress-reporter-not-foundation`.

**ProgressBar** (TQDM-style terminal bar: percentage, rate, ETA) conforms. It is **not thread-safe**; use it from a single thread (CLI / main). Concurrent `advance` calls can interleave output.

Library APIs that take optional `progress: (any FCPXMLProgressReporter)?` (default `nil`):

| API | Typical use |
|-----|-------------|
| `copyReferencedMedia(from:to:baseURL:progress:)` | [11 — Extraction & Media](11-Extraction-Media.md#media-extraction-and-copy) |
| `detectSilence(at:threshold:progress:)` (async) | [13 — Media Processing](13-Media-Processing.md#silence-detection) |
| `measureDuration(at:progress:)` (async) | [13 — Media Processing](13-Media-Processing.md#asset-duration-measurement) |
| `readFiles(from:progress:)` / `writeFiles(dataAndURLs:progress:)` | [13 — Media Processing](13-Media-Processing.md#parallel-file-io) |

```swift
let total = fileRefs.count
let bar = ProgressBar(total: total, desc: "Copying media")
let result = service.copyReferencedMedia(
    from: document,
    to: destDir,
    baseURL: baseURL,
    progress: bar
)
```

CLI draws a **ProgressBar** for `--media-copy` (passed as `FCPXMLProgressReporter`), `--validate`, `--extract-shots`, and `--report`. Progress is hidden when **`--quiet`** is set. See [19 — CLI](19-CLI.md).

---

## FCPXML-style UIDs

**FCPXMLUID** generates and validates FCPXML-style unique identifiers (uppercase UUID with hyphens, e.g. `D71600AB-2F01-4850-8DBD-E9F0594BD004`) used by Final Cut Pro for `event` and `project` `uid` attributes.

- **FCPXMLUID.random()** — Returns a new UID string. Use when creating new FCPXML documents so event/project identity matches FCP export.
- **FCPXMLUID.isValid(_:)** — Returns whether a string is a valid 36-character, hyphenated, uppercase-hex UUID.

When exporting with **FCPXMLExporter**, pass `eventUid` and `projectUid` (or omit for auto-generated UIDs). See [07 — Timeline & Export](07-Timeline-Export.md).

---

## Next

- [19 — CLI](19-CLI.md) — Experimental command-line interface.
- [13 — Media Processing](13-Media-Processing.md) — Silence, duration, and parallel I/O `progress:` parameters.

[← Manual Index](00-Index.md)
