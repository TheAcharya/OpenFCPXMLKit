//
//  TimelineOccupancyIndex.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Interval index over projected media usage windows.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Indexes ``MediaUsageWindow`` values for overlap queries and occupied-duration totals.
    ///
    /// Built once from a ``ReportProjectionContext`` (or any window list). Used by Summary
    /// for overlap-aware occupied media time and available to other report builders.
    public struct TimelineOccupancyIndex: Sendable, Equatable {
        /// Contiguous half-open timeline interval `[start, end)`.
        public struct Interval: Hashable, Sendable, Equatable {
            public var start: Double
            public var end: Double

            public init(start: Double, end: Double) {
                self.start = min(start, end)
                self.end = max(start, end)
            }

            /// Duration in seconds (`max(0, end - start)`).
            public var duration: Double { max(0, end - start) }

            /// `true` when this interval overlaps `[otherStart, otherEnd)`.
            public func overlaps(start otherStart: Double, end otherEnd: Double) -> Bool {
                start < otherEnd && otherStart < end
            }
        }

        /// Source windows (stable order preserved from input).
        public var windows: [MediaUsageWindow]

        public init(windows: [MediaUsageWindow]) {
            self.windows = windows
        }

        /// Convenience from a report projection context.
        public init(projection: ReportProjectionContext) {
            self.windows = projection.windows
        }

        /// Windows whose timeline range overlaps `[start, end)`.
        public func windows(
            overlapping start: Fraction,
            end: Fraction
        ) -> [MediaUsageWindow] {
            windows(overlapping: start.doubleValue, end: end.doubleValue)
        }

        /// Windows whose timeline range overlaps `[start, end)`.
        public func windows(
            overlapping start: Double,
            end: Double
        ) -> [MediaUsageWindow] {
            let queryStart = min(start, end)
            let queryEnd = max(start, end)
            return windows.filter { window in
                Interval(
                    start: window.timelineIn.doubleValue,
                    end: window.timelineOut.doubleValue
                ).overlaps(start: queryStart, end: queryEnd)
            }
        }

        /// Union length (seconds) of timeline occupancy for matching windows.
        ///
        /// Overlapping windows contribute only once to the total (overlap-aware).
        public func occupiedDuration(
            kind: MediaChannel.Kind? = nil,
            matching predicate: ((MediaUsageWindow) -> Bool)? = nil
        ) -> Double {
            let selected = windows.filter { window in
                if let kind, window.channel.kind != kind { return false }
                if let predicate, !predicate(window) { return false }
                return window.timelineOut.doubleValue > window.timelineIn.doubleValue
            }
            return Self.unionDuration(
                selected.map {
                    Interval(
                        start: $0.timelineIn.doubleValue,
                        end: $0.timelineOut.doubleValue
                    )
                }
            )
        }

        /// Sum of individual window durations without merging overlaps.
        public func summedDuration(
            kind: MediaChannel.Kind? = nil
        ) -> Double {
            windows.reduce(0) { partial, window in
                if let kind, window.channel.kind != kind { return partial }
                return partial + max(
                    0,
                    window.timelineOut.doubleValue - window.timelineIn.doubleValue
                )
            }
        }

        /// Merges intervals and returns total covered length in seconds.
        public static func unionDuration(_ intervals: [Interval]) -> Double {
            guard !intervals.isEmpty else { return 0 }
            let sorted = intervals
                .filter { $0.duration > .ulpOfOne }
                .sorted { $0.start < $1.start }
            guard var current = sorted.first else { return 0 }

            var total = 0.0
            for next in sorted.dropFirst() {
                if next.start <= current.end {
                    current.end = max(current.end, next.end)
                } else {
                    total += current.duration
                    current = next
                }
            }
            total += current.duration
            return total
        }
    }
}
