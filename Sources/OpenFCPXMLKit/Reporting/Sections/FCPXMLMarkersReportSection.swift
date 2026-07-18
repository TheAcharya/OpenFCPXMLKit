//
//  FCPXMLMarkersReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Markers report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Markers report section containing timeline marker rows.
    public struct MarkersReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Markers"
        
        public var rows: [MarkerReportRow]
        
        /// When `true`, Excel/PDF append a **Hidden** column (✓/✗) for out-of-bounds markers.
        ///
        /// Set only when ``ReportOptions/includeMarkersOutsideClipBoundaries`` is `true`.
        /// Not controllable via ``ReportColumn`` / `--exclude-column`.
        public var showsHiddenColumn: Bool
        
        public init(rows: [MarkerReportRow], showsHiddenColumn: Bool = false) {
            self.rows = rows
            self.showsHiddenColumn = showsHiddenColumn
        }
        
        public func columnHeaders(
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) -> [String] {
            MarkerReportRow.columnHeaders(
                timecodeFormat: timecodeFormat,
                includeHiddenColumn: showsHiddenColumn
            )
        }
        
        public func columnValues(for row: MarkerReportRow) -> [String] {
            row.columnValues(includeHiddenColumn: showsHiddenColumn)
        }
    }
}
