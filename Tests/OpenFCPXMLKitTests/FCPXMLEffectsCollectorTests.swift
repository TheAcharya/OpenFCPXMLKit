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
        if case .transformCenter(let position) = transforms[0].settings {
            #expect(abs(position.x - 10) < 0.001)
            #expect(abs(position.y - 20) < 0.001)
        } else {
            Issue.record("Expected position transform settings first")
        }
        if case .transformRotation(let rotation) = transforms[1].settings {
            #expect(abs(rotation - 45) < 0.001)
        } else {
            Issue.record("Expected rotation transform settings second")
        }
        if case .transformScale(let scale) = transforms[2].settings {
            #expect(abs(scale.x - 1.5) < 0.001)
            #expect(abs(scale.y - 1.5) < 0.001)
        } else {
            Issue.record("Expected scale transform settings third")
        }
    }
    
    @Test("Identity-only transform emits no transform rows")
    func identityOnlyTransformEmitsNoTransformRows() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <adjust-transform/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "asset-clip")
        let transforms = EffectsCollector.effects(on: host).filter { $0.kind == .transform }
        #expect(transforms.isEmpty)
    }
    
    @Test("Keyframed transform scale emits non-identity samples only")
    func keyframedTransformScaleEmitsNonIdentitySamplesOnly() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <adjust-transform>
                                        <param name="scale">
                                            <keyframeAnimation>
                                                <keyframe time="0s" value="2.44 2.44"/>
                                                <keyframe time="5s" value="1 1"/>
                                            </keyframeAnimation>
                                        </param>
                                    </adjust-transform>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "asset-clip")
        let transforms = EffectsCollector.effects(on: host).filter { $0.kind == .transform }
        
        #expect(transforms.count == 1)
        if case .transformScale(let scale) = transforms[0].settings {
            #expect(abs(scale.x - 2.44) < 0.001)
            #expect(abs(scale.y - 2.44) < 0.001)
        } else {
            Issue.record("Expected keyframed non-identity scale")
        }
    }
    
    @Test("Clip host with static transform position is collected")
    func clipHostWithStaticTransformPositionIsCollected() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Shot" uid="A1" start="0s" duration="5s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Wrapper" duration="5s" format="r1">
                                    <adjust-transform position="0 4.83871"/>
                                    <video ref="r2" offset="0s" duration="5s"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "clip")
        let transforms = EffectsCollector.effects(on: host).filter { $0.kind == .transform }
        
        #expect(transforms.count == 1)
        if case .transformCenter(let position) = transforms[0].settings {
            #expect(abs(position.x) < 0.001)
            #expect(abs(position.y - 4.83871) < 0.001)
        } else {
            Issue.record("Expected clip-host transform position")
        }
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
        #expect(hostTypes.isSubset(of: EffectsCollector.extractedEffectHostTypes))
        #expect(EffectsCollector.extractedEffectHostTypes.contains(.clip))
        #expect(EffectsCollector.extractedEffectHostTypes.contains(.video))
    }
    
    @Test("Report uses FCP opacity percent and clip-host transform settings")
    func reportUsesFCPOpacityPercentAndClipHostTransformSettings() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Shot" uid="A1" start="0s" duration="5s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Blend Clip" duration="5s" format="r1">
                                    <adjust-blend amount="0.3987"/>
                                    <adjust-conform type="fill"/>
                                </asset-clip>
                                <clip offset="5s" name="Resize Clip" duration="5s" format="r1">
                                    <adjust-transform position="0 4.83871" scale="1.71 1.71"/>
                                    <video ref="r2" offset="0s" duration="5s"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.includeEffects = true
        let report = try await fcpxml.buildReport(options: options)
        
        let effectRows = try #require(report.effects?.rows)
        let opacityRow = try #require(effectRows.first { $0.effect == "Compositing" })
        #expect(opacityRow.settings == "Opacity 39.9%")
        
        let transformRows = effectRows.filter {
            $0.effect == "Transform" && $0.clipName == "Resize Clip"
        }
        #expect(transformRows.contains { $0.settings == "Position 0.0 px, 4.8 px" })
        #expect(transformRows.contains { $0.settings.hasPrefix("Scale 171.0%") })
        #expect(!transformRows.contains { $0.settings.contains("Rotation 0.0") })
        
        let inventory = try #require(report.roleInventory)
        let blendInventory = try #require(
            inventory.selectedRoles.first { $0.clipName == "Blend Clip" }
        )
        #expect(blendInventory.effects.contains("Compositing (Opacity 39.9%)"))
        #expect(blendInventory.effects.contains("Spatial Conform (Fill)"))
        
        let resizeInventory = try #require(
            inventory.selectedRoles.first { $0.clipName == "Resize Clip" }
        )
        #expect(resizeInventory.effects.contains("Transform (Position 0.0 px, 4.8 px; Scale 171.0%)"))
    }
    
    @Test("Filter inspector params skip Motion blobs and empty names")
    func filterInspectorParamsSkipMotionBlobsAndEmptyNames() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <effect id="r3" name="Color Adjustments" uid=".../Effects.localized/Color.localized/Color Adjustments.motn"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <filter-video ref="r3" name="Color Adjustments">
                                        <param name="Control Range" value="0 (SDR)"/>
                                        <param name="" value="PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4="/>
                                        <param name="Neutralization Data" value="PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4="/>
                                        <param name="Exposure" value="34"/>
                                        <param name="Brightness" value="29"/>
                                        <param name="Highlights" value="8.00364"/>
                                        <param name="Black Point" value="-4.00055"/>
                                    </filter-video>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "asset-clip")
        let filter = try #require(
            EffectsCollector.effects(on: host).first { $0.name == "Color Adjustments" }
        )
        #expect(filter.isAppleSupplied)
        guard case .namedValues(let pairs) = filter.settings else {
            Issue.record("Expected named inspector values")
            return
        }
        let names = pairs.map(\.name)
        #expect(names == [
            "Control Range",
            "Exposure",
            "Brightness",
            "Highlights",
            "Black Point"
        ])
        #expect(pairs.contains { $0.name == "Control Range" && $0.value == "0 (SDR)" })
        #expect(pairs.contains { $0.name == "Highlights" && $0.value == "8.00364" })
        #expect(!pairs.contains { $0.value.contains("PD94") })
    }
    
    @Test("Draw Mask nested Position is collected and vertex values are omitted")
    func drawMaskNestedPositionIsCollectedAndVertexValuesAreOmitted() throws {
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
                                <clip offset="0s" name="Masked" duration="5s" format="r1">
                                    <filter-video name="Draw Mask">
                                        <param name="Shape Type" value="0 (Linear)"/>
                                        <param name="Invert Mask" value="1"/>
                                        <param name="Transforms">
                                            <param name="Position" value="217.606 46.7851"/>
                                        </param>
                                        <param name="Animation" value="0">
                                            <param name="Vertex Point">
                                                <param name="Vertex">
                                                    <param name="Value" value="-79.6446"/>
                                                </param>
                                            </param>
                                        </param>
                                    </filter-video>
                                    <filter-video name="Green Screen Keyer">
                                        <data key="effectData">PD94bWwgdmVyc2lvbj0iMS4wIg==</data>
                                    </filter-video>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let host = try makeExtractedHost(from: fcpxml, elementName: "clip")
        let effects = EffectsCollector.effects(on: host)
        
        let drawMask = try #require(effects.first { $0.name == "Draw Mask" })
        guard case .namedValues(let pairs) = drawMask.settings else {
            Issue.record("Expected Draw Mask inspector values")
            return
        }
        #expect(pairs.contains { $0.name == "Invert Mask" && $0.value == "1" })
        #expect(pairs.contains { $0.name == "Position" && $0.value == "217.606 46.7851" })
        #expect(!pairs.contains { $0.name == "Value" })
        #expect(!pairs.contains { $0.value == "-79.6446" })
        
        let keyer = try #require(effects.first { $0.name == "Green Screen Keyer" })
        #expect(keyer.settings == .empty)
        #expect(!keyer.isAppleSupplied)
    }
    
    @Test("Filter-video-mask inner filter and blend mode are collected")
    func filterVideoMaskInnerFilterAndBlendModeAreCollected() throws {
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
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <filter-video-mask>
                                        <filter-video name="Color Board">
                                            <param name="Exposure" value="10"/>
                                        </filter-video>
                                    </filter-video-mask>
                                    <adjust-blend mode="multiply"/>
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
        
        let masked = try #require(effects.first { $0.name == "Color Board" })
        #expect(masked.kind == .filterVideo)
        guard case .namedValues(let pairs) = masked.settings else {
            Issue.record("Expected Color Board inspector values")
            return
        }
        #expect(pairs == [ExtractedEffect.NamedValue(name: "Exposure", value: "10")])
        
        let compositing = effects.filter { $0.kind == .compositing }
        #expect(compositing.count == 1)
        guard case .namedValues(let blendPairs) = compositing[0].settings else {
            Issue.record("Expected blend mode named values")
            return
        }
        #expect(blendPairs == [ExtractedEffect.NamedValue(name: "Blend Mode", value: "multiply")])
    }
    
    @Test("Report filter settings use inspector values not duplicated names")
    func reportFilterSettingsUseInspectorValuesNotDuplicatedNames() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Shot" uid="A1" start="0s" duration="5s" hasVideo="1" format="r1" videoSources="1"/>
                <effect id="r3" name="Color Adjustments" uid=".../Effects.localized/Color.localized/Color Adjustments.motn"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Grade Clip" duration="5s" format="r1">
                                    <filter-video ref="r3" name="Color Adjustments">
                                        <param name="Exposure" value="34"/>
                                        <param name="Brightness" value="29"/>
                                    </filter-video>
                                    <video ref="r2" offset="0s" duration="5s"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.includeEffects = true
        let report = try await fcpxml.buildReport(options: options)
        
        let effectRow = try #require(
            report.effects?.rows.first { $0.effect == "Color Adjustments" }
        )
        #expect(effectRow.settings == "Exposure 34; Brightness 29")
        #expect(effectRow.settings != "Color Adjustments")
        #expect(effectRow.isApple == "✓")
        
        let inventory = try #require(
            report.roleInventory?.selectedRoles.first { $0.clipName == "Grade Clip" }
        )
        #expect(inventory.effects.contains("Color Adjustments (Exposure 34; Brightness 29)"))
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

