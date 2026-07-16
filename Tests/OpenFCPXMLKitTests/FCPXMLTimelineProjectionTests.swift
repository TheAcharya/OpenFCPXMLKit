//
//  FCPXMLTimelineProjectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Tests for TimelineProjection: identity, timeMap, nested lanes, multicam/ref/audition, report consume + occupancy.
//

import XCTest
import SwiftTimecode
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTimelineProjectionTests: XCTestCase {

    private let projector = FinalCutPro.FCPXML.TimelineProjector()

    // MARK: - Inline identity asset-clip

    func testProject_SimpleAssetClip_EmitsVideoAndAudioIdentityWindows() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="ClipA" start="10s" duration="60s" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" audioChannels="2" audioRate="48000">
                        <media-rep kind="original-media" src="file:///tmp/ClipA.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="Event">
                        <project name="Project">
                            <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF">
                                <spine>
                                    <asset-clip ref="r2" offset="2s" name="ClipA On Timeline" start="10s" duration="5s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let sources = fcpxml.allReportTimelineSources()
        XCTAssertEqual(sources.count, 1)

        let windows = try await projector.project(
            from: sources[0],
            fcpxml: fcpxml,
            options: .init()
        )

        XCTAssertEqual(windows.count, 2)

        let video = try XCTUnwrap(windows.first { $0.channel.kind == .video })
        let audio = try XCTUnwrap(windows.first { $0.channel.kind == .audio })

        XCTAssertEqual(video.channel.resourceID, "r2")
        XCTAssertEqual(video.channel.sourceIndex, 1)
        XCTAssertEqual(video.channel.originalMediaURL?.path, "/tmp/ClipA.mov")
        XCTAssertEqual(video.clipDisplayName, "ClipA On Timeline")
        XCTAssertEqual(video.lanePath, .primary)
        XCTAssertEqual(video.timelineIn, Fraction(2, 1))
        XCTAssertEqual(video.timelineOut, Fraction(7, 1))
        XCTAssertEqual(video.mediaIn, Fraction(10, 1))
        XCTAssertEqual(video.mediaOut, Fraction(15, 1))
        XCTAssertEqual(video.retiming.scale, 1)
        XCTAssertFalse(video.retiming.isReversed)

        XCTAssertEqual(audio.channel.resourceID, "r2")
        XCTAssertEqual(audio.timelineIn, video.timelineIn)
        XCTAssertEqual(audio.timelineOut, video.timelineOut)
        XCTAssertEqual(audio.mediaIn, video.mediaIn)
        XCTAssertEqual(audio.mediaOut, video.mediaOut)
    }

    func testProject_DisabledAssetClip_OmittedWhenIncludeDisabledFalse() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="ClipA" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="Event">
                        <project name="Project">
                            <sequence format="r1" duration="5s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="On" duration="5s"/>
                                    <asset-clip ref="r2" offset="5s" name="Off" duration="5s" enabled="0"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)

        let included = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeDisabled: true)
        )
        XCTAssertEqual(included.count, 2)
        XCTAssertEqual(Set(included.map(\.clipDisplayName)), Set(["On", "Off"]))

        let visibleOnly = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )
        XCTAssertEqual(visibleOnly.count, 1)
        XCTAssertEqual(visibleOnly.first?.clipDisplayName, "On")
    }

    func testProject_AudioOnlySample_EmitsAudioWindowsForSpineClips() async throws {
        let fcpxml = try loadFCPXMLSample(named: "AudioOnly")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)

        let windows = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )

        // Walks primary spine + anchored lane children (3 Forest Day + 2 Water Lake).
        XCTAssertEqual(windows.count, 5)
        XCTAssertTrue(windows.allSatisfy { $0.channel.kind == .audio })
        XCTAssertEqual(windows.filter { $0.lanePath == .primary }.count, 3)
        XCTAssertEqual(windows.filter { $0.lanePath.components == [-1] }.count, 2)
        XCTAssertTrue(windows.allSatisfy { $0.retiming.scale == 1 })
        XCTAssertEqual(windows[0].clipDisplayName, "Forest Day")
        XCTAssertEqual(windows[0].timelineIn, .zero)

        let waterLake = windows.filter { $0.clipDisplayName == "Water Lake 3" }
        XCTAssertEqual(waterLake.count, 2)
        XCTAssertEqual(waterLake[0].timelineIn, .zero)
        XCTAssertGreaterThan(waterLake[1].timelineIn.doubleValue, 0)
    }

    func testProject_StreamingCallback_MatchesCollect() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" hasVideo="1" videoSources="1" duration="4s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="4s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" duration="2s"/>
                                    <asset-clip ref="r2" offset="2s" duration="2s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)

        let collected = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        var streamed: [FinalCutPro.FCPXML.MediaUsageWindow] = []
        try await projector.project(from: source, fcpxml: fcpxml, options: .init()) { window in
            streamed.append(window)
        }

        XCTAssertEqual(streamed, collected)
        XCTAssertEqual(collected.count, 2)
    }

    func testProjectTimeline_Convenience_UsesFirstSource() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" hasAudio="1" audioSources="1" duration="3s">
                        <media-rep kind="original-media" src="file:///tmp/a.caf"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="3s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="1s" name="A" duration="2s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let windows = try await fcpxml.projectTimeline(options: .mainTimeline)
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows[0].timelineIn, Fraction(1, 1))
        XCTAssertEqual(windows[0].timelineOut, Fraction(3, 1))
    }

    // MARK: - timeMap retiming

    func testProject_TimeMapTwoPoints_EmitsScaledIdentityOccupancy() async throws {
        // Map span is 10s locally; clip duration is 5s → normalize onto [2s, 7s).
        // Media 0→20s over remapped 0→10s → scale 2.0
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="ClipA" hasVideo="1" videoSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="20s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="2s" name="Retime" start="0s" duration="5s">
                                        <timeMap>
                                            <timept time="0s" value="0s" interp="linear"/>
                                            <timept time="10s" value="20s" interp="linear"/>
                                        </timeMap>
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        XCTAssertEqual(windows.count, 1)
        let window = windows[0]
        XCTAssertEqual(window.timelineIn.doubleValue, 2, accuracy: 0.000_1)
        XCTAssertEqual(window.timelineOut.doubleValue, 7, accuracy: 0.000_1)
        XCTAssertEqual(window.mediaIn.doubleValue, 0, accuracy: 0.000_1)
        XCTAssertEqual(window.mediaOut.doubleValue, 20, accuracy: 0.000_1)
        XCTAssertEqual(window.retiming.scale, 2, accuracy: 0.000_1)
        XCTAssertFalse(window.retiming.isReversed)
    }

    func testProject_TimeMapReverse_SetsIsReversedAndNegativeSpeedMagnitude() async throws {
        // Same reverse map as SpeedChangeFormattingTests (-100%).
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2500s" width="1920" height="1080"/>
                    <asset id="r2" hasVideo="1" videoSources="1" duration="100s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="100s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="Reverse" duration="146100/2500s">
                                        <timeMap>
                                            <timept time="158445100/2500s" value="158591200/2500s" interp="smooth2"/>
                                            <timept time="158591200/2500s" value="158445100/2500s" interp="smooth2"/>
                                        </timeMap>
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        XCTAssertEqual(windows.count, 1)
        let retiming = windows[0].retiming
        XCTAssertTrue(retiming.isReversed)
        XCTAssertEqual(retiming.scale, 1, accuracy: 0.001)
        XCTAssertGreaterThan(retiming.mediaStart.doubleValue, retiming.mediaEnd.doubleValue)
        XCTAssertLessThanOrEqual(retiming.timelineStart.doubleValue, retiming.timelineEnd.doubleValue)
    }

    func testProject_TimeMapThreePoints_EmitsTwoSegmentsPerChannel() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="30s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="Multi" duration="10s">
                                        <timeMap>
                                            <timept time="0s" value="0s" interp="linear"/>
                                            <timept time="5s" value="10s" interp="linear"/>
                                            <timept time="10s" value="12s" interp="linear"/>
                                        </timeMap>
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        // 2 segments × 2 channels
        XCTAssertEqual(windows.count, 4)

        let video = windows.filter { $0.channel.kind == .video }
        XCTAssertEqual(video.count, 2)
        XCTAssertEqual(video[0].retiming.scale, 2, accuracy: 0.000_1)
        XCTAssertEqual(video[1].retiming.scale, 0.4, accuracy: 0.000_1)
        XCTAssertEqual(video[0].timelineOut.doubleValue, video[1].timelineIn.doubleValue, accuracy: 0.000_1)
        XCTAssertEqual(video[0].timelineIn.doubleValue, 0, accuracy: 0.000_1)
        XCTAssertEqual(video[1].timelineOut.doubleValue, 10, accuracy: 0.000_1)
    }

    func testConformRate_ApplyingConform_AnnotatesScaleFromSharedTable() throws {
        let conform = FinalCutPro.FCPXML.ConformRate(
            scaleEnabled: true,
            srcFrameRate: .fps29_97
        )
        let identity = FinalCutPro.FCPXML.RetimingSegment.identity(
            timelineStart: .zero,
            duration: Fraction(10, 1),
            mediaStart: .zero
        )
        let adjusted = conform.applyingConform(to: identity, timelineFrameRate: .fps23_976)

        // NTSC 29.97 → 23.976 uses factor 1.001 from the shared conform table.
        XCTAssertEqual(adjusted.scale, 1.001, accuracy: 0.000_1)
        XCTAssertEqual(adjusted.timelineStart, identity.timelineStart)
        XCTAssertEqual(adjusted.timelineEnd, identity.timelineEnd)
        XCTAssertEqual(adjusted.mediaStart, identity.mediaStart)
        XCTAssertEqual(adjusted.mediaEnd, identity.mediaEnd)
    }

    func testConformRate_ScaleDisabled_LeavesSegmentUnchanged() throws {
        let conform = FinalCutPro.FCPXML.ConformRate(
            scaleEnabled: false,
            srcFrameRate: .fps29_97
        )
        let identity = FinalCutPro.FCPXML.RetimingSegment.identity(
            timelineStart: .zero,
            duration: Fraction(5, 1),
            mediaStart: Fraction(1, 1)
        )
        let adjusted = conform.applyingConform(to: identity, timelineFrameRate: .fps24)
        XCTAssertEqual(adjusted, identity)
    }

    // MARK: - Nested lanes, secondary spines, J/L cuts

    func testProject_AnchoredLaneClip_ComposesLanePathAndAbsoluteStart() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="Host" hasVideo="1" videoSources="1" duration="20s">
                        <media-rep kind="original-media" src="file:///tmp/host.mov"/>
                    </asset>
                    <asset id="r3" name="Overlay" hasVideo="1" videoSources="1" duration="20s">
                        <media-rep kind="original-media" src="file:///tmp/overlay.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="2s" name="Host" start="10s" duration="8s">
                                        <asset-clip ref="r3" lane="1" offset="12s" name="Overlay" start="0s" duration="3s"/>
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        let host = try XCTUnwrap(windows.first { $0.clipDisplayName == "Host" })
        let overlay = try XCTUnwrap(windows.first { $0.clipDisplayName == "Overlay" })

        XCTAssertEqual(host.lanePath, .primary)
        XCTAssertEqual(host.timelineIn, Fraction(2, 1))
        XCTAssertEqual(host.timelineOut, Fraction(10, 1))

        // absolute = hostAbs + (overlay.offset − host.start) = 2 + (12 − 10) = 4
        XCTAssertEqual(overlay.lanePath.components, [1])
        XCTAssertEqual(overlay.timelineIn, Fraction(4, 1))
        XCTAssertEqual(overlay.timelineOut, Fraction(7, 1))
        XCTAssertEqual(overlay.mediaIn, .zero)
        XCTAssertEqual(overlay.mediaOut, Fraction(3, 1))
    }

    func testProject_SecondarySpine_AppendsLaneAndShiftsChildren() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="Host" hasVideo="1" videoSources="1" duration="30s">
                        <media-rep kind="original-media" src="file:///tmp/host.mov"/>
                    </asset>
                    <asset id="r3" name="BRoll" hasVideo="1" videoSources="1" duration="30s">
                        <media-rep kind="original-media" src="file:///tmp/broll.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="20s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="Host" start="5s" duration="20s">
                                        <spine lane="1" offset="8s">
                                            <asset-clip ref="r3" offset="2s" name="BRoll" start="0s" duration="4s"/>
                                        </spine>
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        let broll = try XCTUnwrap(windows.first { $0.clipDisplayName == "BRoll" })
        // spineAbs = 0 + (8 − 5) = 3; childAbs = 3 + 2 = 5
        XCTAssertEqual(broll.lanePath.components, [1])
        XCTAssertEqual(broll.timelineIn, Fraction(5, 1))
        XCTAssertEqual(broll.timelineOut, Fraction(9, 1))
    }

    func testProject_AudioStartDuration_EmitsSeparateAudioWindow() async throws {
        // Video: start=10s duration=5s at offset=2s → timeline [2, 7), media [10, 15)
        // Audio: audioStart=9s audioDuration=7s → timeline [1, 8), media [9, 16)
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="ClipA" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="2s" name="JL" start="10s" duration="5s"
                                        audioStart="9s" audioDuration="7s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        XCTAssertEqual(windows.count, 2)
        let video = try XCTUnwrap(windows.first { $0.channel.kind == .video })
        let audio = try XCTUnwrap(windows.first { $0.channel.kind == .audio })

        XCTAssertEqual(video.timelineIn, Fraction(2, 1))
        XCTAssertEqual(video.timelineOut, Fraction(7, 1))
        XCTAssertEqual(video.mediaIn, Fraction(10, 1))
        XCTAssertEqual(video.mediaOut, Fraction(15, 1))

        XCTAssertEqual(audio.timelineIn, Fraction(1, 1))
        XCTAssertEqual(audio.timelineOut, Fraction(8, 1))
        XCTAssertEqual(audio.mediaIn, Fraction(9, 1))
        XCTAssertEqual(audio.mediaOut, Fraction(16, 1))
    }

    func testAudioSplitRetiming_NoSplit_ReusesVideoSegments() throws {
        let segments = FinalCutPro.FCPXML.AudioSplitRetiming.segments(
            timeMap: nil,
            absoluteStart: Fraction(2, 1),
            videoDuration: Fraction(5, 1),
            videoMediaStart: Fraction(10, 1),
            clipStartAttribute: Fraction(10, 1),
            audioStart: nil,
            audioDuration: nil
        )
        XCTAssertEqual(segments.video, segments.audio)
        XCTAssertEqual(segments.video.count, 1)
        XCTAssertEqual(segments.video[0].timelineStart, Fraction(2, 1))
    }

    // MARK: - Multicam, ref-clip, audition, video/audio leaves

    func testProject_MCClip_ActiveAngleOnly_EmitsFromActiveAngle() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="CamA" hasVideo="1" videoSources="1" duration="30s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                    <asset id="r3" name="CamB" hasVideo="1" videoSources="1" duration="30s">
                        <media-rep kind="original-media" src="file:///tmp/b.mov"/>
                    </asset>
                    <media id="r4" name="Multi">
                        <multicam format="r1">
                            <mc-angle name="A" angleID="angle-a">
                                <asset-clip ref="r2" offset="0s" name="CamA" start="0s" duration="30s"/>
                            </mc-angle>
                            <mc-angle name="B" angleID="angle-b">
                                <asset-clip ref="r3" offset="0s" name="CamB" start="0s" duration="30s"/>
                            </mc-angle>
                        </multicam>
                    </media>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <mc-clip ref="r4" offset="2s" name="MC" start="0s" duration="5s">
                                        <mc-source angleID="angle-b" srcEnable="all"/>
                                    </mc-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let active = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active[0].clipDisplayName, "CamB")
        XCTAssertEqual(active[0].timelineIn, Fraction(2, 1))
        XCTAssertEqual(active[0].channel.resourceID, "r3")

        let allAngles = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeDisabled: false, auditions: .active, mcClipAngles: .all)
        )
        XCTAssertEqual(Set(allAngles.map(\.clipDisplayName)), Set(["CamA", "CamB"]))
    }

    func testProject_MCClip_SplitVideoAudioAngles_FiltersChannels() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="V" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="20s">
                        <media-rep kind="original-media" src="file:///tmp/v.mov"/>
                    </asset>
                    <asset id="r3" name="A" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="20s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                    <media id="r4" name="Multi">
                        <multicam format="r1">
                            <mc-angle name="VideoAngle" angleID="v-angle">
                                <asset-clip ref="r2" offset="0s" name="VideoSrc" start="0s" duration="20s"/>
                            </mc-angle>
                            <mc-angle name="AudioAngle" angleID="a-angle">
                                <asset-clip ref="r3" offset="0s" name="AudioSrc" start="0s" duration="20s"/>
                            </mc-angle>
                        </multicam>
                    </media>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <mc-clip ref="r4" offset="0s" name="MC" start="0s" duration="5s">
                                        <mc-source angleID="v-angle" srcEnable="video"/>
                                        <mc-source angleID="a-angle" srcEnable="audio"/>
                                    </mc-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        let video = windows.filter { $0.channel.kind == .video }
        let audio = windows.filter { $0.channel.kind == .audio }
        XCTAssertEqual(video.count, 1)
        XCTAssertEqual(audio.count, 1)
        XCTAssertEqual(video[0].channel.resourceID, "r2")
        XCTAssertEqual(audio[0].channel.resourceID, "r3")
    }

    func testProject_RefClip_UnfoldsMediaSequence() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="Inner" hasVideo="1" videoSources="1" duration="30s">
                        <media-rep kind="original-media" src="file:///tmp/inner.mov"/>
                    </asset>
                    <media id="r3" name="Compound">
                        <sequence format="r1" duration="10s" tcStart="0s">
                            <spine>
                                <asset-clip ref="r2" offset="3s" name="InnerClip" start="3s" duration="4s"/>
                            </spine>
                        </sequence>
                    </media>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="20s" tcStart="0s">
                                <spine>
                                    <ref-clip ref="r3" offset="5s" name="CompoundOnTimeline" start="3s" duration="4s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        XCTAssertEqual(windows.count, 1)
        // absolute = refAbs + (inner.offset − ref.start) = 5 + (3 − 3) = 5
        XCTAssertEqual(windows[0].clipDisplayName, "InnerClip")
        XCTAssertEqual(windows[0].timelineIn, Fraction(5, 1))
        XCTAssertEqual(windows[0].timelineOut, Fraction(9, 1))
        XCTAssertEqual(windows[0].mediaIn, Fraction(3, 1))
    }

    func testProject_Audition_ActiveOnly_EmitsFirstChild() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                    <asset id="r3" name="B" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="file:///tmp/b.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="5s" tcStart="0s">
                                <spine>
                                    <audition offset="1s">
                                        <asset-clip ref="r2" name="Active" start="0s" duration="4s"/>
                                        <asset-clip ref="r3" name="Inactive" start="0s" duration="4s"/>
                                    </audition>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let active = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active[0].clipDisplayName, "Active")
        XCTAssertEqual(active[0].timelineIn, Fraction(1, 1))

        let all = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeDisabled: false, auditions: .all, mcClipAngles: .active)
        )
        XCTAssertEqual(Set(all.map(\.clipDisplayName)), Set(["Active", "Inactive"]))
    }

    func testProject_VideoLeaf_EmitsVideoChannelOnly() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="AV" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="20s">
                        <media-rep kind="original-media" src="file:///tmp/av.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <clip offset="0s" name="Container" start="0s" duration="5s">
                                        <video ref="r2" offset="0s" name="VOnly" start="0s" duration="5s"/>
                                        <audio ref="r2" lane="-1" offset="0s" name="AOnly" start="0s" duration="5s"/>
                                    </clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        XCTAssertEqual(windows.count, 2)
        let video = try XCTUnwrap(windows.first { $0.channel.kind == .video })
        let audio = try XCTUnwrap(windows.first { $0.channel.kind == .audio })
        XCTAssertEqual(video.clipDisplayName, "VOnly")
        XCTAssertEqual(audio.clipDisplayName, "AOnly")
        XCTAssertEqual(audio.lanePath.components, [-1])
    }

    func testProject_SyncClipSample_EmitsNestedAssetClips() async throws {
        let fcpxml = try loadFCPXMLSample(named: "SyncClip")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        XCTAssertGreaterThanOrEqual(windows.count, 2)
        XCTAssertTrue(windows.contains { $0.clipDisplayName == "TestVideo" })
        XCTAssertTrue(windows.contains { $0.clipDisplayName == "TestAudio" })
        let audioLane = windows.first { $0.clipDisplayName == "TestAudio" }
        XCTAssertEqual(audioLane?.lanePath.components, [-1])
    }

    func testProjectionTiming_ConformScaledParent_DoesNotTrap() {
        // Regression: Fraction(double:) conform-scaled starts mixed with literal FCPXML
        // rationals used to trap on Int overflow inside Fraction `+` / `-` (e.g. 24.fcpxml).
        let parentAbs = Fraction(745, 6) // 298000/2400 reduced
        let parentLocal = Fraction(double: 178.845_333_333, decimalPrecision: 18)
        let childOffset = Fraction(571_571, 3000)

        let absolute = FinalCutPro.FCPXML.ProjectionTiming.absoluteStart(
            offset: childOffset,
            parentAbsoluteStart: parentAbs,
            parentLocalStart: parentLocal
        )
        XCTAssertGreaterThan(absolute.doubleValue, 0)
        XCTAssertLessThan(abs(absolute.doubleValue - (parentAbs.doubleValue + (childOffset.doubleValue - parentLocal.doubleValue))), 0.001)
    }

    func testReportOptions_ConsumesTimelineProjection_WhenInventoryOrSpeedEnabled() {
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.effectsOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.summaryOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.markersOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.keywordsOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly.consumesTimelineProjection)
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.transitionsOnly.consumesTimelineProjection)
        XCTAssertFalse(
            FinalCutPro.FCPXML.ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSpeedChangeEffects: false,
                includeSummary: false,
                includeMediaSummary: false,
                includeRoleInventory: false
            ).consumesTimelineProjection
        )
    }

    func testTimelineOccupancyIndex_UnionDurationMergesOverlaps() {
        let channel = FinalCutPro.FCPXML.MediaChannel(
            resourceID: "r1",
            kind: .video,
            sourceIndex: 1
        )
        let a = FinalCutPro.FCPXML.MediaUsageWindow(
            channel: channel,
            retiming: .identity(timelineStart: .zero, duration: Fraction(4, 1), mediaStart: .zero),
            clipDisplayName: "A"
        )
        let b = FinalCutPro.FCPXML.MediaUsageWindow(
            channel: channel,
            retiming: .identity(timelineStart: Fraction(2, 1), duration: Fraction(4, 1), mediaStart: .zero),
            clipDisplayName: "B"
        )
        let index = FinalCutPro.FCPXML.TimelineOccupancyIndex(windows: [a, b])

        XCTAssertEqual(index.summedDuration(kind: .video), 8, accuracy: 0.001)
        XCTAssertEqual(index.occupiedDuration(kind: .video), 6, accuracy: 0.001)
        XCTAssertEqual(index.windows(overlapping: Fraction(3, 1), end: Fraction(5, 1)).count, 2)
        XCTAssertEqual(index.windows(overlapping: Fraction(7, 1), end: Fraction(8, 1)).count, 0)
    }

    func testMediaSummary_ProjectionWindows_PreferChannelURLs() async throws {
        let missingURL = URL(fileURLWithPath: "/tmp/ofk-missing-\(UUID().uuidString).mov")
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="Clip" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="\(missingURL.absoluteString)"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="5s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" name="Clip" start="0s" duration="5s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.workbookCoverSheet = nil
        let report = try await fcpxml.buildReport(options: options)
        let paths = report.mediaSummary?.missingMediaPaths ?? []
        XCTAssertTrue(paths.contains(missingURL.path), "Expected \(missingURL.path) in \(paths)")
    }

    func testBuildReport_24Sample_EffectsAndSummaryWithProjection() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"
        options.includeMarkers = false
        options.includeKeywords = false
        options.includeTitlesAndGenerators = false
        options.includeTransitions = false
        options.includeSpeedChangeEffects = false
        options.includeRoleInventory = false
        options.includeEffects = true
        options.includeSummary = true
        options.includeMediaSummary = true

        let report = try await fcpxml.buildReport(options: options)
        XCTAssertNotNil(report.effects)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.mediaSummary)
    }

    func testProject_ComplexSample_DoesNotCrash() async throws {
        let fcpxml = try loadFCPXMLSample(named: "Complex")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)
        XCTAssertFalse(windows.isEmpty)
    }

    func testProject_23_98Sample_DoesNotCrash() async throws {
        let fcpxml = try loadFCPXMLSample(named: "23.98")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)
        XCTAssertFalse(windows.isEmpty)
    }

    func testProject_24Sample_DoesNotCrash() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )
        XCTAssertFalse(windows.isEmpty)
    }

    func testProject_24Sample_ReportOptions_DoesNotCrash() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .forReport(
                excludeDisabledClips: false,
                auditions: .all,
                mcClipAngles: .all
            )
        )
        XCTAssertFalse(windows.isEmpty)
    }

    func testBuildReport_24Sample_RoleInventoryWithProjection() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"
        let report = try await fcpxml.buildReport(options: options)
        XCTAssertFalse(report.roleInventory?.selectedRoles.isEmpty ?? true)
    }

    func testBuildReport_24Sample_SpeedChangeWithProjection() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.speedChangeEffects?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            XCTAssertTrue(row.effect.hasPrefix("Retime "))
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }
}
