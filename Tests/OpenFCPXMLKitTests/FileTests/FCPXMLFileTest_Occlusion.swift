//
//  FCPXMLFileTest_Occlusion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Occlusion.fcpxml, Occlusion2.fcpxml, Occlusion3.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_Occlusion: XCTestCase {

    func testParse_Occlusion() throws {
        let fcpxml = try loadFCPXMLSample(named: "Occlusion")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
    }

    func testParse_Occlusion2() throws {
        let fcpxml = try loadFCPXMLSample(named: "Occlusion2")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
    }

    func testParse_Occlusion3() throws {
        let fcpxml = try loadFCPXMLSample(named: "Occlusion3")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
    }
}
