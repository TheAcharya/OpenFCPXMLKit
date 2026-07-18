//
//  FCPXMLFileTest_Complex.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Complex.fcpxml — resources, library, events, sequence. Mirrors DAW Complex.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test complex")
struct FCPXMLFileTest_Complex {

    @Test("Parse Complex sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "Complex")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_11)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents)
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects)
    }

    @Test("Root version attribute")
    func rootVersionAttribute() throws {
        let fcpxml = try requireFCPXMLSample(named: "Complex")
        let versionOK = fcpxml.version.major == 1 && fcpxml.version.minor >= 10
        #expect(versionOK)
    }

    @Test("Resources exist")
    func resourcesExist() throws {
        let fcpxml = try requireFCPXMLSample(named: "Complex")
        let resources = fcpxml.root.resources
        #expect(resources.childElements.count > 0, "Expected resource children")
    }
}
