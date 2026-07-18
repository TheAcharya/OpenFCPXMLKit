//
//  FCPXMLTransitionsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Transitions report integration tests (optional local FCPXML fixture).
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Transitions report")
struct FCPXMLTransitionsReportTests {

    @Test("Build transitions report from fixture")
    func buildTransitionsReportFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)

        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = projectName
        options.includeTransitions = true

        let report = try await fcpxml.buildReport(options: options)

        #expect(report.projectName == projectName)
        #expect(report.transitions != nil)
        #expect(
            FinalCutPro.FCPXML.TransitionReportRow.columnHeaders.count
                == 6
        )
    }

    @Test("Transition report rows have valid shape from fixture")
    func transitionReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()

        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeTransitions = true

        let report = try await fcpxml.buildReport(options: options)

        let rows = report.transitions?.rows ?? []

        for row in rows {
            let transitionEmpty = row.transition.isEmpty
            let categoryEmpty = row.category.isEmpty
            #expect(!transitionEmpty)
            #expect(!categoryEmpty)
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.isApple)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.duration)
        }
    }

    @Test("Transitions report sorted by timeline in")
    func transitionsReportSortedByTimelineIn() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()

        let options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly.merging(
            projectName: FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        )

        let report = try await fcpxml.buildReport(options: options)

        let timelineIns = report.transitions?.rows.map(\.timelineIn) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(timelineIns)
    }
}

private extension FinalCutPro.FCPXML.ReportOptions {
    func merging(projectName: String?) -> Self {
        var copy = self
        copy.projectName = projectName
        return copy
    }
}

