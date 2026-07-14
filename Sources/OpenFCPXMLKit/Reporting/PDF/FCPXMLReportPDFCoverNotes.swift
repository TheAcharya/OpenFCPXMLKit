//
//  FCPXMLReportPDFCoverNotes.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Cover-page guidance shown on PDF report exports.
//

import Foundation

enum FCPXMLReportPDFCoverNotes {
    static let title = "About This PDF Export"
    
    /// SF Symbol drawn beside the info-box title.
    static let symbolName = "info.circle"
    
    static let paragraphs = [
        """
        PDF export is experimental and optimised for A4 landscape. Tables paginate across \
        pages and cell text may truncate. The Row column is included by default for \
        traceability; exclude it the same way as in Excel. Matching sheet pages share a tint. \
        For the complete dataset and column options, use the accompanying Excel (.xlsx) report.
        """,
    ]
}
