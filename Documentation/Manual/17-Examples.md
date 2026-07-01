# 17 — Examples

[← Manual Index](00-Index.md)

---

## Open an FCPXML file

```swift
let fileURL = URL(fileURLWithPath: "/Users/username/Documents/sample.fcpxml")

do {
    try fileURL.checkResourceIsReachable()
} catch {
    print("File not found.")
    return
}

let fcpxmlDoc: XMLDocument
do {
    fcpxmlDoc = try XMLDocument(contentsOfFCPXML: fileURL)
} catch {
    print("Error loading FCPXML.")
    return
}
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
let newEvent = XMLElement().fcpxEvent(name: "My New Event")
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

## Build an Excel report

```swift
import OpenFCPXMLKit

let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

// Role inventory + every optional sheet, excluding a role
var options = FinalCutPro.FCPXML.ReportOptions.full
options.excludedRoles = ["Effects"]

let report = try await fcpxml.buildReport(options: options) { phase in
    print("Building \(phase.rawValue)…")
}

let outputURL = URL(fileURLWithPath: "/path/to/Report.xlsx")
try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)
print("Wrote \(report.roleInventory?.roleSheets.count ?? 0) role sheet(s)")
```

See [19 — Reporting & Excel Export](19-Reporting.md) for the full reporting API.

---

For FCPXML format details see [fcp.cafe/developers/fcpxml](https://fcp.cafe/developers/fcpxml). For project overview and installation see the main [README](../../README.md).

[← Manual Index](00-Index.md)
