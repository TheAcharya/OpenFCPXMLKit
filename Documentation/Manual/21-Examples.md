# 21 — Examples

[← Manual Index](00-Index.md)

---

## Open an FCPXML file

Prefer the cross-platform loader / OFKXML document APIs (see [15 — XML Extensions](15-XML-Extensions.md) and [17 — Cross-Platform & iOS](17-Cross-Platform-iOS.md)). On macOS, Foundation `XMLDocument(contentsOfFCPXML:)` remains available as a convenience.

```swift
let fileURL = URL(fileURLWithPath: "/Users/username/Documents/sample.fcpxml")

do {
    try fileURL.checkResourceIsReachable()
} catch {
    print("File not found.")
    return
}

let loader = FCPXMLFileLoader()
let fcpxmlDoc: any OFKXMLDocument
do {
    fcpxmlDoc = try loader.loadFCPXMLDocument(from: fileURL)
} catch {
    print("Error loading FCPXML.")
    return
}

// High-level wrapper (optional):
// let fcpxml = FinalCutPro.FCPXML(fileContent: fcpxmlDoc)
```

---

## List event names

```swift
let eventNames = fcpxmlDoc.fcpxEventNames
print("Events: \(eventNames)")
```

---

## Create and add events

```swift
let newEvent = OFKXMLDefaultFactory()
    .makeElement(name: "event")
    .fcpxEvent(name: "My New Event")
fcpxmlDoc.add(events: [newEvent])
print("Updated events: \(fcpxmlDoc.fcpxEventNames)")
```

---

## Work with clips

```swift
let firstEvent = fcpxmlDoc.fcpxEvents[0]
let matchingClips = try firstEvent.eventClips(forResourceID: "r1")

try firstEvent.removeFromEvent(items: matchingClips)

if let resource = fcpxmlDoc.resource(matchingID: "r1") {
    fcpxmlDoc.remove(resourceAtIndex: resource.index)
}
```

---

## Display clip duration

```swift
let firstEvent = fcpxmlDoc.fcpxEvents[0]
if let eventClips = firstEvent.eventClips, !eventClips.isEmpty {
    let firstClip = eventClips[0]
    if let duration = firstClip.fcpxDuration {
        let timeDisplay = duration.timeAsCounter().counterString
        print("Duration: \(timeDisplay)")
    }
}
```

---

## Save FCPXML file

```swift
do {
    try fcpxmlDoc.fcpxmlString.write(
        toFile: "/Users/username/Documents/sample-output.fcpxml",
        atomically: false,
        encoding: .utf8
    )
    print("Saved.")
} catch {
    print("Error writing file.")
}
```

---

## Create an empty project from the CLI

Use `--create-project` with width, height, frame rate, and output directory. The project file name is derived from the format (e.g. `1920x1080@25p.fcpxml`). The output is validated against the FCPXML DTD before writing.

```bash
OpenFCPXMLKit-CLI --create-project --width 1920 --height 1080 --rate 25 /path/to/output-dir
OpenFCPXMLKit-CLI --create-project --width 640 --height 480 --rate 29.97 --project-version 1.13 /path/to/output-dir
```

---

## Create an empty project with custom format (dimensions and frame rate)

```swift
import OpenFCPXMLKit
import CoreMedia

// Custom 500×500 at 25 fps
let frameDuration = CMTime(value: 1, timescale: 25)
let format = TimelineFormat(
    width: 500,
    height: 500,
    frameDuration: frameDuration,
    colorSpace: .rec709
)
let timeline = Timeline(name: "Custom 500×500 25fps", format: format, clips: [])
let exporter = FCPXMLExporter(version: .v1_13)
let xmlString = try exporter.export(
    timeline: timeline,
    assets: [],
    eventUid: FCPXMLUID.random(),
    projectUid: FCPXMLUID.random(),
    libraryLocation: "file:///Users/user/Movies/MyLibrary.fcpbundle/"
)
// xmlString is valid FCPXML with empty spine, format width="500" height="500", frameDuration for 25 fps
```

Use **TimelineFormat** presets (e.g. `hd1080p(frameDuration:colorSpace:)`) with any `frameDuration` for standard resolutions at different frame rates (23.976, 24, 25, 29.97, 30, 50, 59.94, 60 fps).

---

## Complete timeline workflow

```swift
import OpenFCPXMLKit
import CoreMedia

let format = TimelineFormat.hd1080p(
    frameDuration: CMTime(value: 1001, timescale: 24000),
    colorSpace: .rec709
)

let clip1 = TimelineClip(
    assetRef: "r1",
    offset: CMTime(value: 0, timescale: 1),
    duration: CMTime(value: 10, timescale: 1),
    start: .zero,
    lane: 0
)
let clip2 = TimelineClip(
    assetRef: "r2",
    offset: CMTime(value: 10, timescale: 1),
    duration: CMTime(value: 5, timescale: 1),
    start: .zero,
    lane: 0
)

var timeline = Timeline(name: "My Project", format: format, clips: [clip1, clip2])
timeline.addMarker(Marker(start: CMTime(value: 5, timescale: 1), value: "Marker 1"))
timeline.addChapterMarker(ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Chapter 1"))

let newClip = TimelineClip(
    assetRef: "r3",
    offset: .zero,
    duration: CMTime(value: 3, timescale: 1),
    lane: 0
)
let (updatedTimeline, result) = timeline.insertingClipWithRipple(
    newClip,
    at: CMTime(value: 5, timescale: 1),
    lane: 0
)
print("Shifted \(result.shiftedClips.count) clips")

let assets = [
    FCPXMLExportAsset(id: "r1", name: "Clip 1", src: URL(fileURLWithPath: "/path/to/clip1.mov"),
        duration: CMTime(value: 10, timescale: 1), hasVideo: true, hasAudio: true),
    FCPXMLExportAsset(id: "r2", name: "Clip 2", src: URL(fileURLWithPath: "/path/to/clip2.mov"),
        duration: CMTime(value: 5, timescale: 1), hasVideo: true, hasAudio: true),
    FCPXMLExportAsset(id: "r3", name: "Clip 3", src: URL(fileURLWithPath: "/path/to/clip3.mov"),
        duration: CMTime(value: 3, timescale: 1), hasVideo: true, hasAudio: true)
]

let exporter = FCPXMLBundleExporter(version: .default, includeMedia: false)
let bundleURL = try exporter.exportBundle(
    timeline: updatedTimeline,
    assets: assets,
    to: outputDirectory,
    bundleName: "My Project"
)
print("Exported to: \(bundleURL.path)")
```

---

## Validate assets before export

```swift
import OpenFCPXMLKit

let validator = AssetValidator()
let detector = MIMETypeDetector()

for asset in assets {
    guard let src = asset.src else { continue }
    let result = await validator.validateAsset(
        at: src,
        forLane: 0,
        mimeTypeDetector: detector
    )
    if !result.isValid {
        print("Warning: Asset \(asset.id) failed: \(result.reason ?? "unknown")")
    }
}

for clip in timeline.clips {
    if let asset = assets.first(where: { $0.id == clip.assetRef }),
       let src = asset.src {
        let result = await clip.validateAsset(at: src)
        if !result.isValid {
            print("Clip \(clip.assetRef) on lane \(clip.lane) has invalid asset")
        }
    }
}
```

---

## Build a report (Excel and PDF)

```swift
import OpenFCPXMLKit

let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

// Role inventory + every optional sheet (including Non-Std Effects & Templates when present),
// with filtering and frame-count timecodes
var options = FinalCutPro.FCPXML.ReportOptions.full
options.excludedRoles = ["Effects"]
options.excludeDisabledClips = true
options.excludedColumns = ["Reel", "Metadata", "Source File Path", "Duplicate Frames"]
options.timecodeFormat = .frames
options.mediaBaseURL = URL(fileURLWithPath: "/path/to/project.fcpxmld")

let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
print("Will build \(phases.count) section(s) in product order")
// Product order places Non-Std Effects & Templates immediately before Video & Audio Effects

let report = try await fcpxml.buildReport(options: options) { phase in
    print("Building \(phase.rawValue)…")
}

let xlsxURL = URL(fileURLWithPath: "/path/to/Report.xlsx")
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: xlsxURL)

let pdfURL = URL(fileURLWithPath: "/path/to/Report.pdf")
try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)

print("Wrote \(report.roleInventory?.roleSheets.count ?? 0) role sheet(s)")
print("Non-std effects rows: \(report.nonStandardEffectsTemplates?.rows.count ?? 0)")
print("Excluded columns: \(report.excludedColumns)")
print("Timecode format: \(report.timecodeFormat.rawValue)")
```

Equivalent CLI (Excel + PDF):

```bash
OpenFCPXMLKit-CLI --report --report-full --create-pdf \
  --label-copyright "© 2026 Example Studios" \
  --exclude-role Effects \
  --exclude-disabled-clips \
  --exclude-column Reel \
  --exclude-column Metadata \
  --exclude-column "Source File Path" \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir
```

Library equivalent for the copyright line:

```swift
var options = FinalCutPro.FCPXML.ReportOptions.full
options.copyrightLabel = "© 2026 Example Studios"
let report = try await fcpxml.buildReport(options: options)
// Excel cover A2 + PDF cover/footer centre
```

Markers outside clip boundaries + Excel sheet protection (chapter markers are already on by default):

```swift
var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
// options.includeChapterMarkersInMarkersReport defaults to true
options.includeMarkersOutsideClipBoundaries = true  // Hidden column (✓/✗)
options.protectSheets = true                        // Excel edit lock (not encryption)
let report = try await fcpxml.buildReport(options: options)
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: xlsxURL)
```

```bash
OpenFCPXMLKit-CLI --report --report-markers \
  --include-markers-outside-clip-boundaries \
  --protect-sheets \
  /path/to/project.fcpxmld /path/to/output-dir
```

---

## Author a simple project (detached Authoring)

```swift
typealias Authoring = FinalCutPro.FCPXML.Authoring

let format = Authoring.Format(id: "r1", frameDuration: "100/2400s", width: 1920, height: 1080)
let asset = Authoring.Asset(
    id: "r2",
    hasVideo: true,
    hasAudio: true,
    duration: "10s",
    formatID: "r1",
    mediaReps: [Authoring.MediaRep(src: "file:///tmp/clip.mov")]
)
let clip = Authoring.AssetClip(ref: "r2", offset: "0s", duration: "5s", name: "Clip", start: "0s")
let document = Authoring.Document.simpleProject(
    version: .v1_14,
    format: format,
    asset: asset,
    clip: clip,
    sequenceDuration: "5s"
)
let xml = try document.xmlString()
```

Full Authoring API: [08 — Detached Authoring](08-Detached-Authoring.md).

---

## Project a timeline (MediaUsageWindow)

```swift
import OpenFCPXMLKit

let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
guard let source = fcpxml.allReportTimelineSources().first else { return }

let projector = FinalCutPro.FCPXML.TimelineProjector()
var projectionOptions = FinalCutPro.FCPXML.TimelineProjectionOptions.mainTimeline
projectionOptions.includeAnnotations = true

let windows = try await projector.project(
    from: source,
    fcpxml: fcpxml,
    options: projectionOptions
)

let videoSeconds = FinalCutPro.FCPXML.TimelineOccupancyIndex(windows: windows)
    .occupiedDuration(kind: .video)
print("Union video occupancy:", videoSeconds, "s across", windows.count, "windows")
```

Full Projection API: [12 — Timeline Projection](12-Timeline-Projection.md). Reporting project-once is automatic inside `buildReport` when sections need windows.

---

Excel-only CLI (omit `--create-pdf`):

```bash
OpenFCPXMLKit-CLI --report --report-full \
  --exclude-role Effects \
  --exclude-disabled-clips \
  --exclude-column Reel \
  --exclude-column Metadata \
  --exclude-column "Source File Path" \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir
```

See [20 — Reporting, Excel & PDF Export](20-Reporting.md) and [12 — Timeline Projection](12-Timeline-Projection.md) for the full reporting and Projection APIs.

---

For FCPXML format details see [fcp.cafe/developers/fcpxml](https://fcp.cafe/developers/fcpxml). For project overview and installation see the main [README](../../README.md).

[← Manual Index](00-Index.md)

## Next

- [Manual Index](00-Index.md) — return to the table of contents.

[← Manual Index](00-Index.md)


