//
//  FCPXMLReportExcelExportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	XLKit workbook export tests for structured FCPXML reports.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit
import XLKit

@Suite("Report Excel export")
struct FCPXMLReportExcelExportTests {

    @Test("Workbook sheet titles use title case")
    func reportWorkbookSheetTitlesUseTitleCase() {
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

        #expect(sheetTitles == [
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

        #expect(
            FinalCutPro.FCPXML.ReportBuildPhase.roleInventory.rawValue
                == "Selected Roles Inventory"
        )
    }

    @Test("Sanitize sheet name replaces invalid characters and truncates")
    func sanitizeSheetNameReplacesInvalidCharactersAndTruncates() {
        let sanitized = FinalCutPro.FCPXML.ReportExcelExport.sanitizeSheetName(
            "Video: Effects? [test]/path\\name that is way too long"
        )

        let hasColon = sanitized.contains(":")
        let hasQuestion = sanitized.contains("?")
        let hasOpenBracket = sanitized.contains("[")
        let hasCloseBracket = sanitized.contains("]")
        let hasSlash = sanitized.contains("/")
        let hasBackslash = sanitized.contains("\\")
        #expect(!hasColon)
        #expect(!hasQuestion)
        #expect(!hasOpenBracket)
        #expect(!hasCloseBracket)
        #expect(!hasSlash)
        #expect(!hasBackslash)
        #expect(sanitized.count <= 31)
    }

    @Test("Make workbook from markers report includes Markers sheet")
    @MainActor
    func makeWorkbookFromMarkersReportIncludesMarkersSheet() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()

        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeMarkers = true

        let report = try await fcpxml.buildReport(options: options)

        let names = sheetNames(from: report)
        #expect(names == [
            "Created by OpenFCPXMLKit",
            FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName
        ])
    }

    @Test("Export markers report writes XLSX file")
    func exportMarkersReportWritesXLSXFile() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()

        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeMarkers = true

        let report = try await fcpxml.buildReport(options: options)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-Markers-\(UUID().uuidString).xlsx")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)

        #expect(FileManager.default.fileExists(atPath: outputURL.path))

        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = attributes[.size] as? NSNumber
        #expect((fileSize?.intValue ?? 0) > 0)
    }

    @Test("Make workbook from synthetic report includes all sections")
    @MainActor
    func makeWorkbookFromSyntheticReportIncludesAllSections() {
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
                        rows: [
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
                        ]
                    )
                ]
            )
        )

        let names = sheetNames(from: report)
        #expect(names == [
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

    @Test("Media Summary sheet lists missing media paths")
    @MainActor
    func mediaSummarySheetListsMissingMediaPaths() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: ["/missing/clip.mov", "/missing/audio.wav"]
            )
        )

        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName)

        #expect(sheet?.getCellWithFormat("A1")?.value.stringValue == "Row")
        #expect(sheet?.getCellWithFormat("B1")?.value.stringValue == "Missing Media")
        #expect(sheet?.getCellWithFormat("B1")?.format?.backgroundColor == "#000000")
        #expect(sheet?.getCellWithFormat("B1")?.format?.fontColor == "#FFFFFF")
        #expect(sheet?.getCellWithFormat("A2")?.value.stringValue == "1")
        #expect(sheet?.getCellWithFormat("B2")?.value.stringValue == "/missing/clip.mov")
        #expect(sheet?.getCellWithFormat("B2")?.format?.fontColor == "#FF0000")
        #expect(sheet?.getCellWithFormat("A3")?.value.stringValue == "2")
        #expect(sheet?.getCellWithFormat("B3")?.value.stringValue == "/missing/audio.wav")
        #expect(sheet?.getCellWithFormat("B3")?.format?.fontColor == "#FF0000")
    }

    @Test("Report table headers use black background and white text")
    @MainActor
    func reportTableHeadersUseBlackBackgroundAndWhiteText() {
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
        #expect(headerCell?.format?.backgroundColor == "#000000")
        #expect(headerCell?.format?.fontColor == "#FFFFFF")
        #expect(headerCell?.value.stringValue == "Row")
        #expect(sheet?.getCellWithFormat("B1")?.value.stringValue == "Marker Name")
    }

    @Test("Workbook cover sheet uses configured title header and style")
    @MainActor
    func workbookCoverSheetUsesConfiguredTitleHeaderAndStyle() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: []),
            workbookCoverSheet: FinalCutPro.FCPXML.ReportWorkbookCoverSheet(
                title: "Created by XYZ",
                headerText: "Created by XYZ"
            )
        )

        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let names = workbook.getSheets().map { $0.name }
        #expect(names.first == "Created by XYZ")

        let coverSheet = workbook.getSheet(name: "Created by XYZ")
        let headerCell = coverSheet?.getCellWithFormat("A1")
        #expect(headerCell?.value.stringValue == "Created by XYZ")
        #expect(headerCell?.format?.backgroundColor == "#000000")
        #expect(headerCell?.format?.fontColor == "#FFFFFF")
        #expect(coverSheet?.getCellWithFormat("A2")?.value.stringValue == nil)
    }

    @Test("Workbook cover sheet includes copyright label on row two")
    @MainActor
    func workbookCoverSheetIncludesCopyrightLabelOnRowTwo() {
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
        #expect(
            coverSheet?.getCellWithFormat("A1")?.value.stringValue
                == FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.headerText
        )
        let copyrightCell = coverSheet?.getCellWithFormat("A2")
        #expect(copyrightCell?.value.stringValue == copyright)
        #expect(copyrightCell?.format?.backgroundColor == "#000000")
        #expect(copyrightCell?.format?.fontColor == "#FFFFFF")
    }

    @Test("Marker row uses configured marker type colors")
    @MainActor
    func markerRowUsesConfiguredMarkerTypeColors() {
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

        #expect(sheet?.getCellWithFormat("A2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("B2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("A3")?.format?.fontColor == "#FF0000")
        #expect(sheet?.getCellWithFormat("B3")?.format?.fontColor == "#FF0000")
        #expect(sheet?.getCellWithFormat("A4")?.format?.fontColor == "#00AA44")
        #expect(sheet?.getCellWithFormat("B4")?.format?.fontColor == "#00AA44")
        #expect(sheet?.getCellWithFormat("A5")?.format?.fontColor == "#FF8800")
        #expect(sheet?.getCellWithFormat("B5")?.format?.fontColor == "#FF8800")
    }

    @Test("Role Subrole cell uses configured role colors")
    @MainActor
    func roleSubroleCellUsesConfiguredRoleColors() {
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

        #expect(sheet?.getCellWithFormat("A2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("B2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("C2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("A3")?.format?.fontColor == "#9933FF")
        #expect(sheet?.getCellWithFormat("A4")?.format?.fontColor == "#00AA44")
        #expect(sheet?.getCellWithFormat("A5")?.format?.fontColor == "#808080")
    }

    @Test("Keywords rows use blue text matching section sheets")
    @MainActor
    func keywordsRowsUseBlueTextMatchingSectionSheets() {
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

        #expect(sheet?.getCellWithFormat("A2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("G2")?.format?.fontColor == "#0066FF")
    }

    @Test("Effects rows use role-appropriate colors when category unavailable")
    @MainActor
    func effectsRowsUseRoleAppropriateColorsWhenCategoryUnavailable() {
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

        #expect(sheet?.getCellWithFormat("A2")?.format?.fontColor == "#0066FF")
        #expect(sheet?.getCellWithFormat("A3")?.format?.fontColor == "#00AA44")
        #expect(sheet?.getCellWithFormat("A4")?.format?.fontColor == "#0066FF")
    }

    @Test("Summary long project title does not widen Row column")
    @MainActor
    func summaryLongProjectTitleDoesNotWidenRowColumn() throws {
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

        #expect(sheet?.getCellWithFormat("B1")?.value.stringValue == longTitle)
        #expect(sheet?.getCellWithFormat("A3")?.value.stringValue == "Row")
        let rowColumnWidth = try #require(sheet?.getColumnWidth(1))
        let rowWidthMatch = abs(rowColumnWidth - 8.0) < 0.01
        #expect(rowWidthMatch, "Row column must stay narrow when project title is long")
        let titleColumnWidth = try #require(sheet?.getColumnWidth(2))
        let desired = FCPXMLReportWorkbookColumnAutoFit.summaryProjectTitleColumnWidth(for: longTitle)
        let titleWidthMatch = abs(titleColumnWidth - desired) < 0.01
        #expect(titleWidthMatch, "Title column (B) should use the Summary project-title width")
        #expect(titleColumnWidth >= 56.0)
    }

    @Test("Summary percent column is numeric percentage formatted")
    @MainActor
    func summaryPercentColumnIsNumericPercentageFormatted() {
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
        #expect(titleCell?.value.stringValue == "Test Project")
        #expect(titleCell?.format?.backgroundColor == "#000000")
        #expect(titleCell?.format?.fontColor == "#FFFFFF")
        #expect(titleCell?.format?.fontWeight == .bold)
        #expect(sheet?.getCellWithFormat("A1")?.value.stringValue == nil)

        // Role table header on row 3, data rows on 4–5; columns are Row | Role | Estimated Total | %.
        #expect(sheet?.getCellWithFormat("A3")?.value.stringValue == "Row")
        let percentCell = sheet?.getCellWithFormat("D4")

        // The value must be stored as the raw fraction in a numeric cell (not a text string),
        // so Excel renders it through the percentage number format as "50.0%".
        #expect(percentCell?.value == .number(0.5))
        #expect(percentCell?.format?.numberFormat == .custom)
        #expect(percentCell?.format?.customNumberFormat == "0.0%")
        #expect(percentCell?.format?.fontColor == nil)

        // Summary data uses default black text for all columns (no role colour coding).
        #expect(sheet?.getCellWithFormat("A4")?.format?.fontColor == nil)
        #expect(sheet?.getCellWithFormat("B4")?.format?.fontColor == nil)
        #expect(sheet?.getCellWithFormat("C4")?.format?.fontColor == nil)
        #expect(sheet?.getCellWithFormat("A5")?.format?.fontColor == nil)
        #expect(sheet?.getCellWithFormat("B5")?.format?.fontColor == nil)
        #expect(sheet?.getCellWithFormat("C5")?.format?.fontColor == nil)
        #expect(sheet?.getCellWithFormat("D5")?.format?.fontColor == nil)
    }

    @Test("Make workbook leaves sheets unprotected by default")
    @MainActor
    func makeWorkbookLeavesSheetsUnprotectedByDefault() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Demo",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: []),
            workbookCoverSheet: .openFCPXMLKitDefault
        )

        let sheets = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report).getSheets()
        let sheetsEmpty = sheets.isEmpty
        #expect(!sheetsEmpty)
        for sheet in sheets {
            #expect(
                sheet.protection == nil,
                "Sheet '\(sheet.name)' should be unprotected by default"
            )
        }
    }

    @Test("Make workbook protects all sheets when requested")
    @MainActor
    func makeWorkbookProtectsAllSheetsWhenRequested() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Demo",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: []),
            workbookCoverSheet: .openFCPXMLKitDefault,
            protectSheets: true
        )

        let sheets = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report).getSheets()
        #expect(sheets.count >= 2, "Cover + Markers expected")
        for sheet in sheets {
            #expect(
                sheet.protection != nil,
                "Sheet '\(sheet.name)' should be protected when protectSheets is true"
            )
            #expect(sheet.protection?.sheet == true)
            #expect(
                sheet.protection?.password == nil,
                "Default sheet protection must not set a password"
            )
            #expect(sheet.protection?.hashValue == nil)
        }
    }

    @Test("Per-role inventory sheet writes black Total footer under Clip Duration")
    @MainActor
    func perRoleInventorySheetWritesBlackTotalFooter() {
        let row = FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: "Video",
            clipName: "A",
            category: "Primary video",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:10:00",
            clipDuration: "00:00:10:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: "00:00:10:00",
            frameRateSampleRate: "24 fps"
        )
        let row2 = FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: "Video",
            clipName: "B",
            category: "Primary video",
            enabled: "✓",
            timelineIn: "00:00:10:00",
            timelineOut: "00:00:15:00",
            clipDuration: "00:00:05:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: "00:00:05:00",
            frameRateSampleRate: "24 fps"
        )
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Totals",
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                roleSheets: [
                    .init(sheetName: "Video", rows: [row, row2])
                ]
            )
        )
        
        let sheet = FinalCutPro.FCPXML.ReportExcelExport
            .makeWorkbook(from: report)
            .getSheet(name: "Video")
        
        let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
            metadataColumnKeys: [],
            excludedColumns: [],
            timecodeFormat: .smpteFrames
        )
        let columns = FinalCutPro.FCPXML.RoleInventorySheetTotal.footerColumnIndices(
            in: headers,
            excludedColumns: [],
            timecodeFormat: .smpteFrames
        )
        guard let columns else {
            Issue.record("Expected footer column indices")
            return
        }
        
        let labelCoordinate = CellCoordinate(
            row: 5,
            column: columns.label + 1
        ).excelAddress
        let valueCoordinate = CellCoordinate(
            row: 5,
            column: columns.value + 1
        ).excelAddress
        
        #expect(sheet?.getCellWithFormat(labelCoordinate)?.value.stringValue == "Total:")
        #expect(sheet?.getCellWithFormat(valueCoordinate)?.value.stringValue == "00:00:15:00")
        #expect(sheet?.getCellWithFormat(labelCoordinate)?.format?.backgroundColor == "#000000")
        #expect(sheet?.getCellWithFormat(labelCoordinate)?.format?.fontColor == "#FFFFFF")
        #expect(sheet?.getCellWithFormat(valueCoordinate)?.format?.backgroundColor == "#000000")
        #expect(sheet?.getCellWithFormat(valueCoordinate)?.format?.fontColor == "#FFFFFF")
    }

    @MainActor
    private func sheetNames(from report: FinalCutPro.FCPXML.Report) -> [String] {
        FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report).getSheets().map(\.name)
    }
}


