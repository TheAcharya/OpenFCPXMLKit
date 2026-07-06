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
        let excludedColumns = report.excludedColumns
        
        if let workbookCoverSheet = report.workbookCoverSheet {
            appendWorkbookCoverSheet(workbookCoverSheet, to: workbook)
        }
        
        if let roleInventory = report.roleInventory {
            appendRoleInventory(roleInventory, excludedColumns: excludedColumns, to: workbook)
        }
        
        if let markers = report.markers {
            appendMarkers(markers, excludedColumns: excludedColumns, to: workbook)
        }
        
        if let keywords = report.keywords {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.KeywordReportRow.columnHeaders,
                rows: keywords.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows
            )
        }
        
        if let titles = report.titlesAndGenerators {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.TitleReportRow.columnHeaders,
                rows: titles.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows
            )
        }
        
        if let transitions = report.transitions {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.TransitionReportRow.columnHeaders,
                rows: transitions.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows
            )
        }
        
        if let effects = report.effects {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders,
                rows: effects.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows
            )
        }
        
        if let speedChangeEffects = report.speedChangeEffects {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders,
                rows: speedChangeEffects.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows
            )
        }
        
        if let summary = report.summary {
            appendSummary(summary, excludedColumns: excludedColumns, to: workbook)
        }
        
        if let mediaSummary = report.mediaSummary {
            appendMediaSummary(mediaSummary, excludedColumns: excludedColumns, to: workbook)
        }
        
        return workbook
    }
    
    /// Minimum width for the cover sheet's header column, wider than the auto-fit estimate so the
    /// branding cell reads as a banner rather than a tight-fitting label.
    private static let coverSheetColumnWidth = 48.0
    
    private static func appendWorkbookCoverSheet(
        _ workbookCoverSheet: FinalCutPro.FCPXML.ReportWorkbookCoverSheet,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(name: sanitizeSheetName(workbookCoverSheet.title))
        sheet.setCell("A1", string: workbookCoverSheet.headerText, format: tableHeaderFormat())
        
        // Use an explicit, generous width instead of the tight text-based auto-fit; grow further
        // when a custom header text is longer than the default banner width.
        let width = max(coverSheetColumnWidth, Double(workbookCoverSheet.headerText.count) + 4.0)
        sheet.setColumnWidth(1, width: width)
    }
    
    private static func appendMarkers(
        _ markers: FinalCutPro.FCPXML.MarkersReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        to workbook: Workbook
    ) {
        let filtered = filteredTabularSection(
            headers: FinalCutPro.FCPXML.MarkerReportRow.columnHeaders,
            rows: markers.rows.map(\.columnValues),
            excludedColumns: excludedColumns
        )
        let headers = filtered.headers
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName)
        )
        setTableHeaderRow(sheet, row: 1, strings: headers)
        
        for (index, marker) in markers.rows.enumerated() {
            let rowIndex = index + 2
            let values = filtered.rows[index]
            sheet.setRow(rowIndex, strings: values)
            applyMarkerColorToRow(
                sheet,
                row: rowIndex,
                values: values,
                markerType: marker.type
            )
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: headers)
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
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: headers)
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
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName)
        )
        
        var rowIndex = 1
        
        if let projectSummary = summary.projectSummary {
            sheet.setRow(rowIndex, strings: [projectSummary.title])
            rowIndex += 1
            sheet.setRow(
                rowIndex,
                strings: FinalCutPro.FCPXML.ReportColumnExclusion.filteredProjectSummaryMetrics(
                    projectSummary,
                    excluded: excludedColumns
                )
            )
            rowIndex += 1
        }
        
        if !summary.roleDurations.isEmpty {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders,
                rows: summary.roleDurations.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            let headers = filtered.headers
            setTableHeaderRow(sheet, row: rowIndex, strings: headers)
            rowIndex += 1
            
            let roleColumnIndex = headers
                .firstIndex(of: roleSubroleColumnHeader)
                .map { $0 + 1 }
            let percentColumnIndex = headers
                .firstIndex(of: percentOfTotalColumnHeader)
                .map { $0 + 1 }
            
            for (index, roleDuration) in summary.roleDurations.enumerated() {
                let values = filtered.rows[index]
                sheet.setRow(rowIndex, strings: values)
                applyRoleColorToRow(
                    sheet,
                    row: rowIndex,
                    values: values,
                    roleColumnIndex: roleColumnIndex,
                    categoryColumnIndex: nil
                )
                
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
            
            FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: headers)
            return
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
    }
    
    private static func appendMediaSummary(
        _ mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName)
        )
        
        var rowIndex = 1
        let missingMediaTitle = FinalCutPro.FCPXML.MediaSummaryReportSection.missingMediaSectionTitle
        
        if !mediaSummary.missingMediaPaths.isEmpty,
           !FinalCutPro.FCPXML.ReportColumnExclusion.isHeaderExcluded(
               missingMediaTitle,
               excluded: excludedColumns,
               metadataColumnKeys: []
           )
        {
            setTableHeaderRow(sheet, row: rowIndex, strings: [missingMediaTitle])
            rowIndex += 1
            
            for path in mediaSummary.missingMediaPaths {
                sheet.setRow(rowIndex, strings: [path])
                rowIndex += 1
            }
            
            FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: [missingMediaTitle])
            return
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
    }
    
    private static func appendRoleInventory(
        _ roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        to workbook: Workbook
    ) {
        let metadataColumnKeys = roleInventory.metadataColumnKeys
        let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
            metadataColumnKeys: metadataColumnKeys,
            excludedColumns: excludedColumns
        )
        
        appendTabularSection(
            to: workbook,
            sheetName: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName,
            headers: headers,
            rows: roleInventory.selectedRoles.enumerated().map { index, row in
                FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnValues(
                    for: row,
                    rowIndex: index + 1,
                    metadataColumnKeys: metadataColumnKeys,
                    excludedColumns: excludedColumns
                )
            }
        )
        
        for roleSheet in roleInventory.roleSheets {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
                    for: roleSheet.sheetName
                ),
                headers: headers,
                rows: roleSheet.rows.enumerated().map { index, row in
                    FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnValues(
                        for: row,
                        rowIndex: index + 1,
                        metadataColumnKeys: metadataColumnKeys,
                        excludedColumns: excludedColumns
                    )
                }
            )
        }
    }
    
    private static func filteredTabularSection(
        headers: [String],
        rows: [[String]],
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        metadataColumnKeys: [String] = []
    ) -> (headers: [String], rows: [[String]]) {
        FinalCutPro.FCPXML.ReportColumnExclusion.filter(
            headers: headers,
            rows: rows,
            excluded: excludedColumns,
            metadataColumnKeys: metadataColumnKeys
        )
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
