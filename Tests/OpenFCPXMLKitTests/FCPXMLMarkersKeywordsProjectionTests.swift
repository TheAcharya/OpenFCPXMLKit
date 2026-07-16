//
// FCPXMLMarkersKeywordsProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Markers + Keywords report builders prefer Projection clip annotations.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLMarkersKeywordsProjectionTests: XCTestCase {

    func testBasicMarkersReportUsesProjectionClipAnnotations() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.includeChapterMarkersInMarkersReport = true

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.markers?.rows)
        XCTAssertFalse(rows.isEmpty, "BasicMarkers title markers must appear via Projection")

        let names = Set(rows.map(\.markerName))
        XCTAssertTrue(names.contains("Standard Marker"))
        XCTAssertTrue(names.contains("To Do Marker, Incomplete") || names.contains(where: { $0.contains("To Do") }))
        XCTAssertTrue(rows.contains { $0.type == .chapter })
        XCTAssertTrue(rows.allSatisfy { !$0.position.isEmpty })
        XCTAssertTrue(rows.contains { $0.roleSubrole == "Titles" })
    }

    func testKeywordsSampleReportUsesProjectionWhenPresent() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.keywords.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.keywordsOnly
        options.includeMarkers = false

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.keywords?.rows)
        XCTAssertFalse(rows.isEmpty)
        XCTAssertTrue(rows.allSatisfy { !$0.keyword.isEmpty })
        // Most keywords have timeline In; some fixtures use value-only keywords without start.
        XCTAssertTrue(rows.contains { !$0.timelineIn.isEmpty })
    }

    func testProjectionDetailedCollectsTitleMarkersWithoutMediaWindows() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        XCTAssertTrue(
            detailed.clipAnnotations.contains { !$0.markers.isEmpty },
            "Title-hosted markers must be collected as clip annotations"
        )
        XCTAssertTrue(
            detailed.clipAnnotations.contains { $0.hostElementType == "title" }
        )
    }

    func testMarkersOnlyConsumesTimelineProjection() {
        let options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        XCTAssertTrue(options.consumesTimelineProjection)
        XCTAssertTrue(options.includeMarkers)
    }
}
