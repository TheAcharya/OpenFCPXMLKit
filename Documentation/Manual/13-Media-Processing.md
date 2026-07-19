# 13 — Media Processing

[← Manual Index](00-Index.md)

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

**TimelineClip** integration:

```swift
let result = await clip.validateAsset(at: audioURL)
let isAudio = await clip.isAudioAsset(at: audioURL)
let isVideo = await clip.isVideoAsset(at: audioURL)
let isImage = await clip.isImageAsset(at: audioURL)
```

Sync: `validateAssetSync(at:forLane:mimeTypeDetector:)`.

---

## Silence detection

**SilenceDetection** / **SilenceDetector** detect silence at start/end of audio (configurable threshold and minimum duration):

```swift
let detector = SilenceDetector()
let result = await detector.detectSilence(
    at: audioURL,
    threshold: -60.0,
    minimumDuration: 0.1
)
print("Silence at start: \(result.silenceAtStart), end: \(result.silenceAtEnd)")
print("Total silence: \(result.totalSilenceDuration)")
```

Sync: `detectSilenceSync(at:threshold:minimumDuration:)`.

---

## Asset duration measurement

**AssetDurationMeasurement** / **AssetDurationMeasurer** measure duration of audio/video; images have no duration. **DurationMeasurementResult** has `mediaType` (`.audio`, `.video`, `.image`, `.unknown`), `duration`, `hasDuration`, `isImage`:

```swift
let measurer = AssetDurationMeasurer()
let result = try await measurer.measureDuration(at: url)
if let duration = result.duration { print("Duration: \(duration)s") }
```

Sync: `measureDurationSync(at:)`.

---

## Parallel file I/O

**ParallelFileIO** / **ParallelFileIOExecutor** for concurrent read/write:

```swift
let executor = ParallelFileIOExecutor()

let filesToWrite: [(URL, Data)] = [
    (URL(fileURLWithPath: "/path/to/file1.txt"), Data("content1".utf8)),
    (URL(fileURLWithPath: "/path/to/file2.txt"), Data("content2".utf8))
]
let writeResult = await executor.writeFiles(filesToWrite)

let urlsToRead = [url1, url2, url3]
let readResult = await executor.readFiles(urlsToRead)
```

**ParallelFileIOResult:** `successCount`, `failureCount`, `successes`, `failures`. Configurable `maxConcurrentOperations`, `useFileHandleOptimization`.

---

## Next

- [14 — Typed Models](14-Typed-Models.md) — Adjustments, filters, captions, keyframes, Live Drawing, collections.

