//
//  FCPXMLSpeedChangeFormatting.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Display strings for retimed clips from RetimingSegment / TimeMap.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    enum SpeedChangeFormatting {
        /// Workbook effect/settings labels from a single ``RetimingSegment``.
        ///
        /// Signed percent is `±scale × 100` (negative when ``RetimingSegment/isReversed``).
        static func retimeDisplay(
            from segment: RetimingSegment
        ) -> (effect: String, settings: String)? {
            guard segment.timelineEnd.doubleValue > segment.timelineStart.doubleValue
                || abs(segment.scale) > .ulpOfOne
            else { return nil }

            let signed = segment.isReversed ? -segment.scale : segment.scale
            return formattedRetime(percent: signed * 100)
        }

        /// Aggregates consecutive segments into one workbook row (first→last media over
        /// remapped time inferred from each segment’s `scale`).
        static func retimeDisplay(
            aggregating segments: [RetimingSegment]
        ) -> (effect: String, settings: String)? {
            guard !segments.isEmpty else { return nil }
            if segments.count == 1 {
                return retimeDisplay(from: segments[0])
            }

            let first = segments[0]
            let last = segments[segments.count - 1]
            var remappedSpan = 0.0
            for segment in segments {
                let mediaDelta = abs(segment.mediaEnd.doubleValue - segment.mediaStart.doubleValue)
                guard segment.scale > .ulpOfOne else { continue }
                remappedSpan += mediaDelta / segment.scale
            }
            guard remappedSpan > .ulpOfOne else { return nil }

            let mediaSpan = last.mediaEnd.doubleValue - first.mediaStart.doubleValue
            return formattedRetime(percent: (mediaSpan / remappedSpan) * 100)
        }

        /// Workbook effect/settings labels derived from a clip ``TimeMap``.
        ///
        /// Converts via ``TimeMap/retimingSegments(clipOffset:clipDuration:)`` using the
        /// remapped map span as duration (no occupancy normalize distortion for %).
        static func retimeDisplay(from timeMap: TimeMap) -> (effect: String, settings: String)? {
            let points = Array(timeMap.timePoints)
            guard points.count >= 2 else { return nil }

            let first = points[0]
            let last = points[points.count - 1]
            let mapSpan = last.time - first.time
            guard abs(mapSpan.doubleValue) > .ulpOfOne else { return nil }

            let segments = timeMap.retimingSegments(
                clipOffset: .zero,
                clipDuration: mapSpan
            )
            return retimeDisplay(aggregating: segments)
        }

        /// `true` when a segment represents a non-identity speed change for worksheets.
        static func isSpeedChange(_ segment: RetimingSegment) -> Bool {
            segment.isReversed || abs(segment.scale - 1) > 0.000_1
        }

        private static func formattedRetime(percent: Double) -> (effect: String, settings: String) {
            let formatted = String(format: "%.1f%%", percent)
            return (effect: "Retime \(formatted)", settings: formatted)
        }
    }
}
