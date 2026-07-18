//
//  ReportCLIOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	REPORT option group for Excel and PDF report exports.
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
    
    @Flag(
        name: .customLong("create-pdf"),
        help: "Also write a PDF report alongside the Excel workbook (with --report). Includes the same workbook sections, column exclusions, and timecode formatting when present."
    )
    var createPDF: Bool = false
    
    @Option(
        name: .customLong("report-project"),
        help: "Timeline name filter: matches a <project> name or a standalone compound-clip / ref-clip name when the document has more than one reportable timeline."
    )
    var reportProject: String?
    
    @Option(
        name: .customLong("label-copyright"),
        help: """
        Optional copyright / attribution line for Excel and PDF reports (with --report). \
        Excel: cover sheet cell A2 below the Created-by brand row. \
        PDF: same subtitle style below Created-by on the cover, and centred in the running footer \
        (same footer font/size as the Created-by branding).
        """
    )
    var labelCopyright: String?
    
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
    
    @Flag(
        name: .customLong("include-markers-outside-clip-boundaries"),
        help: """
        Include markers whose start is outside the host clip’s media range (hidden in FCP \
        timeline/Tags) and add a Hidden column (✓/✗) on the Markers sheet (with --report / \
        --report-markers). Default omits those markers and does not show Hidden.
        """
    )
    var includeMarkersOutsideClipBoundaries: Bool = false
    
    @Flag(
        name: .customLong("protect-sheets"),
        help: """
        Protect every sheet in the Excel workbook against casual edits (with --report). \
        Applies to the cover sheet and all content sheets. This is an edit lock, not \
        file-open encryption — Excel can still open the file, and anyone can turn protection \
        off. PDF export is unaffected (use Preview’s Encrypt to password-protect a PDF).
        """
    )
    var protectSheets: Bool = false
    
    @Option(
        name: .customLong("exclude-column"),
        help: """
        Exclude a report column from every applicable Excel/PDF sheet (repeatable; with --report). \
        Case-insensitive names include Row / Row Numbers (all tabular sheets + PDF Row injection), \
        Role Subrole, Clip Name, Frame Rate, Reel, Metadata (role inventory dynamic metadata keys), \
        and other shared column headers. Columns are removed wherever the sheet uses a matching header.
        """
    )
    var excludeColumn: [String] = []
    
    @Option(
        name: .customLong("timecode-format"),
        help: """
        Timeline time display format for Excel and PDF report cells (with --report). \
        Values: \(FinalCutPro.FCPXML.ReportTimecodeFormat.cliHelpValues). \
        Default when omitted: HH:MM:SS:FF (SMPTE with frames; semicolon before frames for drop-frame).
        """
    )
    var timecodeFormat: String?

    @Option(
        name: .customLong("media-resolution"),
        help: """
        How report building treats timeline projection failures (with --report). \
        Values: \(FinalCutPro.FCPXML.ReportMediaResolutionPolicy.cliHelpValues). \
        Default when omitted: fail-soft (continue with empty projection windows). \
        fail-loud aborts with an error. Missing files on disk still appear on Media Summary.
        """
    )
    var mediaResolution: String?

    @Flag(
        name: .customLong("media-summary-distinguish-proxy"),
        help: """
        On Media Summary, emit separate Missing Original and Missing Proxy columns \
        instead of a single Missing Media column (with --report / --report-media-summary).
        """
    )
    var mediaSummaryDistinguishProxy: Bool = false
    
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

    /// True when any REPORT option other than `--report` itself was supplied.
    var hasAnyReportModifier: Bool {
        reportFull
            || hasSectionSelection
            || createPDF
            || reportProject != nil
            || labelCopyright != nil
            || !excludeRole.isEmpty
            || excludeDisabledClips
            || includeMarkersOutsideClipBoundaries
            || protectSheets
            || !excludeColumn.isEmpty
            || timecodeFormat != nil
            || mediaResolution != nil
            || mediaSummaryDistinguishProxy
    }
    
    func makeLibraryReportOptions(mediaBaseURL: URL?) throws -> FinalCutPro.FCPXML.ReportOptions {
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
        options.copyrightLabel = labelCopyright
        options.excludedRoles = excludeRole
        options.excludeDisabledClips = excludeDisabledClips
        options.includeMarkersOutsideClipBoundaries = includeMarkersOutsideClipBoundaries
        options.protectSheets = protectSheets
        options.excludedColumns = excludeColumn
        options.timecodeFormat = try resolvedTimecodeFormat()
        options.mediaResolutionPolicy = try resolvedMediaResolutionPolicy()
        options.mediaSummaryDistinguishProxyAndOriginal = mediaSummaryDistinguishProxy
        return options
    }

    func resolvedMediaResolutionPolicy() throws -> FinalCutPro.FCPXML.ReportMediaResolutionPolicy {
        guard let mediaResolution else { return .failSoft }
        guard let policy = FinalCutPro.FCPXML.ReportMediaResolutionPolicy(cliValue: mediaResolution)
        else {
            throw ValidationError(
                "Invalid --media-resolution: '\(mediaResolution)'. Use one of: \(FinalCutPro.FCPXML.ReportMediaResolutionPolicy.cliHelpValues)."
            )
        }
        return policy
    }
    
    func resolvedTimecodeFormat() throws -> FinalCutPro.FCPXML.ReportTimecodeFormat {
        guard let timecodeFormat else { return .smpteFrames }
        guard let format = FinalCutPro.FCPXML.ReportTimecodeFormat(cliValue: timecodeFormat) else {
            throw ValidationError(
                "Invalid --timecode-format: '\(timecodeFormat)'. Use one of: \(FinalCutPro.FCPXML.ReportTimecodeFormat.cliHelpValues)."
            )
        }
        return format
    }
}
