//
// FCPXMLRoleInventorySourceSpan.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Source media span consumed by retimed Role Inventory clips.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Resolves how much source media a retimed inventory clip consumes (Projection-first).
    ///
    /// A retimed clip covers a different amount of source than it occupies on the timeline:
    /// at 50% an eight-second clip plays four seconds of media, at 200% sixteen. Returns
    /// `nil` for clips at normal speed, where the timeline duration already is the source
    /// duration, so unretimed rows keep their existing values.
    enum RoleInventorySourceSpan {
        /// Seconds of source media consumed, or `nil` when the clip is not retimed.
        ///
        /// Scales the clip's own timeline duration by its speed rather than reading the
        /// projected media bounds: a `timeMap` commonly spans the whole source while the clip
        /// uses only a slice of it, so those bounds describe the map, not the clip.
        static func retimedMediaSeconds(
            for extracted: ExtractedElement,
            clipContext: ExtractedElement,
            timelineSeconds: Double,
            usesAudioTimelineBounds: Bool,
            projectionWindows: [MediaUsageWindow]?,
            windowIndex: ProjectionWindowIndex?
        ) -> Double? {
            guard timelineSeconds > Double.ulpOfOne else { return nil }

            if let projectionWindows, !projectionWindows.isEmpty {
                let index = windowIndex ?? ProjectionWindowIndex(windows: projectionWindows)
                let subjectWindows = matchingWindows(
                    for: extracted,
                    usesAudioTimelineBounds: usesAudioTimelineBounds,
                    index: index
                )
                let changed = subjectWindows.filter {
                    SpeedChangeFormatting.isSpeedChange($0.retiming)
                }
                if !changed.isEmpty {
                    let preferred = changed.filter { $0.channel.kind == .video }
                    let pool = preferred.isEmpty ? changed : preferred
                    if let ratio = SpeedChangeFormatting.averageScale(
                        of: pool.map(\.retiming)
                    ) {
                        return timelineSeconds * ratio
                    }
                }
            }

            guard let ratio = timeMapSpeedRatio(for: clipContext) else { return nil }
            return timelineSeconds * ratio
        }

        /// Extraction fallback: the clip's `timeMap` source-over-timeline ratio.
        private static func timeMapSpeedRatio(for clipContext: ExtractedElement) -> Double? {
            guard let timeMap: TimeMap = clipContext.element.firstChild(whereFCPElement: .timeMap)
            else { return nil }

            let points = Array(timeMap.timePoints)
            guard points.count >= 2 else { return nil }

            // Conform-scaled `time` values carry very large denominators, so an exact
            // rational subtraction here can overflow `Int` computing a common multiple.
            let mapSpan = ProjectionTiming.subtracting(
                points[points.count - 1].time,
                points[0].time
            ).doubleValue
            let valueSpan = ProjectionTiming.subtracting(
                points[points.count - 1].originalTime,
                points[0].originalTime
            ).doubleValue
            guard abs(mapSpan) > Double.ulpOfOne, abs(valueSpan) > Double.ulpOfOne else {
                return nil
            }

            let speed = abs(valueSpan / mapSpan)
            guard abs(speed - 1) > 0.000_1 else { return nil }
            return speed
        }

        private static func matchingWindows(
            for extracted: ExtractedElement,
            usesAudioTimelineBounds: Bool,
            index: ProjectionWindowIndex
        ) -> [MediaUsageWindow] {
            guard let absoluteStart = extracted.value(forContext: .absoluteStart) else {
                return []
            }

            let clipName = extracted.displayClipName()
            let expectedStart: TimeInterval
            if usesAudioTimelineBounds,
               extracted.element.fcpAudioDuration != nil
            {
                let clipStart = extracted.element.fcpStart?.doubleValue ?? 0
                let audioStart = extracted.element.fcpAudioStart?.doubleValue ?? clipStart
                expectedStart = absoluteStart + (audioStart - clipStart)
            } else {
                expectedStart = absoluteStart
            }

            return index.windows(
                clipName: clipName,
                expectedStart: expectedStart
            )
        }
    }
}
