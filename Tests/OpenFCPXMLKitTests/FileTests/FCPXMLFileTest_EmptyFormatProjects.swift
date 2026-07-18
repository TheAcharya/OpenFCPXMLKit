//
//  FCPXMLFileTest_EmptyFormatProjects.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for empty FCPXML projects (zero clips) with different format dimensions (1920x1080, 4096x2160, 5120x2160, Custom500x500).
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test empty format projects")
struct FCPXMLFileTest_EmptyFormatProjects {

    private static let samples: [(name: String, width: String, height: String)] = [
        ("1920x1080", "1920", "1080"),
        ("4096x2160", "4096", "2160"),
        ("5120x2160", "5120", "2160"),
        ("Custom500x500", "500", "500"),
    ]

    @Test("Parse empty project 1920x1080")
    func parseEmptyProject_1920x1080() throws {
        try assertEmptyFormatProjectParses(sampleName: "1920x1080", expectedWidth: "1920", expectedHeight: "1080")
    }

    @Test("Parse empty project 4096x2160")
    func parseEmptyProject_4096x2160() throws {
        try assertEmptyFormatProjectParses(sampleName: "4096x2160", expectedWidth: "4096", expectedHeight: "2160")
    }

    @Test("Parse empty project 5120x2160")
    func parseEmptyProject_5120x2160() throws {
        try assertEmptyFormatProjectParses(sampleName: "5120x2160", expectedWidth: "5120", expectedHeight: "2160")
    }

    @Test("Parse empty project Custom500x500")
    func parseEmptyProject_Custom500x500() throws {
        try assertEmptyFormatProjectParses(sampleName: "Custom500x500", expectedWidth: "500", expectedHeight: "500")
    }

    @Test("Empty format projects — version and structure via FCPXML")
    func emptyFormatProjects_VersionAndStructureViaFCPXML() throws {
        for sample in Self.samples {
            let fcpxml = try requireFCPXMLSample(named: sample.name)
            #expect(fcpxml.root.element.name == "fcpxml")
            #expect(fcpxml.version == .ver1_13, "\(sample.name) should be version 1.13")
            let events = fcpxml.allEvents()
            let hasEvents = !events.isEmpty
            #expect(hasEvents, "\(sample.name): expected at least one event")
            let projects = fcpxml.allProjects()
            let hasProjects = !projects.isEmpty
            #expect(hasProjects, "\(sample.name): expected at least one project")
            let project = try #require(projects.first)
            let sequence = project.sequence
            #expect(sequence.format == "r1", "\(sample.name): sequence format should be r1")
            let spine = sequence.spine
            #expect(Array(spine.contents).count == 0, "\(sample.name): spine should be empty")
        }
    }

    private func assertEmptyFormatProjectParses(sampleName: String, expectedWidth: String, expectedHeight: String) throws {
        let url = urlForFCPXMLSample(named: sampleName)
        _ = try requireFCPXMLSampleData(named: sampleName)
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        let root = try #require(doc.rootElement(), "\(sampleName): no root element")
        #expect(root.name == "fcpxml", "\(sampleName)")
        #expect(root.attribute(forName: "version") == "1.13", "\(sampleName): version should be 1.13")

        let resources = root.firstChildElement(named: "resources")
        let formatResources = resources?.childElements.filter { $0.name == "format" } ?? []
        #expect(formatResources.count == 1, "\(sampleName): expected one format resource")
        let format = try #require(formatResources.first)
        #expect(format.attribute(forName: "id") == "r1", "\(sampleName)")
        #expect(format.attribute(forName: "width") == expectedWidth, "\(sampleName)")
        #expect(format.attribute(forName: "height") == expectedHeight, "\(sampleName)")

        let library = try #require(
            root.firstChildElement(named: "library"),
            "\(sampleName): library/event/project/sequence/spine structure missing"
        )
        let event = try #require(
            library.firstChildElement(named: "event"),
            "\(sampleName): library/event/project/sequence/spine structure missing"
        )
        let project = try #require(
            event.firstChildElement(named: "project"),
            "\(sampleName): library/event/project/sequence/spine structure missing"
        )
        let sequence = try #require(
            project.firstChildElement(named: "sequence"),
            "\(sampleName): library/event/project/sequence/spine structure missing"
        )
        let spine = try #require(
            sequence.firstChildElement(named: "spine"),
            "\(sampleName): library/event/project/sequence/spine structure missing"
        )
        #expect(event.attribute(forName: "uid") != nil, "\(sampleName): event should have uid")
        #expect(project.attribute(forName: "uid") != nil, "\(sampleName): project should have uid")
        #expect(project.attribute(forName: "modDate") != nil, "\(sampleName): project should have modDate")
        let spineChildCount = spine.childElements.count
        #expect(spineChildCount == 0, "\(sampleName): spine should have no story elements")
    }
}
