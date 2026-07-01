//
//  FCPXMLFileTest_BasicMarkers.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for BasicMarkers.fcpxml: marker parsing and event/project structure.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_BasicMarkers: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "BasicMarkers")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_9)
        let root = fcpxml.root.element
        XCTAssertEqual(root.xmlString, fcpxml.root.element.xmlString)
        let resources = fcpxml.root.resources
        XCTAssertGreaterThanOrEqual(resources.childElements.count, 1)
        let library = fcpxml.root.library
        XCTAssertNotNil(library)
    }

    func testAllEventsAndProjects() throws {
        let fcpxml = try loadFCPXMLSample(named: "BasicMarkers")
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty)
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty)
    }
}
