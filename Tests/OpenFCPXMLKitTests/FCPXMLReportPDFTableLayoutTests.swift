//
//  FCPXMLReportPDFTableLayoutTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF table column sizing: fill leftover width after exclusions / short content.
//

import CoreGraphics
import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportPDFTableLayoutTests: XCTestCase {
    
    func testFewShortColumnsExpandToFillContentWidth() {
        let headers = ["Clip Name", "Role ▸ Subrole", "Enabled", "Timeline In", "Timeline Out"]
        let rows = [
            ["Clip A", "Dialogue", "Yes", "00:00:00:00", "00:00:05:00"],
            ["Clip B", "Music", "Yes", "00:00:05:00", "00:00:10:00"],
        ]
        let contentWidth = FCPXMLReportPDFStyle.contentWidth
        
        let chunks = FCPXMLReportPDFTableLayout.columnChunks(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth
        )
        
        XCTAssertEqual(chunks.count, 1, "Short excluded-column style tables should fit on one horizontal part")
        
        let totalWidth = chunks[0].totalWidth
        XCTAssertEqual(
            totalWidth,
            contentWidth,
            accuracy: 0.5,
            "Remaining columns must expand to fill unused page width"
        )
        
        let naturalSum = FCPXMLReportPDFTableLayout.naturalColumnWidths(headers: headers, rows: rows)
            .map { min(max($0, FCPXMLReportPDFStyle.minColumnWidth), FCPXMLReportPDFStyle.maxColumnWidth) }
            .reduce(CGFloat.zero, +)
        XCTAssertGreaterThan(
            totalWidth,
            naturalSum + 1,
            "Expanded widths should exceed content-clamped natural widths when leftover space exists"
        )
    }
    
    func testPinnedRowColumnKeepsPackedWidthWhileOthersExpand() {
        let headers = [
            FCPXMLReportPDFTableLayout.rowColumnHeader,
            "Clip Name",
            "Enabled",
            "Timeline In",
        ]
        let rows = [
            ["1", "Clip A", "Yes", "00:00:00:00"],
            ["2", "Clip B", "Yes", "00:00:05:00"],
        ]
        let contentWidth = FCPXMLReportPDFStyle.contentWidth
        
        let naturalWidths = FCPXMLReportPDFTableLayout.naturalColumnWidths(headers: headers, rows: rows)
        let packedRowWidth = min(
            max(naturalWidths[0], FCPXMLReportPDFStyle.minColumnWidth),
            FCPXMLReportPDFStyle.maxColumnWidth
        )
        
        let chunks = FCPXMLReportPDFTableLayout.columnChunks(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth,
            pinnedColumnIndices: [0]
        )
        
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].widths.count, 4)
        XCTAssertEqual(
            chunks[0].widths[0],
            packedRowWidth,
            accuracy: 0.01,
            "Pinned Row column should not absorb leftover space"
        )
        XCTAssertEqual(chunks[0].totalWidth, contentWidth, accuracy: 0.5)
        
        for width in chunks[0].widths.dropFirst() {
            XCTAssertGreaterThan(
                width,
                FCPXMLReportPDFStyle.minColumnWidth,
                "Non-pinned columns should receive expansion slack"
            )
        }
    }
    
    func testWideTablesStillChunkAndEachPartFillsContentWidth() {
        let headers = (1...20).map { "Column \($0) With A Fairly Long Header Label" }
        let rows = [
            headers.map { header in "Value for \(header) with additional detail text" }
        ]
        let contentWidth = FCPXMLReportPDFStyle.contentWidth
        
        let chunks = FCPXMLReportPDFTableLayout.columnChunks(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth
        )
        
        XCTAssertGreaterThan(chunks.count, 1, "Wide tables should still split horizontally")
        
        for (index, chunk) in chunks.enumerated() {
            XCTAssertEqual(
                chunk.totalWidth,
                contentWidth,
                accuracy: 0.5,
                "Chunk \(index) should fill content width after packing"
            )
        }
    }
    
    func testPreparedPaginatedTableWithExclusionsExpandsVisibleColumns() {
        // Simulate a markers-style table after excluding Reel / Scene / Source Position / Notes.
        let headers = ["Marker", "Type", "Position", "Clip Name", "Role ▸ Subrole"]
        let rows = [
            ["Scene 1", "Standard", "00:00:10:00", "Clip A", "Video"],
            ["Scene 2", "To Do", "00:00:20:00", "Clip B", "Dialogue"],
        ]
        let contentWidth = FCPXMLReportPDFStyle.contentWidth
        
        let prepared = FCPXMLReportPDFTableLayout.preparePaginatedTable(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth
        )
        let chunks = FCPXMLReportPDFTableLayout.columnChunks(
            headers: prepared.headers,
            rows: prepared.rows,
            contentWidth: contentWidth,
            pinnedColumnIndices: prepared.pinnedColumnIndices
        )
        
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].totalWidth, contentWidth, accuracy: 0.5)
    }
    
    func testPreparePaginatedTableDoesNotInjectRowWhenDisallowed() {
        let headers = (1...20).map { "Column \($0) With A Fairly Long Header Label" }
        let rows = [
            headers.map { header in "Value for \(header) with additional detail text" }
        ]
        let contentWidth = FCPXMLReportPDFStyle.contentWidth
        
        let prepared = FCPXMLReportPDFTableLayout.preparePaginatedTable(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth,
            allowInjectedRowColumn: false
        )
        
        XCTAssertFalse(
            prepared.headers.contains(FCPXMLReportPDFTableLayout.rowColumnHeader),
            "Excluded Row must not be injected for multi-page PDF tables"
        )
        XCTAssertTrue(prepared.pinnedColumnIndices.isEmpty)
        XCTAssertEqual(prepared.rows.first?.count, headers.count)
    }
    
    func testPreparePaginatedTableInjectsRowWhenAllowedAndMultiPage() {
        let headers = (1...20).map { "Column \($0) With A Fairly Long Header Label" }
        let rows = [
            headers.map { header in "Value for \(header) with additional detail text" }
        ]
        let contentWidth = FCPXMLReportPDFStyle.contentWidth
        
        let prepared = FCPXMLReportPDFTableLayout.preparePaginatedTable(
            headers: headers,
            rows: rows,
            contentWidth: contentWidth,
            allowInjectedRowColumn: true
        )
        
        XCTAssertEqual(prepared.headers.first, FCPXMLReportPDFTableLayout.rowColumnHeader)
        XCTAssertEqual(prepared.pinnedColumnIndices, [0])
        XCTAssertEqual(prepared.rows.first?.first, "1")
    }
}
