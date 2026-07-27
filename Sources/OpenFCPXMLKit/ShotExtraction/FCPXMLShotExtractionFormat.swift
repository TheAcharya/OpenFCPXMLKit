//
// FCPXMLShotExtractionFormat.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Shot Extraction manifest format (CSV or Notion JSON).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Manifest format for ``ShotExtractor``.
    public enum ShotExtractionFormat: String, Sendable, CaseIterable, Equatable {
        /// UTF-8 CSV with BOM (Shot Data / spreadsheet compatible).
        case csv
        /// Notion-compatible JSON array of shot objects.
        case notion

        /// File extension without the leading dot.
        public var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .notion: return "json"
            }
        }

        /// Display name for folder naming (`[CSV]` / `[Notion]`).
        public var displayName: String {
            switch self {
            case .csv: return "CSV"
            case .notion: return "Notion"
            }
        }
    }
}
