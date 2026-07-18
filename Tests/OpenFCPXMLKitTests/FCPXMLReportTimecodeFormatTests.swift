//
//  FCPXMLReportTimecodeFormatTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Excel report timecode format tests: SMPTE, frames, feet+frames, and DF/NDF notation.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Report timecode format")
struct FCPXMLReportTimecodeFormatTests {

    private func markersOnlyOptions(projectName: String? = nil) -> FinalCutPro.FCPXML.ReportOptions {
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil
        options.projectName = projectName
        return options
    }

    private func fullReportOptions(projectName: String? = nil) -> FinalCutPro.FCPXML.ReportOptions {
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.workbookCoverSheet = nil
        options.projectName = projectName
        return options
    }

    private func keywordsOnlyOptions(projectName: String? = nil) -> FinalCutPro.FCPXML.ReportOptions {
        var options = FinalCutPro.FCPXML.ReportOptions.keywordsOnly
        options.workbookCoverSheet = nil
        options.projectName = projectName
        return options
    }

    @Test("Markers report from 29.97d sample uses drop-frame notation")
    func markersReportFrom29_97dSampleUsesDropFrameNotation() async throws {
        let fcpxml = try requireFCPXMLSample(named: "29.97d")
        let options = markersOnlyOptions(projectName: "29.97d_V1")

        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []

        let positionsEmpty = positions.isEmpty
        #expect(!positionsEmpty, "Expected markers in 29.97d sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertDropFrameTimecode(position)
        }
    }

    @Test("Markers report from 29.97 sample uses non-drop-frame notation")
    func markersReportFrom29_97SampleUsesNonDropFrameNotation() async throws {
        let fcpxml = try requireFCPXMLSample(named: "29.97")
        let options = markersOnlyOptions(projectName: "29.97_V1")

        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []

        let positionsEmpty = positions.isEmpty
        #expect(!positionsEmpty, "Expected markers in 29.97 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertNonDropFrameTimecode(position)
        }
    }

    @Test("Role inventory timeline columns from 29.97d sample use drop-frame notation")
    func roleInventoryTimelineColumnsFrom29_97dSampleUseDropFrameNotation() async throws {
        let fcpxml = try requireFCPXMLSample(named: "29.97d")
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = "29.97d_V1"

        let report = try await fcpxml.buildReport(options: options)
        let rows = report.roleInventory?.selectedRoles ?? []

        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty, "Expected role inventory rows in 29.97d sample")
        for row in rows.prefix(10) {
            FCPXMLReportingReportTestSupport.assertDropFrameTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertDropFrameTimecode(row.timelineOut)
            if !row.clipDuration.isEmpty {
                FCPXMLReportingReportTestSupport.assertDropFrameTimecode(row.clipDuration)
            }
        }
    }

    @Test("Markers report frames format uses integer positions")
    func markersReportFramesFormatUsesIntegerPositions() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .frames

        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []

        let positionsEmpty = positions.isEmpty
        #expect(!positionsEmpty, "Expected markers in 24 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertValidTimecode(
                position,
                format: FinalCutPro.FCPXML.ReportTimecodeFormat.frames
            )
        }
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(
            positions,
            format: .frames
        )
    }

    @Test("Markers report feet and frames format")
    func markersReportFeetAndFramesFormat() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .feetAndFrames

        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []

        let positionsEmpty = positions.isEmpty
        #expect(!positionsEmpty, "Expected markers in 24 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertValidTimecode(
                position,
                format: FinalCutPro.FCPXML.ReportTimecodeFormat.feetAndFrames
            )
        }
    }

    @Test("Markers report SMPTE no-frames format")
    func markersReportSmpteNoFramesFormat() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .smpteNoFrames

        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []

        let positionsEmpty = positions.isEmpty
        #expect(!positionsEmpty, "Expected markers in 24 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertValidTimecode(
                position,
                format: FinalCutPro.FCPXML.ReportTimecodeFormat.smpteNoFrames
            )
            let hasSemicolon = position.contains(";")
            #expect(!hasSemicolon)
        }
    }

    @Test("Markers workbook headers use frames format suffix")
    func markersWorkbookHeadersUseFramesFormatSuffix() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .frames

        let report = try await fcpxml.buildReport(options: options)
        let headers = FinalCutPro.FCPXML.MarkerReportRow.columnHeaders(
            timecodeFormat: report.timecodeFormat
        )

        #expect(headers[3] == "Position (frames)")
        #expect(headers[8] == "Source Position (frames)")
    }

    @Test("Role inventory workbook headers use feet and frames format suffix")
    @MainActor
    func roleInventoryWorkbookHeadersUseFeetAndFramesFormatSuffix() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.timecodeFormat = .feetAndFrames

        let report = try await fcpxml.buildReport(options: options)
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)

        #expect(sheet?.getCellWithFormat("F1")?.value.stringValue == "Timeline In (feet+frames)")
        #expect(sheet?.getCellWithFormat("G1")?.value.stringValue == "Timeline Out (feet+frames)")
        #expect(sheet?.getCellWithFormat("H1")?.value.stringValue == "Clip Duration (feet+frames)")
        #expect(sheet?.getCellWithFormat("I1")?.value.stringValue == "Source In (feet+frames)")
    }

    @Test("Full report from 24 sample timecode values and headers match all formats")
    func fullReportFrom24SampleTimecodeValuesAndHeadersMatchAllFormats() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")

        for format in FinalCutPro.FCPXML.ReportTimecodeFormat.allCases {
            var options = fullReportOptions(projectName: "24_V1")
            options.timecodeFormat = format

            let report = try await fcpxml.buildReport(options: options)
            #expect(report.timecodeFormat == format)

            let markersEmpty = report.markers?.rows.isEmpty ?? true
            #expect(!markersEmpty, "Expected markers for format \(format)")
            let inventoryEmpty = report.roleInventory?.selectedRoles.isEmpty ?? true
            #expect(!inventoryEmpty, "Expected role inventory for format \(format)")

            FCPXMLReportingReportTestSupport.assertReportTimecodeValues(report, format: format)
            FCPXMLReportingReportTestSupport.assertReportColumnHeadersMatchTimecodeFormat(report)
        }
    }

    @Test("Keywords report from Keywords sample timecode values and headers match all formats")
    func keywordsReportFromKeywordsSampleTimecodeValuesAndHeadersMatchAllFormats() async throws {
        let fcpxml = try requireFCPXMLSample(named: "Keywords")

        for format in FinalCutPro.FCPXML.ReportTimecodeFormat.allCases {
            var options = keywordsOnlyOptions(projectName: "Marker Data Demo_V10")
            options.timecodeFormat = format

            let report = try await fcpxml.buildReport(options: options)
            let keywordsEmpty = report.keywords?.rows.isEmpty ?? true
            #expect(!keywordsEmpty, "Expected keywords for format \(format)")

            FCPXMLReportingReportTestSupport.assertReportTimecodeValues(report, format: format)
            FCPXMLReportingReportTestSupport.assertReportColumnHeadersMatchTimecodeFormat(report)
        }
    }

    @Test("Keywords report frames format timeline order is numeric not lexicographic")
    func keywordsReportFramesFormatTimelineOrderIsNumericNotLexicographic() async throws {
        let fcpxml = try requireFCPXMLSample(named: "Keywords")
        var options = keywordsOnlyOptions(projectName: "Marker Data Demo_V10")
        options.timecodeFormat = .frames

        let report = try await fcpxml.buildReport(options: options)
        let timelineIns = report.keywords?.rows.map(\.timelineIn) ?? []

        #expect(timelineIns.count > 1, "Expected multiple keyword rows to verify sort order")
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(
            timelineIns,
            format: .frames
        )

        let numericOrder = timelineIns.sorted {
            FinalCutPro.FCPXML.ReportFormatting.compareTimelinePositions(
                $0,
                $1,
                format: .frames
            ) == .orderedAscending
        }
        let lexicographicOrder = timelineIns.sorted { $0.compare($1) == .orderedAscending }

        #expect(
            numericOrder != lexicographicOrder,
            "Keywords sample must include frame values where numeric and lexicographic sort orders differ"
        )
        #expect(
            timelineIns != lexicographicOrder,
            "Keyword timeline order must use numeric frame sorting, not lexicographic strings"
        )
    }

    @Test("Full report from Complex sample frames format across populated sections")
    func fullReportFromComplexSampleFramesFormatAcrossPopulatedSections() async throws {
        let fcpxml = try requireFCPXMLSample(named: "Complex")
        var options = fullReportOptions(projectName: "Marker Data Demo_V2")
        options.timecodeFormat = .frames

        let report = try await fcpxml.buildReport(options: options)

        let markersEmpty = report.markers?.rows.isEmpty ?? true
        #expect(!markersEmpty, "Expected markers in Complex sample")
        let inventoryEmpty = report.roleInventory?.selectedRoles.isEmpty ?? true
        #expect(!inventoryEmpty, "Expected inventory in Complex sample")

        let populatedSectionCount = [
            report.markers?.rows.isEmpty == false,
            report.keywords?.rows.isEmpty == false,
            report.titlesAndGenerators?.rows.isEmpty == false,
            report.transitions?.rows.isEmpty == false,
            report.effects?.rows.isEmpty == false,
            report.speedChangeEffects?.rows.isEmpty == false,
            report.summary?.roleDurations.isEmpty == false
        ].filter { $0 }.count
        #expect(
            populatedSectionCount >= 2,
            "Expected multiple populated report sections in Complex sample"
        )

        FCPXMLReportingReportTestSupport.assertReportTimecodeValues(report, format: .frames)
        FCPXMLReportingReportTestSupport.assertReportColumnHeadersMatchTimecodeFormat(report)
    }

    @Test("Full report workbook export uses matching frames format headers")
    @MainActor
    func fullReportWorkbookExportUsesMatchingFramesFormatHeaders() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = fullReportOptions(projectName: "24_V1")
        options.timecodeFormat = .frames

        let report = try await fcpxml.buildReport(options: options)
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)

        let markersSheet = workbook.getSheet(
            name: FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName
        )
        // Markers: Row, Marker Name, Type, Notes, Position (frames), …
        #expect(markersSheet?.getCellWithFormat("A1")?.value.stringValue == "Row")
        #expect(markersSheet?.getCellWithFormat("E1")?.value.stringValue == "Position (frames)")

        let inventorySheet = workbook.getSheet(
            name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName
        )
        #expect(
            inventorySheet?.getCellWithFormat("F1")?.value.stringValue
                == "Timeline In (frames)"
        )
    }
}
