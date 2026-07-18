//
//  FCPXMLFileTest_FrameRates.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: All frame-rate samples (23.98, 24, 24With25Media, 25i, 29.97, 29.97d, 30, 50, 59.94, 60). Mirrors DAW one-file-per-frame-rate pattern.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test frame rates")
struct FCPXMLFileTest_FrameRates {

    @Test("Each frame rate sample parses and has valid root")
    func eachFrameRateSampleParsesAndHasValidRoot() throws {
        for name in fcpxmlFrameRateSampleNames {
            let fcpxml = try requireFCPXMLSample(named: name)
            #expect(fcpxml.root.element.name == "fcpxml", "\(name).fcpxml")
            let versionOK = fcpxml.version.major >= 1 && fcpxml.version.minor >= 5
            #expect(versionOK, "\(name).fcpxml version")
        }
    }

    @Test("Frame rate sample 24")
    func frameRateSample_24() throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        #expect(fcpxml.version == .ver1_11)
        let hasProjects = !fcpxml.allProjects().isEmpty
        #expect(hasProjects)
    }

    @Test("Frame rate sample 29.97")
    func frameRateSample_29_97() throws {
        let fcpxml = try requireFCPXMLSample(named: "29.97")
        #expect(fcpxml.root.element.name == "fcpxml")
    }

    @Test("Frame rate sample 60")
    func frameRateSample_60() throws {
        let fcpxml = try requireFCPXMLSample(named: "60")
        #expect(fcpxml.root.element.name == "fcpxml")
    }
}
