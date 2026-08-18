//
//  FCPXMLTransformAdjustmentParsingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for parsing adjust-transform XML into TransformAdjustment.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Transform adjustment parsing")
struct FCPXMLTransformAdjustmentParsingTests {
    private typealias TransformAdjustment = FinalCutPro.FCPXML.TransformAdjustment

    @Test("TransformAdjustment from adjust element parses all attributes")
    func transformAdjustmentFromAdjustElementParsesAllAttributes() {
        let element = makeAdjustTransformElement(
            position: "100 200",
            scale: "1.5 1.5",
            rotation: "45",
            anchor: "50 50",
            enabled: "0"
        )

        let adjustment = TransformAdjustment(from: element)

        #expect(adjustment.position.x == 100)
        #expect(adjustment.position.y == 200)
        #expect(adjustment.scale.x == 1.5)
        #expect(adjustment.scale.y == 1.5)
        #expect(adjustment.rotation == 45)
        #expect(adjustment.anchor.x == 50)
        #expect(adjustment.anchor.y == 50)
        let isEnabled = adjustment.isEnabled
        #expect(!isEnabled)
    }

    @Test("TransformAdjustment from adjust element uses defaults for missing attributes")
    func transformAdjustmentFromAdjustElementUsesDefaultsForMissingAttributes() {
        let element = makeAdjustTransformElement()

        let adjustment = TransformAdjustment(from: element)

        #expect(adjustment.position == .zero)
        #expect(adjustment.scale == FinalCutPro.FCPXML.Point(x: 1, y: 1))
        #expect(adjustment.rotation == 0)
        #expect(adjustment.anchor == .zero)
        #expect(adjustment.isEnabled)
    }

    @Test("Clip transformAdjustment getter matches from initializer")
    func clipTransformAdjustmentGetterMatchesFromInitializer() throws {
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
                                <clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <adjust-transform position="10 20" scale="2 2" rotation="90"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let clipElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        let transformElement = try #require(
            clipElement.firstChildElement(named: "adjust-transform")
        )
        let parsed = TransformAdjustment(from: transformElement)
        let clip = try #require(clipElement.fcpAsClip)

        #expect(clip.transformAdjustment == parsed)
    }

    @Test("Photoshop sample parses non-default transform position")
    func photoshopSampleParsesNonDefaultTransformPosition() throws {
        let fcpxml = try requireFCPXMLSample(named: "PhotoshopSample1")

        guard let transformElement = firstDescendantElement(
            in: fcpxml.root.element,
            named: "adjust-transform"
        ) else {
            try Test.cancel("PhotoshopSample1 has no adjust-transform")
        }

        let adjustment = TransformAdjustment(from: transformElement)

        let xMatch = abs(adjustment.position.x - (-25.463)) < 0.001
        let yMatch = abs(adjustment.position.y - 4.81481) < 0.001
        #expect(xMatch)
        #expect(yMatch)
    }
    
    @Test("Component samples include explicit attributes only")
    func componentSamplesIncludeExplicitAttributesOnly() {
        let element = makeAdjustTransformElement(
            position: "0 4.83871",
            scale: "1.71 1.71"
        )
        
        let samples = TransformAdjustment.componentSamples(from: element)
        
        #expect(samples.positions.count == 1)
        #expect(abs(samples.positions[0].x) < 0.001)
        #expect(abs(samples.positions[0].y - 4.83871) < 0.001)
        #expect(samples.scales.count == 1)
        #expect(abs(samples.scales[0].x - 1.71) < 0.001)
        #expect(samples.rotations.isEmpty)
    }
    
    @Test("Component samples omit synthesized identity when attributes are missing")
    func componentSamplesOmitSynthesizedIdentityWhenAttributesAreMissing() {
        let element = makeAdjustTransformElement()
        let samples = TransformAdjustment.componentSamples(from: element)
        
        #expect(samples.positions.isEmpty)
        #expect(samples.rotations.isEmpty)
        #expect(samples.scales.isEmpty)
    }
    
    @Test("Component samples read scale and split position keyframes")
    func componentSamplesReadScaleAndSplitPositionKeyframes() throws {
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
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <asset-clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <adjust-transform>
                                        <param name="position">
                                            <param name="X" key="1">
                                                <keyframeAnimation>
                                                    <keyframe time="0s" value="34.6237"/>
                                                    <keyframe time="5s" value="0"/>
                                                </keyframeAnimation>
                                            </param>
                                            <param name="Y" key="2">
                                                <keyframeAnimation>
                                                    <keyframe time="0s" value="-16.6667"/>
                                                    <keyframe time="5s" value="0"/>
                                                </keyframeAnimation>
                                            </param>
                                        </param>
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
        
        let transformElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "adjust-transform")
        )
        let samples = TransformAdjustment.componentSamples(from: transformElement)
        
        #expect(samples.scales.count == 2)
        #expect(abs(samples.scales[0].x - 2.44) < 0.001)
        #expect(abs(samples.scales[1].x - 1) < 0.001)
        
        let hasAnimatedPosition = samples.positions.contains {
            abs($0.x - 34.6237) < 0.001 && abs($0.y - (-16.6667)) < 0.001
        }
        #expect(hasAnimatedPosition)
    }

    private func makeAdjustTransformElement(
        position: String? = nil,
        scale: String? = nil,
        rotation: String? = nil,
        anchor: String? = nil,
        enabled: String? = nil
    ) -> any OFKXMLElement {
        let element = OFKXMLDefaultFactory().makeElement(name: "adjust-transform")

        if let position { element.addAttribute(name: "position", value: position) }
        if let scale { element.addAttribute(name: "scale", value: scale) }
        if let rotation { element.addAttribute(name: "rotation", value: rotation) }
        if let anchor { element.addAttribute(name: "anchor", value: anchor) }
        if let enabled { element.addAttribute(name: "enabled", value: enabled) }

        return element
    }
}

