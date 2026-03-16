//
//  FCPXMLStructureTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Logic and Parsing: FCPXML structure (allEvents, allProjects). Uses Structure sample.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class FCPXMLStructureTests: XCTestCase {

    /// Ensure that elements that can appear in various locations in the XML hierarchy are all found.
    func testParse_Structure_AllEventsAndProjects() throws {
        let fcpxml = try loadFCPXMLSample(named: "Structure")
        let events = Set(fcpxml.allEvents().map(\.name))
        XCTAssertEqual(events, ["Test Event", "Test Event 2"])
        let projects = Set(fcpxml.allProjects().compactMap(\.name))
        XCTAssertEqual(projects, ["Test Project", "Test Project 2", "Test Project 3"])
    }

    func testParse_Structure_RootHasResourcesOrLibrary() throws {
        let fcpxml = try loadFCPXMLSample(named: "Structure")
        let root = fcpxml.root.element
        let childNames = root.childElements.map { $0.name }
        XCTAssertTrue(
            childNames.contains("resources") || childNames.contains("library"),
            "Expected resources or library, got \(childNames)"
        )
    }

    func testParse_Structure_Version() throws {
        let fcpxml = try loadFCPXMLSample(named: "Structure")
        _ = fcpxml.version
        XCTAssertTrue(fcpxml.version.major >= 1 && fcpxml.version.minor >= 5)
    }
}
