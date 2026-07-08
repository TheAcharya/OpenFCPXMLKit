//
//  FCPXMLReportTimecodeFormatTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Excel report timecode format tests: SMPTE, frames, feet+frames, and DF/NDF notation.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportTimecodeFormatTests: XCTestCase, @unchecked Sendable {
    
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
    
    func testMarkersReportFrom29_97dSampleUsesDropFrameNotation() async throws {
        let fcpxml = try loadFCPXMLSample(named: "29.97d")
        let options = markersOnlyOptions(projectName: "29.97d_V1")
        
        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []
        
        XCTAssertFalse(positions.isEmpty, "Expected markers in 29.97d sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertDropFrameTimecode(position)
        }
    }
    
    func testMarkersReportFrom29_97SampleUsesNonDropFrameNotation() async throws {
        let fcpxml = try loadFCPXMLSample(named: "29.97")
        let options = markersOnlyOptions(projectName: "29.97_V1")
        
        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []
        
        XCTAssertFalse(positions.isEmpty, "Expected markers in 29.97 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertNonDropFrameTimecode(position)
        }
    }
    
    func testRoleInventoryTimelineColumnsFrom29_97dSampleUseDropFrameNotation() async throws {
        let fcpxml = try loadFCPXMLSample(named: "29.97d")
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = "29.97d_V1"
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.roleInventory?.selectedRoles ?? []
        
        XCTAssertFalse(rows.isEmpty, "Expected role inventory rows in 29.97d sample")
        for row in rows.prefix(10) {
            FCPXMLReportingReportTestSupport.assertDropFrameTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertDropFrameTimecode(row.timelineOut)
            if !row.clipDuration.isEmpty {
                FCPXMLReportingReportTestSupport.assertDropFrameTimecode(row.clipDuration)
            }
        }
    }
    
    func testMarkersReportFramesFormatUsesIntegerPositions() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .frames
        
        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []
        
        XCTAssertFalse(positions.isEmpty, "Expected markers in 24 sample")
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
    
    func testMarkersReportFeetAndFramesFormat() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .feetAndFrames
        
        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []
        
        XCTAssertFalse(positions.isEmpty, "Expected markers in 24 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertValidTimecode(
                position,
                format: FinalCutPro.FCPXML.ReportTimecodeFormat.feetAndFrames
            )
        }
    }
    
    func testMarkersReportSmpteNoFramesFormat() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .smpteNoFrames
        
        let report = try await fcpxml.buildReport(options: options)
        let positions = report.markers?.rows.map(\.position) ?? []
        
        XCTAssertFalse(positions.isEmpty, "Expected markers in 24 sample")
        for position in positions {
            FCPXMLReportingReportTestSupport.assertValidTimecode(
                position,
                format: FinalCutPro.FCPXML.ReportTimecodeFormat.smpteNoFrames
            )
            XCTAssertFalse(position.contains(";"))
        }
    }
    
    func testMarkersWorkbookHeadersUseFramesFormatSuffix() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = markersOnlyOptions()
        options.timecodeFormat = .frames
        
        let report = try await fcpxml.buildReport(options: options)
        let headers = FinalCutPro.FCPXML.MarkerReportRow.columnHeaders(
            timecodeFormat: report.timecodeFormat
        )
        
        XCTAssertEqual(headers[3], "Position (frames)")
        XCTAssertEqual(headers[8], "Source Position (frames)")
    }
    
    @MainActor
    func testRoleInventoryWorkbookHeadersUseFeetAndFramesFormatSuffix() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.timecodeFormat = .feetAndFrames
        
        let report = try await fcpxml.buildReport(options: options)
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("F1")?.value.stringValue, "Timeline In (feet+frames)")
        XCTAssertEqual(sheet?.getCellWithFormat("G1")?.value.stringValue, "Timeline Out (feet+frames)")
        XCTAssertEqual(sheet?.getCellWithFormat("H1")?.value.stringValue, "Clip Duration (feet+frames)")
        XCTAssertEqual(sheet?.getCellWithFormat("I1")?.value.stringValue, "Source In (feet+frames)")
    }
    
    func testFullReportFrom24SampleTimecodeValuesAndHeadersMatchAllFormats() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        
        for format in FinalCutPro.FCPXML.ReportTimecodeFormat.allCases {
            var options = fullReportOptions(projectName: "24_V1")
            options.timecodeFormat = format
            
            let report = try await fcpxml.buildReport(options: options)
            XCTAssertEqual(report.timecodeFormat, format)
            
            XCTAssertFalse(report.markers?.rows.isEmpty ?? true, "Expected markers for format \(format)")
            XCTAssertFalse(
                report.roleInventory?.selectedRoles.isEmpty ?? true,
                "Expected role inventory for format \(format)"
            )
            
            FCPXMLReportingReportTestSupport.assertReportTimecodeValues(report, format: format)
            FCPXMLReportingReportTestSupport.assertReportColumnHeadersMatchTimecodeFormat(report)
        }
    }
    
    func testKeywordsReportFromKeywordsSampleTimecodeValuesAndHeadersMatchAllFormats() async throws {
        let fcpxml = try loadFCPXMLSample(named: "Keywords")
        
        for format in FinalCutPro.FCPXML.ReportTimecodeFormat.allCases {
            var options = keywordsOnlyOptions(projectName: "Marker Data Demo_V10")
            options.timecodeFormat = format
            
            let report = try await fcpxml.buildReport(options: options)
            XCTAssertFalse(report.keywords?.rows.isEmpty ?? true, "Expected keywords for format \(format)")
            
            FCPXMLReportingReportTestSupport.assertReportTimecodeValues(report, format: format)
            FCPXMLReportingReportTestSupport.assertReportColumnHeadersMatchTimecodeFormat(report)
        }
    }
    
    func testKeywordsReportFramesFormatTimelineOrderIsNumericNotLexicographic() async throws {
        let fcpxml = try loadFCPXMLSample(named: "Keywords")
        var options = keywordsOnlyOptions(projectName: "Marker Data Demo_V10")
        options.timecodeFormat = .frames
        
        let report = try await fcpxml.buildReport(options: options)
        let timelineIns = report.keywords?.rows.map(\.timelineIn) ?? []
        
        XCTAssertGreaterThan(timelineIns.count, 1, "Expected multiple keyword rows to verify sort order")
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(
            timelineIns,
            format: .frames
        )
        
        let lexicographicOrder = timelineIns.sorted { $0.compare($1) == .orderedAscending }
        let hasLexicographicMismatch = zip(timelineIns, timelineIns.dropFirst()).contains { lhs, rhs in
            FinalCutPro.FCPXML.ReportFormatting.compareTimelinePositions(
                lhs,
                rhs,
                format: .frames
            ) != lhs.compare(rhs)
        }
        
        if hasLexicographicMismatch {
            XCTAssertNotEqual(
                timelineIns,
                lexicographicOrder,
                "Keyword timeline order must use numeric frame sorting, not lexicographic strings"
            )
        }
    }
    
    func testFullReportFromComplexSampleFramesFormatAcrossPopulatedSections() async throws {
        let fcpxml = try loadFCPXMLSample(named: "Complex")
        var options = fullReportOptions(projectName: "Marker Data Demo_V2")
        options.timecodeFormat = .frames
        
        let report = try await fcpxml.buildReport(options: options)
        
        XCTAssertFalse(report.markers?.rows.isEmpty ?? true, "Expected markers in Complex sample")
        XCTAssertFalse(report.roleInventory?.selectedRoles.isEmpty ?? true, "Expected inventory in Complex sample")
        
        let populatedSectionCount = [
            report.markers?.rows.isEmpty == false,
            report.keywords?.rows.isEmpty == false,
            report.titlesAndGenerators?.rows.isEmpty == false,
            report.transitions?.rows.isEmpty == false,
            report.effects?.rows.isEmpty == false,
            report.speedChangeEffects?.rows.isEmpty == false,
            report.summary?.roleDurations.isEmpty == false
        ].filter { $0 }.count
        XCTAssertGreaterThanOrEqual(
            populatedSectionCount,
            2,
            "Expected multiple populated report sections in Complex sample"
        )
        
        FCPXMLReportingReportTestSupport.assertReportTimecodeValues(report, format: .frames)
        FCPXMLReportingReportTestSupport.assertReportColumnHeadersMatchTimecodeFormat(report)
    }
    
    @MainActor
    func testFullReportWorkbookExportUsesMatchingFramesFormatHeaders() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = fullReportOptions(projectName: "24_V1")
        options.timecodeFormat = .frames
        
        let report = try await fcpxml.buildReport(options: options)
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        
        let markersSheet = workbook.getSheet(
            name: FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName
        )
        XCTAssertEqual(markersSheet?.getCellWithFormat("D1")?.value.stringValue, "Position (frames)")
        
        let inventorySheet = workbook.getSheet(
            name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName
        )
        XCTAssertEqual(
            inventorySheet?.getCellWithFormat("F1")?.value.stringValue,
            "Timeline In (frames)"
        )
    }
}
