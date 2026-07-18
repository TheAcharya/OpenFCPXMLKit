//
//  FCPXMLFileTest_GeneralDemo.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: GeneralDemo.fcpxml — multicam, titles, effects, color, nested storylines.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test general demo")
struct FCPXMLFileTest_GeneralDemo {

    @Test("Parse GeneralDemo sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "GeneralDemo")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_14)
        let hasEvents = !fcpxml.allEvents().isEmpty
        #expect(hasEvents)
        let hasProjects = !fcpxml.allProjects().isEmpty
        #expect(hasProjects)
    }

    @Test("Project and event names")
    func projectAndEventNames() throws {
        let fcpxml = try requireFCPXMLSample(named: "GeneralDemo")
        let events = fcpxml.allEvents()
        let hasGeneralDemoEvent = events.contains { $0.name == "General Demo" }
        #expect(hasGeneralDemoEvent)
        let projects = fcpxml.allProjects()
        let hasGeneralDemoProject = projects.contains { $0.name == "General Demo" }
        #expect(hasGeneralDemoProject)
    }

    @Test("Multicam resources and clips")
    func multicamResourcesAndClips() throws {
        let fcpxml = try requireFCPXMLSample(named: "GeneralDemo")
        let mediaResources = fcpxml.root.resources.childElements.filter { $0.name == "media" }
        let hasMulticamResource = mediaResources.contains { $0.firstChildElement(named: "multicam") != nil }
        #expect(hasMulticamResource, "Expected at least one multicam media resource")

        let project = try #require(fcpxml.allProjects().first, "No project found")
        let spine = project.sequence.spine
        let storyElements = Array(spine.storyElements)
        let hasMCClip = storyElements.contains { $0.name == "mc-clip" }
        #expect(hasMCClip, "Expected multicam clips on the primary spine")
    }

    @Test("Titles and effects present")
    func titlesAndEffectsPresent() throws {
        let fcpxml = try requireFCPXMLSample(named: "GeneralDemo")
        #expect(
            firstDescendantElement(in: fcpxml.root.element, named: "title") != nil,
            "Expected title elements in timeline"
        )
        #expect(
            firstDescendantElement(in: fcpxml.root.element, named: "filter-video") != nil,
            "Expected video filter effects"
        )
    }

    @Test("Media paths are anonymized")
    func mediaPathsAreAnonymized() throws {
        let data = try requireFCPXMLSampleData(named: "GeneralDemo")
        let xml = String(decoding: data, as: UTF8.self)
        let hasAncestral = xml.contains("Ancestral")
        #expect(!hasAncestral, "Sample should not contain original volume names")
        let hasAllie = xml.contains("Allie")
        #expect(!hasAllie, "Sample should not contain identifying names")
        let hasBookmark = xml.contains("<bookmark>")
        #expect(!hasBookmark, "Sample should not contain macOS bookmarks with embedded paths")
        let hasAnonymizedPath = xml.contains("file:///Users/user/Movies/GeneralDemo/Media/")
        #expect(hasAnonymizedPath, "Expected anonymized media paths")
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "GeneralDemo")
        _ = try requireFCPXMLSampleData(named: "GeneralDemo")
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        #expect(doc.rootElement()?.name == "fcpxml")

        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        #expect(parsed.rootElement()?.name == "fcpxml")
    }
}
