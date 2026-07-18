//
// FCPXMLExtractionProjectionPolicyTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Occlusion + excludeDisabledClips consistency between Extraction and Projection.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Extraction projection policy")
struct FCPXMLExtractionProjectionPolicyTests {
    private let projector = FinalCutPro.FCPXML.TimelineProjector()
    private typealias Collector = FinalCutPro.FCPXML.RoleInventoryClipCollector

    @Test("Exclude disabled clips aligns titles effects markers and projection")
    func excludeDisabledClipsAlignsTitlesEffectsMarkersAndProjection() async throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")
        let timeline = try #require(fcpxml.allProjects().first?.sequence.element)
        let source = try #require(fcpxml.allReportTimelineSources().first)

        var includeScope = FinalCutPro.FCPXML.ExtractionScope()
        includeScope.includeDisabled = true

        var excludeScope = FinalCutPro.FCPXML.ExtractionScope()
        excludeScope.includeDisabled = false

        let titlesIncluded = await timeline.fcpExtract(preset: .titles, scope: includeScope)
        let titlesExcluded = await timeline.fcpExtract(preset: .titles, scope: excludeScope)
        #expect(titlesIncluded.count > titlesExcluded.count)
        let excludedHasDisabled = titlesExcluded.contains {
            $0.element.fcpGetEnabled(default: true) == false
        }
        #expect(!excludedHasDisabled)

        let markersIncluded = await timeline.fcpExtract(preset: .markers, scope: includeScope)
        let markersExcluded = await timeline.fcpExtract(preset: .markers, scope: excludeScope)
        #expect(markersIncluded.count >= markersExcluded.count)

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
        #expect(windowsIncluded.count >= windowsExcluded.count)
    }

    @Test("Report projection omits fully occluded leaf windows on Occlusion3")
    func reportProjectionOmitsFullyOccludedLeafWindowsOnOcclusion3() async throws {
        let fcpxml = try requireFCPXMLSample(named: "Occlusion3")
        let source = try #require(fcpxml.allReportTimelineSources().first)

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

        #expect(withOcclusion.count <= withoutOcclusionFilter.count)
        #expect(
            FinalCutPro.FCPXML.TimelineProjectionOptions.forReport(
                excludeDisabledClips: true,
                auditions: .active,
                mcClipAngles: .active
            ).excludeFullyOccluded
        )
    }

    @Test("Titles hosts are subset of report visibility policy on Occlusion3")
    func titlesHostsAreSubsetOfReportVisibilityPolicyOnOcclusion3() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        let titles = await timeline.fcpExtract(preset: .titles, scope: .init())

        #expect(!titles.isEmpty)
        for title in titles {
            let occlusion = title.value(forContext: .effectiveOcclusion)
            #expect(occlusion != .fullyOccluded)
        }
    }

    @Test("Role inventory may retain fully occluded sync-source hosts")
    func roleInventoryMayRetainFullyOccludedSyncSourceHosts() async throws {
        // Intentional inventory exception (documented): channel-source / sync-source hosts
        // can remain inventoriable when fully occluded; Titles/Effects/Markers do not.
        let timeline = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        let entries = await Collector.collectEntries(from: timeline, scope: .init())

        let retained = entries.filter {
            $0.extracted.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        #expect(
            !retained.isEmpty,
            "Role Inventory should retain at least one fully occluded sync-source host on Occlusion3"
        )

        let titles = await timeline.fcpExtract(preset: .titles, scope: .init())
        let titlesHasFullyOccluded = titles.contains {
            $0.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        #expect(!titlesHasFullyOccluded)
    }

    @Test("Exclude disabled clips omits disabled markers and effects from report")
    func excludeDisabledClipsOmitsDisabledMarkersAndEffectsFromReport() async throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")

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
        #expect(markersWith >= markersWithout)

        let effectsWith = reportWith.effects?.rows.count ?? 0
        let effectsWithout = reportWithout.effects?.rows.count ?? 0
        #expect(effectsWith >= effectsWithout)
    }
}
