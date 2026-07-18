//
//  FCPXMLFileTest_24.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for 24.fcpxml: parsing and structure validation for 24fps sample.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test 24")
struct FCPXMLFileTest_24 {

    @Test("Parse 24 sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_11)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")
        let project = try #require(projects.first)
        let sequence = project.sequence
        #expect(sequence.format == "r1")
        let spine = sequence.spine
        #expect(Array(spine.contents).count > 0, "Expected story elements in spine")
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "24")
        _ = try requireFCPXMLSampleData(named: "24")
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        #expect(doc.rootElement()?.name == "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        #expect(parsed.rootElement()?.name == "fcpxml")
    }
}

