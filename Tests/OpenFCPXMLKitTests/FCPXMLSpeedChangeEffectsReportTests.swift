//
//  FCPXMLSpeedChangeEffectsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Speed Change Effects report tests.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLSpeedChangeEffectsReportTests: XCTestCase, @unchecked Sendable {
    
    func testBuildSpeedChangeEffectsReportFromInlineFCPXML() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Clip A" duration="10s">
                                    <timeMap>
                                        <timept time="158445100/2500s" value="158591200/2500s" interp="smooth2"/>
                                        <timept time="158591200/2500s" value="158445100/2500s" interp="smooth2"/>
                                    </timeMap>
                                    <video ref="r1" offset="0s" duration="10s"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let report = try await fcpxml.buildReport(
            options: FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly
        )
        
        let rows = report.speedChangeEffects?.rows ?? []
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].effect, "Retime -100.0%")
        XCTAssertEqual(rows[0].settings, "-100.0%")
        XCTAssertEqual(rows[0].clipName, "Clip A")
        XCTAssertEqual(rows[0].enabled, "")
        XCTAssertEqual(rows[0].isApple, "")
        FCPXMLReportingReportTestSupport.assertValidTimecode(rows[0].timelineIn)
        FCPXMLReportingReportTestSupport.assertValidTimecode(rows[0].timelineOut)
    }
    
    func testBuildSpeedChangeEffectsReportFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeSpeedChangeEffects = true
            }
        )
        
        XCTAssertNotNil(report.speedChangeEffects)
        
        let rows = report.speedChangeEffects?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows {
            XCTAssertTrue(row.effect.hasPrefix("Retime "))
            XCTAssertFalse(row.settings.isEmpty)
            XCTAssertFalse(row.clipName.isEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }
    
    func testSpeedChangeEffectsOnlyPresetEnablesSectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly
        
        XCTAssertTrue(options.includeSpeedChangeEffects)
        XCTAssertFalse(options.includeEffects)
        XCTAssertFalse(options.includeMarkers)
        XCTAssertFalse(options.includeRoleInventory)
    }
}
