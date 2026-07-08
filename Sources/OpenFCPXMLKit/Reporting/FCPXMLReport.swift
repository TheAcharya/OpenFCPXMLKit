//
//  FCPXMLReport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Aggregate report model produced from FCPXML.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Workbook cover sheet settings used by Excel export.
    public struct ReportWorkbookCoverSheet: Sendable, Equatable {
        /// Worksheet tab title.
        public var title: String
        
        /// Header text written into cell `A1`.
        public var headerText: String
        
        public init(
            title: String = "Created by OpenFCPXMLKit",
            headerText: String = "Created by OpenFCPXMLKit"
        ) {
            self.title = title
            self.headerText = headerText
        }
        
        /// Default OpenFCPXMLKit-branded cover sheet.
        public static let openFCPXMLKitDefault = ReportWorkbookCoverSheet()
    }
    
    /// Structured report data extracted from an FCPXML project.
    ///
    /// Export to Excel via ``ReportExcelExport``.
    public struct Report: Sendable, Equatable {
        /// Name of the project the report was built from.
        public var projectName: String
        
        /// Event containing the project, if present.
        public var eventName: String?
        
        /// Markers report section.
        public var markers: MarkersReportSection?
        
        /// Keywords report section.
        public var keywords: KeywordsReportSection?
        
        /// Titles & Generators report section.
        public var titlesAndGenerators: TitlesReportSection?
        
        /// Transitions report section.
        public var transitions: TransitionsReportSection?
        
        /// Video & Audio Effects report section.
        public var effects: EffectsReportSection?
        
        /// Speed Change Effects report section.
        public var speedChangeEffects: SpeedChangeEffectsReportSection?
        
        /// Summary report section (project metrics and role totals).
        public var summary: SummaryReportSection?
        
        /// Media Summary report section (missing media file paths).
        public var mediaSummary: MediaSummaryReportSection?
        
        /// Role-based clip inventory (Selected Roles and per-role sheets).
        public var roleInventory: RoleInventoryReportSection?
        
        /// Optional first workbook sheet prepended by Excel export.
        public var workbookCoverSheet: ReportWorkbookCoverSheet?
        
        /// Columns omitted from every applicable workbook sheet at export.
        public var excludedColumns: Set<ReportColumn>
        
        /// Timecode display format used for workbook timecode columns.
        public var timecodeFormat: ReportTimecodeFormat
        
        public init(
            projectName: String,
            eventName: String? = nil,
            markers: MarkersReportSection? = nil,
            keywords: KeywordsReportSection? = nil,
            titlesAndGenerators: TitlesReportSection? = nil,
            transitions: TransitionsReportSection? = nil,
            effects: EffectsReportSection? = nil,
            speedChangeEffects: SpeedChangeEffectsReportSection? = nil,
            summary: SummaryReportSection? = nil,
            mediaSummary: MediaSummaryReportSection? = nil,
            roleInventory: RoleInventoryReportSection? = nil,
            workbookCoverSheet: ReportWorkbookCoverSheet? = nil,
            excludedColumns: Set<ReportColumn> = [],
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) {
            self.projectName = projectName
            self.eventName = eventName
            self.markers = markers
            self.keywords = keywords
            self.titlesAndGenerators = titlesAndGenerators
            self.transitions = transitions
            self.effects = effects
            self.speedChangeEffects = speedChangeEffects
            self.summary = summary
            self.mediaSummary = mediaSummary
            self.roleInventory = roleInventory
            self.workbookCoverSheet = workbookCoverSheet
            self.excludedColumns = excludedColumns
            self.timecodeFormat = timecodeFormat
        }
    }
}
