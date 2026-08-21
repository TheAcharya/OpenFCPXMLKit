//
//  FCPXMLProjectionWindowIndex.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Fast lookup of projected windows by clip name and timeline start.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Indexes ``MediaUsageWindow`` values for O(1)-ish matching from report builders.
    ///
    /// Replaces per-row full scans (and nested `contains` scans) used when overlaying
    /// projection timing onto Role Inventory / Effects rows.
    ///
    /// Buckets store positions into ``all`` rather than copies of the windows themselves.
    /// ``MediaUsageWindow`` is a large value type, so copying candidates out of the buckets on
    /// every lookup dominated report build time on timelines with many windows.
    struct ProjectionWindowIndex: Sendable {
        /// Start-time bucket size in seconds (matches ±0.05s matcher tolerance).
        private static let bucketSeconds: Double = 0.05

        private let byNameAndBucket: [String: [Int: [Int]]]
        private let byBucket: [Int: [Int]]
        private let all: [MediaUsageWindow]

        init(windows: [MediaUsageWindow]) {
            self.all = windows
            var named: [String: [Int: [Int]]] = [:]
            var buckets: [Int: [Int]] = [:]

            for (position, window) in windows.enumerated() {
                let bucket = Self.bucket(for: window.timelineIn.doubleValue)
                buckets[bucket, default: []].append(position)
                let name = window.clipDisplayName ?? ""
                named[name, default: [:]][bucket, default: []].append(position)
            }

            self.byNameAndBucket = named
            self.byBucket = buckets
        }

        /// Best window near ``expectedStart`` for ``clipName``, preferring audio or video.
        func match(
            clipName: String,
            expectedStart: Double,
            preferAudio: Bool
        ) -> MediaUsageWindow? {
            let candidates = candidatePositions(clipName: clipName, expectedStart: expectedStart)
            guard !candidates.isEmpty else { return nil }

            // Depends only on the candidate set, so it is resolved once rather than per candidate.
            let hasVideoSibling = !preferAudio && candidates.contains { position in
                let sibling = all[position]
                return sibling.channel.kind == .video
                    && abs(sibling.timelineIn.doubleValue - expectedStart) < Self.bucketSeconds
            }

            // Closest preferred-channel window, and closest of any channel as the fallback pool.
            var bestPreferred: Int?
            var bestAny: Int?

            for position in candidates {
                let window = all[position]

                if isCloser(position, than: bestAny, to: expectedStart) {
                    bestAny = position
                }

                let isPreferred: Bool
                if preferAudio {
                    isPreferred = window.channel.kind == .audio
                } else if window.channel.kind == .video {
                    isPreferred = true
                } else {
                    // Keep audio-only usages when no video channel exists for this name/start.
                    isPreferred = !hasVideoSibling
                }

                guard isPreferred else { continue }

                if isCloser(position, than: bestPreferred, to: expectedStart) {
                    bestPreferred = position
                }
            }

            guard let best = bestPreferred ?? bestAny else { return nil }

            let window = all[best]
            guard abs(window.timelineIn.doubleValue - expectedStart) < Self.bucketSeconds else {
                return nil
            }

            return window
        }
        
        /// All windows near ``expectedStart`` for ``clipName`` (video and audio channels).
        func windows(
            clipName: String,
            expectedStart: Double
        ) -> [MediaUsageWindow] {
            candidatePositions(clipName: clipName, expectedStart: expectedStart)
                .filter { abs(all[$0].timelineIn.doubleValue - expectedStart) < Self.bucketSeconds }
                .map { all[$0] }
        }

        /// Whether the window at `position` is strictly closer to `expectedStart` than `current`.
        ///
        /// Strict comparison keeps the earliest candidate on ties, matching `min(by:)`.
        private func isCloser(
            _ position: Int,
            than current: Int?,
            to expectedStart: Double
        ) -> Bool {
            guard let current else { return true }
            let candidate = abs(all[position].timelineIn.doubleValue - expectedStart)
            let incumbent = abs(all[current].timelineIn.doubleValue - expectedStart)
            return candidate < incumbent
        }

        /// Positions of windows in the start buckets adjacent to ``expectedStart``.
        ///
        /// A window within ``bucketSeconds`` of `expectedStart` always falls in one of the three
        /// buckets scanned here, and both callers discard anything outside that tolerance, so
        /// there is nothing to gain from falling back to every window.
        private func candidatePositions(
            clipName: String,
            expectedStart: Double
        ) -> [Int] {
            let center = Self.bucket(for: expectedStart)
            let buckets = [center - 1, center, center + 1]

            if !clipName.isEmpty, let nameMap = byNameAndBucket[clipName] {
                var hits: [Int] = []
                for bucket in buckets {
                    if let group = nameMap[bucket] {
                        hits.append(contentsOf: group)
                    }
                }
                if !hits.isEmpty { return hits }
            }

            // Empty names / unmatched names: search nearby start buckets across all names.
            var hits: [Int] = []
            for bucket in buckets {
                if let group = byBucket[bucket] {
                    hits.append(contentsOf: group)
                }
            }
            return hits
        }

        private static func bucket(for start: Double) -> Int {
            Int((start / bucketSeconds).rounded())
        }
    }
}
