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
    public enum ReportBuildPhase: String, Sendable {
        case markers = "Markers"
        case keywords = "Keywords"
        case titlesAndGenerators = "Titles & Generators"
        case transitions = "Transitions"
        case effects = "Video & Audio Effects"
        case speedChangeEffects = "Speed Change Effects"
        case summary = "Summary"
        case roleInventory = "Role inventory"
    }
    
    /// Called when a report section begins building.
    public typealias ReportBuildPhaseHandler = @Sendable (ReportBuildPhase) -> Void
}
