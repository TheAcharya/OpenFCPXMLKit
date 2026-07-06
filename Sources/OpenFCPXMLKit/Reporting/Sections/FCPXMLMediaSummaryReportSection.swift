//
//  FCPXMLMediaSummaryReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Media Summary report section model (missing media paths).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Media Summary report section (missing media file paths).
    public struct MediaSummaryReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Media Summary"
        public static let missingMediaSectionTitle = "Missing Media"
        
        public var missingMediaPaths: [String]
        
        public init(missingMediaPaths: [String] = []) {
            self.missingMediaPaths = missingMediaPaths
        }
    }
}
