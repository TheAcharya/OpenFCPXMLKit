//
//  FCPXMLEffectsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Video & Audio Effects report section from Projection (preferred) or Extraction.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds video and audio effect report rows from a timeline element.
    enum EffectsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            sequence: Sequence? = nil,
            resources: (any OFKXMLElement)? = nil
        ) async -> EffectsReportSection {
            if let projection,
               projection.clipAnnotations.contains(where: { !$0.effects.isEmpty })
            {
                let rows = rowsFromProjection(
                    projection,
                    timeline: timeline,
                    resources: resources,
                    roleDisplayPreference: roleDisplayPreference,
                    timecodeFormat: timecodeFormat
                )
                return EffectsReportSection(rows: rows)
            }

            return await buildFromExtraction(
                from: timeline,
                scope: scope,
                roleDisplayPreference: roleDisplayPreference,
                timecodeFormat: timecodeFormat,
                projection: projection,
                sequence: sequence
            )
        }

        private static func buildFromExtraction(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat,
            projection: ReportProjectionContext?,
            sequence: Sequence?
        ) async -> EffectsReportSection {
            let extractedEffects = await EffectsExtractionPreset().perform(
                on: timeline,
                scope: scope
            )
            let windows = projection?.windows ?? []
            let windowIndex = windows.isEmpty ? nil : ProjectionWindowIndex(windows: windows)

            let rows = extractedEffects
                .filter { EffectsReportPolicy.shouldInclude($0) }
                .compactMap { effect -> EffectReportRow? in
                    guard var row = EffectReportRow(
                        from: effect,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    ) else {
                        return nil
                    }
                    if let windowIndex {
                        row = EffectsReportTiming.enriching(
                            row,
                            effect: effect,
                            windows: windows,
                            windowIndex: windowIndex,
                            timecodeFormat: timecodeFormat,
                            sequence: sequence
                        )
                    }
                    return row
                }
                .removingDuplicateEffectRows()
                .sorted { sortEffectRows($0, $1, timecodeFormat: timecodeFormat) }

            return EffectsReportSection(rows: rows)
        }

        private static func rowsFromProjection(
            _ projection: ReportProjectionContext,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> [EffectReportRow] {
            var rows: [EffectReportRow] = []
            for host in projection.clipAnnotations {
                let sortedEffects = host.effects.sorted {
                    if $0.timelineIn != $1.timelineIn {
                        return $0.timelineIn.doubleValue < $1.timelineIn.doubleValue
                    }
                    return $0.sortOrder < $1.sortOrder
                }
                for effect in sortedEffects {
                    rows.append(
                        EffectReportRow(
                            effect: effect.name,
                            settings: ReportFormatting.effectSettingsDisplay(for: effect.settings),
                            enabled: ReportFormatting.enabledCheckmark(forEnabled: effect.enabled),
                            isApple: ReportFormatting.appleCheckmark(
                                forAppleSupplied: effect.isAppleSupplied
                            ),
                            clipName: host.clipDisplayName,
                            roleSubrole: ReportFormatting.effectRoleSubrole(
                                kind: effect.kind,
                                hostElementType: host.hostElementType,
                                roles: host.roles,
                                roleDisplayPreference: roleDisplayPreference
                            ),
                            timelineIn: formatFraction(
                                effect.timelineIn,
                                on: timeline,
                                resources: resources,
                                timecodeFormat: timecodeFormat
                            ),
                            timelineOut: formatFraction(
                                effect.timelineOut,
                                on: timeline,
                                resources: resources,
                                timecodeFormat: timecodeFormat
                            )
                        )
                    )
                }
            }

            return rows
                .removingDuplicateEffectRows()
                .sorted { sortEffectRows($0, $1, timecodeFormat: timecodeFormat) }
        }

        private static func formatFraction(
            _ fraction: Fraction,
            on timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> String {
            guard let timecode = try? timeline._fcpTimecode(
                fromRational: fraction,
                frameRateSource: .mainTimeline,
                breadcrumbs: [],
                resources: resources
            ) else {
                return ""
            }
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }

        private static func sortEffectRows(
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

            let effectCompare = lhs.effect.localizedStandardCompare(rhs.effect)
            if effectCompare != .orderedSame {
                return effectCompare == .orderedAscending
            }

            return lhs.settings.localizedStandardCompare(rhs.settings) == .orderedAscending
        }
    }
}

private extension Array where Element == FinalCutPro.FCPXML.EffectReportRow {
    func removingDuplicateEffectRows() -> [FinalCutPro.FCPXML.EffectReportRow] {
        var seen = Set<String>()
        return filter { row in
            let key = [
                row.effect,
                row.settings,
                row.enabled,
                row.isApple,
                row.clipName,
                row.roleSubrole,
                row.timelineIn,
                row.timelineOut
            ].joined(separator: "\u{1F}")
            return seen.insert(key).inserted
        }
    }
}
