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

            let samplingByClipName = frameSamplingByClipName(from: extracted)

            let candidates = extracted
                .compactMap {
                    speedChangeCandidate(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    )
                }
            let extractionRows = candidates.map(\.row)

            let rows: [EffectReportRow]
            if let projection, !projection.windows.isEmpty {
                let projectedRows = rowsFromProjection(
                    windows: projection.windows,
                    extractionByName: Dictionary(grouping: candidates, by: \.row.clipName),
                    samplingByClipName: samplingByClipName,
                    timecodeFormat: timecodeFormat,
                    sequence: sequence
                )
                rows = projectedRows.isEmpty
                    ? extractionRows
                    : mergingExtractionRows(extractionRows, into: projectedRows)
            } else {
                rows = extractionRows
            }

            return SpeedChangeEffectsReportSection(
                rows: rows.sorted { sortSpeedChangeRows($0, $1, timecodeFormat: timecodeFormat) }
            )
        }

        /// Keeps Projection rows and appends Extraction-only retimes Projection missed
        /// (e.g. optical-flow `timeMap` on a spine `<clip>` wrapper).
        private static func mergingExtractionRows(
            _ extractionRows: [EffectReportRow],
            into projectedRows: [EffectReportRow]
        ) -> [EffectReportRow] {
            // Keyed by clip name *and* timeline position: one source reused several times
            // shares a clip name, so a name-only key discards every usage after the first.
            let projectedKeys = Set(projectedRows.map(usageKey))
            let extras = extractionRows.filter { !projectedKeys.contains(usageKey($0)) }
            guard !extras.isEmpty else { return projectedRows }
            return projectedRows + extras
        }

        private static func usageKey(_ row: EffectReportRow) -> String {
            "\(row.clipName)|\(row.timelineIn)"
        }

        /// Groups non-identity projected windows into one workbook row per clip usage.
        private static func rowsFromProjection(
            windows: [MediaUsageWindow],
            extractionByName: [String: [ExtractionCandidate]],
            samplingByClipName: [String: FrameSampling],
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

            return keyed.values.flatMap { bucket in
                usageRuns(in: bucket).compactMap { usage in
                    row(
                        forUsage: usage,
                        extractionByName: extractionByName,
                        samplingByClipName: samplingByClipName,
                        timecodeFormat: timecodeFormat,
                        sequence: sequence
                    )
                }
            }
        }

        /// Splits windows sharing a clip name and resource into separate timeline usages.
        ///
        /// A single retimed clip emits one window per composed retiming segment and per media
        /// channel, so those must collapse into one row. Windows of the same usage either
        /// overlap in timeline (parallel channels) or chain, where `mediaIn` continues the
        /// previous `mediaOut`. A further usage of the same source restarts at an unrelated
        /// media position, and that discontinuity is what separates the runs — timeline
        /// adjacency alone cannot, because consecutive clips are butt-cut.
        private static func usageRuns(in windows: [MediaUsageWindow]) -> [[MediaUsageWindow]] {
            let ordered = windows.sorted {
                let lhs = $0.timelineIn.doubleValue
                let rhs = $1.timelineIn.doubleValue
                if lhs != rhs { return lhs < rhs }
                return $0.mediaIn.doubleValue < $1.mediaIn.doubleValue
            }

            var runs: [[MediaUsageWindow]] = []
            var current: [MediaUsageWindow] = []
            var timelineEnd = 0.0
            var mediaEnd = 0.0

            for window in ordered {
                let start = window.timelineIn.doubleValue
                let overlapsTimeline = !current.isEmpty
                    && start < timelineEnd - usageContinuityTolerance
                let continuesMedia = !current.isEmpty
                    && abs(start - timelineEnd) <= usageContinuityTolerance
                    && abs(window.mediaIn.doubleValue - mediaEnd) <= usageContinuityTolerance

                if current.isEmpty || overlapsTimeline || continuesMedia {
                    current.append(window)
                    timelineEnd = max(timelineEnd, window.timelineOut.doubleValue)
                    mediaEnd = window.mediaOut.doubleValue
                    continue
                }

                runs.append(current)
                current = [window]
                timelineEnd = window.timelineOut.doubleValue
                mediaEnd = window.mediaOut.doubleValue
            }

            if !current.isEmpty { runs.append(current) }
            return runs
        }

        /// Well below one frame at every supported rate, yet above `Fraction` rounding noise.
        private static let usageContinuityTolerance: TimeInterval = 0.001

        private static func row(
            forUsage ordered: [MediaUsageWindow],
            extractionByName: [String: [ExtractionCandidate]],
            samplingByClipName: [String: FrameSampling],
            timecodeFormat: ReportTimecodeFormat,
            sequence: Sequence?
        ) -> EffectReportRow? {
            let segments = ordered.map(\.retiming)
            let clipName = ordered.first?.clipDisplayName ?? ""
            guard let retime = SpeedChangeFormatting.retimeDisplay(
                aggregating: segments,
                frameSampling: samplingByClipName[clipName] ?? .floor
            )
            else { return nil }

            let timelineIn = ordered.map(\.timelineIn.doubleValue).min() ?? 0
            let timelineOut = ordered.map(\.timelineOut.doubleValue).max() ?? timelineIn
            let extractedMatch = extractionMatch(
                in: extractionByName[clipName] ?? [],
                nearestTimelineStart: timelineIn
            )

            return EffectReportRow(
                effect: retime.effect,
                settings: retime.settings,
                enabled: extractedMatch?.enabled ?? "",
                isApple: extractedMatch?.isApple ?? "",
                clipName: clipName,
                roleSubrole: roleSubrole(for: ordered, extractedMatch: extractedMatch),
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
                    sequence: sequence,
                    asReportOut: true
                )
            )
        }

        /// Role ▸ Subrole for a projected run.
        ///
        /// Extraction resolves roles from the host element, which knows what media the clip
        /// carries, so it wins. Window roles only cover runs Extraction never matched — retimed
        /// hosts reached solely through Projection, such as inside an `mc-clip`.
        private static func roleSubrole(
            for ordered: [MediaUsageWindow],
            extractedMatch: EffectReportRow?
        ) -> String {
            if let extracted = extractedMatch?.roleSubrole, !extracted.isEmpty {
                return extracted
            }
            
            let isAudioOnly = ordered.allSatisfy { $0.channel.kind == .audio }
            return ReportFormatting.effectRoleSubrole(
                kind: isAudioOnly ? .filterAudio : .filterVideo,
                hostElementType: "",
                roles: ordered.flatMap(\.roles)
            )
        }

        /// Picks the Extraction row describing the same usage as a projected run.
        ///
        /// Clip names repeat whenever one source is used several times, so the candidate
        /// nearest the run's timeline start wins rather than whichever was extracted first.
        private static func extractionMatch(
            in candidates: [ExtractionCandidate],
            nearestTimelineStart start: TimeInterval
        ) -> EffectReportRow? {
            let positioned = candidates.compactMap { candidate -> (EffectReportRow, Double)? in
                guard let absoluteStart = candidate.absoluteStart else { return nil }
                return (candidate.row, abs(absoluteStart - start))
            }
            guard !positioned.isEmpty else { return candidates.first?.row }
            return positioned.min { $0.1 < $1.1 }?.0
        }

        private static func timelineString(
            seconds: TimeInterval,
            fallback: String?,
            timecodeFormat: ReportTimecodeFormat,
            sequence: Sequence?,
            asReportOut: Bool = false
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
            if asReportOut {
                return ReportFormatting.outTimecodeString(
                    fromExclusiveEnd: timecode,
                    format: timecodeFormat
                )
            }
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }

        /// An Extraction-derived retime row plus the timeline position that produced it,
        /// so repeated uses of one clip name can be told apart.
        private struct ExtractionCandidate {
            let row: EffectReportRow
            let absoluteStart: TimeInterval?
        }

        private static func speedChangeCandidate(
            from extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> ExtractionCandidate? {
            guard let timeMap = extracted.element.fcpTimeMap,
                  let retime = SpeedChangeFormatting.retimeDisplay(from: timeMap),
                  let timelineIn = extracted.value(
                      forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
                  ),
                  let timelineOut = extracted.value(
                      forContext: .absoluteEndAsTimecode(frameRateSource: .mainTimeline)
                  )
            else { return nil }

            // Prefer the outermost retimed host when both a wrapper `<clip>` and a nested
            // `<video>` carry a `timeMap` (common with optical-flow exports).
            if hasRetimedAncestorClipHost(extracted.element) {
                return nil
            }

            let row = EffectReportRow(
                effect: retime.effect,
                settings: retime.settings,
                enabled: "",
                isApple: "",
                clipName: extracted.displayClipName(),
                roleSubrole: ReportFormatting.retimeRoleSubrole(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                ),
                timelineIn: ReportFormatting.timecodeString(timelineIn, format: timecodeFormat),
                timelineOut: ReportFormatting.outTimecodeString(
                    fromExclusiveEnd: timelineOut,
                    inclusiveStart: timelineIn,
                    format: timecodeFormat
                )
            )

            return ExtractionCandidate(
                row: row,
                absoluteStart: extracted.value(forContext: .absoluteStart)
            )
        }

        private static func frameSamplingByClipName(
            from extracted: [ExtractedElement]
        ) -> [String: FrameSampling] {
            var result: [String: FrameSampling] = [:]
            for host in extracted {
                guard let timeMap: TimeMap = host.element.firstChild(whereFCPElement: .timeMap)
                else { continue }
                let name = host.displayClipName()
                let incoming = timeMap.frameSampling
                if let existing = result[name] {
                    result[name] = preferredFrameSampling(existing, incoming)
                } else {
                    result[name] = incoming
                }
            }
            return result
        }

        private static func preferredFrameSampling(
            _ existing: FrameSampling,
            _ incoming: FrameSampling
        ) -> FrameSampling {
            func rank(_ sampling: FrameSampling) -> Int {
                switch sampling {
                case .floor: return 0
                case .nearestNeighbor: return 1
                case .frameBlending: return 2
                case .opticalFlowClassic, .opticalFlowFRC: return 3
                case .opticalFlow: return 4
                }
            }
            return rank(incoming) >= rank(existing) ? incoming : existing
        }

        private static func hasRetimedAncestorClipHost(
            _ element: any OFKXMLElement
        ) -> Bool {
            let hostTypes: Set<ElementType> = [
                .clip, .assetClip, .syncClip, .refClip, .mcClip, .video, .audio
            ]
            return element.ancestorElements(includingSelf: false).contains { ancestor in
                guard let type = ancestor.fcpElementType, hostTypes.contains(type) else {
                    return false
                }
                return ancestor.firstChild(whereFCPElement: .timeMap) != nil
            }
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
