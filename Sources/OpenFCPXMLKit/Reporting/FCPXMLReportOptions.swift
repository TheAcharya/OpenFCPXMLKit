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
        
        /// Include the Non-Standard Effects & Templates report sheet.
        public var includeNonStandardEffectsTemplates: Bool
        
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
        
        /// When building markers, include `chapter-marker` elements on the Markers sheet.
        ///
        /// Default is `true` (chapter markers appear with Type = Chapter; filter in Excel if
        /// undesired). Set to `false` to omit chapter markers from the Markers sheet.
        public var includeChapterMarkersInMarkersReport: Bool
        
        /// When building markers, include markers whose `start` is outside the host clip’s
        /// media range (`[start, start + duration)`). Final Cut Pro hides those markers from
        /// the timeline and Tags list.
        ///
        /// Default is `false` (FCP-visible markers only). When `true`, those markers are included
        /// and the Markers sheet gains a **Hidden** column (✓ outside bounds / ✗ inside).
        /// The Hidden column is not part of ``ReportColumn`` / `--exclude-column`.
        public var includeMarkersOutsideClipBoundaries: Bool
        
        /// Optional timeline name filter. When `nil`, the first project is preferred; if the
        /// document has no `<project>`, the first event-level compound clip (`ref-clip` →
        /// `media`/`sequence`) is used. Matching uses the project name or compound clip name.
        public var projectName: String?
        
        /// Base URL for resolving relative media paths when building the Media Summary missing-media list.
        public var mediaBaseURL: URL?
        
        /// Role priority tables used when a clip carries more than one inherited role.
        /// Defaults to ``RoleDisplayPreference/builtIn`` (FCP built-in role names only).
        public var roleDisplayPreference: RoleDisplayPreference
        
        /// Optional first workbook sheet prepended by Excel export.
        /// Set to `nil` to omit this sheet.
        public var workbookCoverSheet: ReportWorkbookCoverSheet?
        
        /// Optional copyright / attribution label for Excel cover (`A2`) and PDF cover/footer centre.
        ///
        /// Whitespace-only values are treated as omitted. Mapped onto ``Report/copyrightLabel``.
        public var copyrightLabel: String?
        
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
        
        /// How timeline time values are formatted in workbook cells.
        ///
        /// Default is ``ReportTimecodeFormat/smpteFrames`` (`HH:MM:SS:FF` or `HH:MM:SS;FF`).
        public var timecodeFormat: ReportTimecodeFormat

        /// When `true`, Summary role durations merge overlapping timeline spans
        /// (via ``TimelineOccupancyIndex``) instead of summing component durations.
        /// Default `false` preserves historical optimistic totals.
        public var summaryOverlapAwareDurations: Bool

        /// When `true`, Role Inventory may emit distinct rows per media `src` index when
        /// projection windows distinguish sources. Default `false` keeps one host row.
        public var emitPerSourceInventoryRows: Bool

        /// Fail-soft (default) vs fail-loud when timeline projection cannot complete.
        /// Missing files on disk still appear on Media Summary under either mode.
        public var mediaResolutionPolicy: ReportMediaResolutionPolicy

        /// When `true`, Media Summary export prefers separate Missing Original / Missing Proxy columns.
        /// Default `false` keeps a single Missing Media column (combined paths).
        public var mediaSummaryDistinguishProxyAndOriginal: Bool
        
        /// When `true`, Excel export applies worksheet protection to every sheet in the workbook
        /// (cover and content). This is an edit lock to discourage casual changes — **not**
        /// file-open encryption. Anyone can turn protection off in Excel unless a password is
        /// set later. PDF export ignores this flag. Default is `false`.
        public var protectSheets: Bool
        
        public init(
            includeMarkers: Bool = true,
            includeKeywords: Bool = false,
            includeTitlesAndGenerators: Bool = false,
            includeTransitions: Bool = false,
            includeNonStandardEffectsTemplates: Bool = false,
            includeEffects: Bool = false,
            includeSpeedChangeEffects: Bool = false,
            includeSummary: Bool = false,
            includeMediaSummary: Bool = false,
            includeRoleInventory: Bool = false,
            includeChapterMarkersInMarkersReport: Bool = true,
            includeMarkersOutsideClipBoundaries: Bool = false,
            projectName: String? = nil,
            mediaBaseURL: URL? = nil,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            workbookCoverSheet: ReportWorkbookCoverSheet? = .openFCPXMLKitDefault,
            copyrightLabel: String? = nil,
            excludedRoles: [String] = [],
            excludeDisabledClips: Bool = false,
            excludedColumns: [String] = [],
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            summaryOverlapAwareDurations: Bool = false,
            emitPerSourceInventoryRows: Bool = false,
            mediaResolutionPolicy: ReportMediaResolutionPolicy = .failSoft,
            mediaSummaryDistinguishProxyAndOriginal: Bool = false,
            protectSheets: Bool = false
        ) {
            self.includeMarkers = includeMarkers
            self.includeKeywords = includeKeywords
            self.includeTitlesAndGenerators = includeTitlesAndGenerators
            self.includeTransitions = includeTransitions
            self.includeNonStandardEffectsTemplates = includeNonStandardEffectsTemplates
            self.includeEffects = includeEffects
            self.includeSpeedChangeEffects = includeSpeedChangeEffects
            self.includeSummary = includeSummary
            self.includeMediaSummary = includeMediaSummary
            self.includeRoleInventory = includeRoleInventory
            self.includeChapterMarkersInMarkersReport = includeChapterMarkersInMarkersReport
            self.includeMarkersOutsideClipBoundaries = includeMarkersOutsideClipBoundaries
            self.projectName = projectName
            self.mediaBaseURL = mediaBaseURL
            self.roleDisplayPreference = roleDisplayPreference
            self.workbookCoverSheet = workbookCoverSheet
            self.copyrightLabel = Self.normalizedCopyrightLabel(copyrightLabel)
            self.excludedRoles = excludedRoles
            self.excludeDisabledClips = excludeDisabledClips
            self.excludedColumns = excludedColumns
            self.timecodeFormat = timecodeFormat
            self.summaryOverlapAwareDurations = summaryOverlapAwareDurations
            self.emitPerSourceInventoryRows = emitPerSourceInventoryRows
            self.mediaResolutionPolicy = mediaResolutionPolicy
            self.mediaSummaryDistinguishProxyAndOriginal = mediaSummaryDistinguishProxyAndOriginal
            self.protectSheets = protectSheets
        }
        
        /// Trims and drops empty copyright labels so exporters can treat “unset” uniformly.
        public static func normalizedCopyrightLabel(_ value: String?) -> String? {
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
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
                includeNonStandardEffectsTemplates: true,
                includeEffects: true,
                includeSpeedChangeEffects: true,
                includeSummary: true,
                includeMediaSummary: true,
                includeRoleInventory: true,
                includeChapterMarkersInMarkersReport: true
            )
        }
        
        /// Non-Standard Effects & Templates sheet only.
        public static var nonStandardEffectsTemplatesOnly: ReportOptions {
            ReportOptions(
                includeMarkers: false,
                includeKeywords: false,
                includeTitlesAndGenerators: false,
                includeTransitions: false,
                includeNonStandardEffectsTemplates: true,
                includeEffects: false,
                includeSummary: false,
                includeRoleInventory: false
            )
        }
    }
}

