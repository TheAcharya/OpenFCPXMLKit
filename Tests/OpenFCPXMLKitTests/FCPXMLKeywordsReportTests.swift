//
//  FCPXMLKeywordsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Keywords report integration tests (optional local FCPXML fixture).
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Keywords report")
struct FCPXMLKeywordsReportTests {

    private func buildKeywordsReport(
        from fcpxml: FinalCutPro.FCPXML
    ) async throws -> FinalCutPro.FCPXML.Report {
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeKeywords = true
        return try await fcpxml.buildReport(options: options)
    }

    @Test("Build keywords report from fixture")
    func buildKeywordsReportFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildKeywordsReport(from: fcpxml)

        #expect(report.keywords != nil)

        let rows = report.keywords?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)
        #expect(FinalCutPro.FCPXML.KeywordReportRow.columnHeaders.count == 9)
    }

    @Test("Keyword report rows have valid shape from fixture")
    func keywordReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildKeywordsReport(from: fcpxml)

        let rows = report.keywords?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows.prefix(20) {
            let keywordEmpty = row.keyword.isEmpty
            let clipNameEmpty = row.clipName.isEmpty
            #expect(!keywordEmpty)
            #expect(!clipNameEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.duration)
        }
    }

    @Test("Keywords report sorted by timeline position")
    func keywordsReportSortedByTimelinePosition() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildKeywordsReport(from: fcpxml)

        let positions = report.keywords?.rows.map(\.timelineIn) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(positions)
    }
}

