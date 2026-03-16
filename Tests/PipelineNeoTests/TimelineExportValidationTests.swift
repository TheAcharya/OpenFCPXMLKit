//
//  TimelineExportValidationTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for timeline, export, validation, and file loading.
//

import XCTest
import CoreMedia
@testable import PipelineNeo

@available(macOS 12.0, *)
final class TimelineExportValidationTests: XCTestCase {

    // MARK: - Timeline & TimelineClip

    func testTimelineClipEndTime() {
        let clip = TimelineClip(
            assetRef: "r2",
            offset: CMTime(value: 10, timescale: 1),
            duration: CMTime(value: 5, timescale: 1)
        )
        XCTAssertEqual(CMTimeGetSeconds(clip.endTime), 15)
    }

    func testTimelineDurationFromPrimaryLane() {
        let clips: [TimelineClip] = [
            TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0),
            TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0),
        ]
        let timeline = Timeline(name: "T", clips: clips)
        XCTAssertEqual(CMTimeGetSeconds(timeline.duration), 15)
    }

    func testTimelineSortedClips() {
        let clips: [TimelineClip] = [
            TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 1, timescale: 1), lane: 0),
            TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0),
        ]
        let timeline = Timeline(name: "T", clips: clips)
        let sorted = timeline.sortedClips
        XCTAssertEqual(sorted[0].assetRef, "r2")
        XCTAssertEqual(sorted[1].assetRef, "r3")
    }

    func testTimelineFormatHelpers() {
        let fd = CMTime(value: 1001, timescale: 24000)
        let hd = TimelineFormat.hd1080p(frameDuration: fd, colorSpace: .rec709)
        XCTAssertEqual(hd.width, 1920)
        XCTAssertEqual(hd.height, 1080)
        XCTAssertFalse(hd.interlaced)
        XCTAssertTrue(hd.isHD)
        XCTAssertTrue(hd.is1080p)
        XCTAssertFalse(hd.isUHD)
        
        let uhd = TimelineFormat.uhd4K(frameDuration: fd, colorSpace: .rec2020)
        XCTAssertEqual(uhd.width, 3840)
        XCTAssertEqual(uhd.height, 2160)
        XCTAssertTrue(uhd.isUHD)
        XCTAssertTrue(uhd.isStandard4K)
        XCTAssertFalse(uhd.isDCI4K)
        
        let dci = TimelineFormat.dci4K(frameDuration: fd, colorSpace: .rec2020)
        XCTAssertEqual(dci.width, 4096)
        XCTAssertEqual(dci.height, 2160)
        XCTAssertTrue(dci.isUHD)
        XCTAssertTrue(dci.isDCI4K)
        XCTAssertFalse(dci.isStandard4K)
        
        let hd720 = TimelineFormat.hd720p(frameDuration: fd, colorSpace: .rec709)
        XCTAssertEqual(hd720.width, 1280)
        XCTAssertEqual(hd720.height, 720)
        XCTAssertTrue(hd720.isHD)
        XCTAssertTrue(hd720.is720p)
        
        let hd1080i = TimelineFormat.hd1080i(frameDuration: fd, colorSpace: .rec709)
        XCTAssertTrue(hd1080i.interlaced)
        XCTAssertEqual(hd1080i.width, 1920)
        XCTAssertEqual(hd1080i.height, 1080)
    }
    
    func testTimelineFormatComputedProperties() {
        let fd = CMTime(value: 1001, timescale: 24000)
        let format = TimelineFormat.hd1080p(frameDuration: fd)
        
        // Aspect ratio
        XCTAssertEqual(format.aspectRatio, 1920.0 / 1080.0, accuracy: 0.001)
        
        // Resolution checks
        XCTAssertTrue(format.isHD)
        XCTAssertTrue(format.is1080p)
        XCTAssertFalse(format.is720p)
        XCTAssertFalse(format.isUHD)
        XCTAssertFalse(format.interlaced)
    }
    
    func testTimelineFormatEquality() {
        let fd = CMTime(value: 1001, timescale: 24000)
        let format1 = TimelineFormat.hd1080p(frameDuration: fd)
        let format2 = TimelineFormat.hd1080p(frameDuration: fd)
        let format3 = TimelineFormat.hd1080p(frameDuration: fd, colorSpace: .rec2020)
        let format4 = TimelineFormat.hd1080i(frameDuration: fd)
        
        XCTAssertEqual(format1, format2)
        XCTAssertNotEqual(format1, format3) // Different color space
        XCTAssertNotEqual(format1, format4) // Different interlaced
    }
    
    func testTimelineFormatHelpersOnTimeline() {
        let timeline = Timeline(name: "Test")
        XCTAssertFalse(timeline.isHD)
        XCTAssertFalse(timeline.isUHD)
        XCTAssertEqual(timeline.aspectRatio, 0)
        
        let fd = CMTime(value: 1001, timescale: 24000)
        let format = TimelineFormat.hd1080p(frameDuration: fd)
        let timelineWithFormat = Timeline(name: "Test", format: format)
        
        XCTAssertTrue(timelineWithFormat.isHD)
        XCTAssertFalse(timelineWithFormat.isUHD)
        XCTAssertEqual(timelineWithFormat.aspectRatio, 1920.0 / 1080.0, accuracy: 0.001)
    }

    /// Barebone empty timeline creation at different sizes and frame rates (no export); asserts model properties only.
    func testEmptyTimelineCreationAtDifferentSizesAndFrameRates() {
        let configurations: [(width: Int, height: Int, timescale: Int32)] = [
            (1280, 720, 24),
            (1280, 720, 25),
            (1920, 1080, 24),
            (1920, 1080, 25),
            (1920, 1080, 30),
            (3840, 2160, 24),
            (3840, 2160, 25),
            (4096, 2160, 24),  // DCI 4K
            (640, 480, 30),
        ]
        for config in configurations {
            let format = TimelineFormat(
                width: config.width,
                height: config.height,
                frameDuration: CMTime(value: 1, timescale: config.timescale),
                colorSpace: .rec709
            )
            let name = "\(config.width)x\(config.height)@\(config.timescale)p"
            let timeline = Timeline(name: name, format: format, clips: [])
            XCTAssertEqual(timeline.name, name, "\(name): name")
            XCTAssertTrue(timeline.clips.isEmpty, "\(name): empty clips")
            XCTAssertEqual(CMTimeCompare(timeline.duration, .zero), 0, "\(name): duration zero")
            XCTAssertEqual(timeline.sortedClips.count, 0, "\(name): sortedClips empty")
            guard let f = timeline.format else {
                XCTFail("\(name): format non-nil")
                continue
            }
            XCTAssertEqual(f.width, config.width, "\(name): width")
            XCTAssertEqual(f.height, config.height, "\(name): height")
            XCTAssertEqual(f.frameDuration.timescale, config.timescale, "\(name): frame timescale")
            XCTAssertEqual(f.frameDuration.value, 1, "\(name): frame value")
            XCTAssertEqual(timeline.aspectRatio, Double(config.width) / Double(config.height), accuracy: 0.001, "\(name): aspectRatio")
        }
    }

    // MARK: - FCPXMLExporter

    func testFCPXMLExporterExportMinimal() throws {
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0
        )
        let timeline = Timeline(name: "Test", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            name: "Clip1",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xml.contains("<fcpxml"))
        XCTAssertTrue(xml.contains("resources"))
        XCTAssertTrue(xml.contains("r1"))
        XCTAssertTrue(xml.contains("r2"))
        XCTAssertTrue(xml.contains("asset-clip"))
        XCTAssertTrue(xml.contains("ref=\"r2\""))
    }

    func testFCPXMLExporterMissingAssetThrows() {
        let clip = TimelineClip(assetRef: "r99", offset: .zero, duration: CMTime(value: 1, timescale: 1), lane: 0)
        let timeline = Timeline(name: "T", clips: [clip])
        let exporter = FCPXMLExporter(version: .default)
        XCTAssertThrowsError(try exporter.export(timeline: timeline, assets: [])) { err in
            guard case FCPXMLExportError.missingAsset(let id) = err else {
                XCTFail("Expected missingAsset, got \(err)"); return
            }
            XCTAssertEqual(id, "r99")
        }
    }

    func testFCPXMLExporterEmptyTimelineSucceeds() throws {
        let timeline = Timeline(name: "Empty", clips: [])
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [])
        XCTAssertTrue(xml.contains("<fcpxml"))
        XCTAssertTrue(xml.contains("<spine/>") || xml.contains("</spine>"))
        XCTAssertTrue(xml.contains("uid="))
        XCTAssertTrue(xml.contains("modDate="))
        XCTAssertTrue(xml.contains("duration=\"0s\""))
    }

    func testFCPXMLExporterEmptyTimelineWithCustomUIDsAndLocation() throws {
        let timeline = Timeline(name: "Custom", clips: [])
        let exporter = FCPXMLExporter(version: .default)
        let eventUid = FCPXMLUID.random()
        let projectUid = FCPXMLUID.random()
        let xml = try exporter.export(
            timeline: timeline,
            assets: [],
            eventUid: eventUid,
            projectUid: projectUid,
            libraryLocation: "file:///Users/user/Movies/Sample%20Projects.fcpbundle/"
        )
        XCTAssertTrue(xml.contains("uid=\"\(eventUid)\""))
        XCTAssertTrue(xml.contains("uid=\"\(projectUid)\""))
        XCTAssertTrue(xml.contains("location=\"file:///Users/user/Movies/Sample%20Projects.fcpbundle/\""))
    }

    // MARK: - FCPXMLExporter clip-level metadata (PR #14)

    func testFCPXMLExporterExportsClipMarkers() throws {
        let marker = Marker(
            start: CMTime(value: 0, timescale: 24),
            duration: CMTime(value: 1, timescale: 24),
            value: "My Marker",
            note: "A note",
            completed: true
        )
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0,
            markers: [marker]
        )
        let timeline = Timeline(name: "WithMarkers", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            name: "Clip1",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xml.contains("<marker "))
        XCTAssertTrue(xml.contains("value=\"My Marker\""))
        XCTAssertTrue(xml.contains("note=\"A note\""))
        XCTAssertTrue(xml.contains("completed=\"1\""))
    }

    func testFCPXMLExporterExportsClipChapterMarkers() throws {
        let chapter = ChapterMarker(
            start: CMTime(value: 0, timescale: 24),
            value: "Chapter 1",
            posterOffset: CMTime(value: 5, timescale: 24),
            note: "Chapter note"
        )
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0,
            chapterMarkers: [chapter]
        )
        let timeline = Timeline(name: "WithChapters", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xml.contains("<chapter-marker "))
        XCTAssertTrue(xml.contains("value=\"Chapter 1\""))
        XCTAssertTrue(xml.contains("posterOffset="))
        XCTAssertTrue(xml.contains("note=\"Chapter note\""))
    }

    func testFCPXMLExporterExportsClipKeywords() throws {
        let keyword = Keyword(
            start: CMTime(value: 0, timescale: 24),
            duration: CMTime(value: 48, timescale: 24),
            value: "B-Roll",
            note: "Keyword note"
        )
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0,
            keywords: [keyword]
        )
        let timeline = Timeline(name: "WithKeywords", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xml.contains("<keyword "))
        XCTAssertTrue(xml.contains("value=\"B-Roll\""))
        XCTAssertTrue(xml.contains("note=\"Keyword note\""))
    }

    func testFCPXMLExporterExportsClipRatings() throws {
        let rating = Rating(
            start: CMTime(value: 0, timescale: 24),
            duration: CMTime(value: 24, timescale: 24),
            value: .favorite,
            note: "Fav note"
        )
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0,
            ratings: [rating]
        )
        let timeline = Timeline(name: "WithRatings", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xml.contains("<rating "))
        XCTAssertTrue(xml.contains("value=\"favorite\""))
        XCTAssertTrue(xml.contains("note=\"Fav note\""))
    }

    func testFCPXMLExporterExportsClipMetadata() throws {
        var meta = Metadata()
        meta.entries["com.apple.proapps.studio.reel"] = "R1"
        meta.entries["com.apple.proapps.studio.scene"] = "S2"
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0,
            metadata: meta
        )
        let timeline = Timeline(name: "WithMetadata", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xml.contains("<metadata>") || xml.contains("<metadata "))
        XCTAssertTrue(xml.contains("<md ") || xml.contains("<md "))
        XCTAssertTrue(xml.contains("key=") && xml.contains("value="))
    }

    /// Export one clip with all clip-level metadata types; parse and validate against DTD (asset-clip children per FCPXML DTD).
    func testFCPXMLExporterClipMetadataAllTypesValidatesAgainstDTD() throws {
        let marker = Marker(start: .zero, duration: CMTime(value: 1, timescale: 24), value: "M1")
        let chapter = ChapterMarker(start: .zero, value: "Ch1")
        let keyword = Keyword(start: .zero, duration: CMTime(value: 1, timescale: 24), value: "K1")
        let rating = Rating(start: .zero, duration: CMTime(value: 1, timescale: 24), value: .favorite)
        var meta = Metadata()
        meta.entries["custom.key"] = "custom.value"
        let clip = TimelineClip(
            assetRef: "r2",
            offset: .zero,
            duration: CMTime(value: 1001, timescale: 24000),
            start: .zero,
            lane: 0,
            markers: [marker],
            chapterMarkers: [chapter],
            keywords: [keyword],
            ratings: [rating],
            metadata: meta
        )
        let timeline = Timeline(name: "FullMetadata", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            src: URL(fileURLWithPath: "/tmp/sample.mov"),
            duration: CMTime(value: 1001, timescale: 24000),
            hasVideo: true,
            hasAudio: true
        )
        let exporter = FCPXMLExporter(version: .v1_13)
        let xmlString = try exporter.export(timeline: timeline, assets: [asset])
        XCTAssertTrue(xmlString.contains("<marker "))
        XCTAssertTrue(xmlString.contains("<chapter-marker "))
        XCTAssertTrue(xmlString.contains("<keyword "))
        XCTAssertTrue(xmlString.contains("<rating "))
        XCTAssertTrue(xmlString.contains("<metadata>") || xmlString.contains("<metadata "))
        guard let data = xmlString.data(using: .utf8) else {
            XCTFail("FCPXML string encoding failed")
            return
        }
        let service = FCPXMLService(logger: NoOpPipelineLogger())
        let document = try service.parseFCPXML(from: data)
        let result = service.validateDocumentAgainstDTD(document, version: .v1_13)
        XCTAssertTrue(result.isValid, "Export with clip metadata must validate against DTD: \(result.detailedDescription)")
    }

    /// XML declaration must use standalone="no" (or omit) so xmllint --dtdvalid does not warn about whitespace.
    func testFCPXMLExporterXmlDeclarationStandaloneNo() throws {
        let timeline = Timeline(name: "Empty", clips: [])
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [])
        XCTAssertFalse(xml.contains("standalone=\"yes\""), "Exported FCPXML must not declare standalone=\"yes\" for DTD validation")
        XCTAssertTrue(
            xml.contains("standalone=\"no\"") || (xml.hasPrefix("<?xml") && !xml.contains("standalone=")),
            "Exported FCPXML should declare standalone=\"no\" or omit standalone for xmllint compatibility"
        )
    }

    /// Covers the export path used by CLI --create-project: empty timeline, custom format, default smart collections, DTD validation.
    func testProjectCreationStyleExportValidatesAgainstDTD() throws {
        let format = TimelineFormat(
            width: 1920,
            height: 1080,
            frameDuration: CMTime(value: 1, timescale: 25),
            colorSpace: .rec709
        )
        let timeline = Timeline(name: "1920x1080@25p", format: format, clips: [])
        let exporter = FCPXMLExporter(version: .v1_13)
        let xmlString = try exporter.export(
            timeline: timeline,
            assets: [],
            libraryName: "Library",
            eventName: "Event",
            projectName: timeline.name,
            includeDefaultSmartCollections: true
        )
        XCTAssertTrue(xmlString.contains("<!DOCTYPE fcpxml>"))
        XCTAssertTrue(xmlString.contains("colorSpace="))
        XCTAssertTrue(xmlString.contains("smart-collection"))
        XCTAssertTrue(xmlString.contains("match-clip"))
        XCTAssertTrue(xmlString.contains("match-media"))
        XCTAssertTrue(xmlString.contains("match-ratings"))
        guard let data = xmlString.data(using: .utf8) else {
            XCTFail("FCPXML string encoding failed")
            return
        }
        let service = FCPXMLService(logger: NoOpPipelineLogger())
        let document = try service.parseFCPXML(from: data)
        let result = service.validateDocumentAgainstDTD(document, version: .v1_13)
        XCTAssertTrue(result.isValid, "Project-creation style export must validate against DTD: \(result.detailedDescription)")
    }

    /// Project creation (empty timeline export) at multiple sizes and frame rates; each export parses and validates against DTD.
    func testProjectCreationAtDifferentSizesAndFrameRates() throws {
        // (width, height, timescale) — Final Cut Pro–compatible frame rates
        let configurations: [(width: Int, height: Int, timescale: Int32)] = [
            (1280, 720, 24),   // 720p @ 24
            (1280, 720, 25),   // 720p @ 25
            (1920, 1080, 24),  // 1080p @ 24
            (1920, 1080, 25),  // 1080p @ 25
            (1920, 1080, 30),  // 1080p @ 30
            (1920, 1080, 60000), // 1080p @ 59.94 (1001/60000s would be exact; 1/60 for test)
            (3840, 2160, 24),  // 4K UHD @ 24
            (3840, 2160, 25),  // 4K UHD @ 25
            (640, 480, 30),    // Custom size @ 30
        ]
        let service = FCPXMLService(logger: NoOpPipelineLogger())
        let exporter = FCPXMLExporter(version: .v1_13)

        for config in configurations {
            let format = TimelineFormat(
                width: config.width,
                height: config.height,
                frameDuration: CMTime(value: 1, timescale: config.timescale),
                colorSpace: .rec709
            )
            let name = "\(config.width)x\(config.height)@\(config.timescale)p"
            let timeline = Timeline(name: name, format: format, clips: [])
            let xmlString = try exporter.export(
                timeline: timeline,
                assets: [],
                libraryName: "Library",
                eventName: "Event",
                projectName: name,
                includeDefaultSmartCollections: true
            )
            XCTAssertTrue(xmlString.contains("width=\"\(config.width)\""), "\(name): width in output")
            XCTAssertTrue(xmlString.contains("height=\"\(config.height)\""), "\(name): height in output")
            guard let data = xmlString.data(using: .utf8) else {
                XCTFail("\(name): FCPXML string encoding failed")
                continue
            }
            let document = try service.parseFCPXML(from: data)
            let result = service.validateDocumentAgainstDTD(document, version: .v1_13)
            XCTAssertTrue(result.isValid, "\(name): export must validate against DTD: \(result.detailedDescription)")
        }
    }

    func testFCPXMLUIDRandomAndIsValid() {
        let uid = FCPXMLUID.random()
        XCTAssertTrue(FCPXMLUID.isValid(uid))
        XCTAssertEqual(uid.count, 36)
        XCTAssertTrue(uid.contains("-"))
        XCTAssertFalse(FCPXMLUID.isValid("short"))
        XCTAssertFalse(FCPXMLUID.isValid("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"))
        XCTAssertTrue(FCPXMLUID.isValid("D71600AB-2F01-4850-8DBD-E9F0594BD004"))
    }

    // MARK: - FCPXMLBundleExporter

    func testFCPXMLBundleExporterCreatesBundle() throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        let clip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 1, timescale: 1), lane: 0)
        let timeline = Timeline(name: "BundleTest", clips: [clip])
        let asset = FCPXMLExportAsset(
            id: "r2",
            src: URL(fileURLWithPath: "/nonexistent.mov"),
            hasVideo: true,
            hasAudio: true
        )

        // Without media: should still create bundle structure (but we'd fail on copy if includeMedia true and file missing)
        let exporter = FCPXMLBundleExporter(version: .default, includeMedia: false)
        // Export with includeMedia: false doesn't copy files; we need valid FCPXML. So we build assets that aren't copied.
        // Actually with includeMedia: false we don't copy, so we never touch asset.src. So we can use a fake URL.
        let bundleURL = try exporter.exportBundle(timeline: timeline, assets: [asset], to: temp, bundleName: "Out")
        XCTAssertTrue(FileManager.default.fileExists(atPath: bundleURL.path))
        XCTAssertEqual(bundleURL.lastPathComponent, "Out.fcpxmld")
        let infoFcpxml = bundleURL.appendingPathComponent("Info.fcpxml")
        let infoPlist = bundleURL.appendingPathComponent("Info.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: infoFcpxml.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: infoPlist.path))
        let xmlData = try Data(contentsOf: infoFcpxml)
        let xml = String(data: xmlData, encoding: .utf8)
        XCTAssertNotNil(xml)
        XCTAssertTrue(xml?.contains("<fcpxml") == true)
    }

    func testFCPXMLBundleExporterWithMediaCopiesFiles() throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        // Create a real temp file to copy
        let sample = temp.appendingPathComponent("sample.mov")
        try Data("fake".utf8).write(to: sample)

        let clip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 1, timescale: 1), lane: 0)
        let timeline = Timeline(name: "WithMedia", clips: [clip])
        let asset = FCPXMLExportAsset(id: "r2", src: sample, hasVideo: true, hasAudio: true)

        let exporter = FCPXMLBundleExporter(version: .default, includeMedia: true)
        let bundleURL = try exporter.exportBundle(timeline: timeline, assets: [asset], to: temp, bundleName: "WithMedia")
        let mediaDir = bundleURL.appendingPathComponent("Media")
        XCTAssertTrue(FileManager.default.fileExists(atPath: mediaDir.path))
        let mediaContents = try FileManager.default.contentsOfDirectory(atPath: mediaDir.path)
        XCTAssertEqual(mediaContents.count, 1)
        XCTAssertTrue(mediaContents[0].hasSuffix(".mov") || mediaContents[0] == "sample.mov")
        let xmlData = try Data(contentsOf: bundleURL.appendingPathComponent("Info.fcpxml"))
        let xml = String(data: xmlData, encoding: .utf8)!
        XCTAssertTrue(xml.contains("<fcpxml"))
        // Exporter uses relativePath "Media/filename" when includeMedia is true
        XCTAssertTrue(xml.contains("Media/") || xml.contains("src="), "FCPXML should reference media")
    }

    // MARK: - FCPXMLValidator (semantic)

    func testFCPXMLValidatorSuccessWithValidStructure() {
        let root = FoundationXMLFactory().makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.14")
        let resources = FoundationXMLFactory().makeElement(name: "resources")
        let format = FoundationXMLFactory().makeElement(name: "format")
        format.addAttribute(name: "id", value: "r1")
        resources.addChild(format)
        root.addChild(resources)
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(root)
        let validator = FCPXMLValidator()
        let result = validator.validate(doc)
        XCTAssertTrue(result.isValid)
    }

    func testFCPXMLValidatorMissingRoot() {
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(FoundationXMLFactory().makeElement(name: "notfcpxml"))
        let validator = FCPXMLValidator()
        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.message.contains("fcpxml") })
    }

    func testFCPXMLValidatorUnresolvedRef() {
        let root = FoundationXMLFactory().makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.14")
        let resources = FoundationXMLFactory().makeElement(name: "resources")
        root.addChild(resources)
        let event = FoundationXMLFactory().makeElement(name: "event")
        event.addAttribute(name: "name", value: "E1")
        let project = FoundationXMLFactory().makeElement(name: "project")
        let sequence = FoundationXMLFactory().makeElement(name: "sequence")
        let spine = FoundationXMLFactory().makeElement(name: "spine")
        let clip = FoundationXMLFactory().makeElement(name: "asset-clip")
        clip.addAttribute(name: "ref", value: "r99")
        spine.addChild(clip)
        sequence.addChild(spine)
        project.addChild(sequence)
        event.addChild(project)
        root.addChild(event)
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(root)
        let validator = FCPXMLValidator()
        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.type == .missingAssetReference })
    }

    // MARK: - FCPXMLDTDValidator

    func testFCPXMLDTDValidatorReturnsResult() {
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .default)
        let validator = FCPXMLDTDValidator()
        let result = validator.validate(doc, version: .default)
        // A well-formed document with resources + events should validate against the DTD.
        XCTAssertTrue(result.isValid, "Expected valid FCPXML, got errors: \(result.errors.map(\.message))")
    }

    // MARK: - FCPXMLService DTD validation (per-version)

    func testValidateDocumentAgainstDTD_EachSupportedVersion() {
        let service = FCPXMLService()
        // 1.5 DTD requires (import-options?, resources?, library); the convenience init produces (resources?, events); use 1.6–1.14.
        let versionsToTest = FCPXMLVersion.allCases.filter { $0 != .v1_5 }
        for version in versionsToTest {
            let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: version)
            let result = service.validateDocumentAgainstDTD(doc, version: version)
            XCTAssertTrue(
                result.isValid,
                "Version \(version.rawValue) should validate against its own DTD. Errors: \(result.detailedDescription)"
            )
        }
        // Version 1.5 DTD requires (import-options?, resources?, library). Build minimal valid doc.
        let doc1_5 = FoundationXMLFactory().makeDocument() as! FoundationXMLDocument
        doc1_5.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
        doc1_5.fcpxmlVersion = "1.5"
        doc1_5.rootElement()?.addChild(FoundationXMLFactory().makeElement(name: "resources"))
        doc1_5.rootElement()?.addChild(FoundationXMLFactory().makeElement(name: "library"))
        let result1_5 = service.validateDocumentAgainstDTD(doc1_5, version: .v1_5)
        XCTAssertTrue(result1_5.isValid, "Version 1.5 with library should validate. Errors: \(result1_5.detailedDescription)")
    }

    func testValidateDocumentAgainstDeclaredVersion_ValidDocument() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_10)
        let result = service.validateDocumentAgainstDeclaredVersion(doc)
        XCTAssertTrue(result.isValid, "Declared version 1.10 should validate. Errors: \(result.detailedDescription)")
    }

    func testValidateDocumentAgainstDeclaredVersion_MissingVersion() {
        let service = FCPXMLService()
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
        // No version attribute
        let result = service.validateDocumentAgainstDeclaredVersion(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.message.contains("no FCPXML version") })
    }

    func testValidateDocumentAgainstDeclaredVersion_UnsupportedVersion() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_14)
        doc.fcpxmlVersion = "99.99"
        let result = service.validateDocumentAgainstDeclaredVersion(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.message.contains("Unsupported") || $0.message.contains("99.99") })
    }

    // MARK: - performValidation (semantic + DTD)

    func testPerformValidation_ValidDocument() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_10)
        // Ensure resources element exists (semantic validator requires it)
        if doc.fcpxmlElement?.firstChildElement(named: "resources") == nil {
            let resourcesEl = FoundationXMLFactory().makeElement(name: "resources")
            doc.fcpxmlElement?.addChild(resourcesEl)
        }
        let report = service.performValidation(doc)
        XCTAssertTrue(report.isValid, "Valid document should pass full validation. \(report.summary)")
        XCTAssertTrue(report.semantic.isValid)
        XCTAssertTrue(report.dtd.isValid)
    }

    func testPerformValidation_InvalidSemantic() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_10)
        if doc.fcpxmlElement?.firstChildElement(named: "resources") == nil {
            doc.fcpxmlElement?.addChild(FoundationXMLFactory().makeElement(name: "resources"))
        }
        let root = doc.fcpxmlElement!
        let clip = FoundationXMLFactory().makeElement(name: "ref-clip")
        clip.addAttribute(name: "ref", value: "missing-resource")
        root.addChild(clip)
        let report = service.performValidation(doc)
        XCTAssertFalse(report.isValid)
        XCTAssertFalse(report.semantic.isValid, "Semantic validation should fail for unresolved ref")
        XCTAssertTrue(report.semantic.errors.contains { $0.message.contains("missing-resource") || $0.message.contains("Reference") })
    }

    func testPerformValidation_InvalidDTD() {
        let service = FCPXMLService()
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
        // No version attribute -> DTD validation fails
        let report = service.performValidation(doc)
        XCTAssertFalse(report.isValid)
        XCTAssertFalse(report.semantic.isValid) // also missing resources
        XCTAssertFalse(report.dtd.isValid)
    }

    // MARK: - FCPXMLFileLoader (.fcpxml / .fcpxmld file I/O)

    func testFCPXMLFileLoaderLoadsSingleFile() throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".fcpxml")
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.14">
            <resources/>
        </fcpxml>
        """
        try xml.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: temp)
        XCTAssertNotNil(doc.rootElement())
        XCTAssertTrue(doc.rootElement()?.name == "fcpxml")
    }

    func testFCPXMLFileLoaderLoadsBundle() throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let clip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 1, timescale: 1), lane: 0)
        let timeline = Timeline(name: "LoadTest", clips: [clip])
        let asset = FCPXMLExportAsset(id: "r2", src: URL(fileURLWithPath: "/tmp/x.mov"), hasVideo: true, hasAudio: true)
        let exporter = FCPXMLBundleExporter(version: .default, includeMedia: false)
        let bundleURL = try exporter.exportBundle(timeline: timeline, assets: [asset], to: temp, bundleName: "Bundle")
        let loader = FCPXMLFileLoader()
        let resolved = try loader.resolveFCPXMLFileURL(from: bundleURL)
        XCTAssertEqual(resolved.lastPathComponent, "Info.fcpxml")
        let doc = try loader.loadDocument(from: bundleURL)
        XCTAssertNotNil(doc.rootElement())
    }

    func testFCPXMLFileLoaderThrowsForMissingURL() {
        let url = URL(fileURLWithPath: "/nonexistent/path.fcpxml")
        let loader = FCPXMLFileLoader()
        XCTAssertThrowsError(try loader.loadDocument(from: url)) { err in
            XCTAssertTrue(err is FCPXMLLoadError)
        }
    }
}
