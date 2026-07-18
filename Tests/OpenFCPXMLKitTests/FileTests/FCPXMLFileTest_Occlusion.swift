//
//  FCPXMLFileTest_Occlusion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Occlusion.fcpxml, Occlusion2.fcpxml, Occlusion3.fcpxml.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test occlusion")
struct FCPXMLFileTest_Occlusion {

    @Test("Parse Occlusion")
    func parse_Occlusion() throws {
        let fcpxml = try requireFCPXMLSample(named: "Occlusion")
        #expect(fcpxml.root.element.name == "fcpxml")
    }

    @Test("Parse Occlusion2")
    func parse_Occlusion2() throws {
        let fcpxml = try requireFCPXMLSample(named: "Occlusion2")
        #expect(fcpxml.root.element.name == "fcpxml")
    }

    @Test("Parse Occlusion3")
    func parse_Occlusion3() throws {
        let fcpxml = try requireFCPXMLSample(named: "Occlusion3")
        #expect(fcpxml.root.element.name == "fcpxml")
    }
}

