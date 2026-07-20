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
    
    /// Workbook sheet context for row text colour when Category is unavailable.
    private typealias RoleRowColorContext = FCPXMLReportRowColorPolicy.Context
    
    private static func roleFontFormat(
        for roleSubrole: String,
        categoryLabel: String? = nil,
        context: RoleRowColorContext = .roleInventory
    ) -> CellFormat? {
        let bucket = FCPXMLReportRowColorPolicy.bucket(
            for: roleSubrole,
            categoryLabel: categoryLabel,
            context: context
        )
        
        var format = CellFormat()
        format.fontColor = bucket.fontColorHex
        return format
    }
    
    @MainActor
    static func makeWorkbook(from report: FinalCutPro.FCPXML.Report) -> Workbook {
        let workbook = Workbook()
        let excludedColumns = report.excludedColumns
        let timecodeFormat = report.timecodeFormat
        
        if let workbookCoverSheet = report.workbookCoverSheet {
            appendWorkbookCoverSheet(
                workbookCoverSheet,
                copyrightLabel: report.copyrightLabel,
                to: workbook
            )
        }
        
        if let roleInventory = report.roleInventory {
            appendRoleInventory(
                roleInventory,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                projectFrameRateHint: report.summary?.projectSummary?.frameRate,
                to: workbook
            )
        }
        
        if let markers = report.markers {
            appendMarkers(
                markers,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                to: workbook
            )
        }
        
        if let keywords = report.keywords {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.KeywordReportRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: keywords.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows,
                colorContext: .keywords
            )
        }
        
        if let titles = report.titlesAndGenerators {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.TitleReportRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: titles.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows,
                colorContext: .titlesAndGenerators
            )
        }
        
        if let transitions = report.transitions {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.TransitionReportRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: transitions.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows,
                colorContext: .transitions
            )
        }
        
        if let nonStandard = report.nonStandardEffectsTemplates, !nonStandard.rows.isEmpty {
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.NonStandardEffectsTemplatesReportSection.defaultSheetName,
                headers: FinalCutPro.FCPXML.NonStandardEffectTemplateReportRow.columnHeaders,
                rows: nonStandard.rows.map(\.columnValues),
                colorContext: .effects
            )
        }
        
        if let effects = report.effects {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: effects.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows,
                colorContext: .effects
            )
        }
        
        if let speedChangeEffects = report.speedChangeEffects {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: speedChangeEffects.rows.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            appendTabularSection(
                to: workbook,
                sheetName: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
                headers: filtered.headers,
                rows: filtered.rows,
                colorContext: .speedChangeEffects
            )
        }
        
        if let summary = report.summary {
            appendSummary(
                summary,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                to: workbook
            )
        }
        
        if let mediaSummary = report.mediaSummary {
            appendMediaSummary(mediaSummary, excludedColumns: excludedColumns, to: workbook)
        }
        
        if report.protectSheets {
            applySheetProtection(to: workbook)
        }
        
        return workbook
    }
    
    /// Applies XLKit worksheet protection to every sheet (edit lock; no password).
    ///
    /// This discourages accidental edits. It is **not** workbook open-password encryption.
    private static func applySheetProtection(to workbook: Workbook) {
        for sheet in workbook.getSheets() {
            sheet.protection = SheetProtection()
        }
    }
    
    /// Minimum width for the cover sheet's header column, wider than the auto-fit estimate so the
    /// branding cell reads as a banner rather than a tight-fitting label.
    private static let coverSheetColumnWidth = 48.0
    
    private static func appendWorkbookCoverSheet(
        _ workbookCoverSheet: FinalCutPro.FCPXML.ReportWorkbookCoverSheet,
        copyrightLabel: String?,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(name: sanitizeSheetName(workbookCoverSheet.title))
        sheet.setCell("A1", string: workbookCoverSheet.headerText, format: tableHeaderFormat())
        
        var longestCoverLine = workbookCoverSheet.headerText.count
        if let copyrightLabel {
            // Same black/white banner style as the Created-by brand row, on the next row.
            sheet.setCell("A2", string: copyrightLabel, format: tableHeaderFormat())
            longestCoverLine = max(longestCoverLine, copyrightLabel.count)
        }
        
        // Use an explicit, generous width instead of the tight text-based auto-fit; grow further
        // when cover branding or copyright text is longer than the default banner width.
        let width = max(coverSheetColumnWidth, Double(longestCoverLine) + 4.0)
        sheet.setColumnWidth(1, width: width)
    }
    
    private static func appendMarkers(
        _ markers: FinalCutPro.FCPXML.MarkersReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        to workbook: Workbook
    ) {
        let filtered = filteredTabularSection(
            headers: markers.columnHeaders(timecodeFormat: timecodeFormat),
            rows: markers.rows.map { markers.columnValues(for: $0) },
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
            let rowFormat = markerFontFormat(for: marker.type)
            for (columnIndex, value) in values.enumerated() {
                let coordinate = CellCoordinate(row: rowIndex, column: columnIndex + 1).excelAddress
                sheet.setCell(coordinate, string: value, format: rowFormat)
            }
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(
            to: sheet,
            headers: headers,
            rows: filtered.rows
        )
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
        FCPXMLReportRowColorPolicy.markerFontColorHex(for: markerType)
    }
    
    private static func appendTabularSection(
        to workbook: Workbook,
        sheetName: String,
        headers: [String],
        rows: [[String]],
        colorContext: RoleRowColorContext = .roleInventory
    ) {
        let sheet = workbook.addSheet(name: sanitizeSheetName(sheetName))
        setTableHeaderRow(sheet, row: 1, strings: headers)
        let roleColumnIndex = headers.firstIndex(of: FCPXMLReportRowColorPolicy.roleSubroleColumnHeader).map { $0 + 1 }
        let categoryColumnIndex = headers.firstIndex(of: FCPXMLReportRowColorPolicy.categoryColumnHeader).map { $0 + 1 }
        for (index, values) in rows.enumerated() {
            let rowIndex = index + 2
            let roleFormat = roleFontFormatIfNeeded(
                values: values,
                roleColumnIndex: roleColumnIndex,
                categoryColumnIndex: categoryColumnIndex,
                colorContext: colorContext
            )
            for (columnIndex, value) in values.enumerated() {
                let coordinate = CellCoordinate(row: rowIndex, column: columnIndex + 1).excelAddress
                if let roleFormat {
                    sheet.setCell(coordinate, string: value, format: roleFormat)
                } else {
                    sheet.setCell(coordinate, string: value)
                }
            }
        }
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: headers, rows: rows)
    }

    private static func roleFontFormatIfNeeded(
        values: [String],
        roleColumnIndex: Int?,
        categoryColumnIndex: Int?,
        colorContext: RoleRowColorContext
    ) -> CellFormat? {
        guard let roleColumnIndex,
              values.indices.contains(roleColumnIndex - 1)
        else {
            return nil
        }

        let roleValue = values[roleColumnIndex - 1]
        var categoryValue: String?
        if let categoryColumnIndex,
           values.indices.contains(categoryColumnIndex - 1)
        {
            categoryValue = values[categoryColumnIndex - 1]
        }

        return roleFontFormat(
            for: roleValue,
            categoryLabel: categoryValue,
            context: colorContext
        )
    }
    
    private static func applyRoleColorToRow(
        _ sheet: Sheet,
        row: Int,
        values: [String],
        roleColumnIndex: Int?,
        categoryColumnIndex: Int?,
        colorContext: RoleRowColorContext = .roleInventory
    ) {
        guard let roleFormat = roleFontFormatIfNeeded(
            values: values,
            roleColumnIndex: roleColumnIndex,
            categoryColumnIndex: categoryColumnIndex,
            colorContext: colorContext
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
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName)
        )
        
        var rowIndex = 1
        
        if let projectSummary = summary.projectSummary {
            // Title lives in column B so autofit does not widen the Row index column (A)
            // when the project name is long.
            sheet.setCell(
                "B\(rowIndex)",
                string: projectSummary.title,
                format: tableHeaderFormat()
            )
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
                headers: FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: summary.roleDurations.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            let headers = filtered.headers
            setTableHeaderRow(sheet, row: rowIndex, strings: headers)
            rowIndex += 1
            
            let percentColumnIndex = headers
                .firstIndex(of: percentOfTotalColumnHeader)
                .map { $0 + 1 }
            
            for (index, roleDuration) in summary.roleDurations.enumerated() {
                let values = filtered.rows[index]
                sheet.setRow(rowIndex, strings: values)
                
                if let percentColumnIndex {
                    let coordinate = CellCoordinate(
                        row: rowIndex,
                        column: percentColumnIndex
                    ).excelAddress
                    sheet.setCell(
                        coordinate,
                        number: roleDuration.percentOfTotal,
                        format: summaryPercentFormat()
                    )
                }
                
                rowIndex += 1
            }
            
            FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: headers)
            widenSummaryProjectTitleColumn(
                on: sheet,
                title: summary.projectSummary?.title
            )
            return
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
        widenSummaryProjectTitleColumn(
            on: sheet,
            title: summary.projectSummary?.title
        )
    }
    
    /// Ensures Summary column B is wide enough for the project title in ``B1``.
    private static func widenSummaryProjectTitleColumn(on sheet: Sheet, title: String?) {
        guard let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let titleColumn = 2 // B1
        let desired = FCPXMLReportWorkbookColumnAutoFit.summaryProjectTitleColumnWidth(for: title)
        let current = sheet.getColumnWidth(titleColumn) ?? 0
        sheet.setColumnWidth(titleColumn, width: max(current, desired))
    }
    
    private static func appendMediaSummary(
        _ mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        to workbook: Workbook
    ) {
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName)
        )

        let table = mediaSummaryTable(mediaSummary)
        guard !table.headers.isEmpty, !table.rows.isEmpty else {
            FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
            return
        }

        let filtered = filteredTabularSection(
            headers: table.headers,
            rows: table.rows,
            excludedColumns: excludedColumns
        )
        guard !filtered.headers.isEmpty, !filtered.rows.isEmpty else {
            FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet)
            return
        }

        let headers = filtered.headers
        setTableHeaderRow(sheet, row: 1, strings: headers)

        let pathColumnIndices: [Int] = headers.indices.compactMap { index in
            let header = headers[index]
            if header == FinalCutPro.FCPXML.MediaSummaryReportSection.missingMediaSectionTitle
                || header == FinalCutPro.FCPXML.MediaSummaryReportSection.missingOriginalMediaSectionTitle
                || header == FinalCutPro.FCPXML.MediaSummaryReportSection.missingProxyMediaSectionTitle
            {
                return index + 1
            }
            return nil
        }

        for (index, values) in filtered.rows.enumerated() {
            let rowIndex = index + 2
            sheet.setRow(rowIndex, strings: values)

            for pathColumnIndex in pathColumnIndices where values.indices.contains(pathColumnIndex - 1) {
                let coordinate = CellCoordinate(
                    row: rowIndex,
                    column: pathColumnIndex
                ).excelAddress
                sheet.setCell(
                    coordinate,
                    string: values[pathColumnIndex - 1],
                    format: missingMediaPathFormat()
                )
            }
        }

        FCPXMLReportWorkbookColumnAutoFit.apply(
            to: sheet,
            headers: headers,
            rows: filtered.rows
        )
    }

    private static func mediaSummaryTable(
        _ mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection
    ) -> (headers: [String], rows: [[String]]) {
        if mediaSummary.distinguishProxyAndOriginal {
            let originalTitle = FinalCutPro.FCPXML.MediaSummaryReportSection.missingOriginalMediaSectionTitle
            let proxyTitle = FinalCutPro.FCPXML.MediaSummaryReportSection.missingProxyMediaSectionTitle
            let originals = mediaSummary.missingOriginalMediaPaths
            let proxies = mediaSummary.missingProxyMediaPaths
            let rowCount = max(originals.count, proxies.count)
            guard rowCount > 0 else { return ([], []) }
            var rows: [[String]] = []
            rows.reserveCapacity(rowCount)
            for index in 0 ..< rowCount {
                let original = index < originals.count ? originals[index] : ""
                let proxy = index < proxies.count ? proxies[index] : ""
                rows.append([original, proxy])
            }
            return ([originalTitle, proxyTitle], rows)
        }

        let title = FinalCutPro.FCPXML.MediaSummaryReportSection.missingMediaSectionTitle
        guard !mediaSummary.missingMediaPaths.isEmpty else { return ([], []) }
        return ( [title], mediaSummary.missingMediaPaths.map { [$0] } )
    }
    
    private static func appendRoleInventory(
        _ roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        projectFrameRateHint: String?,
        to workbook: Workbook
    ) {
        let metadataColumnKeys = roleInventory.metadataColumnKeys
        let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
            metadataColumnKeys: metadataColumnKeys,
            excludedColumns: excludedColumns,
            timecodeFormat: timecodeFormat
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
            appendRoleInventoryRoleSheet(
                roleSheet,
                headers: headers,
                metadataColumnKeys: metadataColumnKeys,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                projectFrameRateHint: projectFrameRateHint,
                to: workbook
            )
        }
    }
    
    private static func appendRoleInventoryRoleSheet(
        _ roleSheet: FinalCutPro.FCPXML.RoleSheet,
        headers: [String],
        metadataColumnKeys: [String],
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        projectFrameRateHint: String?,
        to workbook: Workbook
    ) {
        let rows = roleSheet.rows.enumerated().map { index, row in
            FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnValues(
                for: row,
                rowIndex: index + 1,
                metadataColumnKeys: metadataColumnKeys,
                excludedColumns: excludedColumns
            )
        }
        guard !rows.isEmpty else { return }
        
        let sheet = workbook.addSheet(
            name: sanitizeSheetName(
                FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
                    for: roleSheet.sheetName
                )
            )
        )
        setTableHeaderRow(sheet, row: 1, strings: headers)
        
        let roleColumnIndex = headers.firstIndex(
            of: FCPXMLReportRowColorPolicy.roleSubroleColumnHeader
        ).map { $0 + 1 }
        let categoryColumnIndex = headers.firstIndex(
            of: FCPXMLReportRowColorPolicy.categoryColumnHeader
        ).map { $0 + 1 }
        
        for (index, values) in rows.enumerated() {
            applyRoleColorToRow(
                sheet,
                row: index + 2,
                values: values,
                roleColumnIndex: roleColumnIndex,
                categoryColumnIndex: categoryColumnIndex,
                colorContext: .roleInventory
            )
        }
        
        if let totalValue = FinalCutPro.FCPXML.RoleInventorySheetTotal.optimisticClipDurationTotal(
            from: roleSheet.rows,
            timecodeFormat: timecodeFormat,
            projectFrameRateHint: projectFrameRateHint
        ),
           let columns = FinalCutPro.FCPXML.RoleInventorySheetTotal.footerColumnIndices(
            in: headers,
            excludedColumns: excludedColumns,
            timecodeFormat: timecodeFormat
           )
        {
            let footerRowIndex = rows.count + 3
            let headerFormat = tableHeaderFormat()
            let labelCoordinate = CellCoordinate(
                row: footerRowIndex,
                column: columns.label + 1
            ).excelAddress
            let valueCoordinate = CellCoordinate(
                row: footerRowIndex,
                column: columns.value + 1
            ).excelAddress
            sheet.setCell(
                labelCoordinate,
                string: FinalCutPro.FCPXML.RoleInventorySheetTotal.label,
                format: headerFormat
            )
            sheet.setCell(valueCoordinate, string: totalValue, format: headerFormat)
        }
        
        FCPXMLReportWorkbookColumnAutoFit.apply(to: sheet, headers: headers, rows: rows)
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
    
    private static let percentOfTotalColumnHeader = "% of Total"
    
    /// Red text for missing media file paths on the Media Summary sheet.
    private static func missingMediaPathFormat() -> CellFormat {
        var format = CellFormat()
        format.fontColor = "#FF0000"
        return format
    }
    
    /// Percentage cell format matching Final Cut Pro's Summary sheet (`0.0%`). The stored value
    /// is a fraction (for example `0.42`), which the number format renders as `42.0%`.
    /// Summary data cells use default black text (no role colour coding).
    private static func summaryPercentFormat() -> CellFormat {
        var format = CellFormat()
        format.numberFormat = .custom
        format.customNumberFormat = "0.0%"
        return format
    }
}
