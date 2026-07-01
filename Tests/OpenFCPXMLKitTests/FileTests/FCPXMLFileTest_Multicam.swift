//
//  FCPXMLFileTest_Multicam.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: MulticamSample.fcpxml, MulticamSampleWithCuts.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_Multicam: XCTestCase {

    func testMulticamSample() throws {
        let fcpxml = try loadFCPXMLSample(named: "MulticamSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        
        // Verify multicam resources exist
        let resources = fcpxml.root.resources
        let mediaResources = resources.childElements.filter { $0.name == "media" }
        var foundMulticam = false
        for media in mediaResources {
            if media.firstChildElement(named: "multicam") != nil {
                foundMulticam = true
                break
            }
        }
        XCTAssertTrue(foundMulticam, "Should find multicam resource")
    }

    func testMulticamSampleWithCuts() throws {
        let fcpxml = try loadFCPXMLSample(named: "MulticamSampleWithCuts")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        
        // Verify multicam clips exist in timeline
        var foundMulticamClip = false
        for element in storyElements {
            if element.name == "mc-clip" {
                foundMulticamClip = true
                break
            }
        }
        XCTAssertTrue(foundMulticamClip, "Should find multicam clips in timeline")
    }

    func testLoadViaLoaderAndParseViaService() throws {
        for name in ["MulticamSample", "MulticamSampleWithCuts"] {
            let url = urlForFCPXMLSample(named: name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw XCTSkip("\(name).fcpxml not found")
            }
            let loader = FCPXMLFileLoader()
            let doc = try loader.loadDocument(from: url)
            XCTAssertEqual(doc.rootElement()?.name, "fcpxml", "\(name).fcpxml")
            let service = FCPXMLService()
            let data = try Data(contentsOf: url)
            let parsed = try service.parseFCPXML(from: data)
            XCTAssertEqual(parsed.rootElement()?.name, "fcpxml", "\(name).fcpxml")
        }
    }
}
