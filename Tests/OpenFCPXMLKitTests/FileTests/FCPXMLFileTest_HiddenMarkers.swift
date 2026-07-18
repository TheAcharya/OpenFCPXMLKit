//
//  FCPXMLFileTest_HiddenMarkers.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for HiddenMarkers.fcpxml: markers outside host media range.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test hidden markers")
struct FCPXMLFileTest_HiddenMarkers {

    @Test("Parse HiddenMarkers sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.hiddenMarkers.rawValue)
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_14)
        let hasProjects = !fcpxml.allProjects().isEmpty
        #expect(hasProjects)
    }
}
