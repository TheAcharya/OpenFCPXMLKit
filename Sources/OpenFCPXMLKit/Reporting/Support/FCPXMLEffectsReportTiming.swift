//
//  FCPXMLEffectsReportTiming.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Overlays projected timeline spans onto Effects report rows.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Timing enrichment for Effects rows from ``MediaUsageWindow`` values.
    ///
    /// Extraction remains the source of effect identity, settings, roles, and Apple
    /// flags. When a projected window matches the host clip, timeline in/out strings
    /// are rewritten from the window span (same matching heuristic as Role Inventory).
    enum EffectsReportTiming {
        static func enriching(
            _ row: EffectReportRow,
            effect: ExtractedEffect,
            windows: [MediaUsageWindow],
            windowIndex: ProjectionWindowIndex? = nil,
            timecodeFormat: ReportTimecodeFormat,
            sequence: Sequence?
        ) -> EffectReportRow {
            guard !windows.isEmpty else { return row }
            guard let span = projectedSpan(
                for: effect,
                windows: windows,
                windowIndex: windowIndex
            ) else {
                return row
            }

            var enriched = row
            enriched.timelineIn = timelineString(
                seconds: span.start,
                fallback: row.timelineIn,
                timecodeFormat: timecodeFormat,
                sequence: sequence
            )
            enriched.timelineOut = timelineString(
                seconds: span.end,
                fallback: row.timelineOut,
                timecodeFormat: timecodeFormat,
                sequence: sequence
            )
            return enriched
        }

        private static func projectedSpan(
            for effect: ExtractedEffect,
            windows: [MediaUsageWindow],
            windowIndex: ProjectionWindowIndex?
        ) -> (start: TimeInterval, end: TimeInterval)? {
            let host = effect.timelineContext ?? effect.host
            guard let absoluteStart = host.value(forContext: .absoluteStart) else {
                return nil
            }

            let clipName = effect.host.displayClipName()
            let index = windowIndex ?? ProjectionWindowIndex(windows: windows)
            guard let best = index.match(
                clipName: clipName,
                expectedStart: absoluteStart,
                preferAudio: false
            ) else {
                return nil
            }

            return (best.timelineIn.doubleValue, best.timelineOut.doubleValue)
        }

        private static func timelineString(
            seconds: TimeInterval,
            fallback: String,
            timecodeFormat: ReportTimecodeFormat,
            sequence: Sequence?
        ) -> String {
            // Prefer keeping Extraction-formatted strings unless we can rebuild cleanly.
            // Window seconds are still useful when Extraction empty; otherwise leave as-is
            // so format/display parity with historical Effects output stays intact.
            guard let sequence else { return fallback }
            guard let timecode = try? sequence.element._fcpTimecode(
                fromRealTime: seconds,
                frameRateSource: .mainTimeline,
                breadcrumbs: [sequence.element],
                resources: nil
            ) else {
                return fallback
            }
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }
    }
}
