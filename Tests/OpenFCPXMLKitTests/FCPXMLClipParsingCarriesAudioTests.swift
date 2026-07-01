//
//  FCPXMLClipParsingCarriesAudioTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for fcpCarriesAudio clip parsing helper.
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLClipParsingCarriesAudioTests: XCTestCase {
    func testFcpCarriesAudioTrueWhenAudioChildPresent() throws {
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
        
        let clip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        
        XCTAssertTrue(clip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }
    
    func testFcpCarriesAudioTrueWhenAudioChannelSourcePresent() throws {
        let fcpxml = try loadFCPXMLSample(named: "AudioOnly")
        let clip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        
        XCTAssertTrue(clip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }
    
    func testFcpCarriesAudioTrueWhenReferencedAssetHasAudio() throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")
        let disabledClip = try XCTUnwrap(
            firstDescendantElement(
                in: fcpxml.root.element,
                named: "asset-clip",
                where: { $0.fcpGetEnabled(default: true) == false }
            )
        )
        
        XCTAssertTrue(disabledClip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }
    
    func testFcpCarriesAudioFalseForVideoOnlyAsset() throws {
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
        
        let clip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        
        XCTAssertFalse(clip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }
    
    func testFcpCarriesAudioTrueForSyncClipWithNestedDialogueAudio() throws {
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
        
        let syncClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "sync-clip")
        )
        
        XCTAssertTrue(syncClip.fcpCarriesAudio(resources: fcpxml.root.resources))
    }
    
    func testFcpWorkbookClipNameAppendsShortMulticamAngle() throws {
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
        
        let mcClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )
        
        XCTAssertEqual(mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources), "10-1-3 Cam A")
    }
    
    func testFcpWorkbookClipNameUsesFullAngleNameWhenAngleIncludesShotID() throws {
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
        
        let mcClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )
        
        XCTAssertEqual(mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources), "5A-4-2 Cam B")
    }
    
    func testFcpWorkbookClipNameUsesInteriorAngleTimelineName() throws {
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
        
        let mcClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )
        
        XCTAssertEqual(
            mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources),
            "13pt 2of2-1-4 MOS Cam A"
        )
    }
    
    func testFcpWorkbookClipNamePrefersVideoOrAudioAngleByRequest() throws {
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
        
        let mcClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "mc-clip")
        )
        
        XCTAssertEqual(
            mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources),
            "1C-2-1 Cam C"
        )
        XCTAssertEqual(
            mcClip.fcpWorkbookClipName(resources: fcpxml.root.resources, preferAudioAngle: true),
            "1C-2-1 Cam B"
        )
    }
    
    func testFcpScanlineVideoInventoryRoleLabelForScanlineOverlay() throws {
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
        
        let overlay = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        
        XCTAssertEqual(
            overlay.fcpScanlineVideoInventoryRoleLabel(),
            "Vfx Scanline Di Final"
        )
    }
    
    func testFcpIsExcludedFromRoleInventoryForDisabledRefClip() throws {
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
        
        let refClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "ref-clip")
        )
        
        XCTAssertTrue(refClip.fcpIsExcludedFromRoleInventory())
    }
    
    func testConnectedDisabledRefClipIsNotExcludedFromRoleInventory() throws {
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
        
        let refClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "ref-clip")
        )
        
        XCTAssertFalse(refClip.fcpIsExcludedFromRoleInventory())
        XCTAssertTrue(refClip.fcpIsExcludedFromRoleInventoryAudio())
    }
    
    func testFcpIsNestedConnectedInventoryHostTrueForAssetClipOnNegativeLaneInsideSyncClip() throws {
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
        
        let nestedClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        
        XCTAssertTrue(nestedClip.fcpIsNestedConnectedInventoryHost())
    }
    
    func testFcpCarriesVideoFalseForAudioOnlyClip() throws {
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
        
        let audioClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        
        XCTAssertFalse(audioClip.fcpCarriesVideo(resources: fcpxml.root.resources))
    }
    
    func testFcpUsesGenericVideoInventoryLabelForConnectedAssetClipWithoutVideoRole() throws {
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
        
        let hostClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        let overlay = try XCTUnwrap(
            hostClip.childElements.first { $0.name == "asset-clip" && ($0.fcpLane ?? 0) == 1 }
        )
        
        XCTAssertTrue(overlay.fcpUsesGenericVideoInventoryLabel())
    }
    
    func testFcpIsNestedConnectedInventoryHostTrueForAudioOnlyClipOnNegativeLaneInsideSyncClip() throws {
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
        
        let nestedClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        
        XCTAssertTrue(nestedClip.fcpIsNestedConnectedInventoryHost())
    }
    
    func testFcpIsNestedConnectedInventoryHostFalseForVideoClipOnNegativeLaneInsideSyncClip() throws {
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
        
        let nestedClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        
        XCTAssertFalse(nestedClip.fcpIsNestedConnectedInventoryHost())
    }
    
    func testFcpIsNestedConnectedInventoryHostFalseForConnectedSyncClipOnSpine() throws {
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
        
        let connectedSync = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "sync-clip")
        )
        
        XCTAssertFalse(connectedSync.fcpIsNestedConnectedInventoryHost())
    }
    
    func testFcpIsNestedConnectedInventoryHostFalseForAudioOnlyClipWithChannelSources() throws {
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
        
        let nestedClip = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        
        XCTAssertTrue(nestedClip.fcpHasActiveInventoryAudioChannelSources())
        XCTAssertFalse(nestedClip.fcpIsNestedConnectedInventoryHost())
    }
}
