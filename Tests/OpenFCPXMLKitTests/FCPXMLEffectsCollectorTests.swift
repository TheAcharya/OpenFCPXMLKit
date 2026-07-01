//
//  FCPXMLEffectsCollectorTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for semantic effect collection from clip hosts.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLEffectsCollectorTests: XCTestCase {
    private typealias EffectsCollector = FinalCutPro.FCPXML.EffectsCollector
    private typealias ExtractedElement = FinalCutPro.FCPXML.ExtractedElement
    private typealias ExtractedEffect = FinalCutPro.FCPXML.ExtractedEffect
    
    func testEffectsOnAssetClipCollectsFilterVideoAndAudio() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1" audioRole="dialogue">
                                    <filter-video name="Blur"/>
                                    <filter-audio name="EQ"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "asset-clip")
        let effects = EffectsCollector.effects(on: host)
        
        XCTAssertTrue(effects.contains { $0.kind == .filterVideo && $0.name == "Blur" })
        XCTAssertTrue(effects.contains { $0.kind == .filterAudio && $0.name == "EQ" })
    }
    
    func testEffectsOnAssetClipVolumeWithoutAmountEmitsEmptyAndZeroDecibelRows() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1" audioRole="dialogue">
                                    <adjust-volume/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "asset-clip")
        let volumeEffects = EffectsCollector.effects(on: host).filter { $0.kind == .volume }
        
        XCTAssertEqual(volumeEffects.count, 2)
        XCTAssertTrue(volumeEffects.contains { $0.settings == .empty && $0.sortOrder == 0 })
        XCTAssertTrue(volumeEffects.contains {
            if case .decibels(0) = $0.settings { return $0.sortOrder == 1 }
            return false
        })
    }
    
    func testEffectsOnAssetClipVolumeWithAmountEmitsSingleDecibelRow() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1" audioRole="dialogue">
                                    <adjust-volume amount="12dB"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "asset-clip")
        let volumeEffects = EffectsCollector.effects(on: host).filter { $0.kind == .volume }
        
        XCTAssertEqual(volumeEffects.count, 1)
        if case .decibels(let amount) = volumeEffects[0].settings {
            XCTAssertEqual(amount, 12, accuracy: 0.001)
        } else {
            XCTFail("Expected decibel volume settings")
        }
    }
    
    func testEffectsOnDisabledAssetClipWithAudioEmitsImplicitVolume() throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")
        let disabledClip = try XCTUnwrap(
            firstDescendantElement(
                in: fcpxml.root.element,
                named: "asset-clip",
                where: { $0.fcpGetEnabled(default: true) == false }
            )
        )
        
        let host = ExtractedElement(
            element: disabledClip,
            breadcrumbs: [],
            resources: fcpxml.root.resources
        )
        let effects = EffectsCollector.effects(on: host)
        
        let implicitVolume = effects.first {
            $0.kind == .implicitVolume && $0.name == "volume"
        }
        XCTAssertNotNil(implicitVolume)
        XCTAssertEqual(implicitVolume?.settings, .empty)
    }
    
    func testEffectsOnTitleCollectsAdjustBlendAsCompositing() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <effect id="r2" name="Basic Title" uid=".../Titles.localized/Basic Title.moti"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <title ref="r2" offset="0s" name="Title" duration="5s">
                                    <adjust-blend amount="0.3"/>
                                </title>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "title")
        let compositing = EffectsCollector.effects(on: host).filter { $0.kind == .compositing }
        
        XCTAssertEqual(compositing.count, 1)
        XCTAssertEqual(compositing[0].name, "Compositing")
        if case .opacityPercent(let amount) = compositing[0].settings {
            XCTAssertEqual(amount, 0.3, accuracy: 0.001)
        } else {
            XCTFail("Expected opacity percent settings")
        }
    }
    
    func testEffectsOnTitleCollectsThreeTransformRowsInSortOrder() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <effect id="r2" name="Basic Title" uid=".../Titles.localized/Basic Title.moti"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <title ref="r2" offset="0s" name="Title" duration="5s">
                                    <adjust-transform position="10 20" rotation="45" scale="1.5 1.5"/>
                                </title>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "title")
        let transforms = EffectsCollector.effects(on: host)
            .filter { $0.kind == .transform }
            .sorted { $0.sortOrder < $1.sortOrder }
        
        XCTAssertEqual(transforms.count, 3)
        XCTAssertEqual(transforms.map(\.sortOrder), [0, 1, 2])
    }
    
    func testEffectsCollectorIsEffectEnabledRespectsEffectElementEnabled() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1" audioRole="dialogue">
                                    <filter-video name="Blur" enabled="0"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let hostElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        let filter = try XCTUnwrap(hostElement.firstChildElement(named: "filter-video"))
        
        XCTAssertFalse(
            EffectsCollector.isEffectEnabled(effectElement: filter, host: hostElement)
        )
    }
    
    func testEffectsCollectorIsEffectEnabledFallsBackToHostEnabled() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" enabled="0" format="r1" audioRole="dialogue">
                                    <filter-video name="Blur"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let hostElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        let filter = try XCTUnwrap(hostElement.firstChildElement(named: "filter-video"))
        
        XCTAssertFalse(
            EffectsCollector.isEffectEnabled(effectElement: filter, host: hostElement)
        )
    }
    
    func testEffectsExtractionPresetReturnsOnlySupportedHostTypes() async throws {
        let timeline = try timelineElement(fromSampleNamed: "TimelineSample")
        let effects = await timeline.fcpExtract(preset: .effects)
        
        let hostTypes = Set(
            effects.map { $0.host.element.fcpElementType }.compactMap { $0 }
        )
        
        XCTAssertFalse(effects.isEmpty)
        XCTAssertTrue(hostTypes.isSubset(of: [.title, .assetClip, .syncClip]))
    }
    
    private func makeExtractedHost(
        from fcpxml: FinalCutPro.FCPXML,
        elementName: String
    ) throws -> ExtractedElement {
        let element = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: elementName)
        )
        return ExtractedElement(
            element: element,
            breadcrumbs: [],
            resources: fcpxml.root.resources
        )
    }
}
