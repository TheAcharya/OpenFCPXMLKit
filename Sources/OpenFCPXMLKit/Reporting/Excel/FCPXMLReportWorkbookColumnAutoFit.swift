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
    /// Fixed width for the 1-based ``Row`` index column (short header + digits only).
    private static let rowColumnWidth = 8.0
    /// Summary project-title column (B): Excel character units under-measure bold banner text.
    private static let summaryTitleColumnMinimumWidth = 56.0
    private static let summaryTitleColumnMaximumWidth = 120.0
    private static let summaryTitleColumnPadding = 20.0
    
    /// Width for Summary sheet column B, sized for the project title in ``B1``.
    static func summaryProjectTitleColumnWidth(for title: String) -> Double {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return summaryTitleColumnMinimumWidth }
        
        let estimated = Double(trimmed.count) + summaryTitleColumnPadding
        return min(
            max(estimated, summaryTitleColumnMinimumWidth),
            summaryTitleColumnMaximumWidth
        )
    }
    
    static func apply(to sheet: Sheet, headers: [String]? = nil) {
        apply(to: sheet, headers: headers, rows: nil)
    }

    /// Applies column widths from header + row string lengths (avoids scanning ``sheet.cells``).
    static func apply(
        to sheet: Sheet,
        headers: [String]?,
        rows: [[String]]?
    ) {
        var widthsByColumn: [Int: Double] = [:]

        if let rows {
            for values in rows {
                for (index, value) in values.enumerated() {
                    let column = index + 1
                    let width = estimatedWidth(for: value)
                    widthsByColumn[column] = max(widthsByColumn[column] ?? minimumWidth, width)
                }
            }
        } else {
            for (address, value) in sheet.cells {
                guard let coordinate = CellCoordinate(excelAddress: address) else { continue }
                let width = estimatedWidth(for: value.stringValue)
                widthsByColumn[coordinate.column] = max(
                    widthsByColumn[coordinate.column] ?? minimumWidth,
                    width
                )
            }
        }

        if let headers {
            for (index, header) in headers.enumerated() {
                let column = index + 1
                widthsByColumn[column] = max(
                    widthsByColumn[column] ?? minimumWidth,
                    estimatedWidth(for: header)
                )
                if header == FinalCutPro.FCPXML.RoleInventoryColumnLayout.rowColumnHeader {
                    // Keep the Row index column narrow regardless of other cells in the column
                    // (e.g. legacy Summary titles that once shared column A).
                    widthsByColumn[column] = rowColumnWidth
                    continue
                }
                if let floor = minimumWidthForHeader(header) {
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
