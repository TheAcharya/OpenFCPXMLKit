//
//  FCPXMLExtractionScopeTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for extraction scope configuration.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Extraction scope")
struct FCPXMLExtractionScopeTests {
    @Test("Main timeline scope excludes disabled elements")
    func mainTimelineScopeExcludesDisabledElements() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "DisabledClips")

        let defaultTitles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        let visibleTitles = await timeline.fcpExtract(
            types: [.title],
            scope: .reportMainTimelineVisible()
        )

        #expect(defaultTitles.count == 1)
        #expect(visibleTitles.count == 2)
        let hasDisabled = visibleTitles.contains { $0.element.fcpGetEnabled(default: true) == false }
        #expect(hasDisabled)
    }

    @Test("Report main timeline visible includes partially occluded elements")
    func reportMainTimelineVisibleIncludesPartiallyOccludedElements() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        let extracted = await timeline.fcpExtract(
            types: [.title, .assetClip],
            scope: .reportMainTimelineVisible()
        )

        let occlusions = Set(extracted.map { $0.value(forContext: .effectiveOcclusion) })
        let hasVisibleOcclusion =
            occlusions.contains(.partiallyOccluded) || occlusions.contains(.notOccluded)
        #expect(hasVisibleOcclusion)
    }

    @Test("Report main timeline visible excludes fully occluded elements")
    func reportMainTimelineVisibleExcludesFullyOccludedElements() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        let extracted = await timeline.fcpExtract(
            types: [.assetClip, .title],
            scope: .reportMainTimelineVisible()
        )

        let hasFullyOccluded = extracted.contains {
            $0.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        #expect(!hasFullyOccluded)
    }

    @Test("Constrain to local timeline limits extraction depth")
    func constrainToLocalTimelineLimitsExtractionDepth() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let nestedClip = try #require(
            firstDescendantElement(in: timeline, named: "clip")
        )

        let globalMarkers = await timeline.fcpExtract(types: [.marker], scope: .mainTimeline)
        var localScope = FinalCutPro.FCPXML.ExtractionScope.mainTimeline
        localScope.constrainToLocalTimeline = true
        let localMarkers = await nestedClip.fcpExtract(types: [.marker], scope: localScope)

        #expect(globalMarkers.count > localMarkers.count)
    }
}

