//
//  FCPXMLKeywordsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Keywords report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLKeywordsReportTests: XCTestCase, @unchecked Sendable {
    
    private func buildKeywordsReport(
        from fcpxml: FinalCutPro.FCPXML
    ) async throws -> FinalCutPro.FCPXML.Report {
        try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeKeywords = true
            }
        )
    }
    
    func testBuildKeywordsReportFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildKeywordsReport(from: fcpxml)
        
        XCTAssertNotNil(report.keywords)
        
        let rows = report.keywords?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(FinalCutPro.FCPXML.KeywordReportRow.columnHeaders.count, 9)
    }
    
    func testKeywordReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildKeywordsReport(from: fcpxml)
        
        let rows = report.keywords?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows.prefix(20) {
            XCTAssertFalse(row.keyword.isEmpty)
            XCTAssertFalse(row.clipName.isEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.duration)
        }
    }
    
    func testKeywordsReportSortedByTimelinePosition() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildKeywordsReport(from: fcpxml)
        
        let positions = report.keywords?.rows.map(\.timelineIn) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(positions)
    }
}
