//
// FCPXMLShotExtractionResult.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Result of a Shot Extraction run.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Artefacts produced by ``ShotExtractor``.
    public struct ShotExtractionResult: Sendable, Equatable {
        /// Export folder containing PNGs + manifest.
        public var exportFolder: URL

        /// CSV or JSON manifest path.
        public var manifestPath: URL

        /// Written PNG paths in shot order.
        public var imagePaths: [URL]

        /// Shot rows (same order as ``imagePaths``).
        public var shots: [ShotRecord]

        /// Timeline display name used for folder / manifest naming.
        public var timelineName: String

        /// Extract format used.
        public var extractFormat: ShotExtractionFormat

        public init(
            exportFolder: URL,
            manifestPath: URL,
            imagePaths: [URL],
            shots: [ShotRecord],
            timelineName: String,
            extractFormat: ShotExtractionFormat
        ) {
            self.exportFolder = exportFolder
            self.manifestPath = manifestPath
            self.imagePaths = imagePaths
            self.shots = shots
            self.timelineName = timelineName
            self.extractFormat = extractFormat
        }

        /// MarkersExtractor-style result dictionary for `--result-file-path`.
        public func resultFileDictionary(date: Date = Date()) -> [String: String] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return [
                "date": formatter.string(from: date),
                "profile": extractFormat.displayName,
                "exportFolder": exportFolder.path,
                "manifestPath": manifestPath.path,
                "timelineName": timelineName,
                "shotCount": String(shots.count)
            ]
        }
    }
}
