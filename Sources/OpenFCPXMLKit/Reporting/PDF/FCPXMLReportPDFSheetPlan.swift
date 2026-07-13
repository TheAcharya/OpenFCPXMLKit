//
//  FCPXMLReportPDFSheetPlan.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Ordered workbook sheet plan for PDF section colours and table of contents.
//

import Foundation

enum FCPXMLReportPDFSheetPlan {
    /// One workbook sheet in PDF export order.
    struct SheetEntry: Sendable, Equatable {
        let title: String
        let colorIndex: Int
        var startPage: Int
        
        init(title: String, colorIndex: Int, startPage: Int = 0) {
            self.title = title
            self.colorIndex = colorIndex
            self.startPage = startPage
        }
    }
    
    /// Builds ordered sheet entries mirroring Excel workbook sheet order.
    static func plannedSheets(from report: FinalCutPro.FCPXML.Report) -> [SheetEntry] {
        var titles: [String] = []
        
        if let roleInventory = report.roleInventory {
            if !roleInventory.selectedRoles.isEmpty {
                titles.append(FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName)
            }
            
            for roleSheet in roleInventory.roleSheets where !roleSheet.rows.isEmpty {
                titles.append(
                    FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
                        for: roleSheet.sheetName
                    )
                )
            }
        }
        
        if let markers = report.markers, !markers.rows.isEmpty {
            titles.append(FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName)
        }
        
        if let keywords = report.keywords, !keywords.rows.isEmpty {
            titles.append(FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName)
        }
        
        if let titlesAndGenerators = report.titlesAndGenerators, !titlesAndGenerators.rows.isEmpty {
            titles.append(FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName)
        }
        
        if let transitions = report.transitions, !transitions.rows.isEmpty {
            titles.append(FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName)
        }
        
        if let effects = report.effects, !effects.rows.isEmpty {
            titles.append(FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName)
        }
        
        if let speedChangeEffects = report.speedChangeEffects, !speedChangeEffects.rows.isEmpty {
            titles.append(FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName)
        }
        
        if let summary = report.summary,
           summary.projectSummary != nil || !summary.roleDurations.isEmpty
        {
            titles.append(FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName)
        }
        
        if let mediaSummary = report.mediaSummary,
           !mediaSummary.missingMediaPaths.isEmpty,
           !FinalCutPro.FCPXML.ReportColumnExclusion.isHeaderExcluded(
               FinalCutPro.FCPXML.MediaSummaryReportSection.missingMediaSectionTitle,
               excluded: report.excludedColumns,
               metadataColumnKeys: []
           )
        {
            titles.append(FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName)
        }
        
        return titles.enumerated().map { index, title in
            SheetEntry(title: title, colorIndex: index)
        }
    }
    
    static func colorIndexLookup(for sheets: [SheetEntry]) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: sheets.map { ($0.title, $0.colorIndex) })
    }
    
    static func tableOfContentsPageCount(entryCount: Int) -> Int {
        guard entryCount > 0 else { return 0 }
        let rowsPerPage = tocRowsPerPage()
        return max(1, Int(ceil(Double(entryCount) / Double(rowsPerPage))))
    }
    
    static func tocRowsPerPage() -> Int {
        let available = FCPXMLReportPDFStyle.contentBottom
            - FCPXMLReportPDFStyle.contentTop
            - FCPXMLReportPDFStyle.sectionTitleFontSize
            - 10
            - FCPXMLReportPDFStyle.headerRowHeight
        guard available > 0 else { return 1 }
        return max(1, Int(floor(available / FCPXMLReportPDFStyle.rowHeight)))
    }
    
    static func tableOfContentsEntries(
        from planned: [SheetEntry],
        recorded: [(title: String, startPage: Int)]
    ) -> [SheetEntry] {
        let pagesByTitle = Dictionary(
            recorded.map { ($0.title, $0.startPage) },
            uniquingKeysWith: { first, _ in first }
        )
        
        return planned.map { entry in
            var updated = entry
            if let page = pagesByTitle[entry.title] {
                updated.startPage = page
            }
            return updated
        }
    }
}
