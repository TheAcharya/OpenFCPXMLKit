//
//  FCPXMLEffectsReportPolicyTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for effects report inclusion policy.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLEffectsReportPolicyTests: XCTestCase {
    private typealias EffectsReportPolicy = FinalCutPro.FCPXML.EffectsReportPolicy
    private typealias ExtractedEffect = FinalCutPro.FCPXML.ExtractedEffect
    
    func testShouldIncludeNonFilterVideoEffectsAlwaysTrue() throws {
        let host = try makeExtractedHost(from: parseInlineFCPXML(minimalTimeline()), elementName: "asset-clip")
        
        let kinds: [ExtractedEffect.Kind] = [
            .volume, .implicitVolume, .transform, .compositing, .spatialConform, .filterAudio
        ]
        
        for kind in kinds {
            let effect = makeExtractedEffect(name: "Effect", kind: kind, host: host)
            XCTAssertTrue(EffectsReportPolicy.shouldInclude(effect), "Expected \(kind) to be included")
        }
    }
    
    func testShouldIncludeFilterVideoByDefault() throws {
        let host = try makeExtractedHost(from: parseInlineFCPXML(minimalTimeline()), elementName: "asset-clip")
        
        for name in ["Custom Vendor Filter", "Cross Dissolve", "Timecode", "Shape Mask"] {
            let effect = makeExtractedEffect(name: name, host: host)
            XCTAssertTrue(EffectsReportPolicy.shouldInclude(effect), "Expected \(name) to be included")
        }
    }
    
    func testShouldExcludeFilterVideoWhenHostIsOccluded() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        let hosts = await timeline.fcpExtract(
            types: [.assetClip, .title],
            scope: .reportMainTimelineVisible()
        )
        
        let occludedHost = try XCTUnwrap(
            hosts.first { $0.value(forContext: .effectiveOcclusion) != .notOccluded }
        )
        let effect = makeExtractedEffect(name: "Any Filter", host: occludedHost)
        
        XCTAssertFalse(EffectsReportPolicy.shouldInclude(effect))
    }
    
    func testExtractedEffectsFilteredByPolicyOnTimeline() async throws {
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
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip offset="0s" name="Clip" duration="10s" format="r1" audioRole="dialogue">
                                    <filter-video name="Cross Dissolve"/>
                                    <adjust-volume amount="0dB"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "sequence")
        )
        let effects = await timeline.fcpExtract(preset: .effects)
        let crossDissolve = try XCTUnwrap(
            effects.first { $0.kind == .filterVideo && $0.name == "Cross Dissolve" }
        )
        let volume = try XCTUnwrap(effects.first { $0.kind == .volume })
        
        XCTAssertTrue(EffectsReportPolicy.shouldInclude(crossDissolve))
        XCTAssertTrue(EffectsReportPolicy.shouldInclude(volume))
    }
    
    private func minimalTimeline() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip offset="0s" name="Clip" duration="10s" format="r1" audioRole="dialogue"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
}
