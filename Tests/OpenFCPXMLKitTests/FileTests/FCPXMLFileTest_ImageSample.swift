//
//  FCPXMLFileTest_ImageSample.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: ImageSample.fcpxml — still image asset with video element.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_ImageSample: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "ImageSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
    }

    func testStillImageAsset() throws {
        let fcpxml = try loadFCPXMLSample(named: "ImageSample")
        let resources = fcpxml.root.resources
        let assets = resources.childElements.filter { $0.name == "asset" }
        XCTAssertFalse(assets.isEmpty, "Expected asset resource")
        
        guard let assetElement = assets.first else {
            XCTFail("No asset element found")
            return
        }
        
        let asset = try XCTUnwrap(assetElement.fcpAsAsset)
        // Still images have duration="0s" which should parse as zero seconds
        if let duration = asset.duration {
            XCTAssertEqual(duration.doubleValue, 0.0, accuracy: 0.001, "Still image should have 0 duration")
        } else {
            XCTFail("Asset should have duration attribute")
        }
        XCTAssertTrue(asset.hasVideo, "Still image should have video")
        XCTAssertFalse(asset.hasAudio, "Still image should not have audio")
    }

    func testVideoElementReferencesStill() throws {
        let fcpxml = try loadFCPXMLSample(named: "ImageSample")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        XCTAssertFalse(storyElements.isEmpty, "Expected story elements in spine")
        
        guard let videoElement = storyElements.first(where: { $0.name == "video" }) else {
            XCTFail("No video element found")
            return
        }
        
        let ref = videoElement.stringValue(forAttributeNamed: "ref")
        XCTAssertNotNil(ref, "Video element should reference an asset")
    }

    func testLoadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "ImageSample")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("ImageSample.fcpxml not found")
        }
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        XCTAssertEqual(doc.rootElement()?.name, "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        XCTAssertEqual(parsed.rootElement()?.name, "fcpxml")
    }
}
