//
//  FCPXMLTitlesReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Titles & Generators report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTitlesReportTests: XCTestCase, @unchecked Sendable {
    
    private func buildTitlesReport(
        from fcpxml: FinalCutPro.FCPXML
    ) async throws -> FinalCutPro.FCPXML.Report {
        try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeTitlesAndGenerators = true
            }
        )
    }
    
    func testBuildTitlesReportFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildTitlesReport(from: fcpxml)
        
        XCTAssertNotNil(report.titlesAndGenerators)
        
        let rows = report.titlesAndGenerators?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(FinalCutPro.FCPXML.TitleReportRow.columnHeaders.count, 9)
    }
    
    func testTitleReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildTitlesReport(from: fcpxml)
        
        let rows = report.titlesAndGenerators?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows.prefix(20) {
            XCTAssertFalse(row.clipName.isEmpty)
            XCTAssertEqual(row.roleSubrole, "Titles")
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.enabled)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.duration)
        }
    }
    
    func testTitlesReportSortedByTimelinePosition() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildTitlesReport(from: fcpxml)
        
        let positions = report.titlesAndGenerators?.rows.map(\.timelineIn) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(positions)
    }
}
