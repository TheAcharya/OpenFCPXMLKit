//
//  FCPXMLFileTest_CompoundClips.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: CompoundClips.fcpxml, CompoundClipSample.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_CompoundClips: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "CompoundClips")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertFalse(fcpxml.allProjects().isEmpty)
    }

    func testCompoundClipSample() throws {
        let fcpxml = try loadFCPXMLSample(named: "CompoundClipSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        
        // Verify compound clip resources exist
        let resources = fcpxml.root.resources
        let mediaResources = resources.childElements.filter { $0.name == "media" }
        XCTAssertFalse(mediaResources.isEmpty, "Expected media resources for compound clips")
    }
}
