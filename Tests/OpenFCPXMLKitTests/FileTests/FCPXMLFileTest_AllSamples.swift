//
//  FCPXMLFileTest_AllSamples.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Smoke test — every available sample in FCPXML Samples parses successfully.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test all samples")
struct FCPXMLFileTest_AllSamples {

    @Test("All available samples parse successfully")
    func allAvailableSamplesParseSuccessfully() throws {
        let names = allFCPXMLSampleNames()
        guard !names.isEmpty else {
            try Test.cancel("FCPXML Samples directory not found or empty")
        }
        let loader = FCPXMLFileLoader()
        for name in names {
            let url = urlForFCPXMLSample(named: name)
            let doc = try loader.loadDocument(from: url)
            #expect(doc.rootElement() != nil, "\(name).fcpxml")
            #expect(doc.rootElement()?.name == "fcpxml", "\(name).fcpxml")
        }
    }

    @Test("All available samples parse as FinalCutPro.FCPXML")
    func allAvailableSamplesParseAsFinalCutProFCPXML() throws {
        let names = allFCPXMLSampleNames()
        guard !names.isEmpty else {
            try Test.cancel("FCPXML Samples directory not found or empty")
        }
        for name in names {
            let fcpxml = try requireFCPXMLSample(named: name)
            #expect(fcpxml.root.element.name == "fcpxml", "\(name).fcpxml")
        }
    }
}
