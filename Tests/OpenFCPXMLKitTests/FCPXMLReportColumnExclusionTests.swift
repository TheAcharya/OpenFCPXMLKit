//
//  FCPXMLReportColumnExclusionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for global workbook column exclusion.
//

import XCTest
@testable import OpenFCPXMLKit
import XLKit

@available(macOS 26.0, *)
final class FCPXMLReportColumnExclusionTests: XCTestCase {
    private typealias Layout = FinalCutPro.FCPXML.RoleInventoryColumnLayout
    private typealias Column = FinalCutPro.FCPXML.ReportColumn
    
    func testResolveColumnAcceptsCommonAliases() {
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Row Numbers"),
            .row
        )
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Role • Subrole"),
            .roleSubrole
        )
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("frame rate"),
            .frameRateSampleRate
        )
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Metadata"),
            .metadata
        )
    }
    
    func testColumnHeadersOmitExcludedColumns() {
        let ingestKey = FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue
        let headers = Layout.columnHeaders(
            metadataColumnKeys: [ingestKey],
            excludedColumns: [.row, .enabled, .metadata]
        )
        
        XCTAssertFalse(headers.contains("Row"))
        XCTAssertFalse(headers.contains("Enabled"))
        XCTAssertFalse(headers.contains(ingestKey))
        XCTAssertTrue(headers.contains("Clip Name"))
        XCTAssertTrue(headers.contains("Role ▸ Subrole"))
    }
    
    func testColumnValuesAlignWithExcludedHeaders() {
        let ingestKey = FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue
        let row = FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: "Video",
            clipName: "Clip A",
            category: "Primary video",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            clipDuration: "00:00:01:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: "",
            metadataValues: [ingestKey: "2024-01-01"]
        )
        
        let excluded: Set<Column> = [.row, .metadata]
        let headers = Layout.columnHeaders(
            metadataColumnKeys: [ingestKey],
            excludedColumns: excluded
        )
        let values = Layout.columnValues(
            for: row,
            rowIndex: 3,
            metadataColumnKeys: [ingestKey],
            excludedColumns: excluded
        )
        
        XCTAssertEqual(headers.count, values.count)
        XCTAssertEqual(headers.first, "Role ▸ Subrole")
        XCTAssertEqual(values.first, "Video")
        XCTAssertFalse(headers.contains(ingestKey))
    }
    
    @MainActor
    func testWorkbookExportOmitsExcludedInventoryColumns() {
        let ingestKey = FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [
                    .init(
                        roleSubrole: "Video",
                        clipName: "Clip",
                        category: "Primary video",
                        enabled: "✓",
                        timelineIn: "00:00:00:00",
                        timelineOut: "00:00:01:00",
                        clipDuration: "00:00:01:00",
                        sourceIn: "",
                        sourceOut: "",
                        sourceDuration: "",
                        metadataValues: [ingestKey: "2024-01-01"]
                    )
                ],
                metadataColumnKeys: [ingestKey]
            ),
            excludedColumns: [.row, .enabled, .metadata]
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A1")?.value.stringValue, "Role ▸ Subrole")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.value.stringValue, "Clip Name")
        XCTAssertEqual(sheet?.getCellWithFormat("C1")?.value.stringValue, "Category")
    }
    
    @MainActor
    func testWorkbookExportOmitsExcludedColumnsFromMarkersSheet() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                .init(
                    markerName: "Marker A",
                    type: .standard,
                    notes: "Note",
                    position: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1",
                    sourcePosition: "01:00:01:00"
                )
            ]),
            excludedColumns: [.reel, .scene, .notes]
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A1")?.value.stringValue, "Marker Name")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.value.stringValue, "Type")
        XCTAssertEqual(sheet?.getCellWithFormat("C1")?.value.stringValue, "Position")
        XCTAssertFalse(
            [
                sheet?.getCellWithFormat("A1")?.value.stringValue,
                sheet?.getCellWithFormat("B1")?.value.stringValue,
                sheet?.getCellWithFormat("C1")?.value.stringValue,
                sheet?.getCellWithFormat("D1")?.value.stringValue,
                sheet?.getCellWithFormat("E1")?.value.stringValue,
                sheet?.getCellWithFormat("F1")?.value.stringValue
            ].contains("Reel")
        )
    }
}
