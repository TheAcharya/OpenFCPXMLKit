//
//  FCPXMLRoleInventoryClipCollectorTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for role inventory clip collection.
//

import XCTest
import SwiftTimecode
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLRoleInventoryClipCollectorTests: XCTestCase {
    private typealias Collector = FinalCutPro.FCPXML.RoleInventoryClipCollector
    
    func testRoleInventoryIncludesFullyOccludedSyncClipWithSyncSource() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let syncClipEntries = entries.filter {
            $0.extracted.displayClipName() == "5-1-9"
        }
        
        XCTAssertFalse(
            syncClipEntries.isEmpty,
            "Expected fully occluded connected sync-clips with sync-source audio to be inventoried"
        )
        
        XCTAssertTrue(
            syncClipEntries.contains {
                $0.roleSubroleField.localizedCaseInsensitiveContains("mix")
            }
        )
    }
    
    func testConnectedSyncClipUsesAnchorFieldForSyncedAudioRow() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles2")
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let connectedSyncAudio = entries.filter {
            $0.extracted.displayClipName() == "5-1-5 NK"
                && $0.category == .connectedAudio
        }
        
        XCTAssertFalse(connectedSyncAudio.isEmpty)
        
        for entry in connectedSyncAudio {
            XCTAssertTrue(entry.roleSubroleField.hasPrefix("Video,"))
        }
    }
    
    func testPrimarySyncClipUsesGroupedSyncSourceFieldForSyncedAudioRow() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithSyncSource)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let syncEntries = entries.filter { $0.extracted.displayClipName() == "Sync" }
        
        let primaryVideo = syncEntries.filter { $0.category == .primaryVideo }
        let syncedAudio = syncEntries.filter { $0.category == .primarySyncedAudio }
        let primaryAudio = syncEntries.filter { $0.category == .primaryAudio }
        
        XCTAssertEqual(primaryVideo.count, 1)
        XCTAssertEqual(primaryVideo[0].roleSubroleField, "Video")
        XCTAssertEqual(syncedAudio.count, 1)
        XCTAssertEqual(syncedAudio[0].roleSubroleField, "Dialogue ▸ Mix L, Mix R, Boom 1")
        XCTAssertEqual(primaryAudio.count, 1)
        XCTAssertTrue(primaryAudio[0].roleSubroleField.hasPrefix("Video,"))
    }
    
    func testSyncedAudioOrdersSubrolesBySrcChIncludingInactiveAndTrailingBlank() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithChannelOrderedSubroles)
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in inline fixture")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let syncedAudio = entries.filter {
            $0.extracted.displayClipName() == "Sync" && $0.category == .primarySyncedAudio
        }
        
        XCTAssertEqual(syncedAudio.count, 1)
        // Subroles follow channel `srcCh` order (not sync-source document order or alphabetical),
        // include inactive `R_` channels, and keep the trailing `<Blank>` (highest srcCh).
        XCTAssertEqual(
            syncedAudio.first?.roleSubroleField,
            "Dialogue ▸ Mix L, Mix R, Boom 1, R_Technician, R_Commander, <Blank>"
        )
    }
    
    func testSyncedAudioOmitsBlankChannelWhenNotFinalChannel() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithMiddleBlankChannel)
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in inline fixture")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let syncedAudio = entries.filter {
            $0.extracted.displayClipName() == "Sync" && $0.category == .primarySyncedAudio
        }
        
        XCTAssertEqual(syncedAudio.count, 1)
        // The `<Blank>` channel sits mid-layout (srcCh 3 of 4) and is therefore omitted.
        XCTAssertEqual(
            syncedAudio.first?.roleSubroleField,
            "Dialogue ▸ Mix L, Mix R, Boom 1"
        )
    }
    
    func testSyncedAudioWithoutSyncSourceOrdersChannelSubrolesBySrcCh() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithNestedDialogueAudio)
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in inline fixture")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let syncedAudio = entries.filter {
            $0.extracted.displayClipName() == "Nested" && $0.category == .primarySyncedAudio
        }
        
        XCTAssertEqual(syncedAudio.count, 1)
        // No sync-source is present, so both authored channels are reported in srcCh order.
        XCTAssertEqual(syncedAudio.first?.roleSubroleField, "Dialogue ▸ Mixl, Mixr")
    }
    
    func testConnectedAudioChannelSourceHostEmitsSingleChannelOrderedRow() async throws {
        let fcpxml = try parseInlineFCPXML(connectedAudioChannelSourceInsideHost)
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in inline fixture")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let connectedAudio = entries.filter {
            $0.extracted.displayClipName() == "Atmo" && $0.category == .connectedAudio
        }
        
        // A connected asset-clip that remaps its channels via audio-channel-source is a
        // standalone connected-audio host even when nested inside another host, and its
        // channels are reported as one srcCh-ordered row: disabled channels are retained,
        // the bare main-role channel (srcCh 4) is skipped, and the trailing `<Blank>`
        // channel (highest srcCh) is included.
        XCTAssertEqual(connectedAudio.count, 1)
        XCTAssertEqual(
            connectedAudio.first?.roleSubroleField,
            "Atmos ▸ Mix L, Mix R, Boom 1, <Blank>"
        )
    }
    
    func testPrimarySyncClipWithCustomVideoRoleOmitsGenericVideoPrefix() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithCustomVideoRole)
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in inline fixture")
        }
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let primaryVideo = entries.filter {
            $0.extracted.displayClipName() == "Sync"
                && $0.category == .primaryVideo
        }
        
        XCTAssertEqual(primaryVideo.count, 1)
        // When the sync-clip already carries an explicit custom video role, Final Cut Pro
        // does not prepend a redundant generic `Video` component.
        XCTAssertEqual(primaryVideo[0].roleSubroleField, "VFX ▸ VFX-Background")
    }
    
    func testPrimarySyncClipWithoutSyncSourceUsesInheritedAudioForSyncedAudioRow() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithNestedDialogueAudio)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let syncEntries = entries.filter { $0.extracted.displayClipName() == "Nested" }
        
        let primaryVideo = syncEntries.filter { $0.category == .primaryVideo }
        let syncedAudio = syncEntries.filter { $0.category == .primarySyncedAudio }
        let primaryAudio = syncEntries.filter { $0.category == .primaryAudio }
        
        XCTAssertEqual(primaryVideo.count, 1)
        XCTAssertEqual(primaryVideo[0].roleSubroleField, "Video")
        XCTAssertEqual(syncedAudio.count, 1)
        XCTAssertTrue(syncedAudio[0].roleSubroleField.localizedCaseInsensitiveContains("mix"))
        XCTAssertTrue(primaryAudio.isEmpty)
    }
    
    func testTenOneThreeCamAEmitsSingleConnectedClipRow() async throws {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ExcelReportTest/Sample.fcpxmld/Info.fcpxml")
        
        guard FileManager.default.fileExists(atPath: sampleURL.path) else {
            throw XCTSkip("Excel report sample fixture unavailable at \(sampleURL.path)")
        }
        
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(contentsOf: sampleURL))
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in Excel report sample")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let connectedClip = entries.filter {
            $0.category == .connectedClip
                && $0.extracted.displayClipName() == "10-1-3 Cam A"
        }
        
        let rows = connectedClip.compactMap {
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: $0)
        }
        
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.timelineIn, "00:04:53:01")
        XCTAssertEqual(rows.first?.timelineOut, "00:04:54:08")
        XCTAssertEqual(
            rows.first?.roleSubrole,
            "Dialogue ▸ Mix L, Mix R, Boom 1, Boom 2, R_Slate, R_Fahd"
        )
    }
    
    func testConnectedAudioMulticamFloorsFractionalTimelineEnd() async throws {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ExcelReportTest/Sample.fcpxmld/Info.fcpxml")
        
        guard FileManager.default.fileExists(atPath: sampleURL.path) else {
            throw XCTSkip("Excel report sample fixture unavailable at \(sampleURL.path)")
        }
        
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(contentsOf: sampleURL))
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in Excel report sample")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let connectedClip = entries.filter {
            $0.category == .connectedClip
                && $0.extracted.displayClipName() == "2Bpt 2of2-5-4 Cam A"
        }
        
        XCTAssertEqual(connectedClip.count, 1)
        XCTAssertTrue(connectedClip[0].usesFlooredTimelineEnd)
        XCTAssertTrue(connectedClip[0].usesAudioTimelineBounds)
        
        let row = try XCTUnwrap(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: connectedClip[0])
        )
        XCTAssertEqual(row.timelineIn, "00:01:28:20")
        XCTAssertEqual(row.timelineOut, "00:01:31:16")
        XCTAssertEqual(row.clipDuration, "00:00:02:21")
    }
    
    func testSplitEditUsesAudioTimelineBoundsForEmbeddedAudioRows() async throws {
        let fcpxml = try parseInlineFCPXML(splitEditSyncClipFixture)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let connectedAudio = entries.filter { $0.category == .connectedAudio }
        XCTAssertEqual(connectedAudio.count, 1)
        XCTAssertTrue(connectedAudio[0].usesAudioTimelineBounds)
        
        let row = try XCTUnwrap(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: connectedAudio[0])
        )
        XCTAssertEqual(row.timelineIn, "00:00:00:00")
        XCTAssertEqual(row.timelineOut, "00:00:02:00")
        XCTAssertEqual(row.clipDuration, "00:00:02:00")
        
        let connectedVideo = entries.filter { $0.category == .connectedVideo }
        XCTAssertEqual(connectedVideo.count, 1)
        XCTAssertFalse(connectedVideo[0].usesAudioTimelineBounds)
        
        let videoRow = try XCTUnwrap(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: connectedVideo[0])
        )
        XCTAssertEqual(videoRow.timelineOut, "00:00:04:00")
    }
    
    func testSampleFixtureFiveOneNineSegmentCount() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let timeline = try XCTUnwrap(fcpxml.allProjects().first).sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let fiveOneNine = entries.filter {
            $0.extracted.displayClipName() == "5-1-9"
        }
        
        let earlyStarts = fiveOneNine.compactMap { entry -> String? in
            guard let timecode = entry.extracted.value(
                forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
            ) else { return nil }
            return FinalCutPro.FCPXML.ReportFormatting.timecodeString(timecode)
        }
        .filter { $0 < "00:02:00:00" }
        
        XCTAssertGreaterThanOrEqual(
            earlyStarts.count,
            8,
            "Expected early timeline 5-1-9 segments; got \(earlyStarts.count) before 00:02:00:00 among \(fiveOneNine.count) total entries"
        )
    }
    
    func testDisabledRefClipIsExcludedFromRoleInventory() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <media id="r2" name="Nested" uid="M1">
                    <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <asset-clip ref="r3" offset="0s" name="Audio" duration="5s" format="r1"/>
                        </spine>
                    </sequence>
                </media>
                <asset id="r3" name="A" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <ref-clip ref="r2" offset="0s" name="Disabled Ref" duration="5s" enabled="0" useAudioSubroles="1">
                                    <audio-role-source role="dialogue.Boom 1"/>
                                </ref-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        XCTAssertTrue(entries.filter { $0.extracted.displayClipName() == "Disabled Ref" }.isEmpty)
    }
    
    func testNestedConnectedAssetClipIsExcludedFromRoleInventory() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="SFX" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <asset-clip ref="r2" lane="-1" offset="0s" name="Nested SFX" duration="5s" format="r1"/>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        XCTAssertTrue(entries.filter { $0.extracted.displayClipName() == "Nested SFX" }.isEmpty)
    }
    
    func testMCClipUsesInheritedAudioWhenMCSourcesLackAudioRoleSources() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="2" format="r1" videoSources="1"/>
                <media id="r3" name="1C-2-2" uid="M1">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="1C-2-2 Cam B" angleID="a1">
                            <sync-clip offset="0s" name="1C-2-2 Cam B" duration="5s" tcFormat="NDF">
                                <clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <video ref="r2" offset="0s" duration="5s" role="VFX.VFX-Main Plate"/>
                                    <audio ref="r2" offset="0s" duration="5s" role="dialogue.MixL" srcCh="1">
                                        <audio ref="r2" lane="-1" offset="0s" duration="5s" role="dialogue.MixR" srcCh="2"/>
                                    </audio>
                                </clip>
                            </sync-clip>
                        </mc-angle>
                    </multicam>
                </media>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <mc-clip ref="r3" offset="0s" name="1C-2-2" duration="5s">
                                    <mc-source angleID="a1" srcEnable="all"/>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let dialogueRows = entries.filter {
            $0.extracted.displayClipName() == "1C-2-2 Cam B"
                && $0.category == .primaryClip
                && $0.roleSubroleField.localizedCaseInsensitiveContains("mix")
        }
        
        XCTAssertEqual(dialogueRows.count, 1)
    }
    
    func testConnectedDisabledRefClipEmitsConnectedVideoWithoutAudioSplits() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <media id="r2" name="Nested" uid="M1">
                    <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <asset-clip ref="r3" offset="0s" name="Audio" duration="5s" format="r1"/>
                        </spine>
                    </sequence>
                </media>
                <asset id="r3" name="A" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <ref-clip ref="r2" lane="1" offset="0s" name="Disabled Ref" duration="5s" enabled="0" useAudioSubroles="1"/>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let refRows = entries.filter { $0.extracted.displayClipName() == "Disabled Ref" }
        XCTAssertEqual(refRows.count, 1)
        XCTAssertEqual(refRows.first?.category, .connectedVideo)
        XCTAssertEqual(refRows.first?.roleSubroleField, "Video, Dialogue")
    }
    
    func testAudioOnlyConnectedMCClipEmitsConnectedClipRoleRow() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <media id="r2" name="Angle" uid="M1">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="Cam A" angleID="a1">
                            <sync-clip offset="0s" name="Cam A" duration="5s" tcFormat="NDF">
                                <clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <video ref="r3" offset="0s" duration="5s" role="VFX.VFX-Background"/>
                                    <audio ref="r3" offset="0s" duration="5s" role="dialogue.MixL" srcCh="1"/>
                                </clip>
                            </sync-clip>
                        </mc-angle>
                    </multicam>
                </media>
                <asset id="r3" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <mc-clip ref="r2" offset="0s" name="Parent" duration="5s">
                                    <mc-source angleID="a1" srcEnable="all"/>
                                    <mc-clip ref="r2" lane="-1" offset="0s" name="5A-4-1" duration="5s" srcEnable="audio">
                                        <mc-source angleID="a1" srcEnable="audio"/>
                                    </mc-clip>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let nestedRows = entries.filter { $0.extracted.displayClipName().contains("5A-4-1") }
        XCTAssertEqual(nestedRows.count, 1)
        XCTAssertEqual(nestedRows.first?.category, .connectedClip)
        XCTAssertEqual(nestedRows.first?.roleSubroleField, "Dialogue ▸ Mixl")
    }
    
    func testNestedAudioOnlyClipIsExcludedFromRoleInventory() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="ADR" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <clip lane="-2" offset="0s" name="ADR Clip" duration="5s" format="r1">
                                        <audio ref="r2" offset="0s" duration="5s" role="dialogue" srcCh="1"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        XCTAssertTrue(entries.filter { $0.extracted.displayClipName() == "ADR Clip" }.isEmpty)
    }
    
    func testConnectedMOSClipUsesInheritedVFXVideoRole() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Plate" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <mc-clip offset="0s" name="Parent" duration="5s">
                                    <mc-source angleID="a1" srcEnable="all"/>
                                    <sync-clip lane="1" offset="0s" name="MOS Plate" duration="5s" tcFormat="NDF">
                                        <clip offset="0s" name="MOS Plate" duration="5s" format="r1">
                                            <video ref="r2" offset="0s" duration="5s" role="VFX.VFX-Background"/>
                                        </clip>
                                    </sync-clip>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let videoRows = entries.filter {
            $0.extracted.displayClipName() == "MOS Plate"
                && $0.category == .connectedVideo
        }
        
        XCTAssertEqual(videoRows.count, 1)
        XCTAssertEqual(videoRows.first?.roleSubroleField, "VFX ▸ VFX-Background")
    }
    
    func testConnectedMOSClipKeepsUserDefinedVFXElementRole() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Element" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip lane="1" offset="0s" name="VFX Element Plate" duration="5s" tcFormat="NDF">
                                    <clip offset="0s" name="VFX Element Plate" duration="5s" format="r1">
                                        <video ref="r2" offset="0s" duration="5s" role="VFX.VFX-Element"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        guard let project = fcpxml.allProjects().first else {
            throw XCTSkip("No project in inline fixture")
        }
        let timeline = project.sequence.element
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let videoRows = entries.filter {
            $0.extracted.displayClipName() == "VFX Element Plate"
                && $0.category == .connectedVideo
        }
        
        XCTAssertEqual(videoRows.count, 1)
        XCTAssertEqual(videoRows.first?.roleSubroleField, "VFX ▸ VFX-Element")
    }
    
    
    private var primarySpineAVAssetClipWithDialogueOnlyAudioRole: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Media" uid="M1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Clip" duration="5s" tcFormat="NDF" audioRole="dialogue"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var primarySyncClipWithNestedDialogueAudio: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
                <asset id="r3" name="B" uid="B1" start="0s" duration="10s" hasAudio="1" audioSources="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Nested" duration="5s" tcFormat="NDF">
                                    <asset-clip ref="r2" offset="0s" name="Video" duration="5s" format="r1">
                                        <clip offset="0s" name="Nested Audio" duration="5s" format="r1">
                                            <audio ref="r3" offset="0s" start="0s" duration="5s" role="dialogue.MixL" srcCh="1">
                                                <audio ref="r3" lane="-1" offset="0s" start="0s" duration="5s" role="dialogue.MixR" srcCh="2"/>
                                            </audio>
                                        </clip>
                                    </asset-clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var connectedAudioChannelSourceInsideHost: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <asset id="r3" name="Atmo" uid="B1" start="0s" duration="10s" hasAudio="1" audioSources="1" audioChannels="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <asset-clip ref="r2" offset="0s" name="Video" duration="5s" format="r1"/>
                                    <asset-clip ref="r3" lane="-1" offset="0s" name="Atmo" duration="5s" format="r1" audioRole="dialogue">
                                        <audio-channel-source srcCh="1" role="Atmos.Mix L"/>
                                        <audio-channel-source srcCh="2" role="Atmos.Mix R"/>
                                        <audio-channel-source srcCh="3" role="Atmos.Boom 1" enabled="0"/>
                                        <audio-channel-source srcCh="4" role="Atmos" enabled="0"/>
                                        <audio-channel-source srcCh="5" role="Atmos.&lt;Blank&gt;" enabled="0"/>
                                    </asset-clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var primarySyncClipWithSyncSource: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Sync" duration="5s" tcFormat="NDF">
                                    <asset-clip ref="r2" offset="0s" name="Video" duration="5s" format="r1"/>
                                    <sync-source sourceID="connected">
                                        <audio-role-source role="dialogue.Boom 1"/>
                                        <audio-role-source role="dialogue.MIX L"/>
                                        <audio-role-source role="dialogue.MIX R"/>
                                    </sync-source>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var primarySyncClipWithChannelOrderedSubroles: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <asset id="r3" name="B" uid="B1" start="0s" duration="10s" hasAudio="1" audioSources="7" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Sync" duration="5s" tcFormat="NDF">
                                    <clip offset="0s" name="V" duration="5s" format="r1">
                                        <video ref="r2" offset="0s" start="0s" duration="5s" role="VFX.VFX-Background"/>
                                        <clip lane="-1" offset="0s" name="A" duration="5s" format="r1">
                                            <audio ref="r3" offset="0s" start="0s" duration="5s" role="dialogue.MIX L" srcCh="1">
                                                <audio ref="r3" lane="-6" offset="0s" start="0s" duration="5s" role="dialogue.&lt;Blank&gt;" srcCh="7"/>
                                                <audio ref="r3" lane="-5" offset="0s" start="0s" duration="5s" role="dialogue" srcCh="6"/>
                                                <audio ref="r3" lane="-4" offset="0s" start="0s" duration="5s" role="dialogue.R_Commander" srcCh="5"/>
                                                <audio ref="r3" lane="-3" offset="0s" start="0s" duration="5s" role="dialogue.R_Technician" srcCh="4"/>
                                                <audio ref="r3" lane="-2" offset="0s" start="0s" duration="5s" role="dialogue.Boom 1" srcCh="3"/>
                                                <audio ref="r3" lane="-1" offset="0s" start="0s" duration="5s" role="dialogue.MIX R" srcCh="2"/>
                                            </audio>
                                        </clip>
                                    </clip>
                                    <sync-source sourceID="connected">
                                        <audio-role-source role="dialogue.Boom 1"/>
                                        <audio-role-source role="dialogue"/>
                                        <audio-role-source role="dialogue.MIX R"/>
                                        <audio-role-source role="dialogue.MIX L"/>
                                        <audio-role-source role="dialogue.R_Commander" active="0"/>
                                        <audio-role-source role="dialogue.R_Technician" active="0"/>
                                        <audio-role-source role="dialogue.&lt;Blank&gt;" active="0"/>
                                    </sync-source>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var primarySyncClipWithMiddleBlankChannel: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <asset id="r3" name="B" uid="B1" start="0s" duration="10s" hasAudio="1" audioSources="4" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Sync" duration="5s" tcFormat="NDF">
                                    <clip offset="0s" name="V" duration="5s" format="r1">
                                        <video ref="r2" offset="0s" start="0s" duration="5s" role="VFX.VFX-Background"/>
                                        <clip lane="-1" offset="0s" name="A" duration="5s" format="r1">
                                            <audio ref="r3" offset="0s" start="0s" duration="5s" role="dialogue.MIX L" srcCh="1">
                                                <audio ref="r3" lane="-3" offset="0s" start="0s" duration="5s" role="dialogue.Boom 1" srcCh="4"/>
                                                <audio ref="r3" lane="-2" offset="0s" start="0s" duration="5s" role="dialogue.&lt;Blank&gt;" srcCh="3"/>
                                                <audio ref="r3" lane="-1" offset="0s" start="0s" duration="5s" role="dialogue.MIX R" srcCh="2"/>
                                            </audio>
                                        </clip>
                                    </clip>
                                    <sync-source sourceID="connected">
                                        <audio-role-source role="dialogue.MIX L"/>
                                        <audio-role-source role="dialogue.MIX R"/>
                                        <audio-role-source role="dialogue.&lt;Blank&gt;" active="0"/>
                                        <audio-role-source role="dialogue.Boom 1"/>
                                    </sync-source>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var primarySyncClipWithCustomVideoRole: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <asset id="r3" name="B" uid="B1" start="0s" duration="10s" hasAudio="1" audioSources="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Sync" duration="5s" tcFormat="NDF">
                                    <clip offset="0s" name="V" duration="5s" format="r1">
                                        <video ref="r2" offset="0s" start="0s" duration="5s" role="VFX.VFX-Background"/>
                                        <clip lane="-1" offset="0s" name="A" duration="5s" format="r1">
                                            <audio ref="r3" offset="0s" start="0s" duration="5s" role="dialogue.MixL" srcCh="1">
                                                <audio ref="r3" lane="-1" offset="0s" start="0s" duration="5s" role="dialogue.MixR" srcCh="2"/>
                                            </audio>
                                        </clip>
                                    </clip>
                                    <sync-source sourceID="connected">
                                        <audio-role-source role="dialogue.MixL"/>
                                        <audio-role-source role="dialogue.MixR"/>
                                    </sync-source>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var splitEditSyncClipFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip lane="-1" offset="0s" name="Split" start="0s" duration="4s" audioStart="0s" audioDuration="2s" tcFormat="NDF">
                                    <asset-clip ref="r2" offset="0s" name="Video" duration="4s" format="r1"/>
                                    <sync-source sourceID="connected">
                                        <audio-role-source role="dialogue.Boom 1"/>
                                    </sync-source>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    func testPrimarySpineAVAssetClipWithDialogueOnlyRoleEmitsVideoAndAudioRows() async throws {
        let fcpxml = try parseInlineFCPXML(primarySpineAVAssetClipWithDialogueOnlyAudioRole)
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project in inline fixture")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let clipEntries = entries.filter { $0.extracted.displayClipName() == "Clip" }
        
        XCTAssertEqual(clipEntries.count, 2)
        XCTAssertTrue(clipEntries.contains { $0.category == .primaryVideo })
        XCTAssertTrue(clipEntries.contains { $0.category == .primaryAudio })
        
        let roleField = "Video, Dialogue ▸ Dialogue-1"
        XCTAssertTrue(clipEntries.allSatisfy { $0.roleSubroleField == roleField })
        
        let rows = clipEntries.compactMap {
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: $0)
        }
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].timelineIn, "00:00:00:00")
        XCTAssertEqual(rows[0].timelineOut, "00:00:05:00")
        
        let roleSheets = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.roleSheets(from: rows)
        let sheetNames = Set(roleSheets.map(\.sheetName))
        XCTAssertTrue(sheetNames.contains("Video"))
        XCTAssertTrue(sheetNames.contains("Dialogue ▸ Dialogue-1"))
        XCTAssertFalse(sheetNames.contains("Dialogue ▸ <Blank>"))
    }
    
    func testLandebahnCaptionIsInventoriedFromSampleFixture() async throws {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ExcelReportTest/Sample.fcpxmld/Info.fcpxml")
        
        guard FileManager.default.fileExists(atPath: sampleURL.path) else {
            throw XCTSkip("Excel report sample fixture unavailable")
        }
        
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(contentsOf: sampleURL))
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let landebahn = entries.filter {
            $0.category == .caption
                && $0.extracted.displayClipName().contains("Landebahn")
        }
        
        XCTAssertEqual(landebahn.count, 1)
        XCTAssertTrue(landebahn[0].usesFlooredTimelineStart)
        XCTAssertTrue(landebahn[0].usesFlooredTimelineEnd)
        
        let row = try XCTUnwrap(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: landebahn[0])
        )
        XCTAssertEqual(row.timelineIn, "00:01:13:22")
        XCTAssertEqual(row.timelineOut, "00:01:18:10")
        XCTAssertEqual(row.roleSubrole, "SRT ▸ de-DE")
    }
    
    func testCaptionTimelinePositionAlignsToComputedFrameFromSampleFixture() async throws {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ExcelReportTest/Sample.fcpxmld/Info.fcpxml")
        
        guard FileManager.default.fileExists(atPath: sampleURL.path) else {
            throw XCTSkip("Excel report sample fixture unavailable")
        }
        
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(contentsOf: sampleURL))
        guard let timeline = fcpxml.allProjects().first?.sequence.element else {
            throw XCTSkip("No project")
        }
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        
        // Caption inventory rows use the caption's computed timeline position directly.
        // These positions land on exact frame boundaries and are not shifted by an extra
        // frame, matching Final Cut Pro's own timeline placement.
        let caption = try XCTUnwrap(
            entries.first {
                $0.category == .caption
                    && $0.extracted.displayClipName() == "Erwachsener Mann. Er duckt sich."
            }
        )
        
        let row = try XCTUnwrap(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: caption)
        )
        let hasMcClipAncestor = caption.extracted.element
            .ancestorElements(includingSelf: false)
            .contains { $0.fcpElementType == .mcClip }
        XCTAssertTrue(hasMcClipAncestor, "Expected caption inside mc-clip")
        XCTAssertEqual(row.timelineIn, "00:03:10:03")
        XCTAssertEqual(row.timelineOut, "00:03:11:08")
        
        let injured = try XCTUnwrap(
            entries.first {
                $0.category == .caption
                    && $0.extracted.displayClipName() == "Ist jemand verletzt? Wir sind hier um Ihnen zu helfen."
            }
        )
        let injuredRow = try XCTUnwrap(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: injured)
        )
        XCTAssertEqual(injuredRow.timelineIn, "00:03:27:09")
        XCTAssertEqual(injuredRow.timelineOut, "00:03:29:15")
    }
}
