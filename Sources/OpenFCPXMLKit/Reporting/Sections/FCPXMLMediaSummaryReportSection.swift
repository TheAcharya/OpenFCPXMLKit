//
// FCPXMLMediaSummaryReportSection.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//

//
//	Media Summary report section model (missing media paths).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Media Summary report section (missing media file paths).
    public struct MediaSummaryReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Media Summary"
        public static let missingMediaSectionTitle = "Missing Media"
        public static let missingOriginalMediaSectionTitle = "Missing Original"
        public static let missingProxyMediaSectionTitle = "Missing Proxy"
        /// Status text when every referenced media file resolves on disk (Excel/PDF path column).
        public static let noMissingMediaMessage = "No Missing Media"

        /// Combined missing paths (original ∪ proxy ∪ locators). Used by default export layout.
        public var missingMediaPaths: [String]

        /// Missing `original-media` paths when distinguished.
        public var missingOriginalMediaPaths: [String]

        /// Missing `proxy-media` paths when distinguished.
        public var missingProxyMediaPaths: [String]

        /// When `true`, Excel/PDF export prefer separate Original / Proxy columns.
        public var distinguishProxyAndOriginal: Bool

        public init(
            missingMediaPaths: [String] = [],
            missingOriginalMediaPaths: [String] = [],
            missingProxyMediaPaths: [String] = [],
            distinguishProxyAndOriginal: Bool = false
        ) {
            self.missingMediaPaths = missingMediaPaths
            self.missingOriginalMediaPaths = missingOriginalMediaPaths
            self.missingProxyMediaPaths = missingProxyMediaPaths
            self.distinguishProxyAndOriginal = distinguishProxyAndOriginal
        }

        /// Shared Excel/PDF table content: headers always present; empty inventories get one status row.
        ///
        /// Default: **Missing Media** (+ injected **Row** at export). Distinguish mode:
        /// **Missing Original** | **Missing Proxy**, with ``noMissingMediaMessage`` under Original only.
        func exportTable() -> (headers: [String], rows: [[String]]) {
            if distinguishProxyAndOriginal {
                let headers = [
                    Self.missingOriginalMediaSectionTitle,
                    Self.missingProxyMediaSectionTitle
                ]
                let originals = missingOriginalMediaPaths
                let proxies = missingProxyMediaPaths
                let rowCount = max(originals.count, proxies.count)
                if rowCount == 0 {
                    return (headers, [[Self.noMissingMediaMessage, ""]])
                }
                var rows: [[String]] = []
                rows.reserveCapacity(rowCount)
                for index in 0 ..< rowCount {
                    let original = index < originals.count ? originals[index] : ""
                    let proxy = index < proxies.count ? proxies[index] : ""
                    rows.append([original, proxy])
                }
                return (headers, rows)
            }

            let headers = [Self.missingMediaSectionTitle]
            if missingMediaPaths.isEmpty {
                return (headers, [[Self.noMissingMediaMessage]])
            }
            return (headers, missingMediaPaths.map { [$0] })
        }

        /// Whether a cell value is a real missing path (red styling) vs the empty-state status message.
        static func isMissingMediaPathCell(_ value: String) -> Bool {
            !value.isEmpty && value != noMissingMediaMessage
        }
    }
}
