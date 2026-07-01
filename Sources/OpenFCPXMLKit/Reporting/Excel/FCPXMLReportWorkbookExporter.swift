//
//  FCPXMLReportWorkbookExporter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Maps ``FinalCutPro/FCPXML/Report`` sections to XLKit workbook sheets.
//

import Foundation
import XLKit

enum FCPXMLReportWorkbookExporter {
    /// Column header style for report sheets (black fill, white text).
    private static func tableHeaderFormat() -> CellFormat {
        var format = CellFormat.header(backgroundColor: "#000000")
        format.fontColor = "#FFFFFF"
        return format
    }
    
    private static func roleFontFormat(
        for roleSubrole: String,
        categoryLabel: String? = nil
    ) -> CellFormat? {
        let bucket = roleColorBucket(for: roleSubrole, categoryLabel: categoryLabel)
        guard let fontColor = bucket.fontColorHex else {
            return nil
        }
        
        var format = CellFormat()
        format.fontColor = fontColor
        return format
    }
    
    private static func roleColorBucket(
        for roleSubrole: String,
        categoryLabel: String? = nil
    ) -> RoleColorBucket {
        if let categoryLabel,
           let category = FinalCutPro.FCPXML.ReportClipCategory.matchingWorkbookLabel(categoryLabel)
        {
            if category == .primaryGap {
                return .gap
            }
            if category.isTitleCategory {
                return .titles
            }
            if category.isVideoCategory || category.isCaptionCategory {
                return .videoOrSRT
            }
            if category.isAudioCategory {
                return .audio
            }
        }
        
        if roleSubrole.localizedCaseInsensitiveContains("gap") {
            return .gap
        }
        
        return .audio
    }
    
    @MainActor
    static func makeWorkbook(from report: FinalCutPro.FCPXML.Report) -> Workbook {
        let workbook = Workbook()
        
        if let workbookCoverSheet = report.workbookCoverSheet {
            appendWorkbookCoverSheet(workbookCoverSheet, to: workbook)
        }
        
        if let roleInventory = report.roleInventory {
            appendRoleInventory(roleInventory, to: workbook)
        }
        
        if let markers = report.markers {
            appendMarkers(markers, to: workbook)
        }
        
        if let keywords = report.keywords {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
                headers: FinalCutPro.FCPXML.KeywordReportRow.columnHeaders,
                rows: keywords.rows.map(\.columnValues)
            )
        }
        
        if let titles = report.titlesAndGenerators {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
                headers: FinalCutPro.FCPXML.TitleReportRow.columnHeaders,
                rows: titles.rows.map(\.columnValues)
            )
        }
        
        if let transitions = report.transitions {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
                headers: FinalCutPro.FCPXML.TransitionReportRow.columnHeaders,
                rows: transitions.rows.map(\.columnValues)
            )
        }
        
        if let effects = report.effects {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
                headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders,
                rows: effects.rows.map(\.columnValues)
            )
        }
        
        if let speedChangeEffects = report.speedChangeEffects {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
                headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders,
                rows: speedChangeEffects.rows.map(\.columnValues)
            )
        }
        
        if let summary = report.summary {
            appendSummary(summary, to: workbook)
        }
        
        return workbook
    }
    
    private static func appendWorkbookCoverSheet(
        _ workbookCoverSheet: FinalCutPro.FCPXML.ReportWorkbookCoverSheet,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(name: sanitizeSheetName(workbookCoverSheet.title))
        sheet.setCell("A1", string: workbookCoverSheet.headerText, format: tableHeaderFormat())
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
    }
    
    private static func appendMarkers(
        _ markers: FinalCutPro.FCPXML.MarkersReportSection,
        to workbook: Workbook
    ) {
        let headers = FinalCutPro.FCPXML.MarkerReportRow.columnHeaders
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName)
        )
        setTableHeaderRow(sheet, row: 1, strings: headers)
        
        for (index, marker) in markers.rows.enumerated() {
            let rowIndex = index + 2
            let values = marker.columnValues
            sheet.setRow(rowIndex, strings: values)
            applyMarkerColorToRow(
                sheet,
                row: rowIndex,
                values: values,
                markerType: marker.type
            )
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
    }
    
    private static func applyMarkerColorToRow(
        _ sheet: Sheet,
        row: Int,
        values: [String],
        markerType: FinalCutPro.FCPXML.MarkerReportType
    ) {
        let rowFormat = markerFontFormat(for: markerType)
        
        for (columnIndex, value) in values.enumerated() {
            let coordinate = CellCoordinate(row: row, column: columnIndex + 1).excelAddress
            sheet.setCell(coordinate, string: value, format: rowFormat)
        }
    }
    
    private static func markerFontFormat(
        for markerType: FinalCutPro.FCPXML.MarkerReportType
    ) -> CellFormat {
        var format = CellFormat()
        format.fontColor = markerFontColorHex(for: markerType)
        return format
    }
    
    private static func markerFontColorHex(
        for markerType: FinalCutPro.FCPXML.MarkerReportType
    ) -> String {
        switch markerType {
        case .standard:
            return RoleColorBucket.videoOrSRT.fontColorHex!
        case .incompleteToDo:
            return "#FF0000"
        case .completedToDo:
            return RoleColorBucket.audio.fontColorHex!
        case .chapter:
            return "#FF8800"
        }
    }
    
    private static func appendTabularSection(
        to workbook: Workbook,
        sheetName: String,
        headers: [String],
        rows: [[String]]
    ) {
        let sheet = workbook.addSheet(name: sanitizeSheetName(sheetName))
        setTableHeaderRow(sheet, row: 1, strings: headers)
        let roleColumnIndex = headers.firstIndex(of: roleSubroleColumnHeader).map { $0 + 1 }
        let categoryColumnIndex = headers.firstIndex(of: "Category").map { $0 + 1 }
        for (index, values) in rows.enumerated() {
            let rowIndex = index + 2
            sheet.setRow(rowIndex, strings: values)
            applyRoleColorToRow(
                sheet,
                row: rowIndex,
                values: values,
                roleColumnIndex: roleColumnIndex,
                categoryColumnIndex: categoryColumnIndex
            )
        }
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
    }
    
    private static func applyRoleColorToRow(
        _ sheet: Sheet,
        row: Int,
        values: [String],
        roleColumnIndex: Int?,
        categoryColumnIndex: Int?
    ) {
        guard let roleColumnIndex,
              values.indices.contains(roleColumnIndex - 1)
        else {
            return
        }
        
        let roleValue = values[roleColumnIndex - 1]
        var categoryValue: String?
        if let categoryColumnIndex,
           values.indices.contains(categoryColumnIndex - 1)
        {
            categoryValue = values[categoryColumnIndex - 1]
        }
        
        guard let roleFormat = roleFontFormat(
            for: roleValue,
            categoryLabel: categoryValue
        ) else {
            return
        }
        
        for (columnIndex, value) in values.enumerated() {
            let coordinate = CellCoordinate(row: row, column: columnIndex + 1).excelAddress
            sheet.setCell(coordinate, string: value, format: roleFormat)
        }
    }
    
    private static func setTableHeaderRow(
        _ sheet: Sheet,
        row: Int,
        strings: [String]
    ) {
        for (index, title) in strings.enumerated() {
            let coordinate = CellCoordinate(row: row, column: index + 1).excelAddress
            sheet.setCell(coordinate, string: title, format: tableHeaderFormat())
        }
    }
    
    private static func appendSummary(
        _ summary: FinalCutPro.FCPXML.SummaryReportSection,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName)
        )
        
        var rowIndex = 1
        
        if let projectSummary = summary.projectSummary {
            sheet.setRow(rowIndex, strings: [projectSummary.title])
            rowIndex += 1
            sheet.setRow(rowIndex, strings: projectSummary.headerMetricValues)
            rowIndex += 1
        }
        
        if !summary.roleDurations.isEmpty {
            setTableHeaderRow(
                sheet,
                row: rowIndex,
                strings: FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders
            )
            rowIndex += 1
            
            let roleColumnIndex = FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders
                .firstIndex(of: roleSubroleColumnHeader)
                .map { $0 + 1 }
            let percentColumnIndex = FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders
                .firstIndex(of: percentOfTotalColumnHeader)
                .map { $0 + 1 }
            
            for roleDuration in summary.roleDurations {
                let values = roleDuration.columnValues
                sheet.setRow(rowIndex, strings: values)
                applyRoleColorToRow(
                    sheet,
                    row: rowIndex,
                    values: values,
                    roleColumnIndex: roleColumnIndex,
                    categoryColumnIndex: nil
                )
                
                // The "% of Total" column is a percentage, so it must be written as a numeric
                // cell with a percentage number format rather than a raw fraction string.
                if let percentColumnIndex {
                    let coordinate = CellCoordinate(
                        row: rowIndex,
                        column: percentColumnIndex
                    ).excelAddress
                    let fontColor = roleFontFormat(for: roleDuration.roleSubrole)?.fontColor
                    sheet.setCell(
                        coordinate,
                        number: roleDuration.percentOfTotal,
                        format: summaryPercentFormat(fontColor: fontColor)
                    )
                }
                
                rowIndex += 1
            }
        }
        
        if !summary.missingMediaPaths.isEmpty {
            sheet.setRow(
                rowIndex,
                strings: [FinalCutPro.FCPXML.SummaryReportSection.missingMediaSectionTitle]
            )
            rowIndex += 1
            
            for path in summary.missingMediaPaths {
                sheet.setRow(rowIndex, strings: [path])
                rowIndex += 1
            }
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
    }
    
    private static func appendRoleInventory(
        _ roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection,
        to workbook: Workbook
    ) {
        appendTabularSection(
            to: workbook,
            sheetName: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName,
            headers: FinalCutPro.FCPXML.RoleClipReportRow.selectedRolesColumnHeaders,
            rows: roleInventory.selectedRoles.map(\.columnValues)
        )
        
        for roleSheet in roleInventory.roleSheets {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
                    for: roleSheet.sheetName
                ),
                headers: FinalCutPro.FCPXML.RoleClipReportRow.selectedRolesColumnHeaders,
                rows: roleSheet.rows.map(\.columnValues)
            )
        }
    }
    
    /// Excel sheet names are limited to 31 characters and exclude `\ / ? * [ ] :`.
    static func sanitizeSheetName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":\\/?*[]")
        let sanitized = name.unicodeScalars.map { scalar -> Character in
            if invalidCharacters.contains(scalar) {
                return "_"
            }
            return Character(scalar)
        }
        
        let string = String(sanitized).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return "Sheet" }
        
        if string.count <= 31 {
            return string
        }
        
        return String(string.prefix(31))
    }
    
    private static let roleSubroleColumnHeader = "Role ▸ Subrole"
    private static let percentOfTotalColumnHeader = "% of Total"
    
    /// Percentage cell format matching Final Cut Pro's Summary sheet (`0.0%`). The stored value
    /// is a fraction (for example `0.42`), which the number format renders as `42.0%`.
    private static func summaryPercentFormat(fontColor: String?) -> CellFormat {
        var format = CellFormat()
        format.numberFormat = .custom
        format.customNumberFormat = "0.0%"
        format.fontColor = fontColor
        return format
    }
}

private extension FCPXMLReportWorkbookExporter {
    enum RoleColorBucket {
        case videoOrSRT
        case titles
        case audio
        case gap
        
        var fontColorHex: String? {
            switch self {
            case .videoOrSRT:
                return "#0066FF"
            case .titles:
                return "#9933FF"
            case .audio:
                return "#00AA44"
            case .gap:
                return "#000000"
            }
        }
    }
}
