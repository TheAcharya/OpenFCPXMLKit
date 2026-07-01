//
//  FCPXMLExtractedElementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for extracted element context helpers.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLExtractedElementTests: XCTestCase {
    func testDisplayClipNameForTitleUsesEffectResourceName() async throws {
        let timeline = try timelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        
        let title = try XCTUnwrap(titles.first)
        XCTAssertEqual(title.displayClipName(), "Basic Title")
    }
    
    func testDisplayClipNameForMarkerUsesAncestorClipName() async throws {
        let timeline = try timelineElement(fromSampleNamed: "TitlesRoles")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)
        
        let nestedMarker = try XCTUnwrap(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Marker 2" }
        )
        
        XCTAssertEqual(nestedMarker.displayClipName(), "Basic Title")
    }
    
    func testAncestorClipElementForKeywordReturnsParentAssetClip() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Keywords")
        let keywords = await timeline.fcpExtract(types: [.keyword], scope: .mainTimeline)
        
        let penguinKeyword = try XCTUnwrap(
            keywords.first { $0.element.fcpValue == "penguin" }
        )
        
        XCTAssertEqual(penguinKeyword.ancestorClipElement()?.fcpName, "Nature Makes You Happy")
    }
    
    func testPreferredRoleForMarkerOnTitleUsesTitleInheritedRoles() async throws {
        let timeline = try timelineElement(fromSampleNamed: "TitlesRoles")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)
        
        let nestedMarker = try XCTUnwrap(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Marker 2" }
        )
        
        let preferred = nestedMarker.preferredRole(for: .markers, using: .builtIn)
        XCTAssertEqual(preferred?.wrapped.role.lowercased(), "titles")
    }
    
    func testPreferredRoleForMarkerOnAssetClipUsesDialogue() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Keywords")
        let markers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)
        
        let flowerMarker = try XCTUnwrap(
            markers.first { $0.element.stringValue(forAttributeNamed: "value") == "Yellow Flower" }
        )
        
        let preferred = flowerMarker.preferredRole(for: .markers, using: .builtIn)
        XCTAssertEqual(preferred?.wrapped.role.lowercased(), "dialogue")
    }
    
    func testKeywordInheritedRolesReturnsAncestorClipRoles() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Keywords")
        let keywords = await timeline.fcpExtract(types: [.keyword], scope: .mainTimeline)
        
        let keyword = try XCTUnwrap(keywords.first)
        let roles = keyword.keywordInheritedRoles()
        
        XCTAssertFalse(roles.isEmpty)
        XCTAssertTrue(roles.contains { $0.wrapped.role.lowercased() == "dialogue" })
    }
    
    func testVisibleKeywordRangeOnMainTimelineReturnsTimelineBounds() async throws {
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
        
        let timeline = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "sequence")
        )
        let keywords = await timeline.fcpExtract(
            types: [.keyword],
            scope: .reportMainTimelineVisible()
        )
        let keyword = try XCTUnwrap(keywords.first)
        let range = try XCTUnwrap(keyword.visibleKeywordRangeOnMainTimeline())
        
        XCTAssertNotNil(range.timelineIn)
        XCTAssertNotNil(range.timelineOut)
        XCTAssertNotNil(range.duration)
    }
    
    func testEffectHostClipElementForTitleReturnsTitleElement() async throws {
        let timeline = try timelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        
        let title = try XCTUnwrap(titles.first)
        XCTAssertTrue(title.effectHostClipElement() === title.element)
    }
    
    func testMarkersExtractionPresetFindsNestedMarkersIncludingDisabled() async throws {
        let timeline = try timelineElement(fromSampleNamed: "DisabledClips")
        let markers = await timeline.fcpExtract(
            preset: .markers,
            scope: .reportMainTimelineVisible()
        )
        
        XCTAssertGreaterThanOrEqual(markers.count, 4)
    }
    
    func testTitlesExtractionPresetIncludesDisabledTitlesOnMainTimeline() async throws {
        let timeline = try timelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(
            preset: .titles,
            scope: .reportMainTimelineVisible()
        )
        
        XCTAssertGreaterThanOrEqual(titles.count, 2)
        XCTAssertTrue(titles.contains { $0.element.fcpGetEnabled(default: true) == false })
    }
}
