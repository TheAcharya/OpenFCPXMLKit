//
// FCPXMLShotExtractionOptions.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Options for still-image Shot Extraction.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Configuration for ``ShotExtractor``.
    public struct ShotExtractionOptions: Sendable, Equatable {
        /// Scene number inherited by every shot row (required; non-empty after trim).
        public var sceneNumber: String

        /// Manifest format (CSV or Notion JSON).
        public var extractFormat: ShotExtractionFormat

        /// Parent directory that will contain the dated/export folder.
        public var outputDir: URL

        /// Folder naming style (default `.medium`).
        public var folderFormat: ShotExtractionFolderFormat

        /// Optional JSON result file path (MarkersExtractor-style summary).
        public var resultFilePath: URL?

        /// Prefer this project / compound-clip display name when multiple timelines exist.
        public var projectName: String?

        /// Base URL for resolving relative media paths (defaults to FCPXML parent when set by CLI).
        public var mediaBaseURL: URL?

        /// Optional emoji (or any text) written to every row’s **Icon Image** column.
        public var icon: String?

        /// Injectable clock for deterministic folder timestamps in tests.
        public var now: Date

        public init(
            sceneNumber: String,
            extractFormat: ShotExtractionFormat = .csv,
            outputDir: URL,
            folderFormat: ShotExtractionFolderFormat = .medium,
            resultFilePath: URL? = nil,
            projectName: String? = nil,
            mediaBaseURL: URL? = nil,
            icon: String? = nil,
            now: Date = Date()
        ) {
            self.sceneNumber = sceneNumber
            self.extractFormat = extractFormat
            self.outputDir = outputDir
            self.folderFormat = folderFormat
            self.resultFilePath = resultFilePath
            self.projectName = projectName
            self.mediaBaseURL = mediaBaseURL
            self.icon = icon
            self.now = now
        }
    }
}
