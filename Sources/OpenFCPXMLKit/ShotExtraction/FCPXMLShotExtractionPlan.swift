//
//  FCPXMLShotExtractionPlan.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Dry-run / preflight plan for still-image Shot Extraction (CLI + GUI).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Preflight result from ``ShotExtractor/plan(from:options:)`` — no files are written.
    ///
    /// Suitable for CLI `--dry-run` and future GUI apps (drag/drop validation + shot count).
    public struct ShotExtractionPlan: Sendable, Equatable {
        /// Always `true` when ``ShotExtractor/plan(from:options:)`` returns successfully.
        /// Content failures throw ``ShotExtractionError`` instead of returning an invalid plan.
        public var isValid: Bool

        /// Timeline display name that would be used for folder / manifest naming.
        public var timelineName: String

        /// Scene number from options (trimmed).
        public var sceneNumber: String

        /// Number of still-image shots that would be exported.
        public var shotCount: Int { shots.count }

        /// Planned shot rows (same shape as a full extract; PNG/manifest not written).
        public var shots: [ShotRecord]

        /// Folder name that would be created under ``plannedExportFolder``’s parent.
        public var plannedFolderName: String

        /// Absolute export folder URL that would be created on a full extract.
        public var plannedExportFolder: URL

        /// Extract format from options.
        public var extractFormat: ShotExtractionFormat

        public init(
            isValid: Bool = true,
            timelineName: String,
            sceneNumber: String,
            shots: [ShotRecord],
            plannedFolderName: String,
            plannedExportFolder: URL,
            extractFormat: ShotExtractionFormat
        ) {
            self.isValid = isValid
            self.timelineName = timelineName
            self.sceneNumber = sceneNumber
            self.shots = shots
            self.plannedFolderName = plannedFolderName
            self.plannedExportFolder = plannedExportFolder
            self.extractFormat = extractFormat
        }

        /// Summary dictionary for `--result-file-path` during dry-run.
        public func resultFileDictionary(date: Date = Date()) -> [String: String] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return [
                "date": formatter.string(from: date),
                "dryRun": "true",
                "isValid": isValid ? "true" : "false",
                "profile": extractFormat.displayName,
                "plannedExportFolder": plannedExportFolder.path,
                "timelineName": timelineName,
                "sceneNumber": sceneNumber,
                "shotCount": String(shotCount)
            ]
        }
    }
}
