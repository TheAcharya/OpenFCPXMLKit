//
//  FCPXMLReportEmptySectionStatus.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared empty-sheet status rows for Excel/PDF tabular report sections.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Presentation helper: when an enabled section has no data rows, Excel and PDF keep
    /// headers and show one status message in the first content column (same pattern as
    /// ``MediaSummaryReportSection/noMissingMediaMessage``).
    enum ReportEmptySectionStatus {
        /// Returns `rows` unchanged, or a single status row when `rows` is empty.
        ///
        /// - When `headers` already begin with **Row** (inventory layout), the status cell is
        ///   placed in column B (`1` | message | …).
        /// - Otherwise the message is placed in column A and ``ReportColumnExclusion/ensuringRowColumn``
        ///   injects **Row** afterward (→ **B2** with Row present).
        static func rowsOrEmptyStatus(
            _ rows: [[String]],
            headers: [String],
            message: String
        ) -> [[String]] {
            guard rows.isEmpty else { return rows }
            return [statusRow(headers: headers, message: message)]
        }

        static func statusRow(headers: [String], message: String) -> [String] {
            let columnCount = max(headers.count, 1)
            var row = Array(repeating: "", count: columnCount)
            if headers.first == RoleInventoryColumnLayout.rowColumnHeader, columnCount > 1 {
                row[0] = "1"
                row[1] = message
            } else {
                row[0] = message
            }
            return row
        }

        /// Whether `value` is an empty-state status string (default body colour; not data tint).
        static func isStatusMessage(_ value: String) -> Bool {
            !value.isEmpty && knownMessages.contains(value)
        }

        private static let knownMessages: Set<String> = [
            RoleInventoryReportSection.emptyStatusMessage,
            MarkersReportSection.emptyStatusMessage,
            KeywordsReportSection.emptyStatusMessage,
            TitlesReportSection.emptyStatusMessage,
            TransitionsReportSection.emptyStatusMessage,
            NonStandardEffectsTemplatesReportSection.emptyStatusMessage,
            EffectsReportSection.emptyStatusMessage,
            SpeedChangeEffectsReportSection.emptyStatusMessage,
            MediaSummaryReportSection.noMissingMediaMessage
        ]
    }
}
