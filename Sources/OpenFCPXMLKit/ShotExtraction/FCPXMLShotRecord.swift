//
// FCPXMLShotRecord.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	One extracted still-image shot row.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One primary-timeline still-image shot prepared for manifest export.
    public struct ShotRecord: Sendable, Equatable {
        /// Shot ID (`{scene}-{NNN}`, e.g. `50-001`).
        public var shotID: String

        /// 1-based shot number within the scene.
        public var shotNumber: Int

        /// Scene number from ``ShotExtractionOptions/sceneNumber``.
        public var sceneNumber: String

        /// Timeline occupancy duration as `HH:MM:SS` (whole seconds, floored).
        public var shotDuration: String

        /// Optional emoji / icon text for the **Icon Image** column (from ``ShotExtractionOptions/icon``).
        public var iconImage: String

        /// PNG filename written beside the manifest (`{shotID}.png`).
        public var imageFilename: String

        /// Resolved source media URL before PNG conversion.
        public var sourceMediaURL: URL

        /// Absolute timeline in (seconds) for diagnostics.
        public var timelineInSeconds: Double

        /// Absolute timeline out (seconds) for diagnostics.
        public var timelineOutSeconds: Double

        public init(
            shotID: String,
            shotNumber: Int,
            sceneNumber: String,
            shotDuration: String,
            iconImage: String = "",
            imageFilename: String,
            sourceMediaURL: URL,
            timelineInSeconds: Double,
            timelineOutSeconds: Double
        ) {
            self.shotID = shotID
            self.shotNumber = shotNumber
            self.sceneNumber = sceneNumber
            self.shotDuration = shotDuration
            self.iconImage = iconImage
            self.imageFilename = imageFilename
            self.sourceMediaURL = sourceMediaURL
            self.timelineInSeconds = timelineInSeconds
            self.timelineOutSeconds = timelineOutSeconds
        }

        /// Formats a zero-padded shot ID for a scene.
        public static func makeShotID(sceneNumber: String, shotNumber: Int) -> String {
            "\(sceneNumber)-\(String(format: "%03d", shotNumber))"
        }

        /// Floors a duration in seconds to `HH:MM:SS`.
        public static func formatDurationHHMMSS(seconds: Double) -> String {
            let total = max(0, Int(seconds.rounded(.down)))
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            let secs = total % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
    }
}
