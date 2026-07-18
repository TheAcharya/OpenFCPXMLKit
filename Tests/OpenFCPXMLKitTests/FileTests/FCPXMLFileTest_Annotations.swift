//
//  FCPXMLFileTest_Annotations.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Annotations.fcpxml.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test annotations")
struct FCPXMLFileTest_Annotations {

    @Test("Parse Annotations sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "Annotations")
        #expect(fcpxml.root.element.name == "fcpxml")
        let hasEvents = !fcpxml.allEvents().isEmpty
        #expect(hasEvents)
        let hasProjects = !fcpxml.allProjects().isEmpty
        #expect(hasProjects)
    }
}

