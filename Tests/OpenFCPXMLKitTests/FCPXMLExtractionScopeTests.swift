//
//  FCPXMLExtractionScopeTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for extraction scope configuration.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLExtractionScopeTests: XCTestCase {
    func testMainTimelineScopeExcludesDisabledElements() async throws {
        let timeline = try timelineElement(fromSampleNamed: "DisabledClips")
        
        let defaultTitles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        let visibleTitles = await timeline.fcpExtract(
            types: [.title],
            scope: .reportMainTimelineVisible()
        )
        
        XCTAssertEqual(defaultTitles.count, 1)
        XCTAssertEqual(visibleTitles.count, 2)
        XCTAssertTrue(visibleTitles.contains { $0.element.fcpGetEnabled(default: true) == false })
    }
    
    func testReportMainTimelineVisibleIncludesPartiallyOccludedElements() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        let extracted = await timeline.fcpExtract(
            types: [.title, .assetClip],
            scope: .reportMainTimelineVisible()
        )
        
        let occlusions = Set(extracted.map { $0.value(forContext: .effectiveOcclusion) })
        XCTAssertTrue(occlusions.contains(.partiallyOccluded) || occlusions.contains(.notOccluded))
    }
    
    func testReportMainTimelineVisibleExcludesFullyOccludedElements() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        let extracted = await timeline.fcpExtract(
            types: [.assetClip, .title],
            scope: .reportMainTimelineVisible()
        )
        
        XCTAssertFalse(extracted.contains { $0.value(forContext: .effectiveOcclusion) == .fullyOccluded })
    }
    
    func testConstrainToLocalTimelineLimitsExtractionDepth() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles")
        let nestedClip = try XCTUnwrap(
            firstDescendantElement(in: timeline, named: "clip")
        )
        
        let globalMarkers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)
        var localScope = FinalCutPro.FCPXML.ExtractionScope.mainTimeline
        localScope.constrainToLocalTimeline = true
        let localMarkers = await nestedClip.fcpExtract(types: [.marker], scope: localScope)
        
        XCTAssertGreaterThan(globalMarkers.count, localMarkers.count)
    }
}
