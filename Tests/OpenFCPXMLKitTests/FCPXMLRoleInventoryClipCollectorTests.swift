//
//  FCPXMLRoleInventoryClipCollectorTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for role inventory clip collection.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory clip collector")
struct FCPXMLRoleInventoryClipCollectorTests {
    private typealias Collector = FinalCutPro.FCPXML.RoleInventoryClipCollector

    private func requireExcelReportSampleFCPXML() throws -> FinalCutPro.FCPXML {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ExcelReportTest/Sample.fcpxmld/Info.fcpxml")

        guard FileManager.default.fileExists(atPath: sampleURL.path) else {
            try Test.cancel("Excel report sample fixture unavailable at \(sampleURL.path)")
        }

        return try FinalCutPro.FCPXML(fileContent: Data(contentsOf: sampleURL))
    }

    @Test("Role inventory includes fully occluded sync-clip with sync-source")
    func roleInventoryIncludesFullyOccludedSyncClipWithSyncSource() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let syncClipEntries = entries.filter {
            $0.extracted.displayClipName() == "5-1-9"
        }

        let syncClipEntriesEmpty = syncClipEntries.isEmpty
        #expect(
            !syncClipEntriesEmpty,
            "Expected fully occluded connected sync-clips with sync-source audio to be inventoried"
        )

        let hasMixRole = syncClipEntries.contains {
            $0.roleSubroleField.localizedCaseInsensitiveContains("mix")
        }
        #expect(hasMixRole)
    }
    

    @Test("Connected sync-clip uses anchor field for synced audio row")
    func connectedSyncClipUsesAnchorFieldForSyncedAudioRow() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles2")
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let connectedSyncAudio = entries.filter {
            $0.extracted.displayClipName() == "5-1-5 NK"
                && $0.category == .connectedAudio
        }
        
        let connectedSyncAudioEmpty = connectedSyncAudio.isEmpty
        #expect(!connectedSyncAudioEmpty)
        
        for entry in connectedSyncAudio {
            #expect(entry.roleSubroleField.hasPrefix("Video,"))
        }
    }
    

    @Test("Primary sync-clip uses grouped sync-source field for synced audio row")
    func primarySyncClipUsesGroupedSyncSourceFieldForSyncedAudioRow() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithSyncSource)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let syncEntries = entries.filter { $0.extracted.displayClipName() == "Sync" }
        
        let primaryVideo = syncEntries.filter { $0.category == .primaryVideo }
        let syncedAudio = syncEntries.filter { $0.category == .primarySyncedAudio }
        let primaryAudio = syncEntries.filter { $0.category == .primaryAudio }
        
        #expect(primaryVideo.count == 1)
        #expect(primaryVideo[0].roleSubroleField == "Video")
        #expect(syncedAudio.count == 1)
        #expect(syncedAudio[0].roleSubroleField == "Dialogue ▸ Mix L, Mix R, Boom 1")
        #expect(primaryAudio.count == 1)
        #expect(primaryAudio[0].roleSubroleField.hasPrefix("Video,"))
    }
    

    @Test("Synced audio orders subroles by srcCh including inactive and trailing Blank")
    func syncedAudioOrdersSubrolesBySrcChIncludingInactiveAndTrailingBlank() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithChannelOrderedSubroles)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let syncedAudio = entries.filter {
            $0.extracted.displayClipName() == "Sync" && $0.category == .primarySyncedAudio
        }
        
        #expect(syncedAudio.count == 1)
        // Subroles follow channel `srcCh` order (not sync-source document order or alphabetical),
        // include inactive `R_` channels, and keep the trailing `<Blank>` (highest srcCh).
        #expect(syncedAudio.first?.roleSubroleField == "Dialogue ▸ Mix L, Mix R, Boom 1, R_Technician, R_Commander, <Blank>")
    }
    

    @Test("Synced audio omits Blank channel when not final channel")
    func syncedAudioOmitsBlankChannelWhenNotFinalChannel() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithMiddleBlankChannel)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let syncedAudio = entries.filter {
            $0.extracted.displayClipName() == "Sync" && $0.category == .primarySyncedAudio
        }
        
        #expect(syncedAudio.count == 1)
        // The `<Blank>` channel sits mid-layout (srcCh 3 of 4) and is therefore omitted.
        #expect(syncedAudio.first?.roleSubroleField == "Dialogue ▸ Mix L, Mix R, Boom 1")
    }
    

    @Test("Synced audio without sync-source orders channel subroles by srcCh")
    func syncedAudioWithoutSyncSourceOrdersChannelSubrolesBySrcCh() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithNestedDialogueAudio)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let syncedAudio = entries.filter {
            $0.extracted.displayClipName() == "Nested" && $0.category == .primarySyncedAudio
        }
        
        #expect(syncedAudio.count == 1)
        // No sync-source is present, so both authored channels are reported in srcCh order.
        #expect(syncedAudio.first?.roleSubroleField == "Dialogue ▸ Mixl, Mixr")
    }
    

    @Test("Connected audio channel-source host emits single channel-ordered row")
    func connectedAudioChannelSourceHostEmitsSingleChannelOrderedRow() async throws {
        let fcpxml = try parseInlineFCPXML(connectedAudioChannelSourceInsideHost)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let connectedAudio = entries.filter {
            $0.extracted.displayClipName() == "Atmosphere" && $0.category == .connectedAudio
        }
        
        // A connected asset-clip that remaps its channels via audio-channel-source is a
        // standalone connected-audio host even when nested inside another host, and its
        // channels are reported as one srcCh-ordered row: disabled channels are retained,
        // the bare main-role channel (srcCh 4) is skipped, and the trailing `<Blank>`
        // channel (highest srcCh) is included.
        #expect(connectedAudio.count == 1)
        #expect(connectedAudio.first?.roleSubroleField == "Atmosphere ▸ Mix L, Mix R, Boom 1, <Blank>")
    }
    

    @Test("Primary sync-clip with custom video role omits generic Video prefix")
    func primarySyncClipWithCustomVideoRoleOmitsGenericVideoPrefix() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithCustomVideoRole)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let primaryVideo = entries.filter {
            $0.extracted.displayClipName() == "Sync"
                && $0.category == .primaryVideo
        }
        
        #expect(primaryVideo.count == 1)
        // When the sync-clip already carries an explicit custom video role, Final Cut Pro
        // does not prepend a redundant generic `Video` component.
        #expect(primaryVideo[0].roleSubroleField == "VFX ▸ VFX-Background")
    }
    

    @Test("Primary sync-clip without sync-source uses inherited audio for synced audio row")
    func primarySyncClipWithoutSyncSourceUsesInheritedAudioForSyncedAudioRow() async throws {
        let fcpxml = try parseInlineFCPXML(primarySyncClipWithNestedDialogueAudio)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let syncEntries = entries.filter { $0.extracted.displayClipName() == "Nested" }
        
        let primaryVideo = syncEntries.filter { $0.category == .primaryVideo }
        let syncedAudio = syncEntries.filter { $0.category == .primarySyncedAudio }
        let primaryAudio = syncEntries.filter { $0.category == .primaryAudio }
        
        #expect(primaryVideo.count == 1)
        #expect(primaryVideo[0].roleSubroleField == "Video")
        #expect(syncedAudio.count == 1)
        #expect(syncedAudio[0].roleSubroleField.localizedCaseInsensitiveContains("mix"))
        #expect(primaryAudio.isEmpty)
    }
    

    @Test("10-1-3 Cam A emits single connected clip row")
    func tenOneThreeCamAEmitsSingleConnectedClipRow() async throws {
        let fcpxml = try requireExcelReportSampleFCPXML()
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let connectedClip = entries.filter {
            $0.category == .connectedClip
                && $0.extracted.displayClipName() == "10-1-3 Cam A"
        }
        
        let rows = connectedClip.compactMap {
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: $0)
        }
        
        #expect(rows.count == 1)
        #expect(rows.first?.timelineIn == "00:04:53:01")
        #expect(rows.first?.timelineOut == "00:04:54:08")
        #expect(rows.first?.roleSubrole == "Dialogue ▸ Mix L, Mix R, Boom 1, Boom 2, R_Slate, R_Fahd")
    }
    

    @Test("Connected audio multicam floors fractional timeline end")
    func connectedAudioMulticamFloorsFractionalTimelineEnd() async throws {
        let fcpxml = try requireExcelReportSampleFCPXML()
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let connectedClip = entries.filter {
            $0.category == .connectedClip
                && $0.extracted.displayClipName() == "2Bpt 2of2-5-4 Cam A"
        }
        
        #expect(connectedClip.count == 1)
        #expect(connectedClip[0].usesFlooredTimelineEnd)
        #expect(connectedClip[0].usesAudioTimelineBounds)
        
        let row = try #require(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: connectedClip[0])
        )
        #expect(row.timelineIn == "00:01:28:20")
        #expect(row.timelineOut == "00:01:31:16")
        #expect(row.clipDuration == "00:00:02:21")
    }
    

    @Test("Split edit uses audio timeline bounds for embedded audio rows")
    func splitEditUsesAudioTimelineBoundsForEmbeddedAudioRows() async throws {
        let fcpxml = try parseInlineFCPXML(splitEditSyncClipFixture)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let connectedAudio = entries.filter { $0.category == .connectedAudio }
        #expect(connectedAudio.count == 1)
        #expect(connectedAudio[0].usesAudioTimelineBounds)
        
        let row = try #require(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: connectedAudio[0])
        )
        #expect(row.timelineIn == "00:00:00:00")
        #expect(row.timelineOut == "00:00:02:00")
        #expect(row.clipDuration == "00:00:02:00")
        
        let connectedVideo = entries.filter { $0.category == .connectedVideo }
        #expect(connectedVideo.count == 1)
        let videoUsesAudioBounds = connectedVideo[0].usesAudioTimelineBounds
        #expect(!videoUsesAudioBounds)
        
        let videoRow = try #require(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: connectedVideo[0])
        )
        #expect(videoRow.timelineOut == "00:00:04:00")
    }
    

    @Test("Sample fixture 5-1-9 segment count")
    func sampleFixtureFiveOneNineSegmentCount() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let timeline = try #require(fcpxml.allProjects().first).sequence.element
        
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
        
        #expect(earlyStarts.count >= 8, "Expected early timeline 5-1-9 segments; got \(earlyStarts.count) before 00:02:00:00 among \(fiveOneNine.count) total entries")
    }
    

    @Test("Disabled ref-clip is excluded from role inventory")
    func disabledRefClipIsExcludedFromRoleInventory() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        #expect(entries.filter { $0.extracted.displayClipName() == "Disabled Ref" }.isEmpty)
    }
    

    @Test("Nested connected asset-clip is excluded from role inventory")
    func nestedConnectedAssetClipIsExcludedFromRoleInventory() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        #expect(entries.filter { $0.extracted.displayClipName() == "Nested SFX" }.isEmpty)
    }

    @Test("Nested connected asset-clip with audioRole is inventoried")
    func nestedConnectedAssetClipWithAudioRoleIsInventoried() async throws {
        // Matches Audio Only_01 shape: spine Music clip (channel-source override) with a
        // connected Effects clip that only sets `audioRole` (no audio-channel-source).
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Forest Day" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" audioChannels="2" format="r1"/>
                <asset id="r3" name="Water Lake 3" uid="A2" start="0s" duration="10s" hasAudio="1" audioSources="1" audioChannels="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Forest Day" duration="5s" format="r1" audioRole="effects">
                                    <asset-clip ref="r3" lane="-1" offset="0s" name="Water Lake 3" duration="5s" format="r1" audioRole="effects"/>
                                    <audio-channel-source srcCh="1, 2" role="music.music-1"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )

        let musicRows = entries.filter {
            $0.extracted.displayClipName() == "Forest Day"
                && $0.roleSubroleField.localizedCaseInsensitiveContains("Music")
        }
        let effectsRows = entries.filter {
            $0.extracted.displayClipName() == "Water Lake 3"
                && $0.roleSubroleField.localizedCaseInsensitiveContains("Effects")
        }

        #expect(musicRows.count == 1)
        #expect(effectsRows.count == 1)
        #expect(effectsRows.first?.category == .connectedAudio)
    }

    @Test("Nested connected clip with child audio role is inventoried")
    func nestedConnectedClipWithChildAudioRoleIsInventoried() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Music" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
                <asset id="r3" name="SFX" uid="A2" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Music Bed" duration="5s" format="r1" audioRole="music">
                                    <clip lane="-1" offset="0s" name="Whoosh" duration="5s" format="r1">
                                        <audio ref="r3" offset="0s" duration="5s" role="effects.effects-1" srcCh="1"/>
                                    </clip>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let whoosh = entries.filter { $0.extracted.displayClipName() == "Whoosh" }
        #expect(whoosh.count == 1)
        #expect(whoosh.first?.roleSubroleField.localizedCaseInsensitiveContains("Effects") == true)
    }

    @Test("Nested connected asset-clip with videoRole is inventoried")
    func nestedConnectedAssetClipWithVideoRoleIsInventoried() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Plate" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <asset id="r3" name="Host" uid="A2" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r3" offset="0s" name="Interview" duration="5s" format="r1" audioRole="dialogue">
                                    <asset-clip ref="r2" lane="-1" offset="0s" name="Lower Third" duration="5s" format="r1" videoRole="VFX.VFX-Background"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let lowerThird = entries.filter { $0.extracted.displayClipName() == "Lower Third" }
        #expect(!lowerThird.isEmpty)
        #expect(
            lowerThird.contains {
                $0.roleSubroleField.localizedCaseInsensitiveContains("VFX")
            }
        )
    }

    @Test("Nested connected asset-clip with audioRole survives full occlusion")
    func nestedConnectedAssetClipWithAudioRoleSurvivesFullOcclusion() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Cover" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <asset id="r3" name="SFX" uid="A2" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="A-Roll" duration="5s" format="r1">
                                    <asset-clip ref="r3" lane="-1" offset="0s" name="Buried SFX" duration="5s" format="r1" audioRole="effects"/>
                                </asset-clip>
                                <asset-clip ref="r2" offset="0s" name="Cover" duration="5s" format="r1"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let buried = entries.filter {
            $0.extracted.displayClipName() == "Buried SFX"
                && $0.roleSubroleField.localizedCaseInsensitiveContains("Effects")
        }
        #expect(buried.count == 1)
    }

    @Test("MC-clip uses inherited audio when mc-sources lack audio-role-sources")
    func mCClipUsesInheritedAudioWhenMCSourcesLackAudioRoleSources() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let dialogueRows = entries.filter {
            $0.extracted.displayClipName() == "1C-2-2 Cam B"
                && $0.category == .primaryClip
                && $0.roleSubroleField.localizedCaseInsensitiveContains("mix")
        }
        
        #expect(dialogueRows.count == 1)
    }
    

    @Test("Connected disabled ref-clip emits connected video without audio splits")
    func connectedDisabledRefClipEmitsConnectedVideoWithoutAudioSplits() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let refRows = entries.filter { $0.extracted.displayClipName() == "Disabled Ref" }
        #expect(refRows.count == 1)
        #expect(refRows.first?.category == .connectedVideo)
        #expect(refRows.first?.roleSubroleField == "Video, Dialogue")
    }
    

    @Test("Audio-only connected MC-clip emits connected clip role row")
    func audioOnlyConnectedMCClipEmitsConnectedClipRoleRow() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let nestedRows = entries.filter { $0.extracted.displayClipName().contains("5A-4-1") }
        #expect(nestedRows.count == 1)
        #expect(nestedRows.first?.category == .connectedClip)
        #expect(nestedRows.first?.roleSubroleField == "Dialogue ▸ Mixl")
    }
    

    @Test("Nested audio-only clip without role is excluded from role inventory")
    func nestedAudioOnlyClipWithoutRoleIsExcludedFromRoleInventory() async throws {
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
                                        <audio ref="r2" offset="0s" duration="5s" srcCh="1"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        #expect(entries.filter { $0.extracted.displayClipName() == "ADR Clip" }.isEmpty)
    }

    @Test("Nested audio-only clip with dialogue role is inventoried")
    func nestedAudioOnlyClipWithDialogueRoleIsInventoried() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let adr = entries.filter { $0.extracted.displayClipName() == "ADR Clip" }
        #expect(adr.count == 1)
        #expect(adr.first?.roleSubroleField.localizedCaseInsensitiveContains("Dialogue") == true)
    }
    

    @Test("Connected MOS clip uses inherited VFX video role")
    func connectedMOSClipUsesInheritedVFXVideoRole() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let videoRows = entries.filter {
            $0.extracted.displayClipName() == "MOS Plate"
                && $0.category == .connectedVideo
        }
        
        #expect(videoRows.count == 1)
        #expect(videoRows.first?.roleSubroleField == "VFX ▸ VFX-Background")
    }
    

    @Test("Connected MOS clip keeps user-defined VFX element role")
    func connectedMOSClipKeepsUserDefinedVFXElementRole() async throws {
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
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(
            from: timeline,
            scope: .init()
        )
        
        let videoRows = entries.filter {
            $0.extracted.displayClipName() == "VFX Element Plate"
                && $0.category == .connectedVideo
        }
        
        #expect(videoRows.count == 1)
        #expect(videoRows.first?.roleSubroleField == "VFX ▸ VFX-Element")
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
                <asset id="r3" name="Atmosphere" uid="B1" start="0s" duration="10s" hasAudio="1" audioSources="1" audioChannels="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <asset-clip ref="r2" offset="0s" name="Video" duration="5s" format="r1"/>
                                    <asset-clip ref="r3" lane="-1" offset="0s" name="Atmosphere" duration="5s" format="r1" audioRole="dialogue">
                                        <audio-channel-source srcCh="1" role="Atmosphere.Mix L"/>
                                        <audio-channel-source srcCh="2" role="Atmosphere.Mix R"/>
                                        <audio-channel-source srcCh="3" role="Atmosphere.Boom 1" enabled="0"/>
                                        <audio-channel-source srcCh="4" role="Atmosphere" enabled="0"/>
                                        <audio-channel-source srcCh="5" role="Atmosphere.&lt;Blank&gt;" enabled="0"/>
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
    

    @Test("Primary spine AV asset-clip with dialogue-only role emits video and audio rows")
    func primarySpineAVAssetClipWithDialogueOnlyRoleEmitsVideoAndAudioRows() async throws {
        let fcpxml = try parseInlineFCPXML(primarySpineAVAssetClipWithDialogueOnlyAudioRole)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let clipEntries = entries.filter { $0.extracted.displayClipName() == "Clip" }
        
        #expect(clipEntries.count == 2)
        #expect(clipEntries.contains { $0.category == .primaryVideo })
        #expect(clipEntries.contains { $0.category == .primaryAudio })
        
        let roleField = "Video, Dialogue ▸ Dialogue-1"
        #expect(clipEntries.allSatisfy { $0.roleSubroleField == roleField })
        
        let rows = clipEntries.compactMap {
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: $0)
        }
        #expect(rows.count == 2)
        #expect(rows[0].timelineIn == "00:00:00:00")
        #expect(rows[0].timelineOut == "00:00:05:00")
        
        let roleSheets = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.roleSheets(from: rows)
        let sheetNames = Set(roleSheets.map(\.sheetName))
        #expect(sheetNames.contains("Video"))
        #expect(sheetNames.contains("Dialogue ▸ Dialogue-1"))
        let hasBlankDialogue = sheetNames.contains("Dialogue ▸ <Blank>")
        #expect(!hasBlankDialogue)
    }
    

    @Test("Caption from sample fixture is inventoried with floored timeline bounds")
    func captionFromSampleFixtureIsInventoriedWithFlooredTimelineBounds() async throws {
        let fcpxml = try requireExcelReportSampleFCPXML()
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let caption = try #require(
            entries.first { entry in
                guard entry.category == .caption,
                      let row = FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: entry)
                else { return false }
                return row.timelineIn == "00:01:13:22" && row.timelineOut == "00:01:18:10"
            }
        )
        
        #expect(caption.usesFlooredTimelineStart)
        #expect(caption.usesFlooredTimelineEnd)
        
        let row = try #require(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: caption)
        )
        #expect(row.timelineIn == "00:01:13:22")
        #expect(row.timelineOut == "00:01:18:10")
        #expect(row.roleSubrole.hasPrefix("SRT"))
    }
    

    @Test("Caption timeline position aligns to computed frame from sample fixture")
    func captionTimelinePositionAlignsToComputedFrameFromSampleFixture() async throws {
        let fcpxml = try requireExcelReportSampleFCPXML()
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        
        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        
        // Caption inventory rows use the caption's computed timeline position directly.
        // These positions land on exact frame boundaries and are not shifted by an extra
        // frame, matching Final Cut Pro's own timeline placement.
        func firstCaption(
            timelineIn: String,
            timelineOut: String
        ) -> FinalCutPro.FCPXML.RoleInventoryClipEntry? {
            entries.first { entry in
                guard entry.category == .caption,
                      let row = FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: entry)
                else { return false }
                return row.timelineIn == timelineIn && row.timelineOut == timelineOut
            }
        }
        
        let earlyCaption = try #require(
            firstCaption(timelineIn: "00:03:10:03", timelineOut: "00:03:11:08")
        )
        let row = try #require(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: earlyCaption)
        )
        let hasMcClipAncestor = earlyCaption.extracted.element
            .ancestorElements(includingSelf: false)
            .contains { $0.fcpElementType == .mcClip }
        #expect(hasMcClipAncestor, "Expected caption inside mc-clip")
        #expect(row.timelineIn == "00:03:10:03")
        #expect(row.timelineOut == "00:03:11:08")
        
        let laterCaption = try #require(
            firstCaption(timelineIn: "00:03:27:09", timelineOut: "00:03:29:15")
        )
        let laterRow = try #require(
            FinalCutPro.FCPXML.RoleInventoryRowBuilder.row(from: laterCaption)
        )
        #expect(laterRow.timelineIn == "00:03:27:09")
        #expect(laterRow.timelineOut == "00:03:29:15")
    }

    @Test("Under-spine connected titles keep custom video roles")
    func underSpineConnectedTitlesKeepCustomVideoRoles() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <effect id="r2" name="Metal" uid=".../Generators.localized/Textures.localized/Metal.localized/Metal.motn"/>
                <effect id="r3" name="Basic Title" uid=".../Titles.localized/Basic Title.moti"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <video ref="r2" offset="0s" name="Metal" start="3600s" duration="10s">
                                    <title ref="r3" lane="-1" offset="3600s" name="TO-DO - Basic Title" start="3600s" duration="2s" role="TO-DO.TO-DO-1">
                                        <text><text-style ref="ts1">TO-DO</text-style></text>
                                        <text-style-def id="ts1"><text-style font="Helvetica"/></text-style-def>
                                        <marker start="3600s" duration="100/2500s" value="TD-001" completed="0"/>
                                    </title>
                                    <title ref="r3" lane="-2" offset="3602s" name="VFX - Basic Title" start="3600s" duration="2s" role="VFX.VFX-1">
                                        <text><text-style ref="ts2">VFX</text-style></text>
                                        <text-style-def id="ts2"><text-style font="Helvetica"/></text-style-def>
                                    </title>
                                </video>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let titleEntries = entries.filter(\.category.isTitleCategory)
        #expect(titleEntries.count == 2)
        #expect(titleEntries.contains { $0.roleSubroleField == "TO-DO ▸ To-Do-1" })
        #expect(titleEntries.contains { $0.roleSubroleField == "VFX ▸ VFX-1" })
        #expect(titleEntries.contains { $0.category == .connectedTitle })

        let report = try await fcpxml.buildReport(options: .full)
        let titleRows = try #require(report.titlesAndGenerators?.rows)
        #expect(titleRows.contains { $0.roleSubrole == "TO-DO ▸ To-Do-1" })
        #expect(titleRows.contains { $0.roleSubrole == "VFX ▸ VFX-1" })

        let sheetNames = Set(report.roleInventory?.roleSheets.map(\.sheetName) ?? [])
        #expect(sheetNames.contains("TO-DO ▸ To-Do-1"))
        #expect(sheetNames.contains("VFX ▸ VFX-1"))

        let markerRoles = Set(report.markers?.rows.map(\.roleSubrole) ?? [])
        #expect(markerRoles.contains("TO-DO"))
    }

    @Test("Under-spine connected video generator is inventoried")
    func underSpineConnectedVideoGeneratorIsInventoried() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="A-Roll" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <effect id="r3" name="Gradient" uid=".../Generators.localized/Textures.localized/Gradient.localized/Gradient.motn"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Interview" duration="10s" format="r1">
                                    <video ref="r3" lane="-1" offset="0s" name="Gradient Under" start="3600s" duration="5s"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let under = entries.filter { $0.extracted.displayClipName() == "Gradient Under" }
        #expect(
            !under.isEmpty,
            "Connected video/generators under the primary storyline must be inventoried"
        )
        #expect(under.contains { $0.category == .connectedGenerator })
    }
}

