//
// FCPXMLShotExtractor.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Extracts primary-timeline still-image shots via Timeline Projection.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Extracts still-image shots from the primary timeline into a PNG + CSV/JSON dataset.
    ///
    /// Uses ``TimelineProjector`` primary-spine video windows (the clips between cuts).
    /// Connected audio / secondary storylines are ignored. Timelines that contain any
    /// non-still **video** media on the primary spine are rejected.
    public struct ShotExtractor: Sendable {
        public var timelineProjector: any TimelineProjecting

        public init(timelineProjector: any TimelineProjecting = TimelineProjector()) {
            self.timelineProjector = timelineProjector
        }

        /// Runs shot extraction for `fcpxml` using `options`.
        public func extract(
            from fcpxml: FinalCutPro.FCPXML,
            options: ShotExtractionOptions
        ) async throws -> ShotExtractionResult {
            let sceneNumber = options.sceneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sceneNumber.isEmpty else {
                throw ShotExtractionError.invalidSceneNumber
            }

            let source = try resolveTimelineSource(in: fcpxml, projectName: options.projectName)
            let projectionOptions = TimelineProjectionOptions(
                auditions: .active,
                mcClipAngles: .active,
                excludeFullyOccluded: true,
                includeAnnotations: false,
                expandAllSourceChannels: true
            )

            var windows: [MediaUsageWindow] = []
            try await timelineProjector.project(
                from: source,
                fcpxml: fcpxml,
                options: projectionOptions
            ) { window in
                windows.append(window)
            }

            let primaryVideo = windows
                .filter { $0.lanePath.components.isEmpty && $0.channel.kind == .video }
                .filter { $0.channel.sourceIndex == 1 }
                .sorted { $0.timelineIn.doubleValue < $1.timelineIn.doubleValue }

            let videoMediaNames = primaryVideo.compactMap { window -> String? in
                guard !Self.isStillImageChannel(window.channel) else { return nil }
                return window.channel.name
                    ?? window.channel.originalMediaURL?.lastPathComponent
                    ?? window.channel.resourceID
            }
            if !videoMediaNames.isEmpty {
                throw ShotExtractionError.containsVideoMedia(names: videoMediaNames)
            }

            let stillWindows = primaryVideo.filter { Self.isStillImageChannel($0.channel) }
            guard !stillWindows.isEmpty else {
                throw ShotExtractionError.noStillImageShots
            }

            let mediaBaseURL = options.mediaBaseURL
            var shots: [ShotRecord] = []
            shots.reserveCapacity(stillWindows.count)

            for (index, window) in stillWindows.enumerated() {
                let shotNumber = index + 1
                let shotID = ShotRecord.makeShotID(sceneNumber: sceneNumber, shotNumber: shotNumber)
                let durationSeconds = window.retiming.timelineDuration
                guard let sourceURL = Self.resolveMediaURL(
                    window.channel.originalMediaURL ?? window.channel.proxyMediaURL,
                    baseURL: mediaBaseURL
                ) else {
                    let hint = window.channel.originalMediaURL?.path
                        ?? window.channel.name
                        ?? window.channel.resourceID
                    throw ShotExtractionError.mediaFileMissing(path: hint)
                }
                guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                    throw ShotExtractionError.mediaFileMissing(path: sourceURL.path)
                }

                shots.append(
                    ShotRecord(
                        shotID: shotID,
                        shotNumber: shotNumber,
                        sceneNumber: sceneNumber,
                        shotDuration: ShotRecord.formatDurationHHMMSS(seconds: durationSeconds),
                        iconImage: options.icon ?? "",
                        imageFilename: "\(shotID).png",
                        sourceMediaURL: sourceURL,
                        timelineInSeconds: window.timelineIn.doubleValue,
                        timelineOutSeconds: window.timelineOut.doubleValue
                    )
                )
            }

            let timelineName = source.displayName
            let folderName = options.folderFormat.folderName(
                timelineName: timelineName,
                format: options.extractFormat,
                now: options.now
            )
            let exportFolder = options.outputDir.appendingPathComponent(folderName, isDirectory: true)

            do {
                try FileManager.default.createDirectory(
                    at: exportFolder,
                    withIntermediateDirectories: true
                )
            } catch {
                throw ShotExtractionError.outputDirectoryFailed(
                    path: exportFolder.path,
                    reason: error.localizedDescription
                )
            }

            var imagePaths: [URL] = []
            imagePaths.reserveCapacity(shots.count)
            for shot in shots {
                let destination = exportFolder.appendingPathComponent(
                    shot.imageFilename,
                    isDirectory: false
                )
                try ShotImageWriter.writePNG(from: shot.sourceMediaURL, to: destination)
                imagePaths.append(destination)
            }

            let manifestPath = try ShotManifestExporter.write(
                shots: shots,
                format: options.extractFormat,
                timelineName: timelineName,
                to: exportFolder
            )

            let result = ShotExtractionResult(
                exportFolder: exportFolder,
                manifestPath: manifestPath,
                imagePaths: imagePaths,
                shots: shots,
                timelineName: timelineName,
                extractFormat: options.extractFormat
            )

            if let resultFilePath = options.resultFilePath {
                let dict = result.resultFileDictionary(date: options.now)
                let data = try JSONSerialization.data(
                    withJSONObject: dict,
                    options: [.prettyPrinted, .sortedKeys]
                )
                try data.write(to: resultFilePath, options: .atomic)
            }

            return result
        }

        // MARK: - Helpers

        /// Still images in FCPXML use asset `duration="0s"` (``MediaChannel/nativeDuration``).
        static func isStillImageChannel(_ channel: MediaChannel) -> Bool {
            guard channel.kind == .video else { return false }
            if let native = channel.nativeDuration {
                return native == .zero || abs(native.doubleValue) < .ulpOfOne
            }
            return Self.isImageFileURL(channel.originalMediaURL ?? channel.proxyMediaURL)
        }

        static func isImageFileURL(_ url: URL?) -> Bool {
            guard let url else { return false }
            let ext = url.pathExtension.lowercased()
            return [
                "png", "jpg", "jpeg", "tif", "tiff", "gif", "bmp",
                "heic", "heif", "webp", "psd"
            ].contains(ext)
        }

        static func resolveMediaURL(_ url: URL?, baseURL: URL?) -> URL? {
            guard let url else { return nil }
            if url.isFileURL { return url }
            if url.scheme != nil { return url.isFileURL ? url : nil }
            if let baseURL {
                let resolved = URL(string: url.relativeString, relativeTo: baseURL)?.absoluteURL
                return resolved?.isFileURL == true ? resolved : nil
            }
            return nil
        }

        private func resolveTimelineSource(
            in fcpxml: FinalCutPro.FCPXML,
            projectName: String?
        ) throws -> ReportTimelineSource {
            let sources = fcpxml.allReportTimelineSources()
            guard !sources.isEmpty else {
                throw ShotExtractionError.noTimelineFound
            }

            if let projectName, !projectName.isEmpty {
                if let match = sources.first(where: { $0.displayName == projectName }) {
                    return match
                }
                throw ShotExtractionError.timelineNotFound(name: projectName)
            }

            if let project = sources.first(where: { $0.project != nil }) {
                return project
            }
            return sources[0]
        }
    }
}

extension FinalCutPro.FCPXML {
    /// Extracts still-image shots from the primary timeline (see ``ShotExtractor``).
    public func extractShots(
        options: ShotExtractionOptions
    ) async throws -> ShotExtractionResult {
        try await ShotExtractor().extract(from: self, options: options)
    }
}
