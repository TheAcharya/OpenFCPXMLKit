//
//  FCPXMLTimelineExportValidationTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for timeline, export, validation, and file loading.
//

import Foundation
import Testing
import CoreMedia
@testable import OpenFCPXMLKit

@Suite("Timeline export validation")
struct FCPXMLTimelineExportValidationTests {

    // MARK: - Timeline & TimelineClip

    @Test("Timeline clip end time")
    func timelineClipEndTime() {
        let clip = TimelineClip(
            assetRef: "r2",
            offset: CMTime(value: 10, timescale: 1),
            duration: CMTime(value: 5, timescale: 1)
        )
        #expect(CMTimeGetSeconds(clip.endTime) == 15)
    }

    @Test("Timeline duration from primary lane")
    func timelineDurationFromPrimaryLane() {
        let clips: [TimelineClip] = [
            TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0),
            TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0),
        ]
        let timeline = Timeline(name: "T", clips: clips)
        #expect(CMTimeGetSeconds(timeline.duration) == 15)
    }

    @Test("Timeline sorted clips")
    func timelineSortedClips() {
        let clips: [TimelineClip] = [
            TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 1, timescale: 1), lane: 0),
            TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0),
        ]
        let timeline = Timeline(name: "T", clips: clips)
        let sorted = timeline.sortedClips
        #expect(sorted[0].assetRef == "r2")
        #expect(sorted[1].assetRef == "r3")
    }

    @Test("Timeline format helpers")
    func timelineFormatHelpers() {
        let fd = CMTime(value: 1001, timescale: 24000)
        let hd = TimelineFormat.hd1080p(frameDuration: fd, colorSpace: .rec709)
        #expect(hd.width == 1920)
        #expect(hd.height == 1080)
        let _notMatch1 = !(hd.interlaced)
        #expect(_notMatch1)
        #expect(hd.isHD)
        #expect(hd.is1080p)
        let _notMatch2 = !(hd.isUHD)
        #expect(_notMatch2)
        
        let uhd = TimelineFormat.uhd4K(frameDuration: fd, colorSpace: .rec2020)
        #expect(uhd.width == 3840)
        #expect(uhd.height == 2160)
        #expect(uhd.isUHD)
        #expect(uhd.isStandard4K)
        let _notMatch3 = !(uhd.isDCI4K)
        #expect(_notMatch3)
        
        let dci = TimelineFormat.dci4K(frameDuration: fd, colorSpace: .rec2020)
        #expect(dci.width == 4096)
        #expect(dci.height == 2160)
        #expect(dci.isUHD)
        #expect(dci.isDCI4K)
        let _notMatch4 = !(dci.isStandard4K)
        #expect(_notMatch4)
        
        let hd720 = TimelineFormat.hd720p(frameDuration: fd, colorSpace: .rec709)
        #expect(hd720.width == 1280)
        #expect(hd720.height == 720)
        #expect(hd720.isHD)
        #expect(hd720.is720p)
        
        let hd1080i = TimelineFormat.hd1080i(frameDuration: fd, colorSpace: .rec709)
        #expect(hd1080i.interlaced)
        #expect(hd1080i.width == 1920)
        #expect(hd1080i.height == 1080)
    }
    
    @Test("Timeline format computed properties")
    func timelineFormatComputedProperties() {
        let fd = CMTime(value: 1001, timescale: 24000)
        let format = TimelineFormat.hd1080p(frameDuration: fd)
        
        // Aspect ratio
        #expect(abs((format.aspectRatio) - (1920.0 / 1080.0)) < 0.001)
        
        // Resolution checks
        #expect(format.isHD)
        #expect(format.is1080p)
        let _notMatch5 = !(format.is720p)
        #expect(_notMatch5)
        let _notMatch6 = !(format.isUHD)
        #expect(_notMatch6)
        let _notMatch7 = !(format.interlaced)
        #expect(_notMatch7)
    }
    
    @Test("Timeline format equality")
    func timelineFormatEquality() {
        let fd = CMTime(value: 1001, timescale: 24000)
        let format1 = TimelineFormat.hd1080p(frameDuration: fd)
        let format2 = TimelineFormat.hd1080p(frameDuration: fd)
        let format3 = TimelineFormat.hd1080p(frameDuration: fd, colorSpace: .rec2020)
        let format4 = TimelineFormat.hd1080i(frameDuration: fd)
        
        #expect(format1 == format2)
        #expect(format1 != format3) // Different color space
        #expect(format1 != format4) // Different interlaced
    }
    
    @Test("Timeline format helpers on timeline")
    func timelineFormatHelpersOnTimeline() {
        let timeline = Timeline(name: "Test")
        let _notMatch8 = !(timeline.isHD)
        #expect(_notMatch8)
        let _notMatch9 = !(timeline.isUHD)
        #expect(_notMatch9)
        #expect(timeline.aspectRatio == 0)
        
        let fd = CMTime(value: 1001, timescale: 24000)
        let format = TimelineFormat.hd1080p(frameDuration: fd)
        let timelineWithFormat = Timeline(name: "Test", format: format)
        
        #expect(timelineWithFormat.isHD)
        let _notMatch10 = !(timelineWithFormat.isUHD)
        #expect(_notMatch10)
        #expect(abs((timelineWithFormat.aspectRatio) - (1920.0 / 1080.0)) < 0.001)
    }

    /// Barebone empty timeline creation at different sizes and frame rates (no export); asserts model properties only.
    @Test("Empty timeline creation at different sizes and frame rates")
    func emptyTimelineCreationAtDifferentSizesAndFrameRates() throws {
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
            #expect(timeline.name == name, "\(name): name")
            #expect(timeline.clips.isEmpty, "\(name): empty clips")
            #expect(CMTimeCompare(timeline.duration, .zero) == 0, "\(name): duration zero")
            #expect(timeline.sortedClips.count == 0, "\(name): sortedClips empty")
            let f = try #require(timeline.format, "\(name): format non-nil")
            #expect(f.width == config.width, "\(name): width")
            #expect(f.height == config.height, "\(name): height")
            #expect(f.frameDuration.timescale == config.timescale, "\(name): frame timescale")
            #expect(f.frameDuration.value == 1, "\(name): frame value")
            #expect(abs((timeline.aspectRatio) - (Double(config.width) / Double(config.height))) < 0.001, "\(name): aspectRatio")
        }
    }

    // MARK: - FCPXMLExporter

    @Test("FCPXML exporter export minimal")
    func fcpxmlExporterExportMinimal() throws {
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
        #expect(xml.contains("<fcpxml"))
        #expect(xml.contains("resources"))
        #expect(xml.contains("r1"))
        #expect(xml.contains("r2"))
        #expect(xml.contains("asset-clip"))
        #expect(xml.contains("ref=\"r2\""))
    }

    @Test("FCPXML exporter missing asset throws")
    func fcpxmlExporterMissingAssetThrows() {
        let clip = TimelineClip(assetRef: "r99", offset: .zero, duration: CMTime(value: 1, timescale: 1), lane: 0)
        let timeline = Timeline(name: "T", clips: [clip])
        let exporter = FCPXMLExporter(version: .default)
        do {
            _ = try exporter.export(timeline: timeline, assets: [])
            Issue.record("Expected missingAsset")
        } catch FCPXMLExportError.missingAsset(let id) {
            #expect(id == "r99")
        } catch {
            Issue.record("Expected missingAsset, got \(error)")
        }
    }

    @Test("FCPXML exporter empty timeline succeeds")
    func fcpxmlExporterEmptyTimelineSucceeds() throws {
        let timeline = Timeline(name: "Empty", clips: [])
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [])
        #expect(xml.contains("<fcpxml"))
        #expect(xml.contains("<spine/>") || xml.contains("</spine>"))
        #expect(xml.contains("uid="))
        #expect(xml.contains("modDate="))
        #expect(xml.contains("duration=\"0s\""))
    }

    @Test("FCPXML exporter empty timeline with custom UIDs and location")
    func fcpxmlExporterEmptyTimelineWithCustomUIDsAndLocation() throws {
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
        #expect(xml.contains("uid=\"\(eventUid)\""))
        #expect(xml.contains("uid=\"\(projectUid)\""))
        #expect(xml.contains("location=\"file:///Users/user/Movies/Sample%20Projects.fcpbundle/\""))
    }

    // MARK: - FCPXMLExporter clip-level metadata (PR #14)

    @Test("FCPXML exporter exports clip markers")
    func fcpxmlExporterExportsClipMarkers() throws {
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
        #expect(xml.contains("<marker "))
        #expect(xml.contains("value=\"My Marker\""))
        #expect(xml.contains("note=\"A note\""))
        #expect(xml.contains("completed=\"1\""))
    }

    @Test("FCPXML exporter exports clip chapter markers")
    func fcpxmlExporterExportsClipChapterMarkers() throws {
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
        #expect(xml.contains("<chapter-marker "))
        #expect(xml.contains("value=\"Chapter 1\""))
        #expect(xml.contains("posterOffset="))
        #expect(xml.contains("note=\"Chapter note\""))
    }

    @Test("FCPXML exporter exports clip keywords")
    func fcpxmlExporterExportsClipKeywords() throws {
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
        #expect(xml.contains("<keyword "))
        #expect(xml.contains("value=\"B-Roll\""))
        #expect(xml.contains("note=\"Keyword note\""))
    }

    @Test("FCPXML exporter exports clip ratings")
    func fcpxmlExporterExportsClipRatings() throws {
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
        #expect(xml.contains("<rating "))
        #expect(xml.contains("value=\"favorite\""))
        #expect(xml.contains("note=\"Fav note\""))
    }

    @Test("FCPXML exporter exports clip metadata")
    func fcpxmlExporterExportsClipMetadata() throws {
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
        #expect(xml.contains("<metadata>") || xml.contains("<metadata "))
        #expect(xml.contains("<md ") || xml.contains("<md "))
        #expect(xml.contains("key=") && xml.contains("value="))
    }

    /// Export one clip with all clip-level metadata types; parse and validate against DTD (asset-clip children per FCPXML DTD).
    @Test("FCPXML exporter clip metadata all types validates against DTD")
    func fcpxmlExporterClipMetadataAllTypesValidatesAgainstDTD() throws {
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
        #expect(xmlString.contains("<marker "))
        #expect(xmlString.contains("<chapter-marker "))
        #expect(xmlString.contains("<keyword "))
        #expect(xmlString.contains("<rating "))
        #expect(xmlString.contains("<metadata>") || xmlString.contains("<metadata "))
        let data = try #require(xmlString.data(using: .utf8), "FCPXML string encoding failed")
        let service = FCPXMLService(logger: NoOpServiceLogger())
        let document = try service.parseFCPXML(from: data)
        let result = service.validateDocumentAgainstDTD(document, version: .v1_13)
        #expect(result.isValid, "Export with clip metadata must validate against DTD: \(result.detailedDescription)")
    }

    /// XML declaration must use standalone="no" (or omit) so xmllint --dtdvalid does not warn about whitespace.
    @Test("FCPXML exporter XML declaration standalone no")
    func fcpxmlExporterXmlDeclarationStandaloneNo() throws {
        let timeline = Timeline(name: "Empty", clips: [])
        let exporter = FCPXMLExporter(version: .default)
        let xml = try exporter.export(timeline: timeline, assets: [])
        let _notMatch11 = !(xml.contains("standalone=\"yes\""))
        #expect(_notMatch11, "Exported FCPXML must not declare standalone=\"yes\" for DTD validation")
        #expect(xml.contains("standalone=\"no\"") || (xml.hasPrefix("<?xml") && !xml.contains("standalone=")), "Exported FCPXML should declare standalone=\"no\" or omit standalone for xmllint compatibility")
    }

    /// Covers the export path used by CLI --create-project: empty timeline, custom format, default smart collections, DTD validation.
    @Test("Project creation style export validates against DTD")
    func projectCreationStyleExportValidatesAgainstDTD() throws {
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
        #expect(xmlString.contains("<!DOCTYPE fcpxml>"))
        #expect(xmlString.contains("colorSpace="))
        #expect(xmlString.contains("smart-collection"))
        #expect(xmlString.contains("match-clip"))
        #expect(xmlString.contains("match-media"))
        #expect(xmlString.contains("match-ratings"))
        let data = try #require(xmlString.data(using: .utf8), "FCPXML string encoding failed")
        let service = FCPXMLService(logger: NoOpServiceLogger())
        let document = try service.parseFCPXML(from: data)
        let result = service.validateDocumentAgainstDTD(document, version: .v1_13)
        #expect(result.isValid, "Project-creation style export must validate against DTD: \(result.detailedDescription)")
    }

    /// Project creation (empty timeline export) at multiple sizes and frame rates; each export parses and validates against DTD.
    @Test("Project creation at different sizes and frame rates")
    func projectCreationAtDifferentSizesAndFrameRates() throws {
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
        let service = FCPXMLService(logger: NoOpServiceLogger())
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
            #expect(xmlString.contains("width=\"\(config.width)\""), "\(name): width in output")
            #expect(xmlString.contains("height=\"\(config.height)\""), "\(name): height in output")
            let data = try #require(xmlString.data(using: .utf8), "\(name): FCPXML string encoding failed")
            let document = try service.parseFCPXML(from: data)
            let result = service.validateDocumentAgainstDTD(document, version: .v1_13)
            #expect(result.isValid, "\(name): export must validate against DTD: \(result.detailedDescription)")
        }
    }

    @Test("FCPXML UID random and is valid")
    func fcpxmlUIDRandomAndIsValid() {
        let uid = FCPXMLUID.random()
        #expect(FCPXMLUID.isValid(uid))
        #expect(uid.count == 36)
        #expect(uid.contains("-"))
        let _notMatch12 = !(FCPXMLUID.isValid("short"))
        #expect(_notMatch12)
        let _notMatch13 = !(FCPXMLUID.isValid("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"))
        #expect(_notMatch13)
        #expect(FCPXMLUID.isValid("D71600AB-2F01-4850-8DBD-E9F0594BD004"))
    }

    // MARK: - FCPXMLBundleExporter

    @Test("FCPXML bundle exporter creates bundle")
    func fcpxmlBundleExporterCreatesBundle() throws {
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
        #expect(FileManager.default.fileExists(atPath: bundleURL.path))
        #expect(bundleURL.lastPathComponent == "Out.fcpxmld")
        let infoFcpxml = bundleURL.appendingPathComponent("Info.fcpxml")
        let infoPlist = bundleURL.appendingPathComponent("Info.plist")
        #expect(FileManager.default.fileExists(atPath: infoFcpxml.path))
        #expect(FileManager.default.fileExists(atPath: infoPlist.path))
        let xmlData = try Data(contentsOf: infoFcpxml)
        let xml = String(data: xmlData, encoding: .utf8)
        #expect(xml != nil)
        #expect(xml?.contains("<fcpxml") == true)
    }

    @Test("FCPXML bundle exporter with media copies files")
    func fcpxmlBundleExporterWithMediaCopiesFiles() throws {
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
        #expect(FileManager.default.fileExists(atPath: mediaDir.path))
        let mediaContents = try FileManager.default.contentsOfDirectory(atPath: mediaDir.path)
        #expect(mediaContents.count == 1)
        #expect(mediaContents[0].hasSuffix(".mov") || mediaContents[0] == "sample.mov")
        let xmlData = try Data(contentsOf: bundleURL.appendingPathComponent("Info.fcpxml"))
        let xml = String(data: xmlData, encoding: .utf8)!
        #expect(xml.contains("<fcpxml"))
        // Exporter uses relativePath "Media/filename" when includeMedia is true
        #expect(xml.contains("Media/") || xml.contains("src="), "FCPXML should reference media")
    }

    // MARK: - FCPXMLValidator (semantic)

    @Test("FCPXML validator success with valid structure")
    func fcpxmlValidatorSuccessWithValidStructure() {
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
        #expect(result.isValid)
    }

    @Test("FCPXML validator missing root")
    func fcpxmlValidatorMissingRoot() {
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(FoundationXMLFactory().makeElement(name: "notfcpxml"))
        let validator = FCPXMLValidator()
        let result = validator.validate(doc)
        let _notMatch14 = !(result.isValid)
        #expect(_notMatch14)
        #expect(result.errors.contains { $0.message.contains("fcpxml") })
    }

    @Test("FCPXML validator unresolved ref")
    func fcpxmlValidatorUnresolvedRef() {
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
        let _notMatch15 = !(result.isValid)
        #expect(_notMatch15)
        #expect(result.errors.contains { $0.type == .missingAssetReference })
    }

    // MARK: - FCPXMLDTDValidator

    @Test("FCPXML DTD validator returns result")
    func fcpxmlDTDValidatorReturnsResult() {
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .default)
        let validator = FCPXMLDTDValidator()
        let result = validator.validate(doc, version: .default)
        // A well-formed document with resources + events should validate against the DTD.
        #expect(result.isValid, "Expected valid FCPXML, got errors: \(result.errors.map(\.message))")
    }

    // MARK: - FCPXMLService DTD validation (per-version)

    @Test("Validate document against DTD each supported version")
    func validateDocumentAgainstDTDEachSupportedVersion() {
        let service = FCPXMLService()
        // 1.5 DTD requires (import-options?, resources?, library); the convenience init produces (resources?, events); use 1.6–1.14.
        let versionsToTest = FCPXMLVersion.allCases.filter { $0 != .v1_5 }
        for version in versionsToTest {
            let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: version)
            let result = service.validateDocumentAgainstDTD(doc, version: version)
            #expect(result.isValid, "Version \(version.rawValue) should validate against its own DTD. Errors: \(result.detailedDescription)")
        }
        // Version 1.5 DTD requires (import-options?, resources?, library). Build minimal valid doc.
        let doc1_5 = FoundationXMLFactory().makeDocument() as! FoundationXMLDocument
        doc1_5.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
        doc1_5.fcpxmlVersion = "1.5"
        doc1_5.rootElement()?.addChild(FoundationXMLFactory().makeElement(name: "resources"))
        doc1_5.rootElement()?.addChild(FoundationXMLFactory().makeElement(name: "library"))
        let result1_5 = service.validateDocumentAgainstDTD(doc1_5, version: .v1_5)
        #expect(result1_5.isValid, "Version 1.5 with library should validate. Errors: \(result1_5.detailedDescription)")
    }

    @Test("Validate document against declared version valid document")
    func validateDocumentAgainstDeclaredVersionValidDocument() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_10)
        let result = service.validateDocumentAgainstDeclaredVersion(doc)
        #expect(result.isValid, "Declared version 1.10 should validate. Errors: \(result.detailedDescription)")
    }

    @Test("Validate document against declared version missing version")
    func validateDocumentAgainstDeclaredVersionMissingVersion() {
        let service = FCPXMLService()
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
        // No version attribute
        let result = service.validateDocumentAgainstDeclaredVersion(doc)
        let _notMatch16 = !(result.isValid)
        #expect(_notMatch16)
        #expect(result.errors.contains { $0.message.contains("no FCPXML version") })
    }

    @Test("Validate document against declared version unsupported version")
    func validateDocumentAgainstDeclaredVersionUnsupportedVersion() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_14)
        doc.fcpxmlVersion = "99.99"
        let result = service.validateDocumentAgainstDeclaredVersion(doc)
        let _notMatch17 = !(result.isValid)
        #expect(_notMatch17)
        #expect(result.errors.contains { $0.message.contains("Unsupported") || $0.message.contains("99.99") })
    }

    // MARK: - performValidation (semantic + DTD)

    @Test("Perform validation valid document")
    func performValidationValidDocument() {
        let service = FCPXMLService()
        let doc = FoundationXMLDocument(resources: [], events: [], fcpxmlVersion: .v1_10)
        // Ensure resources element exists (semantic validator requires it)
        if doc.fcpxmlElement?.firstChildElement(named: "resources") == nil {
            let resourcesEl = FoundationXMLFactory().makeElement(name: "resources")
            doc.fcpxmlElement?.addChild(resourcesEl)
        }
        let report = service.performValidation(doc)
        #expect(report.isValid, "Valid document should pass full validation. \(report.summary)")
        #expect(report.semantic.isValid)
        #expect(report.dtd.isValid)
    }

    @Test("Perform validation invalid semantic")
    func performValidationInvalidSemantic() {
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
        let _notMatch18 = !(report.isValid)
        #expect(_notMatch18)
        let _notMatch19 = !(report.semantic.isValid)
        #expect(_notMatch19, "Semantic validation should fail for unresolved ref")
        #expect(report.semantic.errors.contains { $0.message.contains("missing-resource") || $0.message.contains("Reference") })
    }

    @Test("Perform validation invalid DTD")
    func performValidationInvalidDTD() {
        let service = FCPXMLService()
        let doc = FoundationXMLFactory().makeDocument()
        doc.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
        // No version attribute -> DTD validation fails
        let report = service.performValidation(doc)
        let _notMatch20 = !(report.isValid)
        #expect(_notMatch20)
        let _isFalse1 = !(report.semantic.isValid)
        #expect(_isFalse1) // also missing resources
        let _notMatch21 = !(report.dtd.isValid)
        #expect(_notMatch21)
    }

    // MARK: - FCPXMLFileLoader (.fcpxml / .fcpxmld file I/O)

    @Test("FCPXML file loader loads single file")
    func fcpxmlFileLoaderLoadsSingleFile() throws {
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
        #expect(doc.rootElement() != nil)
        #expect(doc.rootElement()?.name == "fcpxml")
    }

    @Test("FCPXML file loader loads bundle")
    func fcpxmlFileLoaderLoadsBundle() throws {
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
        #expect(resolved.lastPathComponent == "Info.fcpxml")
        let doc = try loader.loadDocument(from: bundleURL)
        #expect(doc.rootElement() != nil)
    }

    @Test("FCPXML file loader throws for missing URL")
    func fcpxmlFileLoaderThrowsForMissingURL() {
        let url = URL(fileURLWithPath: "/nonexistent/path.fcpxml")
        let loader = FCPXMLFileLoader()
        do {
            _ = try loader.loadDocument(from: url)
            Issue.record("Expected FCPXMLLoadError")
        } catch is FCPXMLLoadError {
            // expected
        } catch {
            Issue.record("Expected FCPXMLLoadError, got \(error)")
        }
    }
}

