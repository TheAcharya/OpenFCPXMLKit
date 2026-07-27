//
// FCPXMLShotExtractionFolderFormat.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Output folder naming for Shot Extraction (MarkersExtractor-inspired).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Folder name style for a Shot Extraction export directory.
    ///
    /// Medium example: `Demo_V1-2026-07-27-09-14-21`.
    public enum ShotExtractionFolderFormat: String, Sendable, CaseIterable, Equatable {
        /// `{timelineName}`
        case short
        /// `{timelineName}-{yyyy-MM-dd-HH-mm-ss}`
        case medium
        /// `{timelineName}-{yyyy-MM-dd-HH-mm-ss}-[{CSV|Notion}]`
        case long

        /// Builds a unique folder name for the export.
        public func folderName(
            timelineName: String,
            format: ShotExtractionFormat,
            now: Date = Date(),
            calendar: Calendar = .current
        ) -> String {
            let safeName = timelineName.trimmingCharacters(in: .whitespacesAndNewlines)
            let base = safeName.isEmpty ? "Shots" : safeName
            switch self {
            case .short:
                return base
            case .medium:
                return "\(base)-\(Self.timestamp(now: now, calendar: calendar))"
            case .long:
                return "\(base)-\(Self.timestamp(now: now, calendar: calendar))-[\(format.displayName)]"
            }
        }

        /// `2026-07-27-09-14-21`
        private static func timestamp(now: Date, calendar: Calendar) -> String {
            let parts = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: now
            )
            let year = parts.year ?? 0
            let month = parts.month ?? 0
            let day = parts.day ?? 0
            let hour = parts.hour ?? 0
            let minute = parts.minute ?? 0
            let second = parts.second ?? 0
            return String(
                format: "%04d-%02d-%02d-%02d-%02d-%02d",
                year, month, day, hour, minute, second
            )
        }
    }
}
