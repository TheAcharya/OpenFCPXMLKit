//
//  FCPXMLSummaryReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Summary report integration tests (optional local FCPXML fixture).
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Summary report")
struct FCPXMLSummaryReportTests {

    @Test("Summary percent columnValues match Excel 0.0% display")
    func summaryPercentColumnValuesMatchExcelPercentDisplay() {
        typealias Row = FinalCutPro.FCPXML.SummaryRoleDurationRow
        #expect(Row.formattedPercentOfTotal(0.5) == "50.0%")
        #expect(Row.formattedPercentOfTotal(0.33) == "33.0%")
        #expect(Row.formattedPercentOfTotal(3.8961593172119295) == "389.6%")
        #expect(Row.formattedPercentOfTotal(10.289439694628776) == "1028.9%")
        #expect(Row.formattedPercentOfTotal(2.0) == "200.0%")
        
        let values = Row(
            roleSubrole: "Titles",
            estimatedTotal: "00:21:54:18",
            percentOfTotal: 3.8961593172119295
        ).columnValues
        #expect(values.last == "389.6%")
    }

    private func summaryOptions(
        for fcpxml: FinalCutPro.FCPXML
    ) throws -> FinalCutPro.FCPXML.ReportOptions {
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeSummary = true
        options.mediaBaseURL = try requireReportingFixtureMediaBaseURL()
        return options
    }

    @Test("Build summary report project header from fixture")
    func buildSummaryReportProjectHeaderFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: try summaryOptions(for: fcpxml))

        #expect(report.summary != nil)

        let projectSummary = report.summary?.projectSummary
        #expect(projectSummary?.title == FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml))
        FCPXMLReportingReportTestSupport.assertValidTimecode(projectSummary?.duration ?? "")
        let resolutionEmpty = projectSummary?.resolution.isEmpty ?? true
        let frameRateEmpty = projectSummary?.frameRate.isEmpty ?? true
        let audioSampleRateEmpty = projectSummary?.audioSampleRate.isEmpty ?? true
        #expect(!resolutionEmpty)
        #expect(!frameRateEmpty)
        #expect(!audioSampleRateEmpty)
    }

    @Test("Summary role duration rows have valid shape from fixture")
    func summaryRoleDurationRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: try summaryOptions(for: fcpxml))

        let rows = report.summary?.roleDurations ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows {
            let roleEmpty = row.roleSubrole.isEmpty
            #expect(!roleEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.estimatedTotal)
            #expect(row.percentOfTotal >= 0)
        }
    }

    @Test("Summary missing media paths from fixture")
    func summaryMissingMediaPathsFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeMediaSummary = true
        options.mediaBaseURL = try requireReportingFixtureMediaBaseURL()
        let report = try await fcpxml.buildReport(options: options)

        let paths = report.mediaSummary?.missingMediaPaths ?? []
        let pathsEmpty = paths.isEmpty
        #expect(!pathsEmpty)
        #expect(paths.allSatisfy { $0.hasPrefix("/") })
        #expect(report.summary == nil)
    }

    @Test("Summary only preset enables summary section only")
    func summaryOnlyPresetEnablesSummarySectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.summaryOnly

        #expect(!options.includeMarkers)
        #expect(!options.includeKeywords)
        #expect(!options.includeTitlesAndGenerators)
        #expect(!options.includeTransitions)
        #expect(!options.includeEffects)
        #expect(options.includeSummary)
        #expect(!options.includeMediaSummary)
        #expect(!options.includeRoleInventory)
    }

    @Test("Media summary only preset enables media summary section only")
    func mediaSummaryOnlyPresetEnablesMediaSummarySectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly

        #expect(!options.includeMarkers)
        #expect(!options.includeKeywords)
        #expect(!options.includeTitlesAndGenerators)
        #expect(!options.includeTransitions)
        #expect(!options.includeEffects)
        #expect(!options.includeSummary)
        #expect(options.includeMediaSummary)
        #expect(!options.includeRoleInventory)
    }
}

