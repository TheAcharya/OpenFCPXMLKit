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

    @Test("Speed Change merges Extraction optical-flow clip when Projection omits it")
    func speedChangeMergesExtractionOpticalFlowClipWhenProjectionOmitsIt() async throws {
        // Spine <clip> with optical-flow timeMap + nested <video> timeMap + connected title.
        // Projection often omits these wrapper retimes; Extraction must still surface them.
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Shot" uid="A1" start="486193664/12288s" duration="408576/12288s" hasVideo="1" format="r1" videoSources="1"/>
                <effect id="r3" name="Basic Title" uid=".../Titles.localized/Basic Title.localized/Basic Title.moti"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="20s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Plain Speed" duration="5s" format="r1">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="smooth2"/>
                                        <timept time="10s" value="5s" interp="smooth2"/>
                                    </timeMap>
                                </asset-clip>
                                <clip offset="5s" name="Optical Host" start="486193664/12288s" duration="408576/12288s" format="r1" tcFormat="NDF">
                                    <timeMap frameSampling="optical-flow">
                                        <timept time="972387328/12288s" value="486193664/12288s" interp="smooth2"/>
                                        <timept time="973204480/12288s" value="486602240/12288s" interp="smooth2"/>
                                    </timeMap>
                                    <video ref="r2" offset="486193664/12288s" start="486193664/12288s" duration="408576/12288s">
                                        <timeMap frameSampling="optical-flow">
                                            <timept time="972387328/12288s" value="486193664/12288s" interp="smooth2"/>
                                            <timept time="973204480/12288s" value="486602240/12288s" interp="smooth2"/>
                                        </timeMap>
                                    </video>
                                    <title ref="r3" lane="1" offset="486193664/12288s" name="Tag" start="3600s" duration="1s" role="VFX Shot No.VFX Shot No-1">
                                        <text><text-style ref="ts1">V</text-style></text>
                                        <text-style-def id="ts1"><text-style font="Helvetica"/></text-style-def>
                                    </title>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.includeRoleInventory = true
        options.includeSpeedChangeEffects = true
        let report = try await fcpxml.buildReport(options: options)

        let speedRows = try #require(report.speedChangeEffects?.rows)
        #expect(speedRows.contains { $0.clipName == "Plain Speed" })
        #expect(
            speedRows.contains { $0.clipName == "Optical Host" },
            "Optical-flow spine clip wrappers must appear on Speed Change even when Projection omits them"
        )
        #expect(
            speedRows.filter { $0.clipName == "Optical Host" }.count == 1,
            "Nested video timeMap must not duplicate the host clip row"
        )

        let inventory = try #require(report.roleInventory?.selectedRoles)
        #expect(inventory.contains { $0.clipName == "Optical Host" && $0.roleSubrole == "Video" })
        #expect(inventory.contains {
            $0.clipName == "Basic Title" && $0.roleSubrole == "Vfx Shot No ▸ Vfx Shot No-1"
        })
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

