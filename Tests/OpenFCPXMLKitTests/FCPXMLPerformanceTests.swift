//
//  FCPXMLPerformanceTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Performance smoke tests for parsing, file loading, and timeline projection.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Performance")
struct FCPXMLPerformanceTests {

    /// Sanity bound so pathological hangs fail CI; not a regression baseline.
    private let parseBudget: Duration = .seconds(30)
    private let loadBudget: Duration = .seconds(30)
    private let projectBudget: Duration = .seconds(60)

    @Test("Parse FCPXML data repeatedly")
    func parseFCPXMLDataRepeatedly() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.14">
        <resources>
            <format id="r1" name="FFVideoFormat1080p24" frameDuration="1001/24000s" width="1920" height="1080"/>
            <asset id="r2" name="Clip1" start="0s" duration="1001/24s" hasVideo="1" hasAudio="1"/>
        </resources>
        <library location="file:///">
            <event name="Event1">
                <project name="Project1">
                    <sequence format="r1" duration="1001/24s" tcStart="0s">
                        <spine>
                            <asset-clip ref="r2" offset="0s" duration="1001/24s"/>
                        </spine>
                    </sequence>
                </project>
            </event>
        </library>
        </fcpxml>
        """
        let data = try #require(xml.data(using: .utf8))
        let service = FCPXMLService()
        let elapsed = ContinuousClock().measure {
            for _ in 0..<50 {
                _ = try? service.parseFCPXML(from: data)
            }
        }
        #expect(elapsed < parseBudget)
    }

    @Test("Load sample file when available")
    func loadSampleFileWhenAvailable() throws {
        try cancelIfSampleMissing(named: "Structure")
        let url = urlForFCPXMLSample(named: "Structure")
        let loader = FCPXMLFileLoader()
        let elapsed = ContinuousClock().measure {
            for _ in 0..<20 {
                _ = try? loader.loadDocument(from: url)
            }
        }
        #expect(elapsed < loadBudget)
    }

    @Test("Project complex sample when available")
    func projectComplexSampleWhenAvailable() throws {
        let fcpxml = try requireFCPXMLSample(named: "Complex")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let projector = FinalCutPro.FCPXML.TimelineProjector()
        // Warm once so the timed run focuses on steady-state projection cost.
        try projector.projectSync(from: source, fcpxml: fcpxml, options: .init()) { _ in }
        let elapsed = ContinuousClock().measure {
            try? projector.projectSync(from: source, fcpxml: fcpxml, options: .init()) { _ in }
        }
        #expect(elapsed < projectBudget)
    }
}

