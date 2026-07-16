//
// FCPXMLTransitionsProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Transitions report builder prefers Projection transition annotations.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTransitionsProjectionTests: XCTestCase {

    func testTransitionMarkersReportUsesProjectionAnnotations() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.transitionMarkers1.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.transitions?.rows)
        XCTAssertFalse(rows.isEmpty, "TransitionMarkers1 must yield Transitions via Projection")
        XCTAssertTrue(rows.contains { $0.category == "Primary transition" })
        XCTAssertTrue(rows.allSatisfy { !$0.timelineIn.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.timelineOut.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.duration.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.transition.isEmpty })
    }

    func testProjectionDetailedCollectsTransitionAnnotations() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.transitionMarkers1.rawValue)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        XCTAssertTrue(
            detailed.clipAnnotations.contains { $0.transition != nil },
            "Transition hosts must emit WindowTransitionAnnotation"
        )
        XCTAssertTrue(
            detailed.clipAnnotations.contains {
                $0.hostElementType == "transition" && $0.transition != nil
            }
        )
    }

    func testTransitionsOnlyConsumesTimelineProjection() {
        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly
        XCTAssertTrue(options.consumesTimelineProjection)
        XCTAssertTrue(options.includeTransitions)
    }

    func testTransitionMarkers2ReportHasRowsWhenPresent() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.transitionMarkers2.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.transitions?.rows)
        XCTAssertFalse(rows.isEmpty)
        XCTAssertTrue(rows.allSatisfy { !$0.transition.isEmpty })
    }
}
