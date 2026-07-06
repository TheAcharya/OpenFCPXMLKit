//
//  FCPXMLReportOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Options controlling which report sections are produced from FCPXML.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Controls which optional report sections are included when building a ``Report``.
    ///
    /// Role inventory is produced when ``includeRoleInventory`` is `true`.
    /// Optional sections map to individual report toggles.
    public struct ReportOptions: Sendable, Equatable {
        /// Include the Markers report sheet.
        public var includeMarkers: Bool
        
        /// Include the Keywords report sheet.
        public var includeKeywords: Bool
        
        /// Include the Titles & Generators report sheet.
        public var includeTitlesAndGenerators: Bool
        
        /// Include the Transitions report sheet.
        public var includeTransitions: Bool
        
        /// Include the Video & Audio Effects report sheet.
        public var includeEffects: Bool
        
        /// Include the Speed Change Effects report sheet.
        public var includeSpeedChangeEffects: Bool
        
        /// Include the Summary sheet (project metrics and role-duration totals).
        public var includeSummary: Bool
        
        /// Include the Media Summary sheet (missing media file paths).
        public var includeMediaSummary: Bool
        
        /// Include per-role clip inventory sheets (Selected Roles and role breakdown).
        public var includeRoleInventory: Bool
        
        /// When building markers, include `chapter-marker` elements.
        /// Chapter markers are omitted from the Markers sheet by default.
        public var includeChapterMarkersInMarkersReport: Bool
        
        /// Optional project name filter. When `nil`, the first project in the document is used.
        public var projectName: String?
        
        /// Base URL for resolving relative media paths when building the Media Summary missing-media list.
        public var mediaBaseURL: URL?
        
        /// Role priority tables used when a clip carries more than one inherited role.
        /// Defaults to ``RoleDisplayPreference/builtIn`` (FCP built-in role names only).
        public var roleDisplayPreference: RoleDisplayPreference
        
        /// Optional first workbook sheet prepended by Excel export.
        /// Set to `nil` to omit this sheet.
        public var workbookCoverSheet: ReportWorkbookCoverSheet?
        
        /// Role or subrole names to omit from role inventory sheets.
        ///
        /// Matching is case-insensitive. Excluding a main role (for example `Dialogue`) also
        /// excludes every `Dialogue ▸ …` subrole sheet.
        public var excludedRoles: [String]
        
        /// When `true`, clips with `enabled="0"` are omitted from every report section that
        /// walks the timeline (role inventory, markers, keywords, titles, transitions, effects,
        /// speed-change effects, and summary role durations).
        ///
        /// Default is `false` (disabled clips are included, matching Final Cut Pro workbook exports).
        public var excludeDisabledClips: Bool
        
        /// Column names to omit from every applicable workbook sheet.
        ///
        /// Matching is case-insensitive. Use ``ReportColumn`` header names or common aliases
        /// (for example `Row Numbers`, `Role Subrole`, `Frame Rate`, `Metadata` for all dynamic
        /// metadata key columns on role inventory sheets). Unknown labels are ignored.
        public var excludedColumns: [String]
        
        public init(
            includeMarkers: Bool = true,
            includeKeywords: Bool = false,
            includeTitlesAndGenerators: Bool = false,
            includeTransitions: Bool = false,
            includeEffects: Bool = false,
            includeSpeedChangeEffects: Bool = false,
            includeSummary: Bool = false,
            includeMediaSummary: Bool = false,
            includeRoleInventory: Bool = false,
            includeChapterMarkersInMarkersReport: Bool = false,
            projectName: String? = nil,
            mediaBaseURL: URL? = nil,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            workbookCoverSheet: ReportWorkbookCoverSheet? = .openFCPXMLKitDefault,
            excludedRoles: [String] = [],
            excludeDisabledClips: Bool = false,
            excludedColumns: [String] = []
        ) {
            self.includeMarkers = includeMarkers
            self.includeKeywords = includeKeywords
            self.includeTitlesAndGenerators = includeTitlesAndGenerators
            self.includeTransitions = includeTransitions
            self.includeEffects = includeEffects
            self.includeSpeedChangeEffects = includeSpeedChangeEffects
            self.includeSummary = includeSummary
            self.includeMediaSummary = includeMediaSummary
            self.includeRoleInventory = includeRoleInventory
            self.includeChapterMarkersInMarkersReport = includeChapterMarkersInMarkersReport
            self.projectName = projectName
            self.mediaBaseURL = mediaBaseURL
            self.roleDisplayPreference = roleDisplayPreference
            self.workbookCoverSheet = workbookCoverSheet
            self.excludedRoles = excludedRoles
            self.excludeDisabledClips = excludeDisabledClips
            self.excludedColumns = excludedColumns
        }
        
        /// Role inventory only (Selected Roles and per-role sheets; no optional report sheets).
        public static var roleInventoryOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSummary: false,
                includeRoleInventory: true
            )
        }
        
        /// Markers report sheet only.
        public static var markersOnly: ReportOptions {
            ReportOptions(
                includeMarkers: true,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Transitions report sheet only.
        public static var transitionsOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: true,
                includeEffects: false,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Keywords report sheet only.
        public static var keywordsOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: true,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Titles & Generators report sheet only.
        public static var titlesAndGeneratorsOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: true,
                includeTransitions: false,
                includeEffects: false,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Video & Audio Effects report sheet only.
        public static var effectsOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: true,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Speed Change Effects report sheet only.
        public static var speedChangeEffectsOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSpeedChangeEffects: true,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Summary report sheet only (project metrics and role-duration totals).
        public static var summaryOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSummary: true,
                includeMediaSummary: false,
                includeRoleInventory: false
            )
        }
        
        /// Media Summary report sheet only (missing media file paths).
        public static var mediaSummaryOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeEffects: false,
                includeSummary: false,
                includeMediaSummary: true,
                includeRoleInventory: false
            )
        }
        
        /// Role inventory plus every optional report sheet.
        public static var full: ReportOptions {
            ReportOptions(
                includeMarkers: true,
                includeKeywords: true,
                includeTitlesAndGenerators: true,
                includeTransitions: true,
                includeEffects: true,
                includeSpeedChangeEffects: true,
                includeSummary: true,
                includeMediaSummary: true,
                includeRoleInventory: true,
                includeChapterMarkersInMarkersReport: true
            )
        }
    }
}
