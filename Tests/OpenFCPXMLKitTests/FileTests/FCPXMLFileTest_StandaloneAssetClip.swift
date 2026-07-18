//
//  FCPXMLFileTest_StandaloneAssetClip.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: StandaloneAssetClip.fcpxml.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test standalone asset clip")
struct FCPXMLFileTest_StandaloneAssetClip {

    @Test("Parse StandaloneAssetClip sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "StandaloneAssetClip")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.root.resources.childElements.count >= 1)
    }
}

