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
    private static let maximumWidth = 80.0
    private static let padding = 2.0
    
    static func apply(to sheet: Sheet, headers: [String]? = nil) {
        var widthsByColumn: [Int: Double] = [:]
        
        for (address, value) in sheet.cells {
            guard let coordinate = CellCoordinate(excelAddress: address) else { continue }
            let width = estimatedWidth(for: value.stringValue)
            widthsByColumn[coordinate.column] = max(widthsByColumn[coordinate.column] ?? minimumWidth, width)
        }
        
        if let headers {
            for (index, header) in headers.enumerated() {
                if let floor = minimumWidthForHeader(header) {
                    let column = index + 1
                    widthsByColumn[column] = max(widthsByColumn[column] ?? minimumWidth, floor)
                }
            }
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
    
    private static func minimumWidthForHeader(_ header: String) -> Double? {
        switch header {
        case "Source File Path":
            return 48
        case "Source File Name":
            return 32
        case "Clip Name", "Role ▸ Subrole":
            return 20
        case let key where key.hasPrefix("com.apple."):
            return 36
        default:
            return nil
        }
    }
}
