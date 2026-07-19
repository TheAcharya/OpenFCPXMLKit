//
//  FCPXMLTimelineProjectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Tests for TimelineProjection: identity, timeMap, nested lanes, multicam/ref/audition, report consume + occupancy.
//

import Foundation
import Testing
import SwiftTimecode
@testable import OpenFCPXMLKit

@Suite("Timeline projection")
struct FCPXMLTimelineProjectionTests {

    private let projector = FinalCutPro.FCPXML.TimelineProjector()

    // MARK: - Inline identity asset-clip

    @Test("Simple asset-clip emits video and audio identity windows")
    func project_SimpleAssetClip_EmitsVideoAndAudioIdentityWindows() async throws {
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
        #expect(sources.count == 1)

        let windows = try await projector.project(
            from: sources[0],
            fcpxml: fcpxml,
            options: .init()
        )

        #expect(windows.count == 2)

        let video = try #require(windows.first { $0.channel.kind == .video })
        let audio = try #require(windows.first { $0.channel.kind == .audio })

        #expect(video.channel.resourceID == "r2")
        #expect(video.channel.sourceIndex == 1)
        #expect(video.channel.originalMediaURL?.path == "/tmp/ClipA.mov")
        #expect(video.clipDisplayName == "ClipA On Timeline")
        #expect(video.lanePath == .primary)
        #expect(video.timelineIn == Fraction(2, 1))
        #expect(video.timelineOut == Fraction(7, 1))
        #expect(video.mediaIn == Fraction(10, 1))
        #expect(video.mediaOut == Fraction(15, 1))
        #expect(video.retiming.scale == 1)
        #expect(!video.retiming.isReversed)

        #expect(audio.channel.resourceID == "r2")
        #expect(audio.timelineIn == video.timelineIn)
        #expect(audio.timelineOut == video.timelineOut)
        #expect(audio.mediaIn == video.mediaIn)
        #expect(audio.mediaOut == video.mediaOut)
    }

    @Test("Disabled asset-clip omitted when includeDisabled is false")
    func project_DisabledAssetClip_OmittedWhenIncludeDisabledFalse() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)

        let included = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeDisabled: true)
        )
        #expect(included.count == 2)
        #expect(Set(included.map(\.clipDisplayName)) == Set(["On", "Off"]))

        let visibleOnly = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )
        #expect(visibleOnly.count == 1)
        #expect(visibleOnly.first?.clipDisplayName == "On")
    }

    @Test("AudioOnly sample emits audio windows for spine clips")
    func project_AudioOnlySample_EmitsAudioWindowsForSpineClips() async throws {
        let fcpxml = try requireFCPXMLSample(named: "AudioOnly")
        let source = try #require(fcpxml.allReportTimelineSources().first)

        let windows = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )

        // Walks primary spine + anchored lane children (3 Forest Day + 2 Water Lake).
        #expect(windows.count == 5)
        let allAudio = windows.allSatisfy { $0.channel.kind == .audio }
        #expect(allAudio)
        #expect(windows.filter { $0.lanePath == .primary }.count == 3)
        #expect(windows.filter { $0.lanePath.components == [-1] }.count == 2)
        let allIdentityScale = windows.allSatisfy { $0.retiming.scale == 1 }
        #expect(allIdentityScale)
        #expect(windows[0].clipDisplayName == "Forest Day")
        #expect(windows[0].timelineIn == .zero)

        let waterLake = windows.filter { $0.clipDisplayName == "Water Lake 3" }
        #expect(waterLake.count == 2)
        #expect(waterLake[0].timelineIn == .zero)
        #expect(waterLake[1].timelineIn.doubleValue > 0)
    }

    @Test("Streaming callback matches collect")
    func project_StreamingCallback_MatchesCollect() async throws {
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
        let source = try #require(fcpxml.allReportTimelineSources().first)

        let collected = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        var streamed: [FinalCutPro.FCPXML.MediaUsageWindow] = []
        try await projector.project(from: source, fcpxml: fcpxml, options: .init()) { window in
            streamed.append(window)
        }

        #expect(streamed == collected)
        #expect(collected.count == 2)
    }

    @Test("projectTimeline convenience uses first source")
    func projectTimeline_Convenience_UsesFirstSource() async throws {
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
        #expect(windows.count == 1)
        #expect(windows[0].timelineIn == Fraction(1, 1))
        #expect(windows[0].timelineOut == Fraction(3, 1))
    }

    // MARK: - timeMap retiming

    @Test("TimeMap two points emits scaled identity occupancy")
    func project_TimeMapTwoPoints_EmitsScaledIdentityOccupancy() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        #expect(windows.count == 1)
        let window = windows[0]
        let timelineInMatch = abs(window.timelineIn.doubleValue - 2) < 0.000_1
        let timelineOutMatch = abs(window.timelineOut.doubleValue - 7) < 0.000_1
        let mediaInMatch = abs(window.mediaIn.doubleValue - 0) < 0.000_1
        let mediaOutMatch = abs(window.mediaOut.doubleValue - 20) < 0.000_1
        let scaleMatch = abs(window.retiming.scale - 2) < 0.000_1
        #expect(timelineInMatch)
        #expect(timelineOutMatch)
        #expect(mediaInMatch)
        #expect(mediaOutMatch)
        #expect(scaleMatch)
        #expect(!window.retiming.isReversed)
    }

    @Test("TimeMap reverse sets isReversed and negative speed magnitude")
    func project_TimeMapReverse_SetsIsReversedAndNegativeSpeedMagnitude() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        #expect(windows.count == 1)
        let retiming = windows[0].retiming
        #expect(retiming.isReversed)
        let scaleMatch = abs(retiming.scale - 1) < 0.001
        #expect(scaleMatch)
        #expect(retiming.mediaStart.doubleValue > retiming.mediaEnd.doubleValue)
        #expect(retiming.timelineStart.doubleValue <= retiming.timelineEnd.doubleValue)
    }

    @Test("TimeMap three points emits two segments per channel")
    func project_TimeMapThreePoints_EmitsTwoSegmentsPerChannel() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        // 2 segments × 2 channels
        #expect(windows.count == 4)

        let video = windows.filter { $0.channel.kind == .video }
        #expect(video.count == 2)
        let scale0Match = abs(video[0].retiming.scale - 2) < 0.000_1
        let scale1Match = abs(video[1].retiming.scale - 0.4) < 0.000_1
        let abutMatch = abs(video[0].timelineOut.doubleValue - video[1].timelineIn.doubleValue) < 0.000_1
        let startMatch = abs(video[0].timelineIn.doubleValue - 0) < 0.000_1
        let endMatch = abs(video[1].timelineOut.doubleValue - 10) < 0.000_1
        #expect(scale0Match)
        #expect(scale1Match)
        #expect(abutMatch)
        #expect(startMatch)
        #expect(endMatch)
    }

    @Test("ConformRate applyingConform annotates scale from shared table")
    func conformRate_ApplyingConform_AnnotatesScaleFromSharedTable() throws {
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
        let scaleMatch = abs(adjusted.scale - 1.001) < 0.000_1
        #expect(scaleMatch)
        #expect(adjusted.timelineStart == identity.timelineStart)
        #expect(adjusted.timelineEnd == identity.timelineEnd)
        #expect(adjusted.mediaStart == identity.mediaStart)
        #expect(adjusted.mediaEnd == identity.mediaEnd)
    }

    @Test("ConformRate scaleDisabled leaves segment unchanged")
    func conformRate_ScaleDisabled_LeavesSegmentUnchanged() throws {
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
        #expect(adjusted == identity)
    }

    // MARK: - Nested lanes, secondary spines, J/L cuts

    @Test("Anchored lane clip composes lane path and absolute start")
    func project_AnchoredLaneClip_ComposesLanePathAndAbsoluteStart() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        let host = try #require(windows.first { $0.clipDisplayName == "Host" })
        let overlay = try #require(windows.first { $0.clipDisplayName == "Overlay" })

        #expect(host.lanePath == .primary)
        #expect(host.timelineIn == Fraction(2, 1))
        #expect(host.timelineOut == Fraction(10, 1))

        // absolute = hostAbs + (overlay.offset − host.start) = 2 + (12 − 10) = 4
        #expect(overlay.lanePath.components == [1])
        #expect(overlay.timelineIn == Fraction(4, 1))
        #expect(overlay.timelineOut == Fraction(7, 1))
        #expect(overlay.mediaIn == .zero)
        #expect(overlay.mediaOut == Fraction(3, 1))
    }

    @Test("Secondary spine appends lane and shifts children")
    func project_SecondarySpine_AppendsLaneAndShiftsChildren() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        let broll = try #require(windows.first { $0.clipDisplayName == "BRoll" })
        // spineAbs = 0 + (8 − 5) = 3; childAbs = 3 + 2 = 5
        #expect(broll.lanePath.components == [1])
        #expect(broll.timelineIn == Fraction(5, 1))
        #expect(broll.timelineOut == Fraction(9, 1))
    }

    @Test("Audio start/duration emits separate audio window")
    func project_AudioStartDuration_EmitsSeparateAudioWindow() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())

        #expect(windows.count == 2)
        let video = try #require(windows.first { $0.channel.kind == .video })
        let audio = try #require(windows.first { $0.channel.kind == .audio })

        #expect(video.timelineIn == Fraction(2, 1))
        #expect(video.timelineOut == Fraction(7, 1))
        #expect(video.mediaIn == Fraction(10, 1))
        #expect(video.mediaOut == Fraction(15, 1))

        #expect(audio.timelineIn == Fraction(1, 1))
        #expect(audio.timelineOut == Fraction(8, 1))
        #expect(audio.mediaIn == Fraction(9, 1))
        #expect(audio.mediaOut == Fraction(16, 1))
    }

    @Test("AudioSplitRetiming with no split reuses video segments")
    func audioSplitRetiming_NoSplit_ReusesVideoSegments() throws {
        let segments = FinalCutPro.FCPXML.AudioSplitRetiming.segments(
            timeMap: nil,
            absoluteStart: Fraction(2, 1),
            videoDuration: Fraction(5, 1),
            videoMediaStart: Fraction(10, 1),
            clipStartAttribute: Fraction(10, 1),
            audioStart: nil,
            audioDuration: nil
        )
        #expect(segments.video == segments.audio)
        #expect(segments.video.count == 1)
        #expect(segments.video[0].timelineStart == Fraction(2, 1))
    }

    @Test("AudioStart-only split defaults audioDuration to video duration")
    func audioSplitRetiming_AudioStartOnly_DefaultsDuration() throws {
        // video start=10s duration=5s at offset=2s → [2,7) media [10,15)
        // audioStart=9s only → audio timeline starts 1s earlier, duration remains 5s → [1,6)
        let segments = FinalCutPro.FCPXML.AudioSplitRetiming.segments(
            timeMap: nil,
            absoluteStart: Fraction(2, 1),
            videoDuration: Fraction(5, 1),
            videoMediaStart: Fraction(10, 1),
            clipStartAttribute: Fraction(10, 1),
            audioStart: Fraction(9, 1),
            audioDuration: nil
        )
        #expect(FinalCutPro.FCPXML.AudioSplitRetiming.hasSplitEdit(
            videoStart: Fraction(10, 1),
            videoDuration: Fraction(5, 1),
            audioStart: Fraction(9, 1),
            audioDuration: nil
        ))
        #expect(segments.audio.count == 1)
        #expect(segments.audio[0].timelineStart == Fraction(1, 1))
        #expect(segments.audio[0].timelineEnd == Fraction(6, 1))
        #expect(segments.audio[0].mediaStart == Fraction(9, 1))
        #expect(segments.audio[0].mediaEnd == Fraction(14, 1))
    }

    @Test("trackAnalysis preset uses active audition and multicam")
    func trackAnalysisPreset_UsesActiveMasks() {
        let options = FinalCutPro.FCPXML.TimelineProjectionOptions.trackAnalysis
        #expect(options.auditions == .active)
        #expect(options.mcClipAngles == .active)
        #expect(options.expandAllSourceChannels)
        #expect(options.includeDisabled)
        #expect(!options.excludeFullyOccluded)
    }

    // MARK: - Multicam, ref-clip, audition, video/audio leaves

    @Test("MC-clip active angle only emits from active angle")
    func project_MCClip_ActiveAngleOnly_EmitsFromActiveAngle() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let active = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )
        #expect(active.count == 1)
        #expect(active[0].clipDisplayName == "CamB")
        #expect(active[0].timelineIn == Fraction(2, 1))
        #expect(active[0].channel.resourceID == "r3")

        let allAngles = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeDisabled: false, auditions: .active, mcClipAngles: .all)
        )
        #expect(Set(allAngles.map(\.clipDisplayName)) == Set(["CamA", "CamB"]))
    }

    @Test("MC-clip split video/audio angles filters channels")
    func project_MCClip_SplitVideoAudioAngles_FiltersChannels() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        let video = windows.filter { $0.channel.kind == .video }
        let audio = windows.filter { $0.channel.kind == .audio }
        #expect(video.count == 1)
        #expect(audio.count == 1)
        #expect(video[0].channel.resourceID == "r2")
        #expect(audio[0].channel.resourceID == "r3")
    }

    @Test("Ref-clip unfolds media sequence")
    func project_RefClip_UnfoldsMediaSequence() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        #expect(windows.count == 1)
        // absolute = refAbs + (inner.offset − ref.start) = 5 + (3 − 3) = 5
        #expect(windows[0].clipDisplayName == "InnerClip")
        #expect(windows[0].timelineIn == Fraction(5, 1))
        #expect(windows[0].timelineOut == Fraction(9, 1))
        #expect(windows[0].mediaIn == Fraction(3, 1))
    }

    @Test("Audition active-only emits first child")
    func project_Audition_ActiveOnly_EmitsFirstChild() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let active = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)
        #expect(active.count == 1)
        #expect(active[0].clipDisplayName == "Active")
        #expect(active[0].timelineIn == Fraction(1, 1))

        let all = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeDisabled: false, auditions: .all, mcClipAngles: .active)
        )
        #expect(Set(all.map(\.clipDisplayName)) == Set(["Active", "Inactive"]))
    }

    @Test("Video leaf emits video channel only")
    func project_VideoLeaf_EmitsVideoChannelOnly() async throws {
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

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        #expect(windows.count == 2)
        let video = try #require(windows.first { $0.channel.kind == .video })
        let audio = try #require(windows.first { $0.channel.kind == .audio })
        #expect(video.clipDisplayName == "VOnly")
        #expect(audio.clipDisplayName == "AOnly")
        #expect(audio.lanePath.components == [-1])
    }

    @Test("SyncClip sample emits nested asset-clips")
    func project_SyncClipSample_EmitsNestedAssetClips() async throws {
        let fcpxml = try requireFCPXMLSample(named: "SyncClip")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)

        #expect(windows.count >= 2)
        let hasTestVideo = windows.contains { $0.clipDisplayName == "TestVideo" }
        let hasTestAudio = windows.contains { $0.clipDisplayName == "TestAudio" }
        #expect(hasTestVideo)
        #expect(hasTestAudio)
        let audioLane = windows.first { $0.clipDisplayName == "TestAudio" }
        #expect(audioLane?.lanePath.components == [-1])
    }

    @Test("ProjectionTiming conform-scaled parent does not trap")
    func projectionTiming_ConformScaledParent_DoesNotTrap() {
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
        #expect(absolute.doubleValue > 0)
        let expected =
            parentAbs.doubleValue + (childOffset.doubleValue - parentLocal.doubleValue)
        let deltaMatch = abs(absolute.doubleValue - expected) < 0.001
        #expect(deltaMatch)
    }

    @Test("ReportOptions consumesTimelineProjection when inventory or speed enabled")
    func reportOptions_ConsumesTimelineProjection_WhenInventoryOrSpeedEnabled() {
        #expect(FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.effectsOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.summaryOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.markersOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.keywordsOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly.consumesTimelineProjection)
        #expect(FinalCutPro.FCPXML.ReportOptions.transitionsOnly.consumesTimelineProjection)
        let emptyConsumes = FinalCutPro.FCPXML.ReportOptions(
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
        #expect(!emptyConsumes)
    }

    @Test("TimelineOccupancyIndex union duration merges overlaps")
    func timelineOccupancyIndex_UnionDurationMergesOverlaps() {
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

        let summedMatch = abs(index.summedDuration(kind: .video) - 8) < 0.001
        let occupiedMatch = abs(index.occupiedDuration(kind: .video) - 6) < 0.001
        #expect(summedMatch)
        #expect(occupiedMatch)
        #expect(index.windows(overlapping: Fraction(3, 1), end: Fraction(5, 1)).count == 2)
        #expect(index.windows(overlapping: Fraction(7, 1), end: Fraction(8, 1)).count == 0)
    }

    @Test("Media Summary projection windows prefer channel URLs")
    func mediaSummary_ProjectionWindows_PreferChannelURLs() async throws {
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
        let containsMissing = paths.contains(missingURL.path)
        #expect(containsMissing, "Expected \(missingURL.path) in \(paths)")
    }

    @Test("buildReport 24 sample effects and summary with projection")
    func buildReport_24Sample_EffectsAndSummaryWithProjection() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
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
        #expect(report.effects != nil)
        #expect(report.summary != nil)
        #expect(report.mediaSummary != nil)
    }

    @Test("Project Complex sample does not crash")
    func project_ComplexSample_DoesNotCrash() async throws {
        let fcpxml = try requireFCPXMLSample(named: "Complex")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)
        let hasWindows = !windows.isEmpty
        #expect(hasWindows)
    }

    @Test("Project 23.98 sample does not crash")
    func project_23_98Sample_DoesNotCrash() async throws {
        let fcpxml = try requireFCPXMLSample(named: "23.98")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .mainTimeline)
        let hasWindows = !windows.isEmpty
        #expect(hasWindows)
    }

    @Test("Project 24 sample does not crash")
    func project_24Sample_DoesNotCrash() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .mainTimeline
        )
        let hasWindows = !windows.isEmpty
        #expect(hasWindows)
    }

    @Test("Project 24 sample with report options does not crash")
    func project_24Sample_ReportOptions_DoesNotCrash() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .forReport(
                excludeDisabledClips: false,
                auditions: .all,
                mcClipAngles: .all
            )
        )
        let hasWindows = !windows.isEmpty
        #expect(hasWindows)
    }

    @Test("buildReport 24 sample role inventory with projection")
    func buildReport_24Sample_RoleInventoryWithProjection() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"
        let report = try await fcpxml.buildReport(options: options)
        let hasRoles = !(report.roleInventory?.selectedRoles.isEmpty ?? true)
        #expect(hasRoles)
    }

    @Test("buildReport 24 sample speed change with projection")
    func buildReport_24Sample_SpeedChangeWithProjection() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.speedChangeEffectsOnly
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.speedChangeEffects?.rows ?? []
        let hasRows = !rows.isEmpty
        #expect(hasRows)
        let smptePattern = #"^\d{2}:\d{2}:\d{2}[:;]\d{2}$"#
        for row in rows {
            #expect(row.effect.hasPrefix("Retime "))
            let inNonEmpty = !row.timelineIn.isEmpty
            let outNonEmpty = !row.timelineOut.isEmpty
            #expect(inNonEmpty)
            #expect(outNonEmpty)
            let inValid = row.timelineIn.range(of: smptePattern, options: .regularExpression) != nil
            let outValid = row.timelineOut.range(of: smptePattern, options: .regularExpression) != nil
            #expect(inValid)
            #expect(outValid)
        }
    }
}

