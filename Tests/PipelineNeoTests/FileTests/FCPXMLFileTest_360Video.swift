//
//  FCPXMLFileTest_360Video.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: 360Video.fcpxml — 360 video with projection, stereoscopic, adjust-colorConform, bookmarks, smart collections.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class FCPXMLFileTest_360Video: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
    }

    func testFormatProjectionAndStereoscopic() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let resources = fcpxml.root.resources
        let formats = resources.childElements.filter { $0.name == "format" }
        XCTAssertFalse(formats.isEmpty, "Expected format resource")
        
        guard let formatElement = formats.first else {
            XCTFail("No format element found")
            return
        }
        
        let format = try XCTUnwrap(formatElement.fcpAsFormat)
        XCTAssertEqual(format.projection, "equirectangular", "Format should have equirectangular projection")
        XCTAssertEqual(format.stereoscopic, "mono", "Format should have mono stereoscopic")
        XCTAssertEqual(format.width, 4096)
        XCTAssertEqual(format.height, 2048)
    }

    func testAdjustColorConform() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        XCTAssertFalse(storyElements.isEmpty, "Expected story elements in spine")
        
        // Find the clip element (not transition or gap)
        guard let clipElement = storyElements.first(where: { $0.name == "clip" }) else {
            XCTFail("No clip element found")
            return
        }
        
        let clip = try XCTUnwrap(clipElement.fcpAsClip)
        let colorConform = clip.colorConformAdjustment
        XCTAssertNotNil(colorConform, "Clip should have colorConform adjustment")
        
        if let colorConform = colorConform {
            XCTAssertTrue(colorConform.isEnabled, "ColorConform should be enabled")
            XCTAssertEqual(colorConform.autoOrManual, .manual, "ColorConform should be manual")
            XCTAssertEqual(colorConform.conformType, .conformNone, "ColorConform type should be conformNone")
            XCTAssertEqual(colorConform.peakNitsOfPQSource, "1000")
            XCTAssertEqual(colorConform.peakNitsOfSDRToPQSource, "203")
        }
    }

    func testMediaRepBookmark() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let resources = fcpxml.root.resources
        let assets = resources.childElements.filter { $0.name == "asset" }
        XCTAssertFalse(assets.isEmpty, "Expected asset resource")
        
        guard let assetElement = assets.first else {
            XCTFail("No asset element found")
            return
        }
        
        let mediaReps = assetElement.childElements.filter { $0.name == "media-rep" }
        XCTAssertFalse(mediaReps.isEmpty, "Expected media-rep element")
        
        guard let mediaRepElement = mediaReps.first else {
            XCTFail("No media-rep element found")
            return
        }
        
        let mediaRep = try XCTUnwrap(mediaRepElement.fcpAsMediaRep)
        let bookmark = mediaRep.bookmark
        XCTAssertNotNil(bookmark, "MediaRep should have bookmark element")
        
        if let bookmark = bookmark {
            let bookmarkData = bookmark.stringValue
            XCTAssertNotNil(bookmarkData, "Bookmark should have string value")
            XCTAssertFalse(bookmarkData?.isEmpty ?? true, "Bookmark should not be empty")
        }
    }

    func testSmartCollections() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        XCTAssertGreaterThan(smartCollections.count, 0, "Expected smart collections")
        
        for collectionElement in smartCollections {
            let collection = try XCTUnwrap(collectionElement.fcpAsSmartCollection)
            XCTAssertNotNil(collection.name, "Smart collection should have name")
            XCTAssertNotNil(collection.match, "Smart collection should have match attribute")
        }
    }

    func testLoadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "360Video")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("360Video.fcpxml not found")
        }
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        XCTAssertEqual(doc.rootElement()?.name, "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        XCTAssertEqual(parsed.rootElement()?.name, "fcpxml")
    }

    func testRoundTrip() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let xmlString = fcpxml.root.element.xmlString
        XCTAssertFalse(xmlString.isEmpty)
        
        // Parse it back
        guard let xmlData = xmlString.data(using: .utf8) else {
            XCTFail("Failed to convert XML string to data")
            return
        }
        let reloaded = try FinalCutPro.FCPXML(fileContent: xmlData)
        XCTAssertEqual(reloaded.version, .ver1_13)
        
        // Verify format attributes are preserved
        let resources = reloaded.root.resources
        let formats = resources.childElements.filter { $0.name == "format" }
        guard let formatElement = formats.first,
              let format = formatElement.fcpAsFormat else {
            XCTFail("Format not found after round trip")
            return
        }
        XCTAssertEqual(format.projection, "equirectangular")
        XCTAssertEqual(format.stereoscopic, "mono")
    }
}
