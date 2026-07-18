//
//  FCPXMLEffectsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Video & Audio Effects report integration tests (optional local FCPXML fixture).
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Effects report")
struct FCPXMLEffectsReportTests {

    private func buildEffectsReport(
        from fcpxml: FinalCutPro.FCPXML
    ) async throws -> FinalCutPro.FCPXML.Report {
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeEffects = true
        return try await fcpxml.buildReport(options: options)
    }

    @Test("Build effects report from fixture")
    func buildEffectsReportFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildEffectsReport(from: fcpxml)

        #expect(report.effects != nil)

        let rows = report.effects?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)
        #expect(FinalCutPro.FCPXML.EffectReportRow.columnHeaders.count == 8)
    }

    @Test("Effects report rows have valid shape from fixture")
    func effectsReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildEffectsReport(from: fcpxml)

        let rows = report.effects?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows.prefix(20) {
            let clipNameEmpty = row.clipName.isEmpty
            let effectEmpty = row.effect.isEmpty
            #expect(!clipNameEmpty)
            #expect(!effectEmpty)
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.enabled)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }

    @Test("Effects report sorted by timeline position")
    func effectsReportSortedByTimelinePosition() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await buildEffectsReport(from: fcpxml)

        let rows = report.effects?.rows ?? []
        let sorted = rows.sorted {
            if $0.timelineIn != $1.timelineIn {
                return $0.timelineIn.localizedStandardCompare($1.timelineIn) == .orderedAscending
            }
            if $0.timelineOut != $1.timelineOut {
                return $0.timelineOut.localizedStandardCompare($1.timelineOut) == .orderedDescending
            }
            let clipCompare = $0.clipName.localizedStandardCompare($1.clipName)
            if clipCompare != .orderedSame {
                return clipCompare == .orderedAscending
            }
            let effectCompare = $0.effect.localizedStandardCompare($1.effect)
            if effectCompare != .orderedSame {
                return effectCompare == .orderedAscending
            }
            return $0.settings.localizedStandardCompare($1.settings) == .orderedAscending
        }
        #expect(rows == sorted)
    }
}

