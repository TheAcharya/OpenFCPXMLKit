//
//  FCPXMLFileTest_FrameRates.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: All frame-rate samples (23.98, 24, 24With25Media, 25i, 29.97, 29.97d, 30, 50, 59.94, 60). Mirrors DAW one-file-per-frame-rate pattern.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_FrameRates: XCTestCase {

    func testEachFrameRateSampleParsesAndHasValidRoot() throws {
        for name in fcpxmlFrameRateSampleNames {
            let url = urlForFCPXMLSample(named: name)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let data = try Data(contentsOf: url)
            let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
            XCTAssertEqual(fcpxml.root.element.name, "fcpxml", "\(name).fcpxml")
            XCTAssertTrue(fcpxml.version.major >= 1 && fcpxml.version.minor >= 5, "\(name).fcpxml version")
        }
    }

    func testFrameRateSample_24() throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        XCTAssertEqual(fcpxml.version, .ver1_11)
        XCTAssertFalse(fcpxml.allProjects().isEmpty)
    }

    func testFrameRateSample_29_97() throws {
        let fcpxml = try loadFCPXMLSample(named: "29.97")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
    }

    func testFrameRateSample_60() throws {
        let fcpxml = try loadFCPXMLSample(named: "60")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
    }
}
