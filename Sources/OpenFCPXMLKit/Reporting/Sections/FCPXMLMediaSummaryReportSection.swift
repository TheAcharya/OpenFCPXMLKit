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
    }
}
