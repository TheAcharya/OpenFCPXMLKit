//
//  ReportCLIOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	REPORT option group for Excel workbook exports.
//

import ArgumentParser
import Foundation
import OpenFCPXMLKit

struct ReportCLIOptions: ParsableArguments {
    @Flag(
        name: .long,
        help: "Build an Excel report workbook from FCPXML (role inventory only; use --report-full for all sheets)."
    )
    var report: Bool = false
    
    @Flag(
        name: .customLong("report-full"),
        help: "Include every optional report sheet (with --report). Default --report exports role inventory only."
    )
    var reportFull: Bool = false
    
    @Flag(
        name: .customLong("report-markers"),
        help: "Include the Markers sheet (with --report)."
    )
    var reportMarkers: Bool = false
    
    @Flag(
        name: .customLong("report-keywords"),
        help: "Include the Keywords sheet (with --report)."
    )
    var reportKeywords: Bool = false
    
    @Flag(
        name: .customLong("report-titles-generators"),
        help: "Include the Titles & Generators sheet (with --report)."
    )
    var reportTitlesGenerators: Bool = false
    
    @Flag(
        name: .customLong("report-transitions"),
        help: "Include the Transitions sheet (with --report)."
    )
    var reportTransitions: Bool = false
    
    @Flag(
        name: .customLong("report-effects"),
        help: "Include the Video & Audio Effects sheet (with --report)."
    )
    var reportEffects: Bool = false
    
    @Flag(
        name: .customLong("report-speed-change-effects"),
        help: "Include the Speed Change Effects sheet (with --report)."
    )
    var reportSpeedChangeEffects: Bool = false
    
    @Flag(
        name: .customLong("report-summary"),
        help: "Include the Summary sheet (project metrics and role-duration totals; with --report)."
    )
    var reportSummary: Bool = false
    
    @Flag(
        name: .customLong("report-media-summary"),
        help: "Include the Media Summary sheet (missing media file paths; with --report)."
    )
    var reportMediaSummary: Bool = false
    
    @Option(
        name: .customLong("report-project"),
        help: "Project name filter when the FCPXML contains multiple projects."
    )
    var reportProject: String?
    
    @Option(
        name: .customLong("exclude-role"),
        help: "Exclude a role or subrole from role inventory (repeatable). Excluding a main role also excludes its subroles."
    )
    var excludeRole: [String] = []
    
    @Flag(
        name: .customLong("exclude-disabled-clips"),
        help: "Omit disabled clips (enabled=\"0\") from all report sections (with --report)."
    )
    var excludeDisabledClips: Bool = false
    
    @Option(
        name: .customLong("exclude-column"),
        help: """
        Exclude a workbook column from every applicable report sheet (repeatable; with --report). \
        Case-insensitive names include Row Numbers, Role Subrole, Clip Name, Frame Rate, Reel, \
        Metadata (role inventory dynamic metadata keys), and other shared column headers. \
        Columns are removed wherever the sheet uses a matching header.
        """
    )
    var excludeColumn: [String] = []
    
    var hasSectionSelection: Bool {
        reportMarkers
            || reportKeywords
            || reportTitlesGenerators
            || reportTransitions
            || reportEffects
            || reportSpeedChangeEffects
            || reportSummary
            || reportMediaSummary
    }
    
    func makeLibraryReportOptions(mediaBaseURL: URL?) -> FinalCutPro.FCPXML.ReportOptions {
        var options: FinalCutPro.FCPXML.ReportOptions
        
        if reportFull {
            options = .full
        } else if hasSectionSelection {
            options = FinalCutPro.FCPXML.ReportOptions(
                includeMarkers: reportMarkers,
                includeKeywords: reportKeywords,
                includeTitlesAndGenerators: reportTitlesGenerators,
                includeTransitions: reportTransitions,
                includeEffects: reportEffects,
                includeSpeedChangeEffects: reportSpeedChangeEffects,
                includeSummary: reportSummary,
                includeMediaSummary: reportMediaSummary,
                includeRoleInventory: true
            )
        } else {
            options = .roleInventoryOnly
        }
        
        options.projectName = reportProject
        options.mediaBaseURL = mediaBaseURL
        options.excludedRoles = excludeRole
        options.excludeDisabledClips = excludeDisabledClips
        options.excludedColumns = excludeColumn
        return options
    }
}
