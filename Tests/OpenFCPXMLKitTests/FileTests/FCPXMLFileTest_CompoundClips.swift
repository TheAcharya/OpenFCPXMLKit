//
//  FCPXMLFileTest_CompoundClips.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: CompoundClips.fcpxml, CompoundClipSample.fcpxml.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test compound clips")
struct FCPXMLFileTest_CompoundClips {

    @Test("Parse CompoundClips sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClips")
        #expect(fcpxml.root.element.name == "fcpxml")
        let hasProjects = !fcpxml.allProjects().isEmpty
        #expect(hasProjects)
    }

    @Test("CompoundClipSample")
    func compoundClipSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClipSample")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")

        let resources = fcpxml.root.resources
        let mediaResources = resources.childElements.filter { $0.name == "media" }
        let hasMediaResources = !mediaResources.isEmpty
        #expect(hasMediaResources, "Expected media resources for compound clips")
    }
}
