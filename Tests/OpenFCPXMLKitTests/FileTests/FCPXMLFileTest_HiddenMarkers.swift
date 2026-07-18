//
//  FCPXMLFileTest_HiddenMarkers.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File tests for HiddenMarkers.fcpxml: markers outside host media range.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_HiddenMarkers: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.hiddenMarkers.rawValue)
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_14)
        XCTAssertFalse(fcpxml.allProjects().isEmpty)
    }
}
