//
//  FCPXMLTitlesReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Titles & Generators report integration tests (optional local FCPXML fixture).
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Titles report")
struct FCPXMLTitlesReportTests {

    private func buildTitlesReport(
        from fcpxml: FinalCutPro.FCPXML
    ) async throws -> FinalCutPro.FCPXML.Report {
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeTitlesAndGenerators = true
        return try await fcpxml.buildReport(options: options)
    }

    @Test("Build titles report from fixture")
    func buildTitlesReportFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildTitlesReport(from: fcpxml)

        #expect(report.titlesAndGenerators != nil)

        let rows = report.titlesAndGenerators?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)
        #expect(FinalCutPro.FCPXML.TitleReportRow.columnHeaders.count == 9)
    }

    @Test("Title report rows have valid shape from fixture")
    func titleReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildTitlesReport(from: fcpxml)

        let rows = report.titlesAndGenerators?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows.prefix(20) {
            let clipNameEmpty = row.clipName.isEmpty
            #expect(!clipNameEmpty)
            #expect(row.roleSubrole == "Titles")
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.enabled)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.duration)
        }
    }

    @Test("Titles report sorted by timeline position")
    func titlesReportSortedByTimelinePosition() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildTitlesReport(from: fcpxml)

        let positions = report.titlesAndGenerators?.rows.map(\.timelineIn) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(positions)
    }
}

