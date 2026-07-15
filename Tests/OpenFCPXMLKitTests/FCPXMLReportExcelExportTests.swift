//
//  FCPXMLReportExcelExportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	XLKit workbook export tests for structured FCPXML reports.
//

import Foundation
@testable import OpenFCPXMLKit
import XCTest
import XLKit

@available(macOS 26.0, *)
final class FCPXMLReportExcelExportTests: XCTestCase, @unchecked Sendable {
    
    func testReportWorkbookSheetTitlesUseTitleCase() {
        let sheetTitles = [
            FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName,
            FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName,
            FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName,
            FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName
        ]
        
        XCTAssertEqual(sheetTitles, [
            "Markers",
            "Keywords",
            "Titles & Generators",
            "Transitions",
            "Video & Audio Effects",
            "Speed Change Effects",
            "Summary",
            "Media Summary",
            "Selected Roles Inventory"
        ])
        
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportBuildPhase.roleInventory.rawValue,
            "Selected Roles Inventory"
        )
    }
    
    func testSanitizeSheetNameReplacesInvalidCharactersAndTruncates() {
        let sanitized = FinalCutPro.FCPXML.ReportExcelExport.sanitizeSheetName(
            "Video: Effects? [test]/path\\name that is way too long"
        )
        
        XCTAssertFalse(sanitized.contains(":"))
        XCTAssertFalse(sanitized.contains("?"))
        XCTAssertFalse(sanitized.contains("["))
        XCTAssertFalse(sanitized.contains("]"))
        XCTAssertFalse(sanitized.contains("/"))
        XCTAssertFalse(sanitized.contains("\\"))
        XCTAssertLessThanOrEqual(sanitized.count, 31)
    }
    
    func testMakeWorkbookFromMarkersReportIncludesMarkersSheet() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        
        let report = try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeMarkers = true
            }
        )
        
        let sheetNames = await sheetNames(from: report)
        XCTAssertEqual(sheetNames, [
            "Created by OpenFCPXMLKit",
            FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName
        ])
    }
    
    func testExportMarkersReportWritesXLSXFile() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        
        let report = try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeMarkers = true
            }
        )
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-Markers-\(UUID().uuidString).xlsx")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = attributes[.size] as? NSNumber
        XCTAssertGreaterThan(fileSize?.intValue ?? 0, 0)
    }
    
    func testMakeWorkbookFromSyntheticReportIncludesAllSections() async {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Marker A",
                    type: .standard,
                    position: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "01:00:01:00"
                )
            ]),
            keywords: FinalCutPro.FCPXML.KeywordsReportSection(rows: []),
            titlesAndGenerators: FinalCutPro.FCPXML.TitlesReportSection(rows: []),
            transitions: FinalCutPro.FCPXML.TransitionsReportSection(rows: []),
            effects: FinalCutPro.FCPXML.EffectsReportSection(rows: []),
            speedChangeEffects: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection(rows: []),
            summary: FinalCutPro.FCPXML.SummaryReportSection(
                projectSummary: FinalCutPro.FCPXML.ProjectSummary(
                    title: "Test Project",
                    duration: "00:01:00:00",
                    resolution: "1920x1080",
                    frameRate: "24",
                    audioSampleRate: "48kHz"
                ),
                roleDurations: [
                    FinalCutPro.FCPXML.SummaryRoleDurationRow(
                        roleSubrole: "Video",
                        estimatedTotal: "00:01:00:00",
                        percentOfTotal: 1.0
                    )
                ]
            ),
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: ["/missing/clip.mov"]
            ),
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [
                    FinalCutPro.FCPXML.RoleClipReportRow(
                        roleSubrole: "Video",
                        clipName: "Clip",
                        category: "Video",
                        enabled: "Yes",
                        timelineIn: "00:00:00:00",
                        timelineOut: "00:00:05:00",
                        clipDuration: "00:00:05:00",
                        sourceIn: "00:00:00:00",
                        sourceOut: "00:00:05:00",
                        sourceDuration: "00:00:05:00"
                    )
                ],
                roleSheets: [
                    FinalCutPro.FCPXML.RoleSheet(
                        sheetName: "Video",
                        rows: []
                    )
                ]
            )
        )
        
        let sheetNames = await sheetNames(from: report)
        XCTAssertEqual(sheetNames, [
            FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName,
            "Video",
            FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName,
            FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName,
            FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        ])
    }
    
    @MainActor
    func testMediaSummarySheetListsMissingMediaPaths() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: ["/missing/clip.mov", "/missing/audio.wav"]
            )
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A1")?.value.stringValue, "Row")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.value.stringValue, "Missing Media")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.format?.backgroundColor, "#000000")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.format?.fontColor, "#FFFFFF")
        XCTAssertEqual(sheet?.getCellWithFormat("A2")?.value.stringValue, "1")
        XCTAssertEqual(sheet?.getCellWithFormat("B2")?.value.stringValue, "/missing/clip.mov")
        XCTAssertEqual(sheet?.getCellWithFormat("B2")?.format?.fontColor, "#FF0000")
        XCTAssertEqual(sheet?.getCellWithFormat("A3")?.value.stringValue, "2")
        XCTAssertEqual(sheet?.getCellWithFormat("B3")?.value.stringValue, "/missing/audio.wav")
        XCTAssertEqual(sheet?.getCellWithFormat("B3")?.format?.fontColor, "#FF0000")
    }
    
    @MainActor
    func testReportTableHeadersUseBlackBackgroundAndWhiteText() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Marker A",
                    type: .standard,
                    position: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "01:00:01:00"
                )
            ])
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName)
        
        let headerCell = sheet?.getCellWithFormat("A1")
        XCTAssertEqual(headerCell?.format?.backgroundColor, "#000000")
        XCTAssertEqual(headerCell?.format?.fontColor, "#FFFFFF")
        XCTAssertEqual(headerCell?.value.stringValue, "Row")
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.value.stringValue, "Marker Name")
    }
    
    @MainActor
    func testWorkbookCoverSheetUsesConfiguredTitleHeaderAndStyle() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: []),
            workbookCoverSheet: FinalCutPro.FCPXML.ReportWorkbookCoverSheet(
                title: "Created by XYZ",
                headerText: "Created by XYZ"
            )
        )
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let sheetNames = workbook.getSheets().map { $0.name }
        XCTAssertEqual(sheetNames.first, "Created by XYZ")
        
        let coverSheet = workbook.getSheet(name: "Created by XYZ")
        let headerCell = coverSheet?.getCellWithFormat("A1")
        XCTAssertEqual(headerCell?.value.stringValue, "Created by XYZ")
        XCTAssertEqual(headerCell?.format?.backgroundColor, "#000000")
        XCTAssertEqual(headerCell?.format?.fontColor, "#FFFFFF")
        XCTAssertNil(coverSheet?.getCellWithFormat("A2")?.value.stringValue)
    }
    
    @MainActor
    func testWorkbookCoverSheetIncludesCopyrightLabelOnRowTwo() {
        let copyright = "© 2026 Example Studios"
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: []),
            workbookCoverSheet: .openFCPXMLKitDefault,
            copyrightLabel: copyright
        )
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let coverSheet = workbook.getSheet(
            name: FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.title
        )
        XCTAssertEqual(
            coverSheet?.getCellWithFormat("A1")?.value.stringValue,
            FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.headerText
        )
        let copyrightCell = coverSheet?.getCellWithFormat("A2")
        XCTAssertEqual(copyrightCell?.value.stringValue, copyright)
        XCTAssertEqual(copyrightCell?.format?.backgroundColor, "#000000")
        XCTAssertEqual(copyrightCell?.format?.fontColor, "#FFFFFF")
    }
    
    @MainActor
    func testMarkerRowUsesConfiguredMarkerTypeColors() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                .init(
                    markerName: "Standard Marker",
                    type: .standard,
                    position: "00:00:00:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "00:00:00:00"
                ),
                .init(
                    markerName: "Incomplete",
                    type: .incompleteToDo,
                    position: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "00:00:01:00"
                ),
                .init(
                    markerName: "Completed",
                    type: .completedToDo,
                    position: "00:00:02:00",
                    clipName: "Clip",
                    roleSubrole: "Dialogue",
                    sourcePosition: "00:00:02:00"
                ),
                .init(
                    markerName: "Chapter Start",
                    type: .chapter,
                    position: "00:00:03:00",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    sourcePosition: "00:00:03:00"
                )
            ])
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("B2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("A3")?.format?.fontColor, "#FF0000")
        XCTAssertEqual(sheet?.getCellWithFormat("B3")?.format?.fontColor, "#FF0000")
        XCTAssertEqual(sheet?.getCellWithFormat("A4")?.format?.fontColor, "#00AA44")
        XCTAssertEqual(sheet?.getCellWithFormat("B4")?.format?.fontColor, "#00AA44")
        XCTAssertEqual(sheet?.getCellWithFormat("A5")?.format?.fontColor, "#FF8800")
        XCTAssertEqual(sheet?.getCellWithFormat("B5")?.format?.fontColor, "#FF8800")
    }
    
    @MainActor
    func testRoleSubroleCellUsesConfiguredRoleColors() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [
                    .init(
                        roleSubrole: "Video",
                        clipName: "Video Clip",
                        category: "Primary clip",
                        enabled: "Yes",
                        timelineIn: "00:00:00:00",
                        timelineOut: "00:00:01:00",
                        clipDuration: "00:00:01:00",
                        sourceIn: "00:00:00:00",
                        sourceOut: "00:00:01:00",
                        sourceDuration: "00:00:01:00"
                    ),
                    .init(
                        roleSubrole: "Titles ▸ Main",
                        clipName: "Title Clip",
                        category: "Connected title",
                        enabled: "Yes",
                        timelineIn: "00:00:01:00",
                        timelineOut: "00:00:02:00",
                        clipDuration: "00:00:01:00",
                        sourceIn: "00:00:00:00",
                        sourceOut: "00:00:01:00",
                        sourceDuration: "00:00:01:00"
                    ),
                    .init(
                        roleSubrole: "Dialogue ▸ Mix L",
                        clipName: "Audio Clip",
                        category: "Connected audio",
                        enabled: "Yes",
                        timelineIn: "00:00:02:00",
                        timelineOut: "00:00:03:00",
                        clipDuration: "00:00:01:00",
                        sourceIn: "00:00:00:00",
                        sourceOut: "00:00:01:00",
                        sourceDuration: "00:00:01:00"
                    ),
                    .init(
                        roleSubrole: "Gap",
                        clipName: "Gap Clip",
                        category: "Gap",
                        enabled: "Yes",
                        timelineIn: "00:00:03:00",
                        timelineOut: "00:00:04:00",
                        clipDuration: "00:00:01:00",
                        sourceIn: "00:00:00:00",
                        sourceOut: "00:00:01:00",
                        sourceDuration: "00:00:01:00"
                    )
                ]
            )
        )
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let sheet = workbook.getSheet(name: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("B2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("C2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("A3")?.format?.fontColor, "#9933FF")
        XCTAssertEqual(sheet?.getCellWithFormat("A4")?.format?.fontColor, "#00AA44")
        XCTAssertEqual(sheet?.getCellWithFormat("A5")?.format?.fontColor, "#808080")
    }
    
    @MainActor
    func testKeywordsRowsUseBlueTextMatchingPBFSectionSheets() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            keywords: FinalCutPro.FCPXML.KeywordsReportSection(rows: [
                .init(
                    keyword: "vfx final",
                    timelineIn: "00:00:01:00",
                    timelineOut: "00:00:02:00",
                    duration: "00:00:01:00",
                    clipName: "Clip",
                    roleSubrole: "Dialogue"
                )
            ])
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("G2")?.format?.fontColor, "#0066FF")
    }
    
    @MainActor
    func testEffectsRowsUseRoleAppropriateColorsWhenCategoryUnavailable() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            effects: FinalCutPro.FCPXML.EffectsReportSection(rows: [
                .init(
                    effect: "Transform",
                    settings: "Scale 100.0%",
                    enabled: "✓",
                    isApple: "✓",
                    clipName: "Video Clip",
                    roleSubrole: "Video",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:01:00"
                ),
                .init(
                    effect: "volume",
                    settings: "-3.0 dB",
                    enabled: "✓",
                    isApple: "✓",
                    clipName: "Audio Clip",
                    roleSubrole: "Dialogue",
                    timelineIn: "00:00:01:00",
                    timelineOut: "00:00:02:00"
                ),
                .init(
                    effect: "Timecode",
                    settings: "Timecode",
                    enabled: "✓",
                    isApple: "✓",
                    clipName: "Title Clip",
                    roleSubrole: "Titles",
                    timelineIn: "00:00:02:00",
                    timelineOut: "00:00:03:00"
                )
            ])
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("A2")?.format?.fontColor, "#0066FF")
        XCTAssertEqual(sheet?.getCellWithFormat("A3")?.format?.fontColor, "#00AA44")
        XCTAssertEqual(sheet?.getCellWithFormat("A4")?.format?.fontColor, "#0066FF")
    }
    
    @MainActor
    func testSummaryLongProjectTitleDoesNotWidenRowColumn() throws {
        let longTitle = String(repeating: "Very Long Project Title Segment ", count: 6)
        let report = FinalCutPro.FCPXML.Report(
            projectName: longTitle,
            summary: FinalCutPro.FCPXML.SummaryReportSection(
                projectSummary: FinalCutPro.FCPXML.ProjectSummary(
                    title: longTitle,
                    duration: "00:01:00:00",
                    resolution: "1920x1080",
                    frameRate: "24",
                    audioSampleRate: "48kHz"
                ),
                roleDurations: [
                    FinalCutPro.FCPXML.SummaryRoleDurationRow(
                        roleSubrole: "Video",
                        estimatedTotal: "00:00:30:00",
                        percentOfTotal: 0.5
                    )
                ]
            )
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName)
        
        XCTAssertEqual(sheet?.getCellWithFormat("B1")?.value.stringValue, longTitle)
        XCTAssertEqual(sheet?.getCellWithFormat("A3")?.value.stringValue, "Row")
        let rowColumnWidth = try XCTUnwrap(sheet?.getColumnWidth(1))
        XCTAssertEqual(
            rowColumnWidth,
            8.0,
            accuracy: 0.01,
            "Row column must stay narrow when project title is long"
        )
        let titleColumnWidth = try XCTUnwrap(sheet?.getColumnWidth(2))
        let desired = FCPXMLReportWorkbookColumnAutoFit.summaryProjectTitleColumnWidth(for: longTitle)
        XCTAssertEqual(
            titleColumnWidth,
            desired,
            accuracy: 0.01,
            "Title column (B) should use the Summary project-title width"
        )
        XCTAssertGreaterThanOrEqual(titleColumnWidth, 56.0)
    }
    
    @MainActor
    func testSummaryPercentColumnIsNumericPercentageFormatted() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            summary: FinalCutPro.FCPXML.SummaryReportSection(
                projectSummary: FinalCutPro.FCPXML.ProjectSummary(
                    title: "Test Project",
                    duration: "00:01:00:00",
                    resolution: "1920x1080",
                    frameRate: "24",
                    audioSampleRate: "48kHz"
                ),
                roleDurations: [
                    FinalCutPro.FCPXML.SummaryRoleDurationRow(
                        roleSubrole: "Video",
                        estimatedTotal: "00:00:30:00",
                        percentOfTotal: 0.5
                    ),
                    FinalCutPro.FCPXML.SummaryRoleDurationRow(
                        roleSubrole: "Dialogue",
                        estimatedTotal: "00:00:20:00",
                        percentOfTotal: 0.33
                    )
                ]
            )
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName)
        
        // Project title sits in B1 so a long name does not widen the Row column (A).
        let titleCell = sheet?.getCellWithFormat("B1")
        XCTAssertEqual(titleCell?.value.stringValue, "Test Project")
        XCTAssertEqual(titleCell?.format?.backgroundColor, "#000000")
        XCTAssertEqual(titleCell?.format?.fontColor, "#FFFFFF")
        XCTAssertEqual(titleCell?.format?.fontWeight, .bold)
        XCTAssertNil(sheet?.getCellWithFormat("A1")?.value.stringValue)
        
        // Role table header on row 3, data rows on 4–5; columns are Row | Role | Estimated Total | %.
        XCTAssertEqual(sheet?.getCellWithFormat("A3")?.value.stringValue, "Row")
        let percentCell = sheet?.getCellWithFormat("D4")
        
        // The value must be stored as the raw fraction in a numeric cell (not a text string),
        // so Excel renders it through the percentage number format as "50.0%".
        XCTAssertEqual(percentCell?.value, .number(0.5))
        XCTAssertEqual(percentCell?.format?.numberFormat, .custom)
        XCTAssertEqual(percentCell?.format?.customNumberFormat, "0.0%")
        XCTAssertNil(percentCell?.format?.fontColor)
        
        // Summary data uses default black text for all columns (no role colour coding).
        XCTAssertNil(sheet?.getCellWithFormat("A4")?.format?.fontColor)
        XCTAssertNil(sheet?.getCellWithFormat("B4")?.format?.fontColor)
        XCTAssertNil(sheet?.getCellWithFormat("C4")?.format?.fontColor)
        XCTAssertNil(sheet?.getCellWithFormat("A5")?.format?.fontColor)
        XCTAssertNil(sheet?.getCellWithFormat("B5")?.format?.fontColor)
        XCTAssertNil(sheet?.getCellWithFormat("C5")?.format?.fontColor)
        XCTAssertNil(sheet?.getCellWithFormat("D5")?.format?.fontColor)
    }
    
    @MainActor
    private func sheetNames(from report: FinalCutPro.FCPXML.Report) -> [String] {
        FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report).getSheets().map(\.name)
    }
}
