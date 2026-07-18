//
//  FCPXMLReportColumnExclusionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for global workbook column exclusion.
//

import Testing
@testable import OpenFCPXMLKit
import XLKit

@Suite("Report column exclusion")
struct FCPXMLReportColumnExclusionTests {
    private typealias Layout = FinalCutPro.FCPXML.RoleInventoryColumnLayout
    private typealias Column = FinalCutPro.FCPXML.ReportColumn

    @Test("Resolve column accepts common aliases")
    func resolveColumnAcceptsCommonAliases() {
        #expect(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Row Numbers")
                == .row
        )
        #expect(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Role • Subrole")
                == .roleSubrole
        )
        #expect(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("frame rate")
                == .frameRateSampleRate
        )
        #expect(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Metadata")
                == .metadata
        )
    }

    @Test("Column headers omit excluded columns")
    func columnHeadersOmitExcludedColumns() {
        let ingestKey = FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue
        let headers = Layout.columnHeaders(
            metadataColumnKeys: [ingestKey],
            excludedColumns: [.row, .enabled, .metadata]
        )

        #expect(!headers.contains("Row"))
        #expect(!headers.contains("Enabled"))
        #expect(!headers.contains(ingestKey))
        #expect(headers.contains("Clip Name"))
        #expect(headers.contains("Role ▸ Subrole"))
    }

    @Test("Column headers use timecode format suffix")
    func columnHeadersUseTimecodeFormatSuffix() {
        let headers = Layout.columnHeaders(
            metadataColumnKeys: [],
            timecodeFormat: .frames
        )

        #expect(headers[5] == "Timeline In (frames)")
        #expect(headers[6] == "Timeline Out (frames)")
        #expect(headers[7] == "Clip Duration (frames)")
        #expect(headers[8] == "Source In (frames)")
    }

    @Test("Exclusion matches format-suffixed Timeline In header")
    func exclusionMatchesFormatSuffixedTimelineInHeader() {
        #expect(
            FinalCutPro.FCPXML.ReportColumnExclusion.isHeaderExcluded(
                "Timeline In (frames)",
                excluded: [.timelineIn],
                metadataColumnKeys: []
            )
        )
    }

    @Test("Column values align with excluded headers")
    func columnValuesAlignWithExcludedHeaders() {
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

        #expect(headers.count == values.count)
        #expect(headers.first == "Role ▸ Subrole")
        #expect(values.first == "Video")
        #expect(!headers.contains(ingestKey))
    }

    @Test("Workbook export omits excluded inventory columns")
    @MainActor
    func workbookExportOmitsExcludedInventoryColumns() {
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

        #expect(sheet?.getCellWithFormat("A1")?.value.stringValue == "Role ▸ Subrole")
        #expect(sheet?.getCellWithFormat("B1")?.value.stringValue == "Clip Name")
        #expect(sheet?.getCellWithFormat("C1")?.value.stringValue == "Category")
    }

    @Test("Workbook export omits excluded columns from Markers sheet")
    @MainActor
    func workbookExportOmitsExcludedColumnsFromMarkersSheet() {
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

        let headerCells = [
            sheet?.getCellWithFormat("A1")?.value.stringValue,
            sheet?.getCellWithFormat("B1")?.value.stringValue,
            sheet?.getCellWithFormat("C1")?.value.stringValue,
            sheet?.getCellWithFormat("D1")?.value.stringValue,
            sheet?.getCellWithFormat("E1")?.value.stringValue,
            sheet?.getCellWithFormat("F1")?.value.stringValue,
            sheet?.getCellWithFormat("G1")?.value.stringValue
        ]
        #expect(headerCells[0] == "Row")
        #expect(headerCells[1] == "Marker Name")
        #expect(headerCells[2] == "Type")
        #expect(headerCells[3] == "Position")
        #expect(!headerCells.contains(where: { $0 == "Reel" }))
    }

    @Test("ensuringRowColumn prepends one-based indices")
    func ensuringRowColumnPrependsOneBasedIndices() {
        let prepared = FinalCutPro.FCPXML.ReportColumnExclusion.ensuringRowColumn(
            headers: ["Marker Name", "Type"],
            rows: [["Marker A", "Standard"], ["Marker B", "Chapter"]],
            excluded: []
        )

        #expect(prepared.headers == ["Row", "Marker Name", "Type"])
        #expect(prepared.rows == [
            ["1", "Marker A", "Standard"],
            ["2", "Marker B", "Chapter"]
        ])
    }

    @Test("ensuringRowColumn respects Row exclusion")
    func ensuringRowColumnRespectsRowExclusion() {
        let prepared = FinalCutPro.FCPXML.ReportColumnExclusion.ensuringRowColumn(
            headers: ["Marker Name", "Type"],
            rows: [["Marker A", "Standard"]],
            excluded: [.row]
        )

        #expect(prepared.headers == ["Marker Name", "Type"])
        #expect(prepared.rows == [["Marker A", "Standard"]])
    }

    @Test("filter prepends Row then applies other exclusions")
    func filterPrependsRowThenAppliesOtherExclusions() {
        let filtered = FinalCutPro.FCPXML.ReportColumnExclusion.filter(
            headers: ["Marker Name", "Notes", "Reel"],
            rows: [["Marker A", "Note", "A001"]],
            excluded: [.notes]
        )

        #expect(filtered.headers == ["Row", "Marker Name", "Reel"])
        #expect(filtered.rows == [["1", "Marker A", "A001"]])
    }

    @Test("Workbook export includes Row on section sheets")
    @MainActor
    func workbookExportIncludesRowOnSectionSheets() {
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
            #expect(
                sheet?.getCellWithFormat("A1")?.value.stringValue == "Row",
                "Expected Row as first column on \(name)"
            )
            #expect(
                sheet?.getCellWithFormat("A2")?.value.stringValue == "1",
                "Expected 1-based row index on \(name)"
            )
        }

        let summary = workbook.getSheet(
            name: FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName
        )
        #expect(summary?.getCellWithFormat("A1")?.value.stringValue == "Row")
        #expect(summary?.getCellWithFormat("B1")?.value.stringValue == "Role ▸ Subrole")
        #expect(summary?.getCellWithFormat("A2")?.value.stringValue == "1")
    }

    @Test("Workbook export omits Row from section sheets when excluded")
    @MainActor
    func workbookExportOmitsRowFromSectionSheetsWhenExcluded() {
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
        #expect(markers?.getCellWithFormat("A1")?.value.stringValue == "Marker Name")
        #expect(markers?.getCellWithFormat("A2")?.value.stringValue == "Marker A")

        let media = workbook.getSheet(
            name: FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        )
        #expect(media?.getCellWithFormat("A1")?.value.stringValue == "Missing Media")
        #expect(media?.getCellWithFormat("A2")?.value.stringValue == "/missing/clip.mov")
    }

    /// Selected Roles uses a global 1-based Row sequence; each role sheet renumbers from 1.
    @Test("Inventory Row renumbers independently on Selected Roles and role sheets")
    @MainActor
    func workbookInventoryRowRenumbersIndependentlyOnSelectedRolesAndRoleSheets() throws {
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
        let selected = try #require(
            workbook.getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        )
        let videoSheet = try #require(workbook.getSheet(name: "Video"))
        let dialogueSheet = try #require(workbook.getSheet(name: "Dialogue"))

        #expect(selected.getCellWithFormat("A1")?.value.stringValue == "Row")
        #expect(selected.getCellWithFormat("A2")?.value.stringValue == "1")
        #expect(selected.getCellWithFormat("A3")?.value.stringValue == "2")
        #expect(selected.getCellWithFormat("A4")?.value.stringValue == "3")
        #expect(selected.getCellWithFormat("C2")?.value.stringValue == "Clip A")
        #expect(selected.getCellWithFormat("C3")?.value.stringValue == "Clip B")
        #expect(selected.getCellWithFormat("C4")?.value.stringValue == "Clip C")

        // Video sheet: Clip A and Clip C are rows 1 and 2 — not the Selected Roles indices 1 and 3.
        #expect(videoSheet.getCellWithFormat("A1")?.value.stringValue == "Row")
        #expect(videoSheet.getCellWithFormat("A2")?.value.stringValue == "1")
        #expect(videoSheet.getCellWithFormat("A3")?.value.stringValue == "2")
        #expect(videoSheet.getCellWithFormat("C2")?.value.stringValue == "Clip A")
        #expect(videoSheet.getCellWithFormat("C3")?.value.stringValue == "Clip C")

        #expect(dialogueSheet.getCellWithFormat("A2")?.value.stringValue == "1")
        #expect(dialogueSheet.getCellWithFormat("C2")?.value.stringValue == "Clip B")
    }

    /// Selected Roles and per-role sheets share header layout, exclusions, and metadata cells.
    @Test("Inventory Selected Roles and role sheets share exclusions and metadata")
    @MainActor
    func workbookInventorySelectedRolesAndRoleSheetsShareExclusionsAndMetadata() throws {
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
        #expect(!expectedHeaders.contains("Enabled"))
        #expect(!expectedHeaders.contains("Notes"))
        #expect(expectedHeaders.contains(ingestKey))

        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let selected = try #require(
            workbook.getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        )
        let videoSheet = try #require(workbook.getSheet(name: "Video"))
        let dialogueSheet = try #require(workbook.getSheet(name: "Dialogue"))

        let selectedHeaders = headerRow(from: selected, columnCount: expectedHeaders.count)
        let videoHeaders = headerRow(from: videoSheet, columnCount: expectedHeaders.count)
        let dialogueHeaders = headerRow(from: dialogueSheet, columnCount: expectedHeaders.count)

        #expect(selectedHeaders == expectedHeaders)
        #expect(videoHeaders == expectedHeaders)
        #expect(dialogueHeaders == expectedHeaders)

        let metadataColumn = try #require(expectedHeaders.firstIndex(of: ingestKey))
        let metadataAddress = excelAddress(columnZeroBased: metadataColumn, row: 2)
        #expect(
            selected.getCellWithFormat(metadataAddress)?.value.stringValue
                == "2024-01-01"
        )
        #expect(
            videoSheet.getCellWithFormat(metadataAddress)?.value.stringValue
                == "2024-01-01"
        )
        #expect(
            dialogueSheet.getCellWithFormat(metadataAddress)?.value.stringValue
                == "2024-06-15"
        )

        // With Enabled excluded, Clip Name is column C (Row, Role ▸ Subrole, Clip Name…).
        #expect(selected.getCellWithFormat("C2")?.value.stringValue == "Clip A")
        #expect(videoSheet.getCellWithFormat("C2")?.value.stringValue == "Clip A")
        #expect(dialogueSheet.getCellWithFormat("C2")?.value.stringValue == "Clip B")
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
