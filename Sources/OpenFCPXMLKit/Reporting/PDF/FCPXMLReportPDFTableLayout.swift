//
//  FCPXMLReportPDFTableLayout.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Column sizing, chunking, and text truncation for PDF tables.
//

import CoreGraphics
import CoreText
import Foundation

enum FCPXMLReportPDFTableLayout {
    struct ColumnChunk: Sendable {
        let columnIndices: [Int]
        let widths: [CGFloat]
        
        var totalWidth: CGFloat {
            widths.reduce(0, +)
        }
        
        func headers(from allHeaders: [String]) -> [String] {
            columnIndices.map { allHeaders[$0] }
        }
        
        func rowSlice(from row: [String]) -> [String] {
            columnIndices.map { index in
                row.indices.contains(index) ? row[index] : ""
            }
        }
    }
    
    /// Header label for the traceability row index column (matches workbook ``ReportColumn/row``).
    static let rowColumnHeader = FinalCutPro.FCPXML.RoleInventoryColumnLayout.rowColumnHeader
    
    /// Prepares headers/rows for paginated PDF tables, injecting and pinning ``rowColumnHeader`` when needed.
    static func preparePaginatedTable(
        headers: [String],
        rows: [[String]],
        contentWidth: CGFloat
    ) -> (headers: [String], rows: [[String]], pinnedColumnIndices: [Int]) {
        guard !headers.isEmpty else { return (headers, rows, []) }
        
        let rowsPerPage = rowsPerPage()
        let unpinnedChunks = columnChunks(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth,
            pinnedColumnIndices: []
        )
        let spansMultiplePages = unpinnedChunks.count > 1 || rows.count > rowsPerPage
        
        var preparedHeaders = headers
        var preparedRows = rows
        
        if spansMultiplePages, rowColumnIndex(in: preparedHeaders) == nil {
            preparedHeaders = [rowColumnHeader] + preparedHeaders
            preparedRows = rows.enumerated().map { index, row in
                [String(index + 1)] + row
            }
        }
        
        let pinnedColumnIndices = rowColumnIndex(in: preparedHeaders).map { [$0] } ?? []
        return (preparedHeaders, preparedRows, pinnedColumnIndices)
    }
    
    static func columnChunks(
        headers: [String],
        rows: [[String]],
        contentWidth: CGFloat,
        pinnedColumnIndices: [Int] = []
    ) -> [ColumnChunk] {
        guard !headers.isEmpty else { return [] }
        
        let naturalWidths = naturalColumnWidths(headers: headers, rows: rows)
        let pinnedSet = Set(pinnedColumnIndices)
        let pinnedIndices = pinnedColumnIndices.filter { headers.indices.contains($0) }
        let pinnedWidths = pinnedIndices.map { clampedColumnWidth(naturalWidths[$0]) }
        let pinnedWidth = pinnedWidths.reduce(CGFloat.zero, +)
        let chunkableWidth = max(contentWidth - pinnedWidth, FCPXMLReportPDFStyle.minColumnWidth)
        
        var chunks: [ColumnChunk] = []
        var indices: [Int] = []
        var widths: [CGFloat] = []
        var usedWidth: CGFloat = 0
        
        for index in headers.indices where !pinnedSet.contains(index) {
            let columnWidth = clampedColumnWidth(naturalWidths[index])
            
            if !indices.isEmpty, usedWidth + columnWidth > chunkableWidth {
                chunks.append(
                    makeChunk(
                        pinnedIndices: pinnedIndices,
                        pinnedWidths: pinnedWidths,
                        chunkIndices: indices,
                        chunkWidths: widths,
                        targetWidth: contentWidth
                    )
                )
                indices = []
                widths = []
                usedWidth = 0
            }
            
            indices.append(index)
            widths.append(columnWidth)
            usedWidth += columnWidth
        }
        
        if !indices.isEmpty || chunks.isEmpty {
            chunks.append(
                makeChunk(
                    pinnedIndices: pinnedIndices,
                    pinnedWidths: pinnedWidths,
                    chunkIndices: indices,
                    chunkWidths: widths,
                    targetWidth: contentWidth
                )
            )
        }
        
        return chunks
    }
    
    /// Builds a chunk and expands column widths to fill ``targetWidth`` when content-based
    /// sizes leave unused horizontal space (e.g. after many ``excludedColumns``).
    ///
    /// Packing still uses ``clampedColumnWidth`` / ``maxColumnWidth`` so wide tables chunk
    /// horizontally. Expansion happens after a chunk's column set is fixed, so remaining
    /// columns grow into leftover page width. Pinned columns (``Row``) keep their packed
    /// width; slack goes to the other columns proportionally.
    private static func makeChunk(
        pinnedIndices: [Int],
        pinnedWidths: [CGFloat],
        chunkIndices: [Int],
        chunkWidths: [CGFloat],
        targetWidth: CGFloat
    ) -> ColumnChunk {
        let columnIndices = pinnedIndices + chunkIndices
        var widths = pinnedWidths + chunkWidths
        expandWidthsToFill(&widths, pinnedCount: pinnedWidths.count, targetWidth: targetWidth)
        return ColumnChunk(columnIndices: columnIndices, widths: widths)
    }
    
    /// Distributes leftover space so ``widths`` sum to ``targetWidth`` when underfull.
    ///
    /// - Prefer expanding non-pinned columns (``pinnedCount..<end``).
    /// - If every column is pinned, expand all of them.
    /// - Shares are proportional to each expandable column's current width; the last
    ///   expandable column absorbs residual rounding error so the sum matches exactly.
    private static func expandWidthsToFill(
        _ widths: inout [CGFloat],
        pinnedCount: Int,
        targetWidth: CGFloat
    ) {
        guard !widths.isEmpty else { return }
        
        let totalWidth = widths.reduce(CGFloat.zero, +)
        let slack = targetWidth - totalWidth
        guard slack > 0.5 else { return }
        
        let expandableRange: Range<Int>
        if pinnedCount < widths.count {
            expandableRange = pinnedCount..<widths.count
        } else {
            expandableRange = widths.indices
        }
        
        let expandableTotal = widths[expandableRange].reduce(CGFloat.zero, +)
        var distributed: CGFloat = 0
        let expandableIndices = Array(expandableRange)
        
        for (offset, index) in expandableIndices.enumerated() {
            let share: CGFloat
            if offset == expandableIndices.count - 1 {
                share = slack - distributed
            } else if expandableTotal > 0 {
                share = slack * (widths[index] / expandableTotal)
            } else {
                share = slack / CGFloat(expandableIndices.count)
            }
            widths[index] += share
            distributed += share
        }
    }
    
    private static func clampedColumnWidth(_ naturalWidth: CGFloat) -> CGFloat {
        min(
            max(naturalWidth, FCPXMLReportPDFStyle.minColumnWidth),
            FCPXMLReportPDFStyle.maxColumnWidth
        )
    }
    
    private static func rowColumnIndex(in headers: [String]) -> Int? {
        headers.firstIndex { isRowColumnHeader($0) }
    }
    
    private static func isRowColumnHeader(_ header: String) -> Bool {
        header.compare(rowColumnHeader, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
    
    static func rowsPerPage() -> Int {
        let available = FCPXMLReportPDFStyle.contentBottom - FCPXMLReportPDFStyle.contentTop
            - FCPXMLReportPDFStyle.sectionTitleFontSize - 12
            - FCPXMLReportPDFStyle.headerRowHeight
        guard available > 0 else { return 1 }
        return max(1, Int(floor(available / FCPXMLReportPDFStyle.rowHeight)))
    }
    
    static func truncated(
        _ text: String,
        maxWidth: CGFloat,
        bold: Bool = false,
        fontSize: CGFloat = FCPXMLReportPDFStyle.bodyFontSize
    ) -> String {
        let usableWidth = maxWidth - (FCPXMLReportPDFStyle.cellPadding * 2)
        guard usableWidth > 4 else { return "" }
        guard measuredWidth(text, bold: bold, fontSize: fontSize) > usableWidth else { return text }
        
        let ellipsis = "…"
        var trimmed = text
        while !trimmed.isEmpty {
            trimmed.removeLast()
            let candidate = trimmed + ellipsis
            if measuredWidth(candidate, bold: bold, fontSize: fontSize) <= usableWidth {
                return candidate
            }
        }
        
        return ellipsis
    }
    
    static func wrappedLines(
        _ text: String,
        maxWidth: CGFloat,
        bold: Bool = false,
        fontSize: CGFloat = FCPXMLReportPDFStyle.bodyFontSize
    ) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .map(String.init)
        
        guard !normalized.isEmpty else { return [] }
        
        var lines: [String] = []
        var current = normalized[0]
        
        for word in normalized.dropFirst() {
            let candidate = current + " " + word
            if measuredWidth(candidate, bold: bold, fontSize: fontSize) <= maxWidth {
                current = candidate
            } else {
                lines.append(current)
                current = word
            }
        }
        
        lines.append(current)
        return lines
    }
    
    static func naturalColumnWidths(headers: [String], rows: [[String]]) -> [CGFloat] {
        headers.enumerated().map { index, header in
            var maxWidth = measuredWidth(
                header,
                bold: true,
                fontSize: FCPXMLReportPDFStyle.headerFontSize
            )
            
            for row in rows {
                guard row.indices.contains(index) else { continue }
                maxWidth = max(
                    maxWidth,
                    measuredWidth(
                        row[index],
                        bold: false,
                        fontSize: FCPXMLReportPDFStyle.bodyFontSize
                    )
                )
            }
            
            return maxWidth + (FCPXMLReportPDFStyle.cellPadding * 2)
        }
    }
    
    static func measuredWidth(
        _ text: String,
        bold: Bool,
        fontSize: CGFloat = FCPXMLReportPDFStyle.bodyFontSize
    ) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        
        let fontName = bold
            ? FCPXMLReportPDFStyle.boldFontName
            : FCPXMLReportPDFStyle.regularFontName
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributes = [kCTFontAttributeName as NSAttributedString.Key: font]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }
}

enum FCPXMLReportPDFTableRenderer {
    struct TableDrawContext: Sendable {
        var pageTitle: String
        var sheetColorIndex: Int
        var contentHeading: String?
        var recordsSectionStart: Bool
        var columnPart: Int?
        var columnPartCount: Int?
    }
    
    static func drawTable(
        on canvas: FCPXMLReportPDFCanvas.Builder,
        context: TableDrawContext,
        headers: [String],
        rows: [[String]],
        rowTextColor: CGColor = FCPXMLReportPDFStyle.textColor,
        rowTextColorForRow: ((Int, [String]) -> CGColor)? = nil
    ) {
        guard !headers.isEmpty else { return }
        
        let prepared = FCPXMLReportPDFTableLayout.preparePaginatedTable(
            headers: headers,
            rows: rows,
            contentWidth: FCPXMLReportPDFStyle.contentWidth
        )
        let chunks = FCPXMLReportPDFTableLayout.columnChunks(
            headers: prepared.headers,
            rows: prepared.rows,
            contentWidth: FCPXMLReportPDFStyle.contentWidth,
            pinnedColumnIndices: prepared.pinnedColumnIndices
        )
        let rowsPerPage = FCPXMLReportPDFTableLayout.rowsPerPage()
        
        for (chunkIndex, chunk) in chunks.enumerated() {
            let chunkHeaders = chunk.headers(from: prepared.headers)
            let chunkRows = prepared.rows.map { chunk.rowSlice(from: $0) }
            let columnPart = chunks.count > 1 ? chunkIndex + 1 : nil
            let columnPartCount = chunks.count > 1 ? chunks.count : nil
            
            guard !chunkRows.isEmpty else { continue }
            
            var rowOffset = 0
            while rowOffset < chunkRows.count {
                let pageRows = Array(chunkRows.dropFirst(rowOffset).prefix(rowsPerPage))
                
                canvas.beginContentPage(
                    pageTitle: context.pageTitle,
                    sheetColorIndex: context.sheetColorIndex,
                    contentHeading: rowOffset == 0 ? context.contentHeading : nil,
                    columnPart: columnPart,
                    columnPartCount: columnPartCount,
                    repeatOnContinuation: rowOffset > 0,
                    recordsSectionStart: rowOffset == 0 && chunkIndex == 0 && context.recordsSectionStart
                )
                
                canvas.drawTableHeaderRow(headers: chunkHeaders, columnWidths: chunk.widths)
                
                for (index, row) in pageRows.enumerated() {
                    let globalRowIndex = rowOffset + index
                    let sourceRow = prepared.rows[globalRowIndex]
                    let textColor = rowTextColorForRow?(globalRowIndex, sourceRow) ?? rowTextColor
                    canvas.drawTableDataRow(
                        values: row,
                        columnWidths: chunk.widths,
                        textColor: textColor
                    )
                }
                
                rowOffset += pageRows.count
                
                if rowOffset < chunkRows.count {
                    canvas.endContentPage()
                }
            }
            
            canvas.endContentPage()
        }
    }
}
