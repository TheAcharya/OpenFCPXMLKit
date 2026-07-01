//
//  FCPXMLFileTest_24.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for 24.fcpxml: parsing and structure validation for 24fps sample.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_24: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_11)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        let project = try XCTUnwrap(projects.first)
        XCTAssertNotNil(project.sequence)
        let sequence = try XCTUnwrap(project.sequence)
        XCTAssertEqual(sequence.format, "r1")
        let spine = sequence.spine
        XCTAssertGreaterThan(Array(spine.contents).count, 0, "Expected story elements in spine")
    }

    func testLoadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "24")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("24.fcpxml not found")
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
