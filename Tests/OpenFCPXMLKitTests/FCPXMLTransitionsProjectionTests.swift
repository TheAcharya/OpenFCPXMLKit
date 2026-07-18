//
// FCPXMLTransitionsProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Transitions report builder prefers Projection transition annotations.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Transitions projection")
struct FCPXMLTransitionsProjectionTests {

    @Test("TransitionMarkers report uses projection annotations")
    func transitionMarkersReportUsesProjectionAnnotations() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.transitionMarkers1.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.transitions?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows, "TransitionMarkers1 must yield Transitions via Projection")
        let hasPrimary = rows.contains { $0.category == "Primary transition" }
        #expect(hasPrimary)
        let allHaveIn = rows.allSatisfy { !$0.timelineIn.isEmpty }
        let allHaveOut = rows.allSatisfy { !$0.timelineOut.isEmpty }
        let allHaveDuration = rows.allSatisfy { !$0.duration.isEmpty }
        let allHaveTransition = rows.allSatisfy { !$0.transition.isEmpty }
        #expect(allHaveIn)
        #expect(allHaveOut)
        #expect(allHaveDuration)
        #expect(allHaveTransition)
    }

    @Test("Projection detailed collects transition annotations")
    func projectionDetailedCollectsTransitionAnnotations() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.transitionMarkers1.rawValue)
        let source = try #require(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        let hasTransition = detailed.clipAnnotations.contains { $0.transition != nil }
        #expect(hasTransition, "Transition hosts must emit WindowTransitionAnnotation")
        let hasTransitionHost = detailed.clipAnnotations.contains {
            $0.hostElementType == "transition" && $0.transition != nil
        }
        #expect(hasTransitionHost)
    }

    @Test("Transitions-only consumes timeline projection")
    func transitionsOnlyConsumesTimelineProjection() {
        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly
        #expect(options.consumesTimelineProjection)
        #expect(options.includeTransitions)
    }

    @Test("TransitionMarkers2 report has rows when present")
    func transitionMarkers2ReportHasRowsWhenPresent() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.transitionMarkers2.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.transitions?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows)
        let allHaveTransition = rows.allSatisfy { !$0.transition.isEmpty }
        #expect(allHaveTransition)
    }
}

