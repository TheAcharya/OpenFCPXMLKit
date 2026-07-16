//
// FCPXMLProjectionCoverageTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Projection geometry: annotations, per-src, nested retiming, sync-in-mc, PSD, Summary occupancy.
//

import XCTest
import SwiftTimecode
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLProjectionCoverageTests: XCTestCase {
    private let projector = FinalCutPro.FCPXML.TimelineProjector()

    // MARK: - Annotations

    func testAnnotationsEmptyByDefault() async throws {
        let fcpxml = try parseInlineFCPXML(simpleAssetClipXML)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        XCTAssertFalse(windows.isEmpty)
        XCTAssertTrue(windows.allSatisfy { $0.roles.isEmpty && $0.effects.isEmpty && $0.breadcrumbs.isEmpty })
    }

    func testAnnotationsPopulatedWhenEnabled() async throws {
        let fcpxml = try parseInlineFCPXML(simpleAssetClipWithVolumeXML)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: options)
        XCTAssertFalse(windows.isEmpty)
        XCTAssertTrue(windows.contains { !$0.breadcrumbs.isEmpty })
        XCTAssertTrue(windows.contains { $0.effects.contains { $0.kind == .volume } })
        XCTAssertTrue(windows.contains { window in
            window.channel.kind == .audio && window.roles.contains { $0.isAudio }
        })
    }

    // MARK: - Per-src expansion

    func testExpandAllSourceChannelsFalseEmitsPrimarySrcOnly() async throws {
        let fcpxml = try parseInlineFCPXML(multiAudioSourceXML)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)

        var all = FinalCutPro.FCPXML.TimelineProjectionOptions()
        all.expandAllSourceChannels = true
        let expanded = try await projector.project(from: source, fcpxml: fcpxml, options: all)

        var primary = FinalCutPro.FCPXML.TimelineProjectionOptions()
        primary.expandAllSourceChannels = false
        let collapsed = try await projector.project(from: source, fcpxml: fcpxml, options: primary)

        let expandedAudio = expanded.filter { $0.channel.kind == .audio }
        let collapsedAudio = collapsed.filter { $0.channel.kind == .audio }
        XCTAssertGreaterThanOrEqual(expandedAudio.count, 2)
        XCTAssertEqual(Set(expandedAudio.map(\.channel.sourceIndex)), Set([1, 2]))
        XCTAssertEqual(collapsedAudio.count, 1)
        XCTAssertEqual(collapsedAudio.first?.channel.sourceIndex, 1)
    }

    // MARK: - Nested retiming composition

    func testRetimingSegmentComposingParentAndChild() throws {
        let parent = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(0, 1),
            timelineEnd: Fraction(5, 1),
            mediaStart: Fraction(0, 1),
            mediaEnd: Fraction(10, 1),
            scale: 0.5,
            isReversed: false
        )
        let child = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(2, 1),
            timelineEnd: Fraction(6, 1),
            mediaStart: Fraction(100, 1),
            mediaEnd: Fraction(104, 1),
            scale: 1,
            isReversed: false
        )
        let composed = FinalCutPro.FCPXML.RetimingSegment.composing(parent: parent, child: child)
        XCTAssertEqual(composed.count, 1)
        let segment = try XCTUnwrap(composed.first)
        // Overlap in parent media [2,6) → outer timeline [1,3) at 0.5x
        XCTAssertEqual(segment.timelineStart.doubleValue, 1, accuracy: 0.001)
        XCTAssertEqual(segment.timelineEnd.doubleValue, 3, accuracy: 0.001)
        XCTAssertEqual(segment.scale, 0.5, accuracy: 0.001)
    }

    func testRetimingSegmentComposingReverseXOR() throws {
        let parent = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(0, 1),
            timelineEnd: Fraction(4, 1),
            mediaStart: Fraction(4, 1),
            mediaEnd: Fraction(0, 1),
            scale: 1,
            isReversed: true
        )
        let child = FinalCutPro.FCPXML.RetimingSegment(
            timelineStart: Fraction(1, 1),
            timelineEnd: Fraction(3, 1),
            mediaStart: Fraction(10, 1),
            mediaEnd: Fraction(12, 1),
            scale: 1,
            isReversed: false
        )
        let composed = FinalCutPro.FCPXML.RetimingSegment.composing(parent: parent, child: child)
        XCTAssertEqual(composed.count, 1)
        XCTAssertTrue(try XCTUnwrap(composed.first).isReversed)
    }

    func testNestedRefClipTimeMapComposesInnerIdentity() async throws {
        let fcpxml = try parseInlineFCPXML(nestedRefClipWithOuterTimeMapXML)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        let video = windows.filter { $0.channel.kind == .video }
        XCTAssertFalse(video.isEmpty)
        // Outer 2x map over 4s timeline reading 8s media → inner full clip should compress.
        XCTAssertTrue(video.contains { abs($0.retiming.scale - 2) < 0.05 || $0.timelineOut.doubleValue <= 4.1 })
    }

    // MARK: - Sync-in-multicam + multi-channel audio

    func testSyncInsideMulticamEmitsVideoAndMultiChannelAudio() async throws {
        let fcpxml = try parseInlineFCPXML(syncInMulticamXML)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        XCTAssertTrue(windows.contains { $0.channel.kind == .video })
        let audio = windows.filter { $0.channel.kind == .audio }
        XCTAssertGreaterThanOrEqual(audio.count, 2)
        XCTAssertEqual(Set(audio.map(\.channel.sourceIndex)).count, audio.count)
    }

    // MARK: - Photoshop multi-layer

    func testPhotoshopSample1EmitsMultipleVideoSources() async throws {
        let fcpxml = try loadFCPXMLSample(named: "PhotoshopSample1")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        let video = windows.filter { $0.channel.kind == .video }
        let indices = Set(video.map(\.channel.sourceIndex))
        XCTAssertTrue(indices.isSuperset(of: [1, 2, 3]), "Expected src 1–3, got \(indices)")
        XCTAssertTrue(video.contains { ($0.channel.nativeDuration?.doubleValue ?? -1) == 0 })
    }

    // MARK: - Summary overlap-aware

    func testSummaryOverlapAwareUsesUnionLessThanSum() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="100s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)

        let components: [FinalCutPro.FCPXML.RoleInventoryClipComponent] = [
            .init(
                roleSubroleField: "Dialogue",
                category: .primaryAudio,
                durationSeconds: 4,
                timelineStartSeconds: 0,
                timelineEndSeconds: 4
            ),
            .init(
                roleSubroleField: "Dialogue",
                category: .connectedAudio,
                durationSeconds: 4,
                timelineStartSeconds: 2,
                timelineEndSeconds: 6
            )
        ]

        let summedRows = FinalCutPro.FCPXML.SummaryRoleDurationAggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources,
            overlapAware: false
        )
        let unionedRows = FinalCutPro.FCPXML.SummaryRoleDurationAggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources,
            overlapAware: true
        )

        let sumDialogue = try XCTUnwrap(summedRows.first { $0.roleSubrole == "Dialogue" })
        let unionDialogue = try XCTUnwrap(unionedRows.first { $0.roleSubrole == "Dialogue" })
        XCTAssertEqual(sumDialogue.percentOfTotal, 0.08, accuracy: 0.0001)
        XCTAssertEqual(unionDialogue.percentOfTotal, 0.06, accuracy: 0.0001)
        XCTAssertLessThan(unionDialogue.percentOfTotal, sumDialogue.percentOfTotal)
    }

    // MARK: - Fixtures

    private var simpleAssetClipXML: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="ClipA" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine><asset-clip ref="r2" offset="0s" name="ClipA" duration="5s" audioRole="dialogue"/></spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
    }

    private var simpleAssetClipWithVolumeXML: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="ClipA" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine>
                        <asset-clip ref="r2" offset="0s" name="ClipA" duration="5s" audioRole="dialogue">
                            <adjust-volume amount="-3dB"/>
                        </asset-clip>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
    }

    private var multiAudioSourceXML: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Multi" hasVideo="1" hasAudio="1" videoSources="1" audioSources="2" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/m.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine><asset-clip ref="r2" offset="0s" name="Multi" duration="5s"/></spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
    }

    private var nestedRefClipWithOuterTimeMapXML: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Inner" hasVideo="1" videoSources="1" duration="20s">
                    <media-rep kind="original-media" src="file:///tmp/inner.mov"/>
                </asset>
                <media id="r3" name="Comp">
                    <sequence format="r1" duration="8s" tcStart="0s">
                        <spine>
                            <asset-clip ref="r2" offset="0s" name="Inner" duration="8s"/>
                        </spine>
                    </sequence>
                </media>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="4s" tcStart="0s">
                    <spine>
                        <ref-clip ref="r3" offset="0s" name="Comp" duration="4s">
                            <timeMap>
                                <timept time="0s" value="0s" interp="smooth"/>
                                <timept time="4s" value="8s" interp="smooth"/>
                            </timeMap>
                        </ref-clip>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
    }

    private var syncInMulticamXML: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Cam" hasVideo="1" hasAudio="1" videoSources="1" audioSources="2" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/cam.mov"/>
                </asset>
                <media id="r3" name="MC">
                    <multicam format="r1" tcStart="0s" tcFormat="NDF">
                        <mc-angle name="A" angleID="A">
                            <sync-clip offset="0s" name="Sync" duration="5s" tcFormat="NDF">
                                <video ref="r2" offset="0s" name="V" duration="5s"/>
                                <audio ref="r2" offset="0s" name="A1" duration="5s" srcID="1"/>
                                <audio ref="r2" lane="-1" offset="0s" name="A2" duration="5s" srcID="2"/>
                            </sync-clip>
                        </mc-angle>
                    </multicam>
                </media>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine>
                        <mc-clip ref="r3" offset="0s" name="MC" duration="5s">
                            <mc-source angleID="A" srcEnable="all"/>
                        </mc-clip>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
    }

    private var overlappingSameRoleXML: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" hasAudio="1" audioSources="1" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="6s" tcStart="0s">
                    <spine>
                        <asset-clip ref="r2" offset="0s" name="One" duration="4s" audioRole="dialogue"/>
                        <asset-clip ref="r2" lane="-1" offset="2s" name="Two" duration="4s" audioRole="dialogue"/>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
    }
}
