# 13 — Media Processing

[← Manual Index](00-Index.md)

---

## Table of Contents

- [MIME type detection](#mime-type-detection)
- [Asset validation](#asset-validation)
- [Silence detection](#silence-detection)
- [Asset duration measurement](#asset-duration-measurement)
- [Parallel file I/O](#parallel-file-io)

File existence, MIME type, silence, duration, and parallel I/O operate on **paths you already have**. To resolve a clip’s declared original/proxy URL from FCPXML, use the public Parsing APIs in [02 — Loading & Parsing](02-Loading-Parsing.md#leaf-media-urls-public-parsing-apis) (`fcpMediaURL` / `fcpMediaRepresentationURLs`). Those helpers do not check that the file exists on disk.

Optional `progress:` parameters on silence, duration, copy, and parallel I/O take **`FCPXMLProgressReporter`** (typically a **`ProgressBar`**). See [18 — Errors & Utilities](18-Errors-Utilities.md#fcpxmlprogressreporter-and-progressbar). Do not use Foundation’s `ProgressReporter` (macOS 27 / iOS 27). Sign `fcpxml-progress-reporter-not-foundation`.

---

## MIME type detection

**MIMETypeDetection** / **MIMETypeDetector** use UTType and AVFoundation (with file-extension fallback). Sync and async:

```swift
let detector = MIMETypeDetector()
let url = URL(fileURLWithPath: "/path/to/video.mp4")

let mimeTypeSync = detector.detectMIMETypeSync(at: url)
let mimeTypeAsync = await detector.detectMIMEType(at: url)
```

Supported: video (mp4, mov, avi, mkv, etc.), audio (mp3, m4a, wav, etc.), image (jpg, png, gif, heic, etc.).

---

## Asset validation

**AssetValidation** / **AssetValidator** check file existence and MIME type compatibility with lanes:

- **Negative lanes (&lt; 0):** audio-only (`audio/*`)
- **Non-negative lanes (≥ 0):** video, image, or audio

```swift
let validator = AssetValidator()
let result = await validator.validateAsset(
    at: url,
    forLane: -1,
    mimeTypeDetector: nil
)
if result.isValid { print("Valid: \(result.mimeType ?? "unknown")") }
else { print("Failed: \(result.reason ?? "unknown")") }
```

**AssetValidationResult:** `exists`, `mimeType`, `isCompatible`, `reason`, computed `isValid` (`exists && isCompatible`).

**TimelineClip** integration (uses the clip’s `lane`):

```swift
let result = await clip.validateAsset(at: audioURL)
let isAudio = await clip.isAudioAsset(at: audioURL)
let isVideo = await clip.isVideoAsset(at: audioURL)
let isImage = await clip.isImageAsset(at: audioURL)
```

Sync: `validateAssetSync(at:forLane:mimeTypeDetector:)` on the validator; `validateAssetSync(at:validator:mimeTypeDetector:)` on `TimelineClip`.

---

## Silence detection

**SilenceDetection** / **SilenceDetector** (AVFoundation) measure leading and trailing silence so you can trim an audio file. Threshold is in dB (default **−90** for near-zero). There is **no** `minimumDuration` parameter.

**SilenceDetectionResult:** `duration` (file length in seconds), `trimStart`, `trimEnd`, computed `isEntirelySilent` (`trimStart >= duration`), computed `audioDuration` (`duration − trimStart − trimEnd`).

```swift
let detector = SilenceDetector()
let result = try await detector.detectSilence(
    at: audioURL,
    threshold: -60.0,
    progress: nil  // optional FCPXMLProgressReporter
)
print("Duration: \(result.duration)s")
print("Trim start: \(result.trimStart)s, end: \(result.trimEnd)s")
print("Audio content: \(result.audioDuration)s, entirely silent: \(result.isEntirelySilent)")
```

Sync overload (no `progress`): `detectSilence(at:threshold:) throws -> SilenceDetectionResult`. Prefer the async API when you can.

---

## Asset duration measurement

**AssetDurationMeasurement** / **AssetDurationMeasurer** (AVFoundation) measure duration of audio/video; images have no duration. **DurationMeasurementResult** has `mediaType` (`.audio`, `.video`, `.image`, `.unknown`), `duration`, `hasDuration`, `isImage`:

```swift
let measurer = AssetDurationMeasurer()
let result = try await measurer.measureDuration(at: url, progress: nil)
if let duration = result.duration { print("Duration: \(duration)s") }
```

Sync: `measureDuration(at:) throws -> DurationMeasurementResult` (no `progress`).

---

## Parallel file I/O

**ParallelFileIO** / **ParallelFileIOExecutor** read and write many files concurrently (`withThrowingTaskGroup`). Configure **`taskPriority`** (default `.high`), **`useFileHandleOptimization`**, and **`preallocateFileSpace`**. There is **no** `maxConcurrentOperations` property.

Each call returns **`[ParallelFileIOResult]`** in input order. Per-file: `index`, `url`, `data` (reads), `error`, computed `succeeded`. Count successes with `results.filter(\.succeeded).count` — the result type has no `successCount` / `failureCount` properties.

```swift
let executor = ParallelFileIOExecutor()

let filesToWrite: [(data: Data, url: URL)] = [
    (Data("content1".utf8), URL(fileURLWithPath: "/path/to/file1.txt")),
    (Data("content2".utf8), URL(fileURLWithPath: "/path/to/file2.txt"))
]
let writeResults = try await executor.writeFiles(dataAndURLs: filesToWrite, progress: nil)

let urlsToRead = [url1, url2, url3]
let readResults = try await executor.readFiles(from: urlsToRead, progress: nil)
let ok = readResults.filter(\.succeeded).count
```

Optional `progress:` is `FCPXMLProgressReporter?` (advanced once per completed file). See [18 — Errors & Utilities](18-Errors-Utilities.md#fcpxmlprogressreporter-and-progressbar).

---

## Next

- [14 — Typed Models](14-Typed-Models.md) — Adjustments, filters, captions, keyframes, Live Drawing, collections.
- [02 — Loading & Parsing](02-Loading-Parsing.md#leaf-media-urls-public-parsing-apis) — public primary leaf URLs (declared paths, not existence checks).
- [11 — Extraction & Media](11-Extraction-Media.md#media-extraction-and-copy) — extract and copy every `media-rep` / locator (optional progress).
- [18 — Errors & Utilities](18-Errors-Utilities.md#fcpxmlprogressreporter-and-progressbar) — `FCPXMLProgressReporter` / `ProgressBar`.

[← Manual Index](00-Index.md)
