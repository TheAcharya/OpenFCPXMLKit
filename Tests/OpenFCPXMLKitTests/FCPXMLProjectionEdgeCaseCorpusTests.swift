//
//  FCPXMLProjectionEdgeCaseCorpusTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Projection edge-case corpus: J/L cuts, timeMap, nested ref/spine.
//

import Testing
import SwiftTimecode
@testable import OpenFCPXMLKit

@Suite("Projection edge-case corpus")
struct FCPXMLProjectionEdgeCaseCorpusTests {
    private let projector = FinalCutPro.FCPXML.TimelineProjector()

    private func parseInlineFCPXML(_ xml: String) throws -> FinalCutPro.FCPXML {
        let data = try #require(xml.data(using: .utf8))
        return try FinalCutPro.FCPXML(fileContent: data)
    }

    // MARK: - J/L + timeMap

    @Test("J/L cut with timeMap scales audio occupancy independently")
    func jlCutWithTimeMapScalesAudioIndependently() async throws {
        // Video occupancy normalized onto duration=5s at offset=2s → [2,7).
        // timeMap 0→10 remapped / 0→20 media → scale 2 on video.
        // Audio: audioStart=9s audioDuration=7s → timeline [1,8), also timeMap-normalized.
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
                            <sequence format="r1" duration="20s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="2s" name="JLRetime" start="10s" duration="5s"
                                        audioStart="9s" audioDuration="7s">
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
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .trackAnalysis)
        let video = try #require(windows.first { $0.channel.kind == .video })
        let audio = try #require(windows.first { $0.channel.kind == .audio })

        #expect(abs(video.timelineIn.doubleValue - 2) < 0.001)
        #expect(abs(video.timelineOut.doubleValue - 7) < 0.001)
        #expect(abs(video.retiming.scale - 2) < 0.05)

        #expect(abs(audio.timelineIn.doubleValue - 1) < 0.001)
        #expect(abs(audio.timelineOut.doubleValue - 8) < 0.001)
        #expect(abs(audio.retiming.scale - 2) < 0.05)
        #expect(video.timelineIn != audio.timelineIn)
    }

    @Test("AudioStart-only J-cut from XML emits earlier audio window")
    func audioStartOnlyJCutFromXML() async throws {
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
                                    <asset-clip ref="r2" offset="2s" name="JOnly" start="10s" duration="5s"
                                        audioStart="9s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .init())
        let video = try #require(windows.first { $0.channel.kind == .video })
        let audio = try #require(windows.first { $0.channel.kind == .audio })

        #expect(video.timelineIn == Fraction(2, 1))
        #expect(video.timelineOut == Fraction(7, 1))
        #expect(audio.timelineIn == Fraction(1, 1))
        #expect(audio.timelineOut == Fraction(6, 1))
        #expect(audio.mediaIn == Fraction(9, 1))
    }

    // MARK: - Nested ref + timeMap / JL

    @Test("Nested ref-clip with outer timeMap and inner J/L cut")
    func nestedRefClipOuterTimeMapInnerJL() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="Leaf" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/leaf.mov"/>
                    </asset>
                    <media id="r3" name="Compound">
                        <sequence format="r1" duration="10s" tcStart="0s">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Inner" start="10s" duration="5s"
                                    audioStart="9s" audioDuration="7s"/>
                            </spine>
                        </sequence>
                    </media>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="10s" tcStart="0s">
                                <spine>
                                    <ref-clip ref="r3" offset="0s" name="Outer" duration="4s">
                                        <timeMap>
                                            <timept time="0s" value="0s" interp="linear"/>
                                            <timept time="4s" value="8s" interp="linear"/>
                                        </timeMap>
                                    </ref-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        let source = try #require(fcpxml.allReportTimelineSources().first)
        let windows = try await projector.project(from: source, fcpxml: fcpxml, options: .trackAnalysis)
        let video = windows.filter { $0.channel.kind == .video }
        let audio = windows.filter { $0.channel.kind == .audio }
        #expect(!video.isEmpty)
        #expect(!audio.isEmpty)
        // Outer 2x map compresses nested occupancy onto ~4s timeline.
        #expect(video.contains { $0.timelineOut.doubleValue <= 4.1 + 0.05 })
        #expect(audio.contains { abs($0.timelineIn.doubleValue - $0.timelineOut.doubleValue) > 0.01 })
    }

    @Test("Nested secondary spine with timeMap child")
    func nestedSecondarySpineWithTimeMapChild() async throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/a.mov"/>
                    </asset>
                    <asset id="r3" name="B" hasVideo="1" videoSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/b.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="20s" tcStart="0s">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="Primary" start="0s" duration="10s">
                                        <spine lane="1" offset="2s">
                                            <asset-clip ref="r3" offset="0s" name="NestedRetime" start="0s" duration="4s">
                                                <timeMap>
                                                    <timept time="0s" value="0s" interp="linear"/>
                                                    <timept time="4s" value="8s" interp="linear"/>
                                                </timeMap>
                                            </asset-clip>
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
        let nested = try #require(windows.first { $0.clipDisplayName == "NestedRetime" })
        #expect(nested.lanePath.components == [1])
        // Nested clip at parent abs 0+2=2, duration 4 → [2,6), scale ~2.
        #expect(abs(nested.timelineIn.doubleValue - 2) < 0.05)
        #expect(abs(nested.timelineOut.doubleValue - 6) < 0.05)
        #expect(abs(nested.retiming.scale - 2) < 0.1)
    }
}
