//
// FCPXMLExtractionProjectionPolicyTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Occlusion + excludeDisabledClips consistency between Extraction and Projection.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLExtractionProjectionPolicyTests: XCTestCase {
    private let projector = FinalCutPro.FCPXML.TimelineProjector()
    private typealias Collector = FinalCutPro.FCPXML.RoleInventoryClipCollector

    func testExcludeDisabledClipsAlignsTitlesEffectsMarkersAndProjection() async throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)

        var includeScope = FinalCutPro.FCPXML.ExtractionScope()
        includeScope.includeDisabled = true

        var excludeScope = FinalCutPro.FCPXML.ExtractionScope()
        excludeScope.includeDisabled = false

        let titlesIncluded = await timeline.fcpExtract(preset: .titles, scope: includeScope)
        let titlesExcluded = await timeline.fcpExtract(preset: .titles, scope: excludeScope)
        XCTAssertGreaterThan(titlesIncluded.count, titlesExcluded.count)
        XCTAssertFalse(titlesExcluded.contains { $0.element.fcpGetEnabled(default: true) == false })

        let markersIncluded = await timeline.fcpExtract(preset: .markers, scope: includeScope)
        let markersExcluded = await timeline.fcpExtract(preset: .markers, scope: excludeScope)
        XCTAssertGreaterThanOrEqual(markersIncluded.count, markersExcluded.count)

        let windowsIncluded = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .forReport(excludeDisabledClips: false, auditions: .active, mcClipAngles: .active)
        )
        let windowsExcluded = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .forReport(excludeDisabledClips: true, auditions: .active, mcClipAngles: .active)
        )
        XCTAssertGreaterThanOrEqual(windowsIncluded.count, windowsExcluded.count)
    }

    func testReportProjectionOmitsFullyOccludedLeafWindowsOnOcclusion3() async throws {
        let fcpxml = try loadFCPXMLSample(named: "Occlusion3")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)

        let withOcclusion = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .forReport(excludeDisabledClips: true, auditions: .all, mcClipAngles: .all)
        )
        let withoutOcclusionFilter = try await projector.project(
            from: source,
            fcpxml: fcpxml,
            options: .init(
                includeDisabled: false,
                auditions: .all,
                mcClipAngles: .all,
                excludeFullyOccluded: false
            )
        )

        XCTAssertLessThanOrEqual(withOcclusion.count, withoutOcclusionFilter.count)
        XCTAssertTrue(
            FinalCutPro.FCPXML.TimelineProjectionOptions.forReport(
                excludeDisabledClips: true,
                auditions: .active,
                mcClipAngles: .active
            ).excludeFullyOccluded
        )
    }

    func testTitlesHostsAreSubsetOfReportVisibilityPolicyOnOcclusion3() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        let titles = await timeline.fcpExtract(preset: .titles, scope: .init())

        XCTAssertFalse(titles.isEmpty)
        for title in titles {
            let occlusion = title.value(forContext: .effectiveOcclusion)
            XCTAssertNotEqual(occlusion, .fullyOccluded)
        }
    }

    func testRoleInventoryMayRetainFullyOccludedSyncSourceHosts() async throws {
        // Intentional inventory exception (documented): channel-source / sync-source hosts
        // can remain inventoriable when fully occluded; Titles/Effects/Markers do not.
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        let entries = await Collector.collectEntries(from: timeline, scope: .init())

        let retained = entries.filter {
            $0.extracted.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        XCTAssertFalse(
            retained.isEmpty,
            "Role Inventory should retain at least one fully occluded sync-source host on Occlusion3"
        )

        let titles = await timeline.fcpExtract(preset: .titles, scope: .init())
        XCTAssertFalse(
            titles.contains { $0.value(forContext: .effectiveOcclusion) == .fullyOccluded }
        )
    }

    func testExcludeDisabledClipsOmitsDisabledMarkersAndEffectsFromReport() async throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")

        var including = FinalCutPro.FCPXML.ReportOptions()
        including.includeMarkers = true
        including.includeEffects = true
        including.includeTitlesAndGenerators = false
        including.includeRoleInventory = false
        including.excludeDisabledClips = false

        var excluding = including
        excluding.excludeDisabledClips = true

        let reportWith = try await fcpxml.buildReport(options: including)
        let reportWithout = try await fcpxml.buildReport(options: excluding)

        let markersWith = reportWith.markers?.rows.count ?? 0
        let markersWithout = reportWithout.markers?.rows.count ?? 0
        XCTAssertGreaterThanOrEqual(markersWith, markersWithout)

        let effectsWith = reportWith.effects?.rows.count ?? 0
        let effectsWithout = reportWithout.effects?.rows.count ?? 0
        XCTAssertGreaterThanOrEqual(effectsWith, effectsWithout)
    }
}
