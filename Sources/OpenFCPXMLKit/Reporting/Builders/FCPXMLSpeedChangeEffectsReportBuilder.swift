//
//  FCPXMLSpeedChangeEffectsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Builds the Speed Change Effects report section from Projection retiming (with Extraction fallback).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds retime rows from projected ``RetimingSegment``s when available,
    /// otherwise from clips that carry a `timeMap` (formatted via Projection math).
    enum SpeedChangeEffectsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            sequence: Sequence? = nil
        ) async -> SpeedChangeEffectsReportSection {
            let extracted = await timeline.fcpExtract(
                types: .allClipCases,
                scope: .reportMainTimelineVisible(modifying: scope)
            )

            let extractionRows = extracted
                .compactMap {
                    speedChangeRow(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    )
                }

            let rows: [EffectReportRow]
            if let projection, !projection.windows.isEmpty {
                let projectedRows = rowsFromProjection(
                    windows: projection.windows,
                    extractionByName: Dictionary(grouping: extractionRows, by: \.clipName),
                    timecodeFormat: timecodeFormat,
                    sequence: sequence
                )
                rows = projectedRows.isEmpty ? extractionRows : projectedRows
            } else {
                rows = extractionRows
            }

            return SpeedChangeEffectsReportSection(
                rows: rows.sorted { sortSpeedChangeRows($0, $1, timecodeFormat: timecodeFormat) }
            )
        }

        /// Groups non-identity projected windows into one workbook row per clip usage.
        private static func rowsFromProjection(
            windows: [MediaUsageWindow],
            extractionByName: [String: [EffectReportRow]],
            timecodeFormat: ReportTimecodeFormat,
            sequence: Sequence?
        ) -> [EffectReportRow] {
            let changed = windows.filter { SpeedChangeFormatting.isSpeedChange($0.retiming) }
            guard !changed.isEmpty else { return [] }

            let preferred = changed.filter { $0.channel.kind == .video }
            let pool = preferred.isEmpty ? changed : preferred

            let keyed = Dictionary(grouping: pool) { window -> String in
                let name = window.clipDisplayName ?? ""
                return "\(name)|\(window.channel.resourceID)"
            }

            return keyed.values.compactMap { group -> EffectReportRow? in
                let ordered = group.sorted {
                    $0.timelineIn.doubleValue < $1.timelineIn.doubleValue
                }
                let segments = ordered.map(\.retiming)
                guard let retime = SpeedChangeFormatting.retimeDisplay(aggregating: segments)
                else { return nil }

                let timelineIn = ordered.map(\.timelineIn.doubleValue).min() ?? 0
                let timelineOut = ordered.map(\.timelineOut.doubleValue).max() ?? timelineIn
                let clipName = ordered.first?.clipDisplayName ?? ""
                let extractedMatch = extractionByName[clipName]?.first

                return EffectReportRow(
                    effect: retime.effect,
                    settings: retime.settings,
                    enabled: extractedMatch?.enabled ?? "",
                    isApple: extractedMatch?.isApple ?? "",
                    clipName: clipName,
                    roleSubrole: extractedMatch?.roleSubrole ?? "",
                    timelineIn: timelineString(
                        seconds: timelineIn,
                        fallback: extractedMatch?.timelineIn,
                        timecodeFormat: timecodeFormat,
                        sequence: sequence
                    ),
                    timelineOut: timelineString(
                        seconds: timelineOut,
                        fallback: extractedMatch?.timelineOut,
                        timecodeFormat: timecodeFormat,
                        sequence: sequence
                    )
                )
            }
        }

        private static func timelineString(
            seconds: TimeInterval,
            fallback: String?,
            timecodeFormat: ReportTimecodeFormat,
            sequence: Sequence?
        ) -> String {
            // Prefer Extraction-formatted strings; sequence timecode without breadcrumbs
            // can fail hard on some samples.
            if let fallback, !fallback.isEmpty {
                return fallback
            }
            guard let sequence else { return "" }
            guard let timecode = try? sequence.element._fcpTimecode(
                fromRealTime: seconds,
                frameRateSource: .mainTimeline,
                breadcrumbs: [sequence.element],
                resources: sequence.element.parentElement?.parentElement // may be nil
            ) else {
                return ""
            }
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }

        private static func speedChangeRow(
            from extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> EffectReportRow? {
            guard let timeMap = extracted.element.fcpTimeMap,
                  let retime = SpeedChangeFormatting.retimeDisplay(from: timeMap),
                  let timelineIn = extracted.value(
                      forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
                  ),
                  let timelineOut = extracted.value(
                      forContext: .absoluteEndAsTimecode(frameRateSource: .mainTimeline)
                  )
            else { return nil }

            return EffectReportRow(
                effect: retime.effect,
                settings: retime.settings,
                enabled: "",
                isApple: "",
                clipName: extracted.displayClipName(),
                roleSubrole: ReportFormatting.markerRoleSubrole(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                ),
                timelineIn: ReportFormatting.timecodeString(timelineIn, format: timecodeFormat),
                timelineOut: ReportFormatting.timecodeString(timelineOut, format: timecodeFormat)
            )
        }

        private static func sortSpeedChangeRows(
            _ lhs: EffectReportRow,
            _ rhs: EffectReportRow,
            timecodeFormat: ReportTimecodeFormat
        ) -> Bool {
            let timelineCompare = ReportFormatting.compareTimelinePositions(
                lhs.timelineIn,
                rhs.timelineIn,
                format: timecodeFormat
            )
            if timelineCompare != .orderedSame {
                return timelineCompare == .orderedAscending
            }

            let durationCompare = ReportFormatting.compareTimelinePositions(
                rhs.timelineOut,
                lhs.timelineOut,
                format: timecodeFormat
            )
            if durationCompare != .orderedSame {
                return durationCompare == .orderedAscending
            }

            let clipCompare = lhs.clipName.localizedStandardCompare(rhs.clipName)
            if clipCompare != .orderedSame {
                return clipCompare == .orderedAscending
            }

            return lhs.settings.localizedStandardCompare(rhs.settings) == .orderedAscending
        }
    }
}

private extension OFKXMLElement {
    var fcpTimeMap: FinalCutPro.FCPXML.TimeMap? {
        firstChild(whereFCPElement: .timeMap)
    }
}
