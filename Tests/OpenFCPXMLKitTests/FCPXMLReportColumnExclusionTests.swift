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
    
    func testColumnHeadersUseTimecodeFormatSuffix() {
        let headers = Layout.columnHeaders(
            metadataColumnKeys: [],
            timecodeFormat: .frames
        )
        
        XCTAssertEqual(headers[5], "Timeline In (frames)")
        XCTAssertEqual(headers[6], "Timeline Out (frames)")
        XCTAssertEqual(headers[7], "Clip Duration (frames)")
        XCTAssertEqual(headers[8], "Source In (frames)")
    }
    
    func testExclusionMatchesFormatSuffixedTimelineInHeader() {
        XCTAssertTrue(
            FinalCutPro.FCPXML.ReportColumnExclusion.isHeaderExcluded(
                "Timeline In (frames)",
                excluded: [.timelineIn],
                metadataColumnKeys: []
            )
        )
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
        
        XCTAssertEqual(sheet?.getCellWithFormat("A1")?.value.stringValue, "Row")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.value.stringValue, "Marker Name")
        XCTAssertEqual(sheet?.getCellWithFormat("C1")?.value.stringValue, "Type")
        XCTAssertEqual(sheet?.getCellWithFormat("D1")?.value.stringValue, "Position")
        XCTAssertFalse(
            [
                sheet?.getCellWithFormat("A1")?.value.stringValue,
                sheet?.getCellWithFormat("B1")?.value.stringValue,
                sheet?.getCellWithFormat("C1")?.value.stringValue,
                sheet?.getCellWithFormat("D1")?.value.stringValue,
                sheet?.getCellWithFormat("E1")?.value.stringValue,
                sheet?.getCellWithFormat("F1")?.value.stringValue,
                sheet?.getCellWithFormat("G1")?.value.stringValue
            ].contains("Reel")
        )
    }
    
    func testEnsuringRowColumnPrependsOneBasedIndices() {
        let prepared = FinalCutPro.FCPXML.ReportColumnExclusion.ensuringRowColumn(
            headers: ["Marker Name", "Type"],
            rows: [["Marker A", "Standard"], ["Marker B", "Chapter"]],
            excluded: []
        )
        
        XCTAssertEqual(prepared.headers, ["Row", "Marker Name", "Type"])
        XCTAssertEqual(prepared.rows, [
            ["1", "Marker A", "Standard"],
            ["2", "Marker B", "Chapter"]
        ])
    }
    
    func testEnsuringRowColumnRespectsRowExclusion() {
        let prepared = FinalCutPro.FCPXML.ReportColumnExclusion.ensuringRowColumn(
            headers: ["Marker Name", "Type"],
            rows: [["Marker A", "Standard"]],
            excluded: [.row]
        )
        
        XCTAssertEqual(prepared.headers, ["Marker Name", "Type"])
        XCTAssertEqual(prepared.rows, [["Marker A", "Standard"]])
    }
    
    func testFilterPrependsRowThenAppliesOtherExclusions() {
        let filtered = FinalCutPro.FCPXML.ReportColumnExclusion.filter(
            headers: ["Marker Name", "Notes", "Reel"],
            rows: [["Marker A", "Note", "A001"]],
            excluded: [.notes]
        )
        
        XCTAssertEqual(filtered.headers, ["Row", "Marker Name", "Reel"])
        XCTAssertEqual(filtered.rows, [["1", "Marker A", "A001"]])
    }
    
    @MainActor
    func testWorkbookExportIncludesRowOnSectionSheets() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                .init(
                    markerName: "Marker A",
                    type: .standard,
                    position: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "01:00:01:00"
                )
            ]),
            keywords: FinalCutPro.FCPXML.KeywordsReportSection(rows: [
                .init(
                    keyword: "KW",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:01:00",
                    duration: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video"
                )
            ]),
            titlesAndGenerators: FinalCutPro.FCPXML.TitlesReportSection(rows: [
                .init(
                    clipName: "Title",
                    enabled: "✓",
                    isApple: "✓",
                    roleSubrole: "Titles",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:01:00",
                    duration: "00:00:01:00",
                    font: "Helvetica",
                    titleText: "Hello"
                )
            ]),
            transitions: FinalCutPro.FCPXML.TransitionsReportSection(rows: [
                .init(
                    transition: "Cross Dissolve",
                    category: "Dissolve",
                    isApple: "✓",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:01:00",
                    duration: "00:00:01:00"
                )
            ]),
            effects: FinalCutPro.FCPXML.EffectsReportSection(rows: [
                .init(
                    effect: "Gaussian",
                    settings: "",
                    enabled: "✓",
                    isApple: "✓",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:01:00"
                )
            ]),
            speedChangeEffects: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection(rows: [
                .init(
                    effect: "50%",
                    settings: "",
                    enabled: "✓",
                    isApple: "",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:02:00"
                )
            ]),
            summary: FinalCutPro.FCPXML.SummaryReportSection(
                roleDurations: [
                    .init(roleSubrole: "Video", estimatedTotal: "00:00:10:00", percentOfTotal: 100)
                ]
            ),
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: ["/missing/clip.mov"]
            )
        )
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        
        let sheetNames = [
            FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName,
            FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        ]
        
        for name in sheetNames {
            let sheet = workbook.getSheet(name: name)
            XCTAssertEqual(
                sheet?.getCellWithFormat("A1")?.value.stringValue,
                "Row",
                "Expected Row as first column on \(name)"
            )
            XCTAssertEqual(
                sheet?.getCellWithFormat("A2")?.value.stringValue,
                "1",
                "Expected 1-based row index on \(name)"
            )
        }
        
        let summary = workbook.getSheet(
            name: FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName
        )
        XCTAssertEqual(summary?.getCellWithFormat("A1")?.value.stringValue, "Row")
        XCTAssertEqual(summary?.getCellWithFormat("B1")?.value.stringValue, "Role ▸ Subrole")
        XCTAssertEqual(summary?.getCellWithFormat("A2")?.value.stringValue, "1")
    }
    
    @MainActor
    func testWorkbookExportOmitsRowFromSectionSheetsWhenExcluded() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                .init(
                    markerName: "Marker A",
                    type: .standard,
                    position: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "01:00:01:00"
                )
            ]),
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: ["/missing/clip.mov"]
            ),
            excludedColumns: [.row]
        )
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        
        let markers = workbook.getSheet(
            name: FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName
        )
        XCTAssertEqual(markers?.getCellWithFormat("A1")?.value.stringValue, "Marker Name")
        XCTAssertEqual(markers?.getCellWithFormat("A2")?.value.stringValue, "Marker A")
        
        let media = workbook.getSheet(
            name: FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        )
        XCTAssertEqual(media?.getCellWithFormat("A1")?.value.stringValue, "Missing Media")
        XCTAssertEqual(media?.getCellWithFormat("A2")?.value.stringValue, "/missing/clip.mov")
    }
    
    /// Selected Roles uses a global 1-based Row sequence; each role sheet renumbers from 1.
    @MainActor
    func testWorkbookInventoryRowRenumbersIndependentlyOnSelectedRolesAndRoleSheets() throws {
        let videoA = inventoryRow(roleSubrole: "Video", clipName: "Clip A")
        let dialogue = inventoryRow(roleSubrole: "Dialogue", clipName: "Clip B")
        let videoC = inventoryRow(roleSubrole: "Video", clipName: "Clip C")
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [videoA, dialogue, videoC],
                roleSheets: [
                    .init(sheetName: "Video", rows: [videoA, videoC]),
                    .init(sheetName: "Dialogue", rows: [dialogue])
                ]
            )
        )
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let selected = try XCTUnwrap(
            workbook.getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        )
        let videoSheet = try XCTUnwrap(workbook.getSheet(name: "Video"))
        let dialogueSheet = try XCTUnwrap(workbook.getSheet(name: "Dialogue"))
        
        XCTAssertEqual(selected.getCellWithFormat("A1")?.value.stringValue, "Row")
        XCTAssertEqual(selected.getCellWithFormat("A2")?.value.stringValue, "1")
        XCTAssertEqual(selected.getCellWithFormat("A3")?.value.stringValue, "2")
        XCTAssertEqual(selected.getCellWithFormat("A4")?.value.stringValue, "3")
        XCTAssertEqual(selected.getCellWithFormat("C2")?.value.stringValue, "Clip A")
        XCTAssertEqual(selected.getCellWithFormat("C3")?.value.stringValue, "Clip B")
        XCTAssertEqual(selected.getCellWithFormat("C4")?.value.stringValue, "Clip C")
        
        // Video sheet: Clip A and Clip C are rows 1 and 2 — not the Selected Roles indices 1 and 3.
        XCTAssertEqual(videoSheet.getCellWithFormat("A1")?.value.stringValue, "Row")
        XCTAssertEqual(videoSheet.getCellWithFormat("A2")?.value.stringValue, "1")
        XCTAssertEqual(videoSheet.getCellWithFormat("A3")?.value.stringValue, "2")
        XCTAssertEqual(videoSheet.getCellWithFormat("C2")?.value.stringValue, "Clip A")
        XCTAssertEqual(videoSheet.getCellWithFormat("C3")?.value.stringValue, "Clip C")
        
        XCTAssertEqual(dialogueSheet.getCellWithFormat("A2")?.value.stringValue, "1")
        XCTAssertEqual(dialogueSheet.getCellWithFormat("C2")?.value.stringValue, "Clip B")
    }
    
    /// Selected Roles and per-role sheets share header layout, exclusions, and metadata cells.
    @MainActor
    func testWorkbookInventorySelectedRolesAndRoleSheetsShareExclusionsAndMetadata() throws {
        let ingestKey = FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue
        let video = inventoryRow(
            roleSubrole: "Video",
            clipName: "Clip A",
            metadataValues: [ingestKey: "2024-01-01"]
        )
        let dialogue = inventoryRow(
            roleSubrole: "Dialogue",
            clipName: "Clip B",
            metadataValues: [ingestKey: "2024-06-15"]
        )
        let excluded: Set<Column> = [.enabled, .notes]
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [video, dialogue],
                roleSheets: [
                    .init(sheetName: "Video", rows: [video]),
                    .init(sheetName: "Dialogue", rows: [dialogue])
                ],
                metadataColumnKeys: [ingestKey]
            ),
            excludedColumns: excluded
        )
        
        let expectedHeaders = Layout.columnHeaders(
            metadataColumnKeys: [ingestKey],
            excludedColumns: excluded
        )
        XCTAssertFalse(expectedHeaders.contains("Enabled"))
        XCTAssertFalse(expectedHeaders.contains("Notes"))
        XCTAssertTrue(expectedHeaders.contains(ingestKey))
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let selected = try XCTUnwrap(
            workbook.getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        )
        let videoSheet = try XCTUnwrap(workbook.getSheet(name: "Video"))
        let dialogueSheet = try XCTUnwrap(workbook.getSheet(name: "Dialogue"))
        
        let selectedHeaders = headerRow(from: selected, columnCount: expectedHeaders.count)
        let videoHeaders = headerRow(from: videoSheet, columnCount: expectedHeaders.count)
        let dialogueHeaders = headerRow(from: dialogueSheet, columnCount: expectedHeaders.count)
        
        XCTAssertEqual(selectedHeaders, expectedHeaders)
        XCTAssertEqual(videoHeaders, expectedHeaders)
        XCTAssertEqual(dialogueHeaders, expectedHeaders)
        
        let metadataColumn = try XCTUnwrap(expectedHeaders.firstIndex(of: ingestKey))
        let metadataAddress = excelAddress(columnZeroBased: metadataColumn, row: 2)
        XCTAssertEqual(
            selected.getCellWithFormat(metadataAddress)?.value.stringValue,
            "2024-01-01"
        )
        XCTAssertEqual(
            videoSheet.getCellWithFormat(metadataAddress)?.value.stringValue,
            "2024-01-01"
        )
        XCTAssertEqual(
            dialogueSheet.getCellWithFormat(metadataAddress)?.value.stringValue,
            "2024-06-15"
        )
        
        // With Enabled excluded, Clip Name is column C (Row, Role ▸ Subrole, Clip Name…).
        XCTAssertEqual(selected.getCellWithFormat("C2")?.value.stringValue, "Clip A")
        XCTAssertEqual(videoSheet.getCellWithFormat("C2")?.value.stringValue, "Clip A")
        XCTAssertEqual(dialogueSheet.getCellWithFormat("C2")?.value.stringValue, "Clip B")
    }
    
    private func inventoryRow(
        roleSubrole: String,
        clipName: String,
        metadataValues: [String: String] = [:]
    ) -> FinalCutPro.FCPXML.RoleClipReportRow {
        FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: roleSubrole,
            clipName: clipName,
            category: roleSubrole == "Video" ? "Primary video" : "Connected audio",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            clipDuration: "00:00:01:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: "",
            notes: "keep-me-out",
            metadataValues: metadataValues
        )
    }
    
    private func headerRow(from sheet: Sheet, columnCount: Int) -> [String] {
        (0..<columnCount).map { column in
            sheet.getCellWithFormat(excelAddress(columnZeroBased: column, row: 1))?
                .value.stringValue ?? ""
        }
    }
    
    /// 0-based column index → Excel column letters (0 → A, 25 → Z, 26 → AA).
    private func excelAddress(columnZeroBased: Int, row: Int) -> String {
        var index = columnZeroBased
        var letters = ""
        repeat {
            letters = String(UnicodeScalar(65 + index % 26)!) + letters
            index = index / 26 - 1
        } while index >= 0
        return "\(letters)\(row)"
    }
}
