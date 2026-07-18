//
// FCPXMLRoleInheritanceMatrixTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Role inheritance matrix — primary / connected / sync / multicam × channel-source edges.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Role inheritance matrix")
struct FCPXMLRoleInheritanceMatrixTests {
    private typealias Collector = FinalCutPro.FCPXML.RoleInventoryClipCollector

    @Test("Primary spine asset-clip uses audio channel source over clip audio role")
    func primarySpineAssetClipUsesAudioChannelSourceOverClipAudioRole() async throws {
        let fcpxml = try parseInlineFCPXML(primaryWithChannelSource)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)

        let entries = await Collector.collectEntries(from: timeline, scope: .init())
        let audio = entries.filter {
            $0.extracted.displayClipName() == "Primary" && $0.category == .primaryAudio
        }
        #expect(audio.count == 1)
        let containsMix = audio[0].roleSubroleField.localizedCaseInsensitiveContains("mix")
        #expect(containsMix, "Expected channel-source Mix role, got \(audio[0].roleSubroleField)")
        let containsDialogue = audio[0].roleSubroleField.localizedCaseInsensitiveContains("dialogue")
        #expect(!containsDialogue, "Clip audioRole should be overridden by active audio-channel-source")
    }

    @Test("Connected lane inherits anchor video in role field")
    func connectedLaneInheritsAnchorVideoInRoleField() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles2")
        let entries = await Collector.collectEntries(from: timeline, scope: .init())

        let connectedAudio = entries.filter {
            $0.extracted.displayClipName() == "5-1-5 NK"
                && $0.category == .connectedAudio
        }
        let connectedAudioEmpty = connectedAudio.isEmpty
        #expect(!connectedAudioEmpty)
        for entry in connectedAudio {
            let hasVideoPrefix = entry.roleSubroleField.hasPrefix("Video,")
            #expect(
                hasVideoPrefix,
                "Connected sync audio should prefix Video anchor, got \(entry.roleSubroleField)"
            )
        }
    }

    @Test("Sync-clip synced audio uses sync-source grouped roles")
    func syncClipSyncedAudioUsesSyncSourceGroupedRoles() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(
            preset: .roles(roleTypes: [.audio]),
            scope: .reportMainTimelineVisible()
        )
        let hasDialogue = roles.contains { $0.role.lowercased() == "dialogue" }
        #expect(hasDialogue)
    }

    @Test("MC-clip inherited audio when sources lack role sources")
    func mcClipInheritedAudioWhenSourcesLackRoleSources() async throws {
        let fcpxml = try parseInlineFCPXML(mcClipInheritedAudio)
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        let entries = await Collector.collectEntries(from: timeline, scope: .init())

        let dialogueRows = entries.filter {
            $0.extracted.displayClipName() == "1C-2-2 Cam B"
                && $0.category == .primaryClip
                && $0.roleSubroleField.localizedCaseInsensitiveContains("mix")
        }
        #expect(dialogueRows.count == 1)
    }

    @Test("Inherited roles honors mc-clip angles all mask")
    func inheritedRolesHonorsMcClipAnglesAllMask() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "MulticamSample")

        var activeScope = FinalCutPro.FCPXML.ExtractionScope.reportMainTimelineVisible()
        activeScope.mcClipAngles = .active
        let activeExtracted = await timeline.fcpExtract(
            types: [.mcClip, .assetClip],
            scope: activeScope
        )

        var allScope = FinalCutPro.FCPXML.ExtractionScope.reportMainTimelineVisible()
        allScope.mcClipAngles = .all
        let allExtracted = await timeline.fcpExtract(
            types: [.mcClip, .assetClip],
            scope: allScope
        )

        #expect(allExtracted.count >= activeExtracted.count)

        // Scope masks must be stored on ExtractedElement for role resolution.
        let allHaveAllMask = allExtracted.allSatisfy { $0.mcClipAngles == .all }
        #expect(allHaveAllMask)
        let activeHaveActiveMask = activeExtracted.allSatisfy { $0.mcClipAngles == .active }
        #expect(activeHaveActiveMask)
    }

    // MARK: - Fixtures

    private var primaryWithChannelSource: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Clip" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" audioChannels="2" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                </asset>
            </resources>
            <library>
                <event name="E">
                    <project name="P">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Primary" duration="5s" audioRole="dialogue">
                                    <audio-channel-source srcCh="1, 2" role="mix.mix1"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }

    private var mcClipInheritedAudio: String {
        """
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
        """
    }
}
