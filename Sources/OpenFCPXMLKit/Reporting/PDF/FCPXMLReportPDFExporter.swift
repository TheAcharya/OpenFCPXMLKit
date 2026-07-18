//
//  FCPXMLReportPDFExporter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Maps ``FinalCutPro/FCPXML/Report`` sections to a multi-page PDF document.
//

import CoreGraphics
import Foundation

enum FCPXMLReportPDFExporter {
    static func makePDFData(from report: FinalCutPro.FCPXML.Report) throws -> Data {
        let plannedSheets = FCPXMLReportPDFSheetPlan.plannedSheets(from: report)
        let colorIndexByTitle = FCPXMLReportPDFSheetPlan.colorIndexLookup(for: plannedSheets)
        
        guard !plannedSheets.isEmpty else {
            return try renderPDF(
                from: report,
                colorIndexByTitle: colorIndexByTitle,
                tableOfContents: nil,
                reservedTOCPages: 0,
                recordsSectionStarts: false
            )
        }
        
        let reservedTOCPages = FCPXMLReportPDFSheetPlan.tableOfContentsPageCount(
            entryCount: plannedSheets.count
        )
        var recordedStarts: [(title: String, startPage: Int)] = []
        
        _ = try renderPDF(
            from: report,
            colorIndexByTitle: colorIndexByTitle,
            tableOfContents: nil,
            reservedTOCPages: reservedTOCPages,
            recordsSectionStarts: true,
            layoutOnly: true,
            sectionStartSink: { title, startPage in
                recordedStarts.append((title, startPage))
            }
        )
        
        let tableOfContents = FCPXMLReportPDFSheetPlan.tableOfContentsEntries(
            from: plannedSheets,
            recorded: recordedStarts
        )
        
        return try renderPDF(
            from: report,
            colorIndexByTitle: colorIndexByTitle,
            tableOfContents: tableOfContents,
            reservedTOCPages: 0,
            recordsSectionStarts: false,
            layoutOnly: false
        )
    }
    
    private static func renderPDF(
        from report: FinalCutPro.FCPXML.Report,
        colorIndexByTitle: [String: Int],
        tableOfContents: [FCPXMLReportPDFSheetPlan.SheetEntry]?,
        reservedTOCPages: Int,
        recordsSectionStarts: Bool,
        layoutOnly: Bool = false,
        sectionStartSink: ((String, Int) -> Void)? = nil
    ) throws -> Data {
        let data = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw FinalCutPro.FCPXML.ReportPDFExportError.couldNotCreateDocument
        }
        
        var mediaBox = CGRect(origin: .zero, size: FCPXMLReportPDFStyle.pageSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw FinalCutPro.FCPXML.ReportPDFExportError.couldNotCreateDocument
        }
        
        let canvas = FCPXMLReportPDFCanvas.Builder(context: context)
        canvas.configureDocument(
            projectName: report.projectName,
            eventName: report.eventName,
            exportBrandingText: report.exportBrandingText,
            copyrightLabel: report.copyrightLabel,
            sectionStartRecorder: recordsSectionStarts ? sectionStartSink : nil,
            layoutOnly: layoutOnly
        )
        canvas.drawCoverPage(projectName: report.projectName, eventName: report.eventName)
        
        if let tableOfContents, !tableOfContents.isEmpty {
            canvas.drawTableOfContents(entries: tableOfContents)
        } else if reservedTOCPages > 0 {
            canvas.reserveBlankPages(reservedTOCPages)
        }
        
        let excludedColumns = report.excludedColumns
        let timecodeFormat = report.timecodeFormat
        
        if let roleInventory = report.roleInventory {
            appendRoleInventory(
                roleInventory,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let markers = report.markers {
            appendMarkers(
                markers,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let keywords = report.keywords {
            appendKeywords(
                keywords,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let titlesAndGenerators = report.titlesAndGenerators {
            appendTitlesAndGenerators(
                titlesAndGenerators,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let transitions = report.transitions {
            appendTransitions(
                transitions,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let effects = report.effects {
            appendEffects(
                effects,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let speedChangeEffects = report.speedChangeEffects {
            appendSpeedChangeEffects(
                speedChangeEffects,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let summary = report.summary {
            appendSummary(
                summary,
                excludedColumns: excludedColumns,
                timecodeFormat: timecodeFormat,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        if let mediaSummary = report.mediaSummary {
            appendMediaSummary(
                mediaSummary,
                excludedColumns: excludedColumns,
                colorIndexByTitle: colorIndexByTitle,
                recordsSectionStarts: recordsSectionStarts,
                to: canvas
            )
        }
        
        canvas.finishDocument()
        return data as Data
    }
    
    private static func sheetColorIndex(
        for title: String,
        colorIndexByTitle: [String: Int]
    ) -> Int {
        colorIndexByTitle[title] ?? 0
    }
    
    private static func appendRoleInventory(
        _ roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        let metadataColumnKeys = roleInventory.metadataColumnKeys
        let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
            metadataColumnKeys: metadataColumnKeys,
            excludedColumns: excludedColumns,
            timecodeFormat: timecodeFormat
        )
        
        guard !headers.isEmpty else { return }
        
        let selectedSheetName = FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName
        let selectedRows = roleInventory.selectedRoles.enumerated().map { index, row in
            FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnValues(
                for: row,
                rowIndex: index + 1,
                metadataColumnKeys: metadataColumnKeys,
                excludedColumns: excludedColumns
            )
        }
        
        if !selectedRows.isEmpty {
            canvas.drawTable(
                context: tableDrawContext(
                    pageTitle: selectedSheetName,
                    sheetColorIndex: sheetColorIndex(
                        for: selectedSheetName,
                        colorIndexByTitle: colorIndexByTitle
                    ),
                    recordsSectionStart: recordsSectionStarts,
                    excludedColumns: excludedColumns
                ),
                headers: headers,
                rows: selectedRows,
                rowTextColorForRow: { _, values in
                    FCPXMLReportRowColorPolicy.textColor(
                        forRowValues: values,
                        headers: headers,
                        context: .roleInventory,
                        defaultColor: FCPXMLReportPDFStyle.textColor
                    )
                }
            )
        }
        
        for roleSheet in roleInventory.roleSheets {
            let rows = roleSheet.rows.enumerated().map { index, row in
                FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnValues(
                    for: row,
                    rowIndex: index + 1,
                    metadataColumnKeys: metadataColumnKeys,
                    excludedColumns: excludedColumns
                )
            }
            
            guard !rows.isEmpty else { continue }
            
            let sheetTitle = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
                for: roleSheet.sheetName
            )
            
            canvas.drawTable(
                context: tableDrawContext(
                    pageTitle: sheetTitle,
                    sheetColorIndex: sheetColorIndex(
                        for: sheetTitle,
                        colorIndexByTitle: colorIndexByTitle
                    ),
                    recordsSectionStart: recordsSectionStarts,
                    excludedColumns: excludedColumns
                ),
                headers: headers,
                rows: rows,
                rowTextColorForRow: { _, values in
                    FCPXMLReportRowColorPolicy.textColor(
                        forRowValues: values,
                        headers: headers,
                        context: .roleInventory,
                        defaultColor: FCPXMLReportPDFStyle.textColor
                    )
                }
            )
        }
    }
    
    private static func appendMarkers(
        _ markers: FinalCutPro.FCPXML.MarkersReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        let filtered = filteredTabularSection(
            headers: markers.columnHeaders(timecodeFormat: timecodeFormat),
            rows: markers.rows.map { markers.columnValues(for: $0) },
            excludedColumns: excludedColumns
        )
        
        guard !filtered.headers.isEmpty else { return }
        
        let sheetName = FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName
        canvas.drawTable(
            context: tableDrawContext(
                pageTitle: sheetName,
                sheetColorIndex: sheetColorIndex(for: sheetName, colorIndexByTitle: colorIndexByTitle),
                recordsSectionStart: recordsSectionStarts,
                excludedColumns: excludedColumns
            ),
            headers: filtered.headers,
            rows: filtered.rows,
            rowTextColorForRow: { index, _ in
                FCPXMLReportRowColorPolicy.markerCGColor(for: markers.rows[index].type)
                    ?? FCPXMLReportPDFStyle.textColor
            }
        )
    }
    
    private static func appendKeywords(
        _ keywords: FinalCutPro.FCPXML.KeywordsReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        appendTabularSection(
            sheetName: FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
            headers: FinalCutPro.FCPXML.KeywordReportRow.columnHeaders(timecodeFormat: timecodeFormat),
            rows: keywords.rows.map(\.columnValues),
            excludedColumns: excludedColumns,
            colorIndexByTitle: colorIndexByTitle,
            recordsSectionStarts: recordsSectionStarts,
            colorContext: .keywords,
            to: canvas
        )
    }
    
    private static func appendTitlesAndGenerators(
        _ titles: FinalCutPro.FCPXML.TitlesReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        appendTabularSection(
            sheetName: FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
            headers: FinalCutPro.FCPXML.TitleReportRow.columnHeaders(timecodeFormat: timecodeFormat),
            rows: titles.rows.map(\.columnValues),
            excludedColumns: excludedColumns,
            colorIndexByTitle: colorIndexByTitle,
            recordsSectionStarts: recordsSectionStarts,
            colorContext: .titlesAndGenerators,
            to: canvas
        )
    }
    
    private static func appendTransitions(
        _ transitions: FinalCutPro.FCPXML.TransitionsReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        appendTabularSection(
            sheetName: FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
            headers: FinalCutPro.FCPXML.TransitionReportRow.columnHeaders(timecodeFormat: timecodeFormat),
            rows: transitions.rows.map(\.columnValues),
            excludedColumns: excludedColumns,
            colorIndexByTitle: colorIndexByTitle,
            recordsSectionStarts: recordsSectionStarts,
            colorContext: .transitions,
            to: canvas
        )
    }
    
    private static func appendEffects(
        _ effects: FinalCutPro.FCPXML.EffectsReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        appendTabularSection(
            sheetName: FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
            headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders(timecodeFormat: timecodeFormat),
            rows: effects.rows.map(\.columnValues),
            excludedColumns: excludedColumns,
            colorIndexByTitle: colorIndexByTitle,
            recordsSectionStarts: recordsSectionStarts,
            colorContext: .effects,
            to: canvas
        )
    }
    
    private static func appendSpeedChangeEffects(
        _ speedChangeEffects: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        appendTabularSection(
            sheetName: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
            headers: FinalCutPro.FCPXML.EffectReportRow.columnHeaders(timecodeFormat: timecodeFormat),
            rows: speedChangeEffects.rows.map(\.columnValues),
            excludedColumns: excludedColumns,
            colorIndexByTitle: colorIndexByTitle,
            recordsSectionStarts: recordsSectionStarts,
            colorContext: .speedChangeEffects,
            to: canvas
        )
    }
    
    private static func appendTabularSection(
        sheetName: String,
        headers: [String],
        rows: [[String]],
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        colorContext: FCPXMLReportRowColorPolicy.Context,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        let filtered = filteredTabularSection(
            headers: headers,
            rows: rows,
            excludedColumns: excludedColumns
        )
        
        guard !filtered.headers.isEmpty, !filtered.rows.isEmpty else { return }
        
        canvas.drawTable(
            context: tableDrawContext(
                pageTitle: sheetName,
                sheetColorIndex: sheetColorIndex(for: sheetName, colorIndexByTitle: colorIndexByTitle),
                recordsSectionStart: recordsSectionStarts,
                excludedColumns: excludedColumns
            ),
            headers: filtered.headers,
            rows: filtered.rows,
            rowTextColorForRow: { _, values in
                FCPXMLReportRowColorPolicy.textColor(
                    forRowValues: values,
                    headers: filtered.headers,
                    context: colorContext,
                    defaultColor: FCPXMLReportPDFStyle.textColor
                )
            }
        )
    }
    
    private static func appendSummary(
        _ summary: FinalCutPro.FCPXML.SummaryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        let sheetName = FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName
        let colorIndex = sheetColorIndex(for: sheetName, colorIndexByTitle: colorIndexByTitle)
        
        if let projectSummary = summary.projectSummary {
            canvas.beginContentPage(
                pageTitle: sheetName,
                sheetColorIndex: colorIndex,
                contentHeading: nil,
                recordsSectionStart: recordsSectionStarts
            )
            canvas.drawSummaryProjectTitle(projectSummary.title)
            
            let metrics = FinalCutPro.FCPXML.ReportColumnExclusion.filteredProjectSummaryMetrics(
                projectSummary,
                excluded: excludedColumns
            )
            let metricLine = metrics
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "  ·  ")
            
            if !metricLine.isEmpty {
                canvas.drawBodyLine(metricLine, color: FCPXMLReportPDFStyle.mutedTextColor)
            }
            
            canvas.endContentPage()
        }
        
        if !summary.roleDurations.isEmpty {
            let filtered = filteredTabularSection(
                headers: FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders(
                    timecodeFormat: timecodeFormat
                ),
                rows: summary.roleDurations.map(\.columnValues),
                excludedColumns: excludedColumns
            )
            
            if !filtered.headers.isEmpty {
                canvas.drawTable(
                    context: tableDrawContext(
                        pageTitle: sheetName,
                        sheetColorIndex: colorIndex,
                        contentHeading: summary.projectSummary == nil ? nil : "Role Durations",
                        recordsSectionStart: recordsSectionStarts && summary.projectSummary == nil,
                        excludedColumns: excludedColumns
                    ),
                    headers: filtered.headers,
                    rows: filtered.rows
                )
            }
        }
    }
    
    private static func appendMediaSummary(
        _ mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>,
        colorIndexByTitle: [String: Int],
        recordsSectionStarts: Bool,
        to canvas: FCPXMLReportPDFCanvas.Builder
    ) {
        let table: (headers: [String], rows: [[String]])
        if mediaSummary.distinguishProxyAndOriginal {
            let originals = mediaSummary.missingOriginalMediaPaths
            let proxies = mediaSummary.missingProxyMediaPaths
            let rowCount = max(originals.count, proxies.count)
            guard rowCount > 0 else { return }
            var rows: [[String]] = []
            for index in 0 ..< rowCount {
                rows.append([
                    index < originals.count ? originals[index] : "",
                    index < proxies.count ? proxies[index] : ""
                ])
            }
            table = (
                [
                    FinalCutPro.FCPXML.MediaSummaryReportSection.missingOriginalMediaSectionTitle,
                    FinalCutPro.FCPXML.MediaSummaryReportSection.missingProxyMediaSectionTitle
                ],
                rows
            )
        } else {
            guard !mediaSummary.missingMediaPaths.isEmpty else { return }
            table = (
                [FinalCutPro.FCPXML.MediaSummaryReportSection.missingMediaSectionTitle],
                mediaSummary.missingMediaPaths.map { [$0] }
            )
        }

        let filtered = filteredTabularSection(
            headers: table.headers,
            rows: table.rows,
            excludedColumns: excludedColumns
        )

        guard !filtered.headers.isEmpty, !filtered.rows.isEmpty else { return }

        let sheetName = FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        canvas.drawTable(
            context: tableDrawContext(
                pageTitle: sheetName,
                sheetColorIndex: sheetColorIndex(for: sheetName, colorIndexByTitle: colorIndexByTitle),
                recordsSectionStart: recordsSectionStarts,
                excludedColumns: excludedColumns
            ),
            headers: filtered.headers,
            rows: filtered.rows,
            rowTextColor: FCPXMLReportPDFStyle.missingMediaTextColor
        )
    }
    
    private static func tableDrawContext(
        pageTitle: String,
        sheetColorIndex: Int,
        contentHeading: String? = nil,
        recordsSectionStart: Bool,
        excludedColumns: Set<FinalCutPro.FCPXML.ReportColumn>
    ) -> FCPXMLReportPDFTableRenderer.TableDrawContext {
        FCPXMLReportPDFTableRenderer.TableDrawContext(
            pageTitle: pageTitle,
            sheetColorIndex: sheetColorIndex,
            contentHeading: contentHeading,
            recordsSectionStart: recordsSectionStart,
            allowInjectedRowColumn: FinalCutPro.FCPXML.ReportColumnExclusion.allowsInjectedRowColumn(
                excluded: excludedColumns
            )
        )
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
}
