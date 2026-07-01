//
//  FCPXMLFileTest_AllSamples.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Smoke test — every available sample in FCPXML Samples parses successfully.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_AllSamples: XCTestCase {

    func testAllAvailableSamplesParseSuccessfully() throws {
        let names = allFCPXMLSampleNames()
        guard !names.isEmpty else {
            throw XCTSkip("FCPXML Samples directory not found or empty")
        }
        let loader = FCPXMLFileLoader()
        for name in names {
            let url = urlForFCPXMLSample(named: name)
            let doc = try loader.loadDocument(from: url)
            XCTAssertNotNil(doc.rootElement(), "\(name).fcpxml")
            XCTAssertEqual(doc.rootElement()?.name, "fcpxml", "\(name).fcpxml")
        }
    }

    func testAllAvailableSamplesParseAsFinalCutProFCPXML() throws {
        let names = allFCPXMLSampleNames()
        guard !names.isEmpty else {
            throw XCTSkip("FCPXML Samples directory not found or empty")
        }
        for name in names {
            let fcpxml = try loadFCPXMLSample(named: name)
            XCTAssertEqual(fcpxml.root.element.name, "fcpxml", "\(name).fcpxml")
        }
    }
}
