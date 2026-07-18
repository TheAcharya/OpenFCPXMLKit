//
//  FCPXMLEffectsCollectorTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for semantic effect collection from clip hosts.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Effects collector")
struct FCPXMLEffectsCollectorTests {
    private typealias EffectsCollector = FinalCutPro.FCPXML.EffectsCollector
    private typealias ExtractedElement = FinalCutPro.FCPXML.ExtractedElement
    private typealias ExtractedEffect = FinalCutPro.FCPXML.ExtractedEffect

    @Test("Effects on asset clip collects filter video and audio")
    func effectsOnAssetClipCollectsFilterVideoAndAudio() throws {
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

        let hasBlur = effects.contains { $0.kind == .filterVideo && $0.name == "Blur" }
        let hasEQ = effects.contains { $0.kind == .filterAudio && $0.name == "EQ" }
        #expect(hasBlur)
        #expect(hasEQ)
    }

    @Test("Effects on asset clip volume without amount emits empty and zero decibel rows")
    func effectsOnAssetClipVolumeWithoutAmountEmitsEmptyAndZeroDecibelRows() throws {
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

        #expect(volumeEffects.count == 2)
        let hasEmpty = volumeEffects.contains { $0.settings == .empty && $0.sortOrder == 0 }
        let hasZeroDecibel = volumeEffects.contains {
            if case .decibels(0) = $0.settings { return $0.sortOrder == 1 }
            return false
        }
        #expect(hasEmpty)
        #expect(hasZeroDecibel)
    }

    @Test("Effects on asset clip volume with amount emits single decibel row")
    func effectsOnAssetClipVolumeWithAmountEmitsSingleDecibelRow() throws {
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

        #expect(volumeEffects.count == 1)
        if case .decibels(let amount) = volumeEffects[0].settings {
            #expect(abs(amount - 12) < 0.001)
        } else {
            Issue.record("Expected decibel volume settings")
        }
    }

    @Test("Effects on disabled asset clip with audio emits implicit volume")
    func effectsOnDisabledAssetClipWithAudioEmitsImplicitVolume() throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")
        let disabledClip = try #require(
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
        #expect(implicitVolume != nil)
        #expect(implicitVolume?.settings == .empty)
    }

    @Test("Effects on title collects adjust-blend as compositing")
    func effectsOnTitleCollectsAdjustBlendAsCompositing() throws {
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

        #expect(compositing.count == 1)
        #expect(compositing[0].name == "Compositing")
        if case .opacityPercent(let amount) = compositing[0].settings {
            #expect(abs(amount - 0.3) < 0.001)
        } else {
            Issue.record("Expected opacity percent settings")
        }
    }

    @Test("Effects on title collects three transform rows in sort order")
    func effectsOnTitleCollectsThreeTransformRowsInSortOrder() throws {
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

        #expect(transforms.count == 3)
        #expect(transforms.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("Effects collector isEffectEnabled respects effect element enabled")
    func effectsCollectorIsEffectEnabledRespectsEffectElementEnabled() throws {
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

        let hostElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        let filter = try #require(hostElement.firstChildElement(named: "filter-video"))

        #expect(!EffectsCollector.isEffectEnabled(effectElement: filter, host: hostElement))
    }

    @Test("Effects collector isEffectEnabled falls back to host enabled")
    func effectsCollectorIsEffectEnabledFallsBackToHostEnabled() throws {
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

        let hostElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "asset-clip")
        )
        let filter = try #require(hostElement.firstChildElement(named: "filter-video"))

        #expect(!EffectsCollector.isEffectEnabled(effectElement: filter, host: hostElement))
    }

    @Test("Effects extraction preset returns only supported host types")
    func effectsExtractionPresetReturnsOnlySupportedHostTypes() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "TimelineSample")
        let effects = await timeline.fcpExtract(preset: .effects)

        let hostTypes = Set(
            effects.map { $0.host.element.fcpElementType }.compactMap { $0 }
        )

        #expect(!effects.isEmpty)
        #expect(hostTypes.isSubset(of: [.title, .assetClip, .syncClip]))
    }

    private func makeExtractedHost(
        from fcpxml: FinalCutPro.FCPXML,
        elementName: String
    ) throws -> ExtractedElement {
        let element = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: elementName)
        )
        return ExtractedElement(
            element: element,
            breadcrumbs: [],
            resources: fcpxml.root.resources
        )
    }
}
