//
//  FCPXMLReportWorkbookColumnAutoFit.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Estimates and applies Excel column widths from cell text content.
//

import Foundation
import XLKit

enum FCPXMLReportWorkbookColumnAutoFit {
    private static let minimumWidth = 8.0
    private static let maximumWidth = 60.0
    private static let padding = 2.0
    
    static func apply(to sheet: Sheet) {
        var widthsByColumn: [Int: Double] = [:]
        
        for (address, value) in sheet.cells {
            guard let coordinate = CellCoordinate(excelAddress: address) else { continue }
            let width = estimatedWidth(for: value.stringValue)
            widthsByColumn[coordinate.column] = max(widthsByColumn[coordinate.column] ?? minimumWidth, width)
        }
        
        for (column, width) in widthsByColumn {
            sheet.setColumnWidth(column, width: width)
        }
    }
    
    private static func estimatedWidth(for text: String) -> Double {
        guard !text.isEmpty else { return minimumWidth }
        
        let longestLine = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(\.count)
            .max() ?? text.count
        
        let estimated = Double(longestLine) + padding
        return min(max(estimated, minimumWidth), maximumWidth)
    }
}
