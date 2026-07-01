//
//  FCPXMLMarkersReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Markers report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Markers report section containing timeline marker rows.
    public struct MarkersReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Markers"
        
        public var rows: [MarkerReportRow]
        
        public init(rows: [MarkerReportRow]) {
            self.rows = rows
        }
    }
}
