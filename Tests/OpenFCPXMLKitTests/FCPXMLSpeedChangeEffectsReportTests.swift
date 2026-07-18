//
//  FCPXMLSpeedChangeEffectsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Speed Change Effects report tests.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Speed change effects report")
struct FCPXMLSpeedChangeEffectsReportTests {

    @Test("Build speed change effects report from inline FCPXML")
    func buildSpeedChangeEffectsReportFromInlineFCPXML() async throws {
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
        #expect(rows.count == 1)
        #expect(rows[0].effect == "Retime -100.0%")
        #expect(rows[0].settings == "-100.0%")
        #expect(rows[0].clipName == "Clip A")
        #expect(rows[0].enabled == "")
        #expect(rows[0].isApple == "")
        FCPXMLReportingReportTestSupport.assertValidTimecode(rows[0].timelineIn)
        FCPXMLReportingReportTestSupport.assertValidTimecode(rows[0].timelineOut)
    }

    @Test("Build speed change effects report from fixture")
    func buildSpeedChangeEffectsReportFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeSpeedChangeEffects = true

        let report = try await fcpxml.buildReport(options: options)

        #expect(report.speedChangeEffects != nil)

        let rows = report.speedChangeEffects?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows {
            #expect(row.effect.hasPrefix("Retime "))
            let settingsEmpty = row.settings.isEmpty
            let clipNameEmpty = row.clipName.isEmpty
            #expect(!settingsEmpty)
            #expect(!clipNameEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }

    @Test("Speed change effects only preset enables section only")
    func speedChangeEffectsOnlyPresetEnablesSectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly

        #expect(options.includeSpeedChangeEffects)
        #expect(!options.includeEffects)
        #expect(!options.includeMarkers)
        #expect(!options.includeRoleInventory)
    }
}

