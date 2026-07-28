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
    /// Connected / secondary storylines are ignored. The primary spine must contain only
    /// still-image video — **video** media, **titles / generators / Motion templates**, and
    /// **audio** clips on the primary spine are rejected.
    ///
    /// Call ``plan(from:options:)`` (CLI `--dry-run`) to validate and count shots without writing.
    public struct ShotExtractor: Sendable {
        public var timelineProjector: any TimelineProjecting

        public init(timelineProjector: any TimelineProjecting = TimelineProjector()) {
            self.timelineProjector = timelineProjector
        }

        /// Validates the timeline and builds a shot plan without writing PNGs or manifests.
        ///
        /// Throws the same ``ShotExtractionError`` cases as ``extract(from:options:)`` when the
        /// timeline is unsuitable or media is missing — ideal for GUI preflight after open/drop.
        public func plan(
            from fcpxml: FinalCutPro.FCPXML,
            options: ShotExtractionOptions
        ) async throws -> ShotExtractionPlan {
            try await buildPlan(from: fcpxml, options: options)
        }

        /// Runs shot extraction for `fcpxml` using `options`.
        public func extract(
            from fcpxml: FinalCutPro.FCPXML,
            options: ShotExtractionOptions
        ) async throws -> ShotExtractionResult {
            let plan = try await buildPlan(from: fcpxml, options: options)

            do {
                try FileManager.default.createDirectory(
                    at: plan.plannedExportFolder,
                    withIntermediateDirectories: true
                )
            } catch {
                throw ShotExtractionError.outputDirectoryFailed(
                    path: plan.plannedExportFolder.path,
                    reason: error.localizedDescription
                )
            }

            var imagePaths: [URL] = []
            imagePaths.reserveCapacity(plan.shots.count)
            for shot in plan.shots {
                let destination = plan.plannedExportFolder.appendingPathComponent(
                    shot.imageFilename,
                    isDirectory: false
                )
                try ShotImageWriter.writePNG(from: shot.sourceMediaURL, to: destination)
                imagePaths.append(destination)
            }

            let manifestPath = try ShotManifestExporter.write(
                shots: plan.shots,
                format: options.extractFormat,
                timelineName: plan.timelineName,
                to: plan.plannedExportFolder
            )

            let result = ShotExtractionResult(
                exportFolder: plan.plannedExportFolder,
                manifestPath: manifestPath,
                imagePaths: imagePaths,
                shots: plan.shots,
                timelineName: plan.timelineName,
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

        // MARK: - Plan / validation

        private func buildPlan(
            from fcpxml: FinalCutPro.FCPXML,
            options: ShotExtractionOptions
        ) async throws -> ShotExtractionPlan {
            let sceneNumber = options.sceneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sceneNumber.isEmpty else {
                throw ShotExtractionError.invalidSceneNumber
            }

            let source = try resolveTimelineSource(in: fcpxml, projectName: options.projectName)
            let resources = fcpxml.root.resources

            let spineViolations = Self.collectPrimarySpineViolations(
                storyElements: source.sequence.spine.storyElements,
                resources: resources
            )
            if !spineViolations.titles.isEmpty {
                throw ShotExtractionError.containsTitlesOrGenerators(names: spineViolations.titles)
            }
            if !spineViolations.audios.isEmpty {
                throw ShotExtractionError.containsPrimaryAudio(names: spineViolations.audios)
            }

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

            let primaryWindows = windows.filter { $0.lanePath.components.isEmpty }

            let primaryAudioNames = primaryWindows
                .filter { $0.channel.kind == .audio }
                .map { window in
                    window.channel.name
                        ?? window.clipDisplayName
                        ?? window.channel.originalMediaURL?.lastPathComponent
                        ?? window.channel.resourceID
                }
            if !primaryAudioNames.isEmpty {
                throw ShotExtractionError.containsPrimaryAudio(names: Self.uniquePreservingOrder(primaryAudioNames))
            }

            let primaryVideo = primaryWindows
                .filter { $0.channel.kind == .video }
                .filter { $0.channel.sourceIndex == 1 }
                .sorted { $0.timelineIn.doubleValue < $1.timelineIn.doubleValue }

            let videoMediaNames = primaryVideo.compactMap { window -> String? in
                guard !Self.isStillImageChannel(window.channel) else { return nil }
                return window.channel.name
                    ?? window.channel.originalMediaURL?.lastPathComponent
                    ?? window.channel.resourceID
            }
            if !videoMediaNames.isEmpty {
                throw ShotExtractionError.containsVideoMedia(names: Self.uniquePreservingOrder(videoMediaNames))
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

            return ShotExtractionPlan(
                isValid: true,
                timelineName: timelineName,
                sceneNumber: sceneNumber,
                shots: shots,
                plannedFolderName: folderName,
                plannedExportFolder: exportFolder,
                extractFormat: options.extractFormat
            )
        }

        // MARK: - Primary spine violations (titles / audio)

        /// Walks primary-lane (`lane` absent or `0`) story elements looking for titles/generators
        /// and audio-only clips. Connected lanes (`lane ≠ 0`) are ignored.
        static func collectPrimarySpineViolations(
            storyElements: [any OFKXMLElement],
            resources: (any OFKXMLElement)?
        ) -> (titles: [String], audios: [String]) {
            var titles: [String] = []
            var audios: [String] = []

            func walk(_ elements: [any OFKXMLElement]) {
                for element in elements {
                    let lane = element.fcpLane ?? 0
                    guard lane == 0 else { continue }

                    if element.fcpAsTitle != nil {
                        titles.append(displayName(for: element, fallback: "Title"))
                        continue
                    }

                    if element.fcpAsAudio != nil {
                        audios.append(displayName(for: element, fallback: "Audio"))
                        continue
                    }

                    if element.fcpAsAssetClip != nil {
                        let carriesVideo = element.fcpCarriesVideo(resources: resources)
                        let carriesAudio = element.fcpCarriesAudio(resources: resources)
                        if carriesAudio && !carriesVideo {
                            audios.append(displayName(for: element, fallback: "Audio"))
                        }
                        walk(element.fcpStoryElements)
                        continue
                    }

                    if element.fcpAsVideo != nil {
                        walk(element.fcpStoryElements)
                        continue
                    }

                    // Nested primary containers (sync-clip, clip, gap, ref/mc/audition shells).
                    walk(element.fcpStoryElements)
                }
            }

            walk(storyElements)
            return (Self.uniquePreservingOrder(titles), Self.uniquePreservingOrder(audios))
        }

        private static func displayName(for element: any OFKXMLElement, fallback: String) -> String {
            let name = element.fcpName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? fallback : name
        }

        private static func uniquePreservingOrder(_ names: [String]) -> [String] {
            var seen = Set<String>()
            var result: [String] = []
            for name in names where seen.insert(name).inserted {
                result.append(name)
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

    /// Dry-run / preflight for Shot Extraction (see ``ShotExtractor/plan(from:options:)``).
    public func planShots(
        options: ShotExtractionOptions
    ) async throws -> ShotExtractionPlan {
        try await ShotExtractor().plan(from: self, options: options)
    }
}
