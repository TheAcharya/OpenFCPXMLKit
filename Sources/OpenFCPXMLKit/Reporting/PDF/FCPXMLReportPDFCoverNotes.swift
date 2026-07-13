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
    
    static let paragraphs = [
        """
        PDF report export is experimental. This document is optimised for A4 landscape \
        review and distribution. Column titles, cell values, and metadata may be truncated \
        where they exceed the available page width or column layout limits. Wide tables are \
        paginated horizontally into column sets and vertically across continuation pages. The Row \
        column is repeated on every continuation and column-set page so row numbers stay traceable \
        across the sheet. All pages that belong to the same workbook sheet share a subtle background \
        tint and header accent colour so spanned sections remain visually grouped. For the complete, \
        untruncated dataset, column customisation, and workbook formatting options, please \
        refer to the accompanying Excel (.xlsx) report exported alongside this PDF.
        """,
    ]
}
