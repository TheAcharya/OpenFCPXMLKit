//
//  FCPXMLFileTest_Multicam.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: MulticamSample.fcpxml, MulticamSampleWithCuts.fcpxml.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test multicam")
struct FCPXMLFileTest_Multicam {

    @Test("MulticamSample")
    func multicamSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "MulticamSample")
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
        var foundMulticam = false
        for media in mediaResources {
            if media.firstChildElement(named: "multicam") != nil {
                foundMulticam = true
                break
            }
        }
        #expect(foundMulticam, "Should find multicam resource")
    }

    @Test("MulticamSampleWithCuts")
    func multicamSampleWithCuts() throws {
        let fcpxml = try requireFCPXMLSample(named: "MulticamSampleWithCuts")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")

        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)

        var foundMulticamClip = false
        for element in storyElements {
            if element.name == "mc-clip" {
                foundMulticamClip = true
                break
            }
        }
        #expect(foundMulticamClip, "Should find multicam clips in timeline")
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        for name in ["MulticamSample", "MulticamSampleWithCuts"] {
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

