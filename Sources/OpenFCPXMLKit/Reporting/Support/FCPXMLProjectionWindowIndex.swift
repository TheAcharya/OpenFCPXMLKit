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
    struct ProjectionWindowIndex: Sendable {
        /// Start-time bucket size in seconds (matches ±0.05s matcher tolerance).
        private static let bucketSeconds: Double = 0.05

        private let byNameAndBucket: [String: [Int: [MediaUsageWindow]]]
        private let byBucket: [Int: [MediaUsageWindow]]
        private let all: [MediaUsageWindow]

        init(windows: [MediaUsageWindow]) {
            self.all = windows
            var named: [String: [Int: [MediaUsageWindow]]] = [:]
            var buckets: [Int: [MediaUsageWindow]] = [:]

            for window in windows {
                let bucket = Self.bucket(for: window.timelineIn.doubleValue)
                buckets[bucket, default: []].append(window)
                let name = window.clipDisplayName ?? ""
                var nameBuckets = named[name] ?? [:]
                nameBuckets[bucket, default: []].append(window)
                named[name] = nameBuckets
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
            let candidates = candidateWindows(clipName: clipName, expectedStart: expectedStart)
            guard !candidates.isEmpty else { return nil }

            let filtered = candidates.filter { window in
                if preferAudio {
                    return window.channel.kind == .audio
                }
                if window.channel.kind == .video {
                    return true
                }
                // Keep audio-only usages when no video channel exists for this name/start.
                let tolerance = Self.bucketSeconds
                let hasVideoSibling = candidates.contains { sibling in
                    sibling.channel.kind == .video
                        && abs(sibling.timelineIn.doubleValue - expectedStart) < tolerance
                }
                return !hasVideoSibling
            }

            let pool = filtered.isEmpty ? candidates : filtered
            guard let best = pool.min(by: { lhs, rhs in
                abs(lhs.timelineIn.doubleValue - expectedStart)
                    < abs(rhs.timelineIn.doubleValue - expectedStart)
            }) else {
                return nil
            }
            guard abs(best.timelineIn.doubleValue - expectedStart) < Self.bucketSeconds else {
                return nil
            }
            return best
        }

        private func candidateWindows(
            clipName: String,
            expectedStart: Double
        ) -> [MediaUsageWindow] {
            let center = Self.bucket(for: expectedStart)
            let buckets = [center - 1, center, center + 1]

            if !clipName.isEmpty, let nameMap = byNameAndBucket[clipName] {
                var hits: [MediaUsageWindow] = []
                for bucket in buckets {
                    if let group = nameMap[bucket] {
                        hits.append(contentsOf: group)
                    }
                }
                if !hits.isEmpty { return hits }
            }

            // Empty names / unmatched names: search nearby start buckets, then fall back.
            var hits: [MediaUsageWindow] = []
            for bucket in buckets {
                if let group = byBucket[bucket] {
                    hits.append(contentsOf: group)
                }
            }
            if !hits.isEmpty { return hits }
            return all
        }

        private static func bucket(for start: Double) -> Int {
            Int((start / bucketSeconds).rounded())
        }
    }
}
