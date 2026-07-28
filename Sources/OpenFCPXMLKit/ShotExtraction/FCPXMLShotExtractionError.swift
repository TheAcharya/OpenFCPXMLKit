//
// FCPXMLShotExtractionError.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Errors for still-image Shot Extraction.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Errors thrown by ``ShotExtractor``.
    public enum ShotExtractionError: Error, LocalizedError, Sendable, Equatable {
        /// No project or standalone compound-clip timeline was found.
        case noTimelineFound

        /// Named project / timeline was not found.
        case timelineNotFound(name: String)

        /// Primary timeline contains one or more video (non-still) media files.
        case containsVideoMedia(names: [String])

        /// Primary timeline contains titles, generators, or Motion templates (`<title>`).
        case containsTitlesOrGenerators(names: [String])

        /// Primary timeline contains audio clips (standalone `<audio>` or audio-only media).
        case containsPrimaryAudio(names: [String])

        /// No still-image shots were found on the primary spine.
        case noStillImageShots

        /// A referenced still image file could not be resolved or read.
        case mediaFileMissing(path: String)

        /// PNG conversion or write failed.
        case imageWriteFailed(path: String, reason: String)

        /// Manifest encode/write failed.
        case manifestWriteFailed(reason: String)

        /// Output directory could not be created.
        case outputDirectoryFailed(path: String, reason: String)

        /// Scene number was empty after trimming.
        case invalidSceneNumber

        public var errorDescription: String? {
            switch self {
            case .noTimelineFound:
                return "No FCPXML timeline found for shot extraction."
            case .timelineNotFound(let name):
                return "Timeline named '\(name)' was not found."
            case .containsVideoMedia(let names):
                let list = names.joined(separator: ", ")
                return "Shot Extraction requires a still-image primary timeline. Video media is present: \(list)."
            case .containsTitlesOrGenerators(let names):
                let list = names.joined(separator: ", ")
                return "Shot Extraction requires a still-image primary timeline. Titles, generators, or Motion templates are present: \(list)."
            case .containsPrimaryAudio(let names):
                let list = names.joined(separator: ", ")
                return "Shot Extraction requires a still-image primary timeline. Audio clips are present on the primary spine: \(list)."
            case .noStillImageShots:
                return "No still-image shots were found on the primary timeline."
            case .mediaFileMissing(let path):
                return "Still image file is missing or unreadable: \(path)"
            case .imageWriteFailed(let path, let reason):
                return "Failed to write PNG '\(path)': \(reason)"
            case .manifestWriteFailed(let reason):
                return "Failed to write shot manifest: \(reason)"
            case .outputDirectoryFailed(let path, let reason):
                return "Failed to create output directory '\(path)': \(reason)"
            case .invalidSceneNumber:
                return "Scene number must be a non-empty value."
            }
        }
    }
}
