//
//  FCPXMLFileTest_SyncClip.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: SyncClip.fcpxml.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test sync clip")
struct FCPXMLFileTest_SyncClip {

    @Test("Parse SyncClip sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "SyncClip")
        #expect(fcpxml.root.element.name == "fcpxml")
        let hasProjects = !fcpxml.allProjects().isEmpty
        #expect(hasProjects)
    }
}

