//
//  FCPXMLReportBuildProgress.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Progress callbacks while assembling and exporting reports.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Identifies a report build / export step for progress UI.
    ///
    /// Content cases (inventory … Media Summary) match workbook section order.
    /// Pipeline cases (``projecting``, ``savingWorkbook``, ``savingPDF``) bookend
    /// content so CLI / GUI progress reflects the real wall-clock phases.
    public enum ReportBuildPhase: String, Sendable, CaseIterable {
        case projecting = "Projecting Timeline"
        case roleInventory = "Selected Roles Inventory"
        case markers = "Markers"
        case keywords = "Keywords"
        case titlesAndGenerators = "Titles & Generators"
        case transitions = "Transitions"
        case effects = "Video & Audio Effects"
        case speedChangeEffects = "Speed Change Effects"
        case summary = "Summary"
        case mediaSummary = "Media Summary"
        case savingWorkbook = "Saving Workbook"
        case savingPDF = "Saving PDF"

        /// Content sheet phases only (checkbox / workbook section order).
        public static var contentCases: [ReportBuildPhase] {
            [
                .roleInventory,
                .markers,
                .keywords,
                .titlesAndGenerators,
                .transitions,
                .effects,
                .speedChangeEffects,
                .summary,
                .mediaSummary
            ]
        }

        /// Enabled content phases for ``options``, in product / workbook order.
        ///
        /// GUI apps and the CLI should use this list (or ``exportPipelinePhases``)
        /// for progress UI so labels and completion order match checkboxes and
        /// Excel sheet order.
        public static func enabledPhases(
            for options: ReportOptions
        ) -> [ReportBuildPhase] {
            contentCases.filter { $0.isEnabled(in: options) }
        }

        /// Full CLI / GUI export pipeline: optional projection, content phases, saves.
        public static func exportPipelinePhases(
            for options: ReportOptions,
            includeWorkbookSave: Bool = true,
            includePDFSave: Bool = false
        ) -> [ReportBuildPhase] {
            var phases: [ReportBuildPhase] = []
            if options.consumesTimelineProjection {
                phases.append(.projecting)
            }
            phases.append(contentsOf: enabledPhases(for: options))
            if includeWorkbookSave {
                phases.append(.savingWorkbook)
            }
            if includePDFSave {
                phases.append(.savingPDF)
            }
            return phases
        }

        /// Whether this content phase is requested by ``options``.
        public func isEnabled(in options: ReportOptions) -> Bool {
            switch self {
            case .projecting:
                return options.consumesTimelineProjection
            case .roleInventory:
                return options.includeRoleInventory
            case .markers:
                return options.includeMarkers
            case .keywords:
                return options.includeKeywords
            case .titlesAndGenerators:
                return options.includeTitlesAndGenerators
            case .transitions:
                return options.includeTransitions
            case .effects:
                return options.includeEffects
            case .speedChangeEffects:
                return options.includeSpeedChangeEffects
            case .summary:
                return options.includeSummary
            case .mediaSummary:
                return options.includeMediaSummary
            case .savingWorkbook, .savingPDF:
                return false
            }
        }
    }

    /// Called when a report section or export step begins.
    public typealias ReportBuildPhaseHandler = @Sendable (ReportBuildPhase) -> Void
}
