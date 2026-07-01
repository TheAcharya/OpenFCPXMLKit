//
//  FCPXMLFileTest_Annotations.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Annotations.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_Annotations: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "Annotations")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertFalse(fcpxml.allEvents().isEmpty)
        XCTAssertFalse(fcpxml.allProjects().isEmpty)
    }
}
