//
//  FCPXMLSpeedChangeEffectsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Speed Change Effects report tests.
//

import Testing
import SwiftTimecode
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
        #expect(rows[0].effect == "Retime")
        #expect(rows[0].settings == "-100.0%")
        #expect(rows[0].clipName == "Clip A")
        #expect(rows[0].enabled == "")
        #expect(rows[0].isApple == "")
        FCPXMLReportingReportTestSupport.assertValidTimecode(rows[0].timelineIn)
        FCPXMLReportingReportTestSupport.assertValidTimecode(rows[0].timelineOut)
    }

    @Test("Retimed inventory rows report the source they actually consume")
    func retimedInventoryRowsReportConsumedSource() async throws {
        // 212 timeline frames at 50% consume 106 source frames: 00:00:08:20 of timeline
        // against 00:00:04:10 of source. The unretimed control must stay equal.
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="1/24s" width="1920" height="1080"/>
                <asset id="r2" name="HalfShot" uid="EEEE5555" start="0s" duration="2400/24s" hasVideo="1" format="r1" videoSources="1">
                    <media-rep kind="original-media" sig="EEEE5555" src="file:///tmp/HalfShot.mov"/>
                </asset>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="424/24s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0/24s" name="HalfShot" start="0/24s" duration="212/24s" format="r1" tcFormat="NDF">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="linear"/>
                                        <timept time="212/24s" value="106/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
                                <asset-clip ref="r2" offset="212/24s" name="NormalShot" start="600/24s" duration="212/24s" format="r1" tcFormat="NDF"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let report = try await fcpxml.buildReport(
            options: FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        )
        let rows = report.roleInventory?.selectedRoles ?? []

        let retimed = try #require(rows.first { $0.clipName == "HalfShot" })
        #expect(retimed.clipDuration == "00:00:08:20")
        #expect(
            retimed.sourceDuration == "00:00:04:10",
            "A 50% clip consumes half its timeline duration of source"
        )
        #expect(retimed.sourceOut == "00:00:04:09")

        let normal = try #require(rows.first { $0.clipName == "NormalShot" })
        #expect(normal.sourceDuration == normal.clipDuration)
    }

    @Test("Aggregated speed counts freeze segments as occupied timeline")
    func aggregatedSpeedCountsFreezeSegments() throws {
        // 1s at 200% followed by a 1s freeze: 2s of media across 2s of timeline is 100%,
        // so the freeze must not be dropped from the denominator.
        let motion = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(0, 1),
            timelineEnd: Fraction(1, 1),
            mediaStart: Fraction(0, 1),
            mediaEnd: Fraction(2, 1),
            scale: 2
        )
        let freeze = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(1, 1),
            timelineEnd: Fraction(2, 1),
            mediaStart: Fraction(2, 1),
            mediaEnd: Fraction(2, 1),
            scale: 0
        )

        let display = try #require(
            FinalCutPro.FCPXML.SpeedChangeFormatting.retimeDisplay(
                aggregating: [motion, freeze]
            )
        )
        #expect(display.settings == "100.0%")
    }

    @Test("Aggregated speed uses absolute media across a direction change")
    func aggregatedSpeedUsesAbsoluteMediaAcrossDirectionChange() throws {
        // Forward then back over the same media: the net media span is zero, so only
        // absolute per-segment spans give a meaningful speed.
        let forward = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(0, 1),
            timelineEnd: Fraction(1, 1),
            mediaStart: Fraction(0, 1),
            mediaEnd: Fraction(2, 1),
            scale: 2
        )
        let backward = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(1, 1),
            timelineEnd: Fraction(2, 1),
            mediaStart: Fraction(2, 1),
            mediaEnd: Fraction(0, 1),
            scale: 2,
            isReversed: true
        )

        let display = try #require(
            FinalCutPro.FCPXML.SpeedChangeFormatting.retimeDisplay(
                aggregating: [forward, backward]
            )
        )
        #expect(display.settings == "200.0%")
    }

    @Test("Each retimed use of one source gets its own speed change row")
    func repeatedUsesOfOneSourceEachGetTheirOwnRow() async throws {
        // Three separate retimes of the same asset, butt-cut so they are timeline-adjacent
        // and share a clip name: only the media discontinuity distinguishes the usages.
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="1/24s" width="1920" height="1080"/>
                <asset id="r2" name="ShotA" uid="AAAA1111" start="0s" duration="2400/24s" hasVideo="1" format="r1" videoSources="1">
                    <media-rep kind="original-media" sig="AAAA1111" src="file:///tmp/ShotA.mov"/>
                </asset>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="360/24s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0/24s" name="ShotA" start="0/24s" duration="120/24s" format="r1" tcFormat="NDF">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="linear"/>
                                        <timept time="120/24s" value="240/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
                                <asset-clip ref="r2" offset="120/24s" name="ShotA" start="480/24s" duration="120/24s" format="r1" tcFormat="NDF">
                                    <timeMap>
                                        <timept time="480/24s" value="480/24s" interp="linear"/>
                                        <timept time="600/24s" value="840/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
                                <asset-clip ref="r2" offset="240/24s" name="ShotA" start="1200/24s" duration="120/24s" format="r1" tcFormat="NDF">
                                    <timeMap>
                                        <timept time="1200/24s" value="1200/24s" interp="linear"/>
                                        <timept time="1320/24s" value="1800/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
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
        #expect(
            rows.count == 3,
            "Reusing one source must not collapse its retimes into a single row"
        )
        #expect(rows.allSatisfy { $0.clipName == "ShotA" })

        // Each usage reports its own speed rather than one blended figure.
        #expect(Set(rows.map(\.settings)).count == 3)
        #expect(rows.map(\.settings).contains("200.0%"))

        // Each usage reports its own timeline position rather than the first one's.
        #expect(Set(rows.map(\.timelineIn)).count == 3)
        for row in rows {
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }

    @Test("Retimed clips report a role even when the host omits the attribute")
    func retimedClipsReportRoleWhenHostOmitsAttribute() async throws {
        // Exports routinely omit videoRole / audioRole, and the inventory still files those
        // clips under FCP's implicit default. Speed Change must agree instead of blanking,
        // otherwise --exclude-role can never reach the row.
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="1/24s" width="1920" height="1080"/>
                <asset id="r2" name="NoRoleShot" uid="AAAA1111" start="0s" duration="2400/24s" hasVideo="1" format="r1" videoSources="1">
                    <media-rep kind="original-media" sig="AAAA1111" src="file:///tmp/NoRoleShot.mov"/>
                </asset>
                <asset id="r3" name="CustomRoleShot" uid="BBBB2222" start="0s" duration="2400/24s" hasVideo="1" format="r1" videoSources="1">
                    <media-rep kind="original-media" sig="BBBB2222" src="file:///tmp/CustomRoleShot.mov"/>
                </asset>
                <asset id="r4" name="MusicBed" uid="CCCC3333" start="0s" duration="2400/24s" hasAudio="1" audioSources="1" audioChannels="2" audioRate="48000">
                    <media-rep kind="original-media" sig="CCCC3333" src="file:///tmp/MusicBed.wav"/>
                </asset>
                <asset id="r5" name="NoRoleAudio" uid="DDDD4444" start="0s" duration="2400/24s" hasAudio="1" audioSources="1" audioChannels="2" audioRate="48000">
                    <media-rep kind="original-media" sig="DDDD4444" src="file:///tmp/NoRoleAudio.wav"/>
                </asset>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="480/24s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0/24s" name="NoRoleShot" start="0/24s" duration="120/24s" format="r1" tcFormat="NDF">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="linear"/>
                                        <timept time="120/24s" value="240/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
                                <asset-clip ref="r3" offset="120/24s" name="CustomRoleShot" start="0/24s" duration="120/24s" format="r1" tcFormat="NDF" videoRole="Vfx Shot No.Vfx Shot No-1">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="linear"/>
                                        <timept time="120/24s" value="240/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
                                <asset-clip ref="r4" lane="-1" offset="240/24s" name="MusicBed" start="0/24s" duration="120/24s" audioRole="Music.Music-1">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="linear"/>
                                        <timept time="120/24s" value="240/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
                                <asset-clip ref="r5" lane="-2" offset="360/24s" name="NoRoleAudio" start="0/24s" duration="120/24s">
                                    <timeMap>
                                        <timept time="0s" value="0s" interp="linear"/>
                                        <timept time="120/24s" value="240/24s" interp="linear"/>
                                    </timeMap>
                                </asset-clip>
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

        #expect(rows.allSatisfy { !$0.roleSubrole.isEmpty })

        let roleByClip = Dictionary(
            rows.map { ($0.clipName, $0.roleSubrole) },
            uniquingKeysWith: { first, _ in first }
        )
        #expect(roleByClip["NoRoleShot"] == "Video")
        #expect(roleByClip["CustomRoleShot"] == "Vfx Shot No")
        #expect(roleByClip["MusicBed"] == "Music")
        #expect(
            roleByClip["NoRoleAudio"] == "Dialogue",
            "Audio-only retimes take FCP's audio default, not the video one"
        )
    }

    @Test("Excluding a role drops retimes whose host omits the role attribute")
    func excludingRoleDropsRetimesWithDefaultedRole() {
        let section = FinalCutPro.FCPXML.SpeedChangeEffectsReportSection(
            rows: [
                FinalCutPro.FCPXML.EffectReportRow(
                    effect: "Retime",
                    settings: "200.0%",
                    enabled: "",
                    isApple: "",
                    clipName: "NoRoleShot",
                    roleSubrole: "Video",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:04:23"
                ),
                FinalCutPro.FCPXML.EffectReportRow(
                    effect: "Retime",
                    settings: "200.0%",
                    enabled: "",
                    isApple: "",
                    clipName: "MusicBed",
                    roleSubrole: "Music",
                    timelineIn: "00:00:10:00",
                    timelineOut: "00:00:14:23"
                )
            ]
        )

        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["Video"],
            to: section
        )
        #expect(filtered.rows.map(\.clipName) == ["MusicBed"])
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
        let optical = try #require(speedRows.first { $0.clipName == "Optical Host" })
        #expect(optical.effect == "Optical Flow Retime")
        #expect(optical.settings == "50.0%")
        let plain = try #require(speedRows.first { $0.clipName == "Plain Speed" })
        #expect(plain.effect == "Retime")

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
            #expect(row.effect.hasSuffix("Retime"))
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

