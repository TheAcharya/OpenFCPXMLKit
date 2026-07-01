//
//  FCPXMLReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared protocol for report sections.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A single report section that maps to one workbook sheet in reference exports.
    public protocol ReportSection: Sendable, Equatable {
        /// Default sheet name for this section in reference workbooks.
        static var defaultSheetName: String { get }
    }
}
