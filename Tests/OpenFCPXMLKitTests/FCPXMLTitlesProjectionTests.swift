//
// FCPXMLTitlesProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Titles & Generators report builder prefers Projection title annotations.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTitlesProjectionTests: XCTestCase {

    func testTitlesRolesReportUsesProjectionTitleAnnotations() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.titlesRoles.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.titlesAndGenerators?.rows)
        XCTAssertEqual(rows.count, 2, "TitlesRoles has spine + anchored titles")
        XCTAssertTrue(rows.allSatisfy { $0.clipName == "Basic Title" })
        XCTAssertTrue(rows.allSatisfy { $0.roleSubrole == "Titles" })
        XCTAssertTrue(rows.allSatisfy { $0.titleText == "Title" })
        XCTAssertTrue(rows.contains { $0.font.contains("Helvetica") })
        XCTAssertTrue(rows.allSatisfy { !$0.timelineIn.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.timelineOut.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.duration.isEmpty })
    }

    func testBasicMarkersTitlesReportUsesProjection() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.titlesAndGenerators?.rows)
        XCTAssertFalse(rows.isEmpty, "BasicMarkers titles must appear via Projection")
        XCTAssertTrue(rows.allSatisfy { $0.roleSubrole == "Titles" })
        XCTAssertTrue(rows.contains { !$0.titleText.isEmpty })
    }

    func testProjectionDetailedCollectsTitleAnnotationsWithoutMediaWindows() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        XCTAssertTrue(
            detailed.clipAnnotations.contains { $0.title != nil },
            "Title hosts must emit WindowTitleAnnotation"
        )
        XCTAssertTrue(
            detailed.clipAnnotations.contains {
                $0.hostElementType == "title" && $0.title != nil
            }
        )
    }

    func testTitlesOnlyConsumesTimelineProjection() {
        let options = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        XCTAssertTrue(options.consumesTimelineProjection)
        XCTAssertTrue(options.includeTitlesAndGenerators)
    }

    func testDisabledTitlesRespectExcludeDisabledClips() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.disabledClips.rawValue)

        var including = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        including.excludeDisabledClips = false
        let included = try await fcpxml.buildReport(options: including)
        let includedRows = try XCTUnwrap(included.titlesAndGenerators?.rows)

        var excluding = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        excluding.excludeDisabledClips = true
        let excluded = try await fcpxml.buildReport(options: excluding)
        let excludedRows = try XCTUnwrap(excluded.titlesAndGenerators?.rows)

        XCTAssertGreaterThan(
            includedRows.count,
            excludedRows.count,
            "Excluding disabled clips should drop disabled titles"
        )
        XCTAssertTrue(includedRows.contains { $0.enabled == "✗" })
        XCTAssertTrue(excludedRows.allSatisfy { $0.enabled == "✓" })
    }
}
