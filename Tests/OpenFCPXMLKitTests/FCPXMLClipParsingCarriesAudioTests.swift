//
//  FCPXMLClipParsingCarriesAudioTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for fcpCarriesAudio clip parsing helper.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Clip parsing carries audio")
struct FCPXMLClipParsingCarriesAudioTests {
    @Test("fcpCarriesAudio true when audio child present")
    func fcpCarriesAudioTrueWhenAudioChildPresent() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Nested Audio" duration="5s">
                                    <audio/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let clip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )

        #expect(clip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }

    @Test("fcpCarriesAudio true when audio channel source present")
    func fcpCarriesAudioTrueWhenAudioChannelSourcePresent() throws {
        let fcpxml = try requireFCPXMLSample(named: "AudioOnly")
        let clip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )

        #expect(clip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }

    @Test("fcpCarriesAudio true when referenced asset has audio")
    func fcpCarriesAudioTrueWhenReferencedAssetHasAudio() throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")
        let disabledClip = try #require(
            firstDescendantElement(
                in: fcpxml.root.element,
                named: "asset-clip",
                where: { $0.fcpGetEnabled(default: true) == false }
            )
        )

        #expect(disabledClip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }

    @Test("fcpCarriesAudio false for video-only asset")
    func fcpCarriesAudioFalseForVideoOnlyAsset() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Silent" uid="ABC" start="0s" duration="5s" hasVideo="1" hasAudio="0" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Silent" duration="5s" audioRole="dialogue"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let clip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )

        let carriesAudio = clip.fcpCarriesAudio(resources: fcpxml.root.resources)
        #expect(!carriesAudio)
    }

    @Test("fcpCarriesAudio true for sync-clip with nested dialogue audio")
    func fcpCarriesAudioTrueForSyncClipWithNestedDialogueAudio() throws {
        let fcpxml = try parseInlineFCPXML("""
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
                                            <audio ref="r3" offset="0s" start="0s" duration="5s" role="dialogue.MixL" srcCh="1"/>
                                        </clip>
                                    </asset-clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let syncClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "sync-clip")
        )

        #expect(syncClip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }

    @Test("fcpWorkbookClipName appends short multicam angle")
    func fcpWorkbookClipNameAppendsShortMulticamAngle() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <media id="r3" name="MC" uid="M1">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="Cam A" angleID="a1">
                            <asset-clip ref="r2" offset="0s" name="Angle A" duration="5s" format="r1"/>
                        </mc-angle>
                    </multicam>
                </media>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <mc-clip ref="r3" offset="0s" name="10-1-3" duration="5s">
                                    <mc-source angleID="a1" srcEnable="all"/>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let mcClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )

        #expect(mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources) == "10-1-3 Cam A")
    }

    @Test("fcpWorkbookClipName uses full angle name when angle includes shot ID")
    func fcpWorkbookClipNameUsesFullAngleNameWhenAngleIncludesShotID() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <media id="r3" name="5A-4-2" uid="M1">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="5A-4-2 Cam B" angleID="a1">
                            <asset-clip ref="r2" offset="0s" name="Angle B" duration="5s" format="r1"/>
                        </mc-angle>
                    </multicam>
                </media>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <mc-clip ref="r3" offset="0s" name="5A-4-2" duration="5s">
                                    <mc-source angleID="a1" srcEnable="all"/>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let mcClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )

        #expect(mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources) == "5A-4-2 Cam B")
    }

    @Test("fcpWorkbookClipName uses interior angle timeline name")
    func fcpWorkbookClipNameUsesInteriorAngleTimelineName() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <media id="r3" name="13pt 2of2-1-4" uid="M1">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="Cam A" angleID="a1">
                            <sync-clip offset="0s" name="13pt 2of2-1-4 MOS Cam A" duration="5s" tcFormat="NDF">
                                <asset-clip ref="r2" offset="0s" name="Angle A" duration="5s" format="r1"/>
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
                                <mc-clip ref="r3" offset="0s" name="13pt 2of2-1-4" duration="5s">
                                    <mc-source angleID="a1" srcEnable="all"/>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let mcClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )

        #expect(
            mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources)
                == "13pt 2of2-1-4 MOS Cam A"
        )
    }

    @Test("fcpWorkbookClipName prefers video or audio angle by request")
    func fcpWorkbookClipNamePrefersVideoOrAudioAngleByRequest() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
                <media id="r3" name="1C-2-1" uid="M1">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="1C-2-1 Cam B" angleID="a1">
                            <asset-clip ref="r2" offset="0s" name="Angle B" duration="5s" format="r1"/>
                        </mc-angle>
                        <mc-angle name="1C-2-1 Cam C" angleID="a2">
                            <asset-clip ref="r2" offset="0s" name="Angle C" duration="5s" format="r1"/>
                        </mc-angle>
                    </multicam>
                </media>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <mc-clip ref="r3" offset="0s" name="1C-2-1" duration="5s">
                                    <mc-source angleID="a2" srcEnable="video"/>
                                    <mc-source angleID="a1" srcEnable="audio"/>
                                </mc-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let mcClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )

        #expect(
            mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources)
                == "1C-2-1 Cam C"
        )
        #expect(
            mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources, preferAudioAngle: true)
                == "1C-2-1 Cam B"
        )
    }

    @Test("fcpScanlineVideoInventoryRoleLabel for scanline overlay")
    func fcpScanlineVideoInventoryRoleLabelForScanlineOverlay() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" lane="1" offset="0s" name="Overlay" duration="5s" format="r1" videoRole="VFX Scanline DI Final"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let overlay = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )

        #expect(
            overlay.fcpScanlineVideoInventoryRoleLabel()
                == "Vfx Scanline Di Final"
        )
    }

    @Test("fcpIsExcludedFromRoleInventory for disabled ref-clip")
    func fcpIsExcludedFromRoleInventoryForDisabledRefClip() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <media id="r2" name="Nested" uid="M1">
                    <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <gap name="Gap" offset="0s" duration="5s"/>
                        </spine>
                    </sequence>
                </media>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <ref-clip ref="r2" offset="0s" name="Disabled Ref" duration="5s" enabled="0"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let refClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "ref-clip")
        )

        #expect(refClip.fcpIsExcludedFromRoleInventory())
    }

    @Test("Connected disabled ref-clip is not excluded from role inventory")
    func connectedDisabledRefClipIsNotExcludedFromRoleInventory() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <media id="r2" name="Nested" uid="M1">
                    <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <gap name="Gap" offset="0s" duration="5s"/>
                        </spine>
                    </sequence>
                </media>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <ref-clip ref="r2" lane="-1" offset="0s" name="Disabled Ref" duration="5s" enabled="0"/>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let refClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "ref-clip")
        )

        let isExcluded = refClip.fcpIsExcludedFromRoleInventory()
        #expect(!isExcluded)
        #expect(refClip.fcpIsExcludedFromRoleInventoryAudio())
    }

    @Test("fcpIsNestedConnectedInventoryHost true for asset-clip on negative lane inside sync-clip")
    func fcpIsNestedConnectedInventoryHostTrueForAssetClipOnNegativeLaneInsideSyncClip() throws {
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

        let nestedClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )

        #expect(nestedClip.fcpIsNestedConnectedInventoryHost())
    }

    @Test("fcpCarriesVideo false for audio-only clip")
    func fcpCarriesVideoFalseForAudioOnlyClip() throws {
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
                                    <clip lane="-1" offset="0s" name="ADR Clip" duration="5s" format="r1">
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

        let audioClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )

        let carriesVideo = audioClip.fcpCarriesVideo(resources: fcpxml.root.resources)
        #expect(!carriesVideo)
    }

    @Test("fcpUsesGenericVideoInventoryLabel for connected asset-clip without video role")
    func fcpUsesGenericVideoInventoryLabelForConnectedAssetClipWithoutVideoRole() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Host" duration="10s" format="r1">
                                    <video ref="r2" offset="0s" duration="10s" role="VFX.VFX-Background"/>
                                    <asset-clip ref="r2" lane="1" offset="0s" name="Overlay" duration="5s" format="r1"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let hostClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        let overlay = try #require(
            hostClip.childElements.first { $0.name == "asset-clip" && ($0.fcpLane ?? 0) == 1 }
        )

        #expect(overlay.fcpUsesGenericVideoInventoryLabel())
    }

    @Test("fcpIsNestedConnectedInventoryHost false for audio-only clip with explicit child role")
    func fcpIsNestedConnectedInventoryHostFalseForAudioOnlyClipWithExplicitChildRole() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="SFX" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <clip lane="-1" offset="0s" name="Nested Clip" duration="5s" format="r1">
                                        <audio ref="r2" offset="0s" duration="5s" role="effects.effects-1" srcCh="1, 2"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let nestedClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )

        let isNestedHost = nestedClip.fcpIsNestedConnectedInventoryHost()
        #expect(!isNestedHost)
        #expect(nestedClip.fcpHasStandaloneConnectedInventoryAssignment())
    }

    @Test("fcpIsNestedConnectedInventoryHost true for audio-only clip without role")
    func fcpIsNestedConnectedInventoryHostTrueForAudioOnlyClipWithoutRole() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="SFX" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <clip lane="-1" offset="0s" name="Nested Clip" duration="5s" format="r1">
                                        <audio ref="r2" offset="0s" duration="5s" srcCh="1, 2"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let nestedClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )

        #expect(nestedClip.fcpIsNestedConnectedInventoryHost())
    }

    @Test("fcpIsNestedConnectedInventoryHost false for asset-clip with audioRole")
    func fcpIsNestedConnectedInventoryHostFalseForAssetClipWithAudioRole() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Host" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
                <asset id="r3" name="SFX" uid="A2" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Host" duration="5s" format="r1" audioRole="music">
                                    <asset-clip ref="r3" lane="-1" offset="0s" name="Nested SFX" duration="5s" format="r1" audioRole="effects"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let nested = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip") {
                $0.fcpName == "Nested SFX"
            }
        )
        let isNestedHost = nested.fcpIsNestedConnectedInventoryHost()
        #expect(!isNestedHost)
        #expect(nested.fcpHasStandaloneConnectedInventoryAssignment())
    }

    @Test("fcpIsNestedConnectedInventoryHost false for video clip on negative lane inside sync-clip")
    func fcpIsNestedConnectedInventoryHostFalseForVideoClipOnNegativeLaneInsideSyncClip() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="SFX" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <clip lane="-1" offset="0s" name="Nested Effect" duration="5s" format="r1">
                                        <video ref="r2" offset="0s" duration="5s" role="VFX.VFX-Background"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let nestedClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )

        let isNestedHost = nestedClip.fcpIsNestedConnectedInventoryHost()
        #expect(!isNestedHost)
    }

    @Test("fcpIsNestedConnectedInventoryHost false for connected sync-clip on spine")
    func fcpIsNestedConnectedInventoryHostFalseForConnectedSyncClipOnSpine() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip lane="-1" offset="0s" name="Connected" duration="5s" tcFormat="NDF">
                                    <asset-clip ref="r2" offset="0s" name="Video" duration="5s" format="r1"/>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let connectedSync = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "sync-clip")
        )

        let isNestedHost = connectedSync.fcpIsNestedConnectedInventoryHost()
        #expect(!isNestedHost)
    }

    @Test("fcpIsNestedConnectedInventoryHost false for audio-only clip with channel sources")
    func fcpIsNestedConnectedInventoryHostFalseForAudioOnlyClipWithChannelSources() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="SFX" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="2" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <sync-clip offset="0s" name="Host" duration="5s" tcFormat="NDF">
                                    <clip lane="-1" offset="0s" name="Surround Stem" duration="5s" format="r1">
                                        <audio ref="r2" offset="0s" duration="5s" role="dialogue.MIX L" srcCh="1"/>
                                        <audio-channel-source srcCh="1" role="Ambient Beds.MIX L"/>
                                    </clip>
                                </sync-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let nestedClip = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )

        #expect(nestedClip.fcpHasActiveInventoryAudioChannelSources())
        let isNestedHost = nestedClip.fcpIsNestedConnectedInventoryHost()
        #expect(!isNestedHost)
    }
}

