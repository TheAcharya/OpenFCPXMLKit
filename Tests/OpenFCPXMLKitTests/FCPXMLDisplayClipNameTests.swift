//
//  FCPXMLDisplayClipNameTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for workbook clip name resolution.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Display clip name")
struct FCPXMLDisplayClipNameTests {
    @Test("Asset clip uses name attribute")
    func assetClipUsesNameAttribute() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let clips = await timeline.fcpExtract(types: [.assetClip], scope: .mainTimeline)
        let clip = try #require(clips.first)

        #expect(clip.displayClipName() == "Nature Makes You Happy")
    }

    @Test("Title uses referenced effect name not name attribute")
    func titleUsesReferencedEffectNameNotNameAttribute() async throws {
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
                                <title ref="r2" offset="0s" name="Custom Title Name" duration="5s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let timeline = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "sequence")
        )
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        let title = try #require(titles.first)

        #expect(title.displayClipName() == "Basic Title")
        #expect(title.displayClipName() != title.element.fcpName)
    }

    @Test("Marker on keyword uses ancestor clip name")
    func markerOnKeywordUsesAncestorClipName() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)
        let marker = try #require(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Yellow Flower" }
        )

        #expect(marker.displayClipName() == "Nature Makes You Happy")
    }

    @Test("MC clip appends active angle name")
    func mcClipAppendsActiveAngleName() async throws {
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
                        <mc-angle name="Cam B" angleID="a2">
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

        let timeline = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "sequence")
        )
        let mcClips = await timeline.fcpExtract(types: [.mcClip], scope: .mainTimeline)
        let mcClip = try #require(mcClips.first)

        #expect(mcClip.displayClipName() == "10-1-3 Cam A")
    }

    @Test("MC clip uses angle name when angle includes shot ID")
    func mcClipUsesAngleNameWhenAngleIncludesShotID() async throws {
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

        let timeline = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "sequence")
        )
        let mcClips = await timeline.fcpExtract(types: [.mcClip], scope: .mainTimeline)
        let mcClip = try #require(mcClips.first)

        #expect(mcClip.displayClipName() == "5A-4-2 Cam B")
    }

    @Test("Sync clip uses name attribute")
    func syncClipUsesNameAttribute() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let syncClips = await timeline.fcpExtract(types: [.syncClip], scope: .mainTimeline)
        let syncClip = try #require(syncClips.first)

        #expect(syncClip.displayClipName() == "Sync Clip 1")
    }

    @Test("Caption uses text body for workbook clip name")
    func captionUsesTextBodyForWorkbookClipName() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Host" uid="A1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="1-X-1" duration="10s" format="r1">
                                    <caption lane="1" offset="1s" name="Fallback Name" duration="2s" role="SRT?captionFormat=SRT.de-DE">
                                        <text placement="bottom">
                                            <text-style ref="ts1">Bleiben Sie stehen!</text-style>
                                        </text>
                                        <text-style-def id="ts1">
                                            <text-style font=".AppleSystemUIFont" fontSize="13" fontFace="Regular"/>
                                        </text-style-def>
                                    </caption>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)

        let timeline = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "sequence")
        )
        let captions = await timeline.fcpExtract(types: [.caption], scope: .mainTimeline)
        let caption = try #require(captions.first)

        #expect(caption.displayClipName() == "Bleiben Sie stehen!")
        #expect(caption.displayClipName() != "1-X-1")
    }
}

