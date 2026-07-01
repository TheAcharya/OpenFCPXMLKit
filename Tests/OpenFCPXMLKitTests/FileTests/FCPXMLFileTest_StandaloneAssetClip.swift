//
//  FCPXMLFileTest_StandaloneAssetClip.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: StandaloneAssetClip.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_StandaloneAssetClip: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "StandaloneAssetClip")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertTrue(fcpxml.root.resources.childElements.count >= 1)
    }
}
