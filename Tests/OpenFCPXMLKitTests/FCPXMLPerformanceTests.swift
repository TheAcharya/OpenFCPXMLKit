//
//  FCPXMLPerformanceTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Performance tests for timecode conversion, document creation, and filtering.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLPerformanceTests: XCTestCase {

    func testPerformanceParseFCPXMLDataRepeatedly() throws {
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
        let data = xml.data(using: .utf8)!
        let service = FCPXMLService()
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<50 {
                _ = try? service.parseFCPXML(from: data)
            }
        }
    }

    func testPerformanceLoadSampleFileWhenAvailable() throws {
        let url = urlForFCPXMLSample(named: "Structure")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Structure.fcpxml not found")
        }
        let loader = FCPXMLFileLoader()
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<20 {
                _ = try? loader.loadDocument(from: url)
            }
        }
    }

    func testPerformanceProjectComplexSampleWhenAvailable() throws {
        let fcpxml: FinalCutPro.FCPXML
        do {
            fcpxml = try loadFCPXMLSample(named: "Complex")
        } catch {
            throw XCTSkip("Complex.fcpxml not found")
        }
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let projector = FinalCutPro.FCPXML.TimelineProjector()
        // Warm once so measure focuses on steady-state projection cost.
        try projector.projectSync(from: source, fcpxml: fcpxml, options: .init()) { _ in }
        measure(metrics: [XCTClockMetric()]) {
            try? projector.projectSync(from: source, fcpxml: fcpxml, options: .init()) { _ in }
        }
    }
}
