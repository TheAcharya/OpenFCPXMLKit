//
//  FCPXMLFileTest_BasicMarkers.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for BasicMarkers.fcpxml: marker parsing and event/project structure.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test basic markers")
struct FCPXMLFileTest_BasicMarkers {

    @Test("Parse BasicMarkers sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "BasicMarkers")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_9)
        let root = fcpxml.root.element
        #expect(root.xmlString == fcpxml.root.element.xmlString)
        let resources = fcpxml.root.resources
        #expect(resources.childElements.count >= 1)
        let library = fcpxml.root.library
        #expect(library != nil)
    }

    @Test("All events and projects")
    func allEventsAndProjects() throws {
        let fcpxml = try requireFCPXMLSample(named: "BasicMarkers")
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents)
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects)
    }
}
