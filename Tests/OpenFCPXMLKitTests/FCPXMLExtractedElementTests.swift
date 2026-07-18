//
//  FCPXMLExtractedElementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for extracted element context helpers.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Extracted element")
struct FCPXMLExtractedElementTests {
    @Test("Display clip name for title uses effect resource name")
    func displayClipNameForTitleUsesEffectResourceName() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)

        let title = try #require(titles.first)
        #expect(title.displayClipName() == "Basic Title")
    }

    @Test("Display clip name for marker uses ancestor clip name")
    func displayClipNameForMarkerUsesAncestorClipName() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "TitlesRoles")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)

        let nestedMarker = try #require(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Marker 2" }
        )

        #expect(nestedMarker.displayClipName() == "Basic Title")
    }

    @Test("Ancestor clip element for keyword returns parent asset clip")
    func ancestorClipElementForKeywordReturnsParentAssetClip() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let keywords = await timeline.fcpExtract(types: [.keyword], scope: .mainTimeline)

        let penguinKeyword = try #require(
            keywords.first { $0.element.fcpValue == "penguin" }
        )

        #expect(penguinKeyword.ancestorClipElement()?.fcpName == "Nature Makes You Happy")
    }

    @Test("Preferred role for marker on title uses title inherited roles")
    func preferredRoleForMarkerOnTitleUsesTitleInheritedRoles() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "TitlesRoles")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)

        let nestedMarker = try #require(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Marker 2" }
        )

        let preferred = nestedMarker.preferredRole(for: .markers, using: .builtIn)
        #expect(preferred?.wrapped.role.lowercased() == "titles")
    }

    @Test("Preferred role for marker on asset clip uses dialogue")
    func preferredRoleForMarkerOnAssetClipUsesDialogue() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)

        let flowerMarker = try #require(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Yellow Flower" }
        )

        let preferred = flowerMarker.preferredRole(for: .markers, using: .builtIn)
        #expect(preferred?.wrapped.role.lowercased() == "dialogue")
    }

    @Test("Keyword inherited roles returns ancestor clip roles")
    func keywordInheritedRolesReturnsAncestorClipRoles() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let keywords = await timeline.fcpExtract(types: [.keyword], scope: .mainTimeline)

        let keyword = try #require(keywords.first)
        let roles = keyword.keywordInheritedRoles()

        #expect(!roles.isEmpty)
        let hasDialogue = roles.contains { $0.wrapped.role.lowercased() == "dialogue" }
        #expect(hasDialogue)
    }

    @Test("Visible keyword range on main timeline returns timeline bounds")
    func visibleKeywordRangeOnMainTimelineReturnsTimelineBounds() async throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Clip" uid="ABC" start="0s" duration="10s" hasVideo="1" hasAudio="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Clip" duration="10s" audioRole="dialogue">
                                    <keyword start="0s" duration="5s" value="visible"/>
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
        let keywords = await timeline.fcpExtract(
            types: [.keyword],
            scope: .reportMainTimelineVisible()
        )
        let keyword = try #require(keywords.first)
        let range = try #require(keyword.visibleKeywordRangeOnMainTimeline())

        #expect(range.timelineOut > range.timelineIn)
        #expect(range.duration.frameCount.wholeFrames > 0)
    }

    @Test("Effect host clip element for title returns title element")
    func effectHostClipElementForTitleReturnsTitleElement() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)

        let title = try #require(titles.first)
        #expect(title.effectHostClipElement() === title.element)
    }

    @Test("Markers extraction preset finds nested markers including disabled")
    func markersExtractionPresetFindsNestedMarkersIncludingDisabled() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "DisabledClips")
        let markers = await timeline.fcpExtract(
            preset: .markers,
            scope: .reportMainTimelineVisible()
        )

        #expect(markers.count >= 4)
    }

    @Test("Titles extraction preset includes disabled titles on main timeline")
    func titlesExtractionPresetIncludesDisabledTitlesOnMainTimeline() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(
            preset: .titles,
            scope: .reportMainTimelineVisible()
        )

        #expect(titles.count >= 2)
        let hasDisabled = titles.contains { $0.element.fcpGetEnabled(default: true) == false }
        #expect(hasDisabled)
    }
}
