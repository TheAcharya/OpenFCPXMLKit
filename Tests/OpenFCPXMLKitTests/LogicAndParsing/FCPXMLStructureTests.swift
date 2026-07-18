//
//  FCPXMLStructureTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Logic and Parsing: FCPXML structure (allEvents, allProjects). Uses Structure sample.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("FCPXML structure")
struct FCPXMLStructureTests {

    /// Ensure that elements that can appear in various locations in the XML hierarchy are all found.
    @Test("Parse Structure sample — all events and projects")
    func parse_Structure_AllEventsAndProjects() throws {
        let fcpxml = try requireFCPXMLSample(named: "Structure")
        let events = Set(fcpxml.allEvents().map(\.name))
        #expect(events == ["Test Event", "Test Event 2"])
        let projects = Set(fcpxml.allProjects().compactMap(\.name))
        #expect(projects == ["Test Project", "Test Project 2", "Test Project 3"])
    }

    @Test("Parse Structure sample — root has resources or library")
    func parse_Structure_RootHasResourcesOrLibrary() throws {
        let fcpxml = try requireFCPXMLSample(named: "Structure")
        let root = fcpxml.root.element
        let childNames = root.childElements.map { $0.name }
        #expect(
            childNames.contains("resources") || childNames.contains("library"),
            "Expected resources or library, got \(childNames)"
        )
    }

    @Test("Parse Structure sample — version")
    func parse_Structure_Version() throws {
        let fcpxml = try requireFCPXMLSample(named: "Structure")
        _ = fcpxml.version
        #expect(fcpxml.version.major >= 1 && fcpxml.version.minor >= 5)
    }
}
