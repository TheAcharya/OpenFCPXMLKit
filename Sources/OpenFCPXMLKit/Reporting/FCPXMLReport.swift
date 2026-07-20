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
    /// Workbook cover sheet settings used by Excel export and PDF cover/footer branding.
    public struct ReportWorkbookCoverSheet: Sendable, Equatable {
        /// Worksheet tab title.
        public var title: String
        
        /// Header text written into Excel cell `A1` and used for PDF cover/footer branding.
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
        
        /// Branding label shared by Excel cover cell A1 and PDF cover/footer.
        public var brandingText: String { headerText }
    }
    
    /// Structured report data extracted from an FCPXML project.
    ///
    /// Export to Excel via ``ReportExcelExport`` or PDF via ``ReportPDFExport``.
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
        
        /// Non-standard / missing Motion templates and custom effects.
        public var nonStandardEffectsTemplates: NonStandardEffectsTemplatesReportSection?
        
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
        
        /// Optional cover sheet prepended by Excel export; branding text is also used on PDF cover/footer.
        public var workbookCoverSheet: ReportWorkbookCoverSheet?
        
        /// Optional copyright / label line shown below export branding.
        ///
        /// Excel: cover sheet cell `A2` (when a cover sheet is written). PDF: cover page below
        /// branding (same subtitle font/size) and running footer centre (same footer font/size).
        public var copyrightLabel: String?
        
        /// Columns omitted from every applicable workbook sheet at export.
        public var excludedColumns: Set<ReportColumn>
        
        /// Timecode display format used for workbook timecode columns.
        public var timecodeFormat: ReportTimecodeFormat
        
        /// When `true`, ``ReportExcelExport`` protects every worksheet (edit lock, not encryption).
        /// PDF export ignores this. See ``ReportOptions/protectSheets``.
        public var protectSheets: Bool
        
        public init(
            projectName: String,
            eventName: String? = nil,
            markers: MarkersReportSection? = nil,
            keywords: KeywordsReportSection? = nil,
            titlesAndGenerators: TitlesReportSection? = nil,
            transitions: TransitionsReportSection? = nil,
            nonStandardEffectsTemplates: NonStandardEffectsTemplatesReportSection? = nil,
            effects: EffectsReportSection? = nil,
            speedChangeEffects: SpeedChangeEffectsReportSection? = nil,
            summary: SummaryReportSection? = nil,
            mediaSummary: MediaSummaryReportSection? = nil,
            roleInventory: RoleInventoryReportSection? = nil,
            workbookCoverSheet: ReportWorkbookCoverSheet? = nil,
            copyrightLabel: String? = nil,
            excludedColumns: Set<ReportColumn> = [],
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            protectSheets: Bool = false
        ) {
            self.projectName = projectName
            self.eventName = eventName
            self.markers = markers
            self.keywords = keywords
            self.titlesAndGenerators = titlesAndGenerators
            self.transitions = transitions
            self.nonStandardEffectsTemplates = nonStandardEffectsTemplates
            self.effects = effects
            self.speedChangeEffects = speedChangeEffects
            self.summary = summary
            self.mediaSummary = mediaSummary
            self.roleInventory = roleInventory
            self.workbookCoverSheet = workbookCoverSheet
            self.copyrightLabel = ReportOptions.normalizedCopyrightLabel(copyrightLabel)
            self.excludedColumns = excludedColumns
            self.timecodeFormat = timecodeFormat
            self.protectSheets = protectSheets
        }
        
        /// Resolved export branding for Excel cover and PDF cover/footer.
        ///
        /// Uses ``workbookCoverSheet`` when set; otherwise ``ReportWorkbookCoverSheet/openFCPXMLKitDefault``.
        public var exportBrandingText: String {
            workbookCoverSheet?.brandingText ?? ReportWorkbookCoverSheet.openFCPXMLKitDefault.brandingText
        }
    }
}

