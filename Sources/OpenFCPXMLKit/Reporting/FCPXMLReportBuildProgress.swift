//
//  FCPXMLReportBuildProgress.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Progress callbacks while assembling report sections.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Identifies a report section while it is being built.
    ///
    /// Case order matches the product UI / workbook section order:
    /// Selected Roles Inventory, Markers, Keywords, Titles & Generators, Transitions,
    /// Video & Audio Effects, Speed Change Effects, Summary, Media Summary.
    public enum ReportBuildPhase: String, Sendable, CaseIterable {
        case roleInventory = "Selected Roles Inventory"
        case markers = "Markers"
        case keywords = "Keywords"
        case titlesAndGenerators = "Titles & Generators"
        case transitions = "Transitions"
        case effects = "Video & Audio Effects"
        case speedChangeEffects = "Speed Change Effects"
        case summary = "Summary"
        case mediaSummary = "Media Summary"
        
        /// Enabled content phases for ``options``, in product / workbook order.
        ///
        /// GUI apps and the CLI should use this list for progress UI so labels and
        /// completion order match checkboxes and Excel sheet order.
        public static func enabledPhases(
            for options: ReportOptions
        ) -> [ReportBuildPhase] {
            allCases.filter { $0.isEnabled(in: options) }
        }
        
        /// Whether this phase is requested by ``options``.
        public func isEnabled(in options: ReportOptions) -> Bool {
            switch self {
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
            }
        }
    }
    
    /// Called when a report section begins building.
    public typealias ReportBuildPhaseHandler = @Sendable (ReportBuildPhase) -> Void
}
