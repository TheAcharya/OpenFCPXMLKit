//
//  FCPXMLFileTest_GeneralDemo.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: GeneralDemo.fcpxml — multicam, titles, effects, color, nested storylines.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_GeneralDemo: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "GeneralDemo")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_14)
        XCTAssertFalse(fcpxml.allEvents().isEmpty)
        XCTAssertFalse(fcpxml.allProjects().isEmpty)
    }

    func testProjectAndEventNames() throws {
        let fcpxml = try loadFCPXMLSample(named: "GeneralDemo")
        let events = fcpxml.allEvents()
        XCTAssertTrue(events.contains { $0.name == "General Demo" })
        let projects = fcpxml.allProjects()
        XCTAssertTrue(projects.contains { $0.name == "General Demo" })
    }

    func testMulticamResourcesAndClips() throws {
        let fcpxml = try loadFCPXMLSample(named: "GeneralDemo")
        let mediaResources = fcpxml.root.resources.childElements.filter { $0.name == "media" }
        XCTAssertTrue(
            mediaResources.contains { $0.firstChildElement(named: "multicam") != nil },
            "Expected at least one multicam media resource"
        )

        guard let project = fcpxml.allProjects().first else {
            XCTFail("No project found")
            return
        }
        let spine = try XCTUnwrap(project.sequence.spine)
        let storyElements = Array(spine.storyElements)
        XCTAssertTrue(
            storyElements.contains { $0.name == "mc-clip" },
            "Expected multicam clips on the primary spine"
        )
    }

    func testTitlesAndEffectsPresent() throws {
        let fcpxml = try loadFCPXMLSample(named: "GeneralDemo")
        XCTAssertNotNil(
            firstDescendantElement(in: fcpxml.root.element, named: "title"),
            "Expected title elements in timeline"
        )
        XCTAssertNotNil(
            firstDescendantElement(in: fcpxml.root.element, named: "filter-video"),
            "Expected video filter effects"
        )
    }

    func testMediaPathsAreAnonymized() throws {
        let data = try loadFCPXMLSampleData(named: "GeneralDemo")
        let xml = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(xml.contains("Ancestral"), "Sample should not contain original volume names")
        XCTAssertFalse(xml.contains("Allie"), "Sample should not contain identifying names")
        XCTAssertFalse(xml.contains("<bookmark>"), "Sample should not contain macOS bookmarks with embedded paths")
        XCTAssertTrue(
            xml.contains("file:///Users/user/Movies/GeneralDemo/Media/"),
            "Expected anonymized media paths"
        )
    }

    func testLoadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "GeneralDemo")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("GeneralDemo.fcpxml not found")
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
