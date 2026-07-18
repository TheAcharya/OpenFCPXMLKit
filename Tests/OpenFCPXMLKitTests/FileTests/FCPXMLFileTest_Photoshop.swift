//
//  FCPXMLFileTest_Photoshop.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: PhotoshopSample1.fcpxml, PhotoshopSample2.fcpxml.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test photoshop")
struct FCPXMLFileTest_Photoshop {

    @Test("PhotoshopSample1")
    func photoshopSample1() throws {
        let fcpxml = try requireFCPXMLSample(named: "PhotoshopSample1")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")
    }

    @Test("PhotoshopSample2")
    func photoshopSample2() throws {
        let fcpxml = try requireFCPXMLSample(named: "PhotoshopSample2")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        for name in ["PhotoshopSample1", "PhotoshopSample2"] {
            let url = urlForFCPXMLSample(named: name)
            _ = try requireFCPXMLSampleData(named: name)
            let loader = FCPXMLFileLoader()
            let doc = try loader.loadDocument(from: url)
            #expect(doc.rootElement()?.name == "fcpxml", "\(name).fcpxml")
            let service = FCPXMLService()
            let data = try Data(contentsOf: url)
            let parsed = try service.parseFCPXML(from: data)
            #expect(parsed.rootElement()?.name == "fcpxml", "\(name).fcpxml")
        }
    }
}
