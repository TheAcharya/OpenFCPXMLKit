//
//  FCPXMLReportTimecodeFormat.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Workbook timecode display formats for Excel report columns.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// How timeline time values are formatted in Excel report cells.
    public enum ReportTimecodeFormat: String, Sendable, CaseIterable, Equatable {
        /// SMPTE timecode with a frames field: `HH:MM:SS:FF` (NDF) or `HH:MM:SS;FF` (drop-frame).
        case smpteFrames = "HH:MM:SS:FF"
        
        /// Total elapsed frames from timeline zero (integer frame count).
        case frames = "Frames"
        
        /// Film-style feet and frames (35 mm 4-perf), e.g. `5400+00`.
        case feetAndFrames = "Feet+Frames"
        
        /// Hours, minutes, and seconds only (no frames field).
        case smpteNoFrames = "HH:MM:SS"
        
        /// Parses a CLI or API string (case-insensitive ``rawValue`` match).
        public init?(cliValue: String) {
            let normalized = cliValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return nil }
            
            if let match = Self.allCases.first(
                where: { $0.rawValue.caseInsensitiveCompare(normalized) == .orderedSame }
            ) {
                self = match
                return
            }
            
            switch normalized.lowercased() {
            case "smpte", "timecode", "hh:mm:ss:ff":
                self = .smpteFrames
            case "frame", "frames", "framecount", "frame-count":
                self = .frames
            case "feet+frames", "feet-frames", "feetandframes", "feet_and_frames":
                self = .feetAndFrames
            case "hh:mm:ss", "smpte-no-frames", "no-frames":
                self = .smpteNoFrames
            default:
                return nil
            }
        }
        
        /// Comma-separated allowed values for CLI help text.
        public static var cliHelpValues: String {
            allCases.map(\.rawValue).joined(separator: ", ")
        }
        
        /// Suffix appended to timecode column headers when not using default SMPTE frames notation.
        var columnHeaderSuffix: String? {
            switch self {
            case .smpteFrames:
                return nil
            case .frames:
                return " (frames)"
            case .feetAndFrames:
                return " (feet+frames)"
            case .smpteNoFrames:
                return " (HH:MM:SS)"
            }
        }
        
        /// Workbook column header for a timecode field, with a format-specific suffix when applicable.
        func formattedColumnHeader(_ baseName: String) -> String {
            guard let suffix = columnHeaderSuffix else { return baseName }
            return baseName + suffix
        }
    }
}
