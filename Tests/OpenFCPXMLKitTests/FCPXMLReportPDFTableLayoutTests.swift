//
//  FCPXMLReportPDFTableLayoutTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF table column sizing: fill leftover width after exclusions / short content.
//

import CoreGraphics
import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Report PDF table layout")
struct FCPXMLReportPDFTableLayoutTests {

    @Test("Few short columns expand to fill content width")
    func fewShortColumnsExpandToFillContentWidth() {
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

        #expect(chunks.count == 1, "Short excluded-column style tables should fit on one horizontal part")

        let totalWidth = chunks[0].totalWidth
        let fillsContentWidth = abs(totalWidth - contentWidth) < 0.5
        #expect(fillsContentWidth, "Remaining columns must expand to fill unused page width")

        let naturalSum = FCPXMLReportPDFTableLayout.naturalColumnWidths(headers: headers, rows: rows)
            .map { min(max($0, FCPXMLReportPDFStyle.minColumnWidth), FCPXMLReportPDFStyle.maxColumnWidth) }
            .reduce(CGFloat.zero, +)
        let expandedBeyondNatural = totalWidth > naturalSum + 1
        #expect(
            expandedBeyondNatural,
            "Expanded widths should exceed content-clamped natural widths when leftover space exists"
        )
    }

    @Test("Pinned Row column keeps packed width while others expand")
    func pinnedRowColumnKeepsPackedWidthWhileOthersExpand() {
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

        #expect(chunks.count == 1)
        #expect(chunks[0].widths.count == 4)
        let pinnedWidthMatch = abs(chunks[0].widths[0] - packedRowWidth) < 0.01
        #expect(pinnedWidthMatch, "Pinned Row column should not absorb leftover space")
        let fillsContentWidth = abs(chunks[0].totalWidth - contentWidth) < 0.5
        #expect(fillsContentWidth)

        for width in chunks[0].widths.dropFirst() {
            #expect(
                width > FCPXMLReportPDFStyle.minColumnWidth,
                "Non-pinned columns should receive expansion slack"
            )
        }
    }

    @Test("Wide tables still chunk and each part fills content width")
    func wideTablesStillChunkAndEachPartFillsContentWidth() {
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

        #expect(chunks.count > 1, "Wide tables should still split horizontally")

        for (index, chunk) in chunks.enumerated() {
            let fillsContentWidth = abs(chunk.totalWidth - contentWidth) < 0.5
            #expect(
                fillsContentWidth,
                "Chunk \(index) should fill content width after packing"
            )
        }
    }

    @Test("Prepared paginated table with exclusions expands visible columns")
    func preparedPaginatedTableWithExclusionsExpandsVisibleColumns() {
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

        #expect(chunks.count == 1)
        let fillsContentWidth = abs(chunks[0].totalWidth - contentWidth) < 0.5
        #expect(fillsContentWidth)
    }

    @Test("Prepare paginated table does not inject Row when disallowed")
    func preparePaginatedTableDoesNotInjectRowWhenDisallowed() {
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

        let injectsRow = prepared.headers.contains(FCPXMLReportPDFTableLayout.rowColumnHeader)
        #expect(
            !injectsRow,
            "Excluded Row must not be injected for multi-page PDF tables"
        )
        #expect(prepared.pinnedColumnIndices.isEmpty)
        #expect(prepared.rows.first?.count == headers.count)
    }

    @Test("Prepare paginated table injects Row when allowed and multi-page")
    func preparePaginatedTableInjectsRowWhenAllowedAndMultiPage() {
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

        #expect(prepared.headers.first == FCPXMLReportPDFTableLayout.rowColumnHeader)
        #expect(prepared.pinnedColumnIndices == [0])
        #expect(prepared.rows.first?.first == "1")
    }
}
