//
//  FCPXMLFileTest_EmptyFormatProjects.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	File tests for empty FCPXML projects (zero clips) with different format dimensions (1920x1080, 4096x2160, 5120x2160, Custom500x500).
//

import Foundation
import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class FCPXMLFileTest_EmptyFormatProjects: XCTestCase {

    private static let samples: [(name: String, width: String, height: String)] = [
        ("1920x1080", "1920", "1080"),
        ("4096x2160", "4096", "2160"),
        ("5120x2160", "5120", "2160"),
        ("Custom500x500", "500", "500"),
    ]

    func testParseEmptyProject_1920x1080() throws {
        try _assertEmptyFormatProjectParses(sampleName: "1920x1080", expectedWidth: "1920", expectedHeight: "1080")
    }

    func testParseEmptyProject_4096x2160() throws {
        try _assertEmptyFormatProjectParses(sampleName: "4096x2160", expectedWidth: "4096", expectedHeight: "2160")
    }

    func testParseEmptyProject_5120x2160() throws {
        try _assertEmptyFormatProjectParses(sampleName: "5120x2160", expectedWidth: "5120", expectedHeight: "2160")
    }

    func testParseEmptyProject_Custom500x500() throws {
        try _assertEmptyFormatProjectParses(sampleName: "Custom500x500", expectedWidth: "500", expectedHeight: "500")
    }

    func testEmptyFormatProjects_VersionAndStructureViaFCPXML() throws {
        for sample in Self.samples {
            let url = urlForFCPXMLSample(named: sample.name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw XCTSkip("\(sample.name).fcpxml not found")
            }
            let fcpxml = try loadFCPXMLSample(named: sample.name)
            XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
            XCTAssertEqual(fcpxml.version, .ver1_13, "\(sample.name) should be version 1.13")
            let events = fcpxml.allEvents()
            XCTAssertFalse(events.isEmpty, "\(sample.name): expected at least one event")
            let projects = fcpxml.allProjects()
            XCTAssertFalse(projects.isEmpty, "\(sample.name): expected at least one project")
            let project = try XCTUnwrap(projects.first)
            let sequence = try XCTUnwrap(project.sequence)
            XCTAssertEqual(sequence.format, "r1", "\(sample.name): sequence format should be r1")
            let spine = sequence.spine
            XCTAssertEqual(Array(spine.contents).count, 0, "\(sample.name): spine should be empty")
        }
    }

    private func _assertEmptyFormatProjectParses(sampleName: String, expectedWidth: String, expectedHeight: String) throws {
        let url = urlForFCPXMLSample(named: sampleName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("\(sampleName).fcpxml not found")
        }
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        guard let root = doc.rootElement() else {
            XCTFail("\(sampleName): no root element")
            return
        }
        XCTAssertEqual(root.name, "fcpxml", "\(sampleName)")
        XCTAssertEqual(root.attribute(forName: "version"), "1.13", "\(sampleName): version should be 1.13")

        // Find format resources in the resources element
        let resources = root.firstChildElement(named: "resources")
        let formatResources = resources?.childElements.filter { $0.name == "format" } ?? []
        XCTAssertEqual(formatResources.count, 1, "\(sampleName): expected one format resource")
        let format = try XCTUnwrap(formatResources.first)
        XCTAssertEqual(format.attribute(forName: "id"), "r1", "\(sampleName)")
        XCTAssertEqual(format.attribute(forName: "width"), expectedWidth, "\(sampleName)")
        XCTAssertEqual(format.attribute(forName: "height"), expectedHeight, "\(sampleName)")

        guard let library = root.firstChildElement(named: "library"),
              let event = library.firstChildElement(named: "event"),
              let project = event.firstChildElement(named: "project"),
              let sequence = project.firstChildElement(named: "sequence"),
              let spine = sequence.firstChildElement(named: "spine") else {
            XCTFail("\(sampleName): library/event/project/sequence/spine structure missing")
            return
        }
        XCTAssertNotNil(event.attribute(forName: "uid"), "\(sampleName): event should have uid")
        XCTAssertNotNil(project.attribute(forName: "uid"), "\(sampleName): project should have uid")
        XCTAssertNotNil(project.attribute(forName: "modDate"), "\(sampleName): project should have modDate")
        let spineChildCount = spine.childElements.count
        XCTAssertEqual(spineChildCount, 0, "\(sampleName): spine should have no story elements")
    }
}
