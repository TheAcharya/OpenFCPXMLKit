//
//  FCPXMLFileTest_Photoshop.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: PhotoshopSample1.fcpxml, PhotoshopSample2.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_Photoshop: XCTestCase {

    func testPhotoshopSample1() throws {
        let fcpxml = try loadFCPXMLSample(named: "PhotoshopSample1")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
    }

    func testPhotoshopSample2() throws {
        let fcpxml = try loadFCPXMLSample(named: "PhotoshopSample2")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
    }

    func testLoadViaLoaderAndParseViaService() throws {
        for name in ["PhotoshopSample1", "PhotoshopSample2"] {
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
