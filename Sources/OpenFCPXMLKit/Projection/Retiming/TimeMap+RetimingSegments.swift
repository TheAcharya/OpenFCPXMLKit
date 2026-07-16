//
//  TimeMap+RetimingSegments.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Builds RetimingSegment values from consecutive timeMap time points.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML.TimeMap {
    /// Converts consecutive ``TimePoint`` pairs into ``RetimingSegment`` values placed on the
    /// sequence timeline.
    ///
    /// Each pair `(a, b)` maps:
    /// - Timeline: normalized onto `[clipOffset, clipOffset + clipDuration)` using the
    ///   first→last remapped `time` span (so occupancy matches the spine `duration`)
    /// - Media: `a.originalTime` → `b.originalTime` (may reverse)
    /// - Scale: `abs(mediaDelta / remappedTimeDelta)` when remapped time advances
    ///
    /// Returns an empty array when fewer than two points exist or the remapped span is zero.
    func retimingSegments(
        clipOffset: Fraction,
        clipDuration: Fraction
    ) -> [FinalCutPro.FCPXML.RetimingSegment] {
        let points = Array(timePoints)
        guard points.count >= 2 else { return [] }

        let first = points[0]
        let last = points[points.count - 1]
        let mapSpan = last.time - first.time
        let mapSpanSeconds = mapSpan.doubleValue
        guard abs(mapSpanSeconds) > .ulpOfOne else { return [] }

        var segments: [FinalCutPro.FCPXML.RetimingSegment] = []
        segments.reserveCapacity(points.count - 1)

        for index in 0 ..< (points.count - 1) {
            let a = points[index]
            let b = points[index + 1]
            let remappedDelta = b.time - a.time
            let remappedDeltaSeconds = remappedDelta.doubleValue
            guard abs(remappedDeltaSeconds) > .ulpOfOne else { continue }

            // Double-backed placement avoids Int overflow when mixing conform-scaled
            // Fraction(double:) values with large literal FCPXML rationals.
            let startFraction = (a.time - first.time).doubleValue / mapSpanSeconds
            let endFraction = (b.time - first.time).doubleValue / mapSpanSeconds
            let base = clipOffset.doubleValue
            let span = clipDuration.doubleValue
            let timelineStart = Fraction(
                double: base + span * startFraction,
                decimalPrecision: FinalCutPro.FCPXML.ProjectionTiming.fractionPrecision
            )
            let timelineEnd = Fraction(
                double: base + span * endFraction,
                decimalPrecision: FinalCutPro.FCPXML.ProjectionTiming.fractionPrecision
            )

            // Ensure timeline advances forward for occupancy reporting.
            let (forwardStart, forwardEnd) = timelineStart.doubleValue <= timelineEnd.doubleValue
                ? (timelineStart, timelineEnd)
                : (timelineEnd, timelineStart)

            let mediaStart = a.originalTime
            let mediaEnd = b.originalTime
            let mediaDeltaSeconds = mediaEnd.doubleValue - mediaStart.doubleValue
            let isReversed = mediaEnd.doubleValue < mediaStart.doubleValue
            let scale = abs(mediaDeltaSeconds / remappedDeltaSeconds)

            segments.append(
                FinalCutPro.FCPXML.RetimingSegment(
                    timelineStart: forwardStart,
                    timelineEnd: forwardEnd,
                    mediaStart: mediaStart,
                    mediaEnd: mediaEnd,
                    scale: scale,
                    isReversed: isReversed
                )
            )
        }

        return segments
    }
}
