//
//  FCPXMLFileTest_SyncClip.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: SyncClip.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_SyncClip: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "SyncClip")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertFalse(fcpxml.allProjects().isEmpty)
    }
}
