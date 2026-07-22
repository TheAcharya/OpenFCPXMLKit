//
//  FCPXMLKeywordsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Keywords report section from Projection (preferred) or Extraction.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds keyword report rows from a timeline element.
    enum KeywordsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            resources: (any OFKXMLElement)? = nil
        ) async -> KeywordsReportSection {
            if let projection,
               projection.clipAnnotations.contains(where: { !$0.keywords.isEmpty })
            {
                let rows = rowsFromProjection(
                    projection,
                    timeline: timeline,
                    resources: resources,
                    roleDisplayPreference: roleDisplayPreference,
                    timecodeFormat: timecodeFormat
                )
                // Prefer Projection when it produced rows; if annotations existed but
                // filtering left none (e.g. formatting failure), fall back to Extraction.
                if !rows.isEmpty {
                    return KeywordsReportSection(rows: rows)
                }
            }

            return await buildFromExtraction(
                from: timeline,
                scope: scope,
                roleDisplayPreference: roleDisplayPreference,
                timecodeFormat: timecodeFormat
            )
        }

        private static func buildFromExtraction(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) async -> KeywordsReportSection {
            let extracted = await timeline.fcpExtract(
                types: [.keyword],
                scope: .reportMainTimelineVisible(modifying: scope)
            )

            let rows = extracted
                .flatMap {
                    keywordRows(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    )
                }
                .sorted {
                    ReportFormatting.compareTimelinePositions(
                        $0.timelineIn,
                        $1.timelineIn,
                        format: timecodeFormat
                    ) == .orderedAscending
                }

            return KeywordsReportSection(rows: rows)
        }

        private static func rowsFromProjection(
            _ projection: ReportProjectionContext,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> [KeywordReportRow] {
            var rows: [KeywordReportRow] = []
            for host in projection.clipAnnotations {
                let roleDisplays = keywordRoleDisplays(
                    for: host,
                    roleDisplayPreference: roleDisplayPreference
                )

                for keyword in host.keywords {
                    // Match Extraction: keywords without a duration attribute are omitted.
                    guard keyword.duration != .zero else { continue }

                    let timelineIn = formatFraction(
                        keyword.timelineIn,
                        on: timeline,
                        resources: resources,
                        timecodeFormat: timecodeFormat
                    )
                    let timelineOut = formatFraction(
                        keyword.timelineOut,
                        on: timeline,
                        resources: resources,
                        timecodeFormat: timecodeFormat
                    )
                    let duration = formatFraction(
                        keyword.duration,
                        on: timeline,
                        resources: resources,
                        timecodeFormat: timecodeFormat
                    )
                    guard !timelineIn.isEmpty, !timelineOut.isEmpty, !duration.isEmpty else {
                        continue
                    }

                    for roleDisplay in roleDisplays {
                        rows.append(
                            KeywordReportRow(
                                keyword: keyword.keyword,
                                notes: keyword.notes,
                                timelineIn: timelineIn,
                                timelineOut: timelineOut,
                                duration: duration,
                                clipName: host.clipDisplayName,
                                roleSubrole: roleDisplay,
                                reel: keyword.reel,
                                scene: keyword.scene
                            )
                        )
                    }
                }
            }

            return rows.sorted {
                ReportFormatting.compareTimelinePositions(
                    $0.timelineIn,
                    $1.timelineIn,
                    format: timecodeFormat
                ) == .orderedAscending
            }
        }

        private static func keywordRoleDisplays(
            for host: ProjectedClipAnnotations,
            roleDisplayPreference: RoleDisplayPreference
        ) -> [String] {
            _ = roleDisplayPreference
            let displays = host.roles
                .map { ReportFormatting.mainRoleDisplay(from: $0.collapsingSubRole()) }
                .filter { !$0.isEmpty }
                .removingDuplicates()

            guard !displays.isEmpty else { return [""] }

            return displays.sorted { lhs, rhs in
                let lhsRank = RoleDisplayPreference.keywordSortRank(for: lhs)
                let rhsRank = RoleDisplayPreference.keywordSortRank(for: rhs)
                if lhsRank != rhsRank { return lhsRank < rhsRank }
                return lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
        }

        private static func formatFraction(
            _ fraction: Fraction,
            on timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> String {
            // Projection timeline math uses Double intermediates; format via real-time
            // seconds and sequence breadcrumbs (same pattern as Effects report timing).
            guard let timecode = try? timeline._fcpTimecode(
                fromRealTime: fraction.doubleValue,
                frameRateSource: .mainTimeline,
                breadcrumbs: [timeline],
                resources: resources
            ) else {
                return ""
            }
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }

        private static func keywordRows(
            from extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> [KeywordReportRow] {
            guard let timelineRange = extracted.visibleKeywordRangeOnMainTimeline()
            else { return [] }

            let keyword = extracted.element.fcpValue ?? ""
            let notes = extracted.element.fcpAsKeyword?.note ?? ""
            let metadata = extracted.ancestorClipContext()?.value(forContext: .metadata) ?? []
            let clipName = extracted.displayClipName()
            let roleDisplays = ReportFormatting.keywordRoleDisplays(
                for: extracted,
                roleDisplayPreference: roleDisplayPreference
            )

            let timelineInString = ReportFormatting.timecodeString(
                timelineRange.timelineIn,
                format: timecodeFormat
            )
            let timelineOutString = ReportFormatting.timecodeString(
                timelineRange.timelineOut,
                format: timecodeFormat
            )
            let durationString = ReportFormatting.timecodeString(
                timelineRange.duration,
                format: timecodeFormat
            )
            let reel = ReportFormatting.metadataString(from: metadata, key: .reel)
            let scene = ReportFormatting.metadataString(from: metadata, key: .scene)

            return roleDisplays.map { roleDisplay in
                KeywordReportRow(
                    keyword: keyword,
                    notes: notes,
                    timelineIn: timelineInString,
                    timelineOut: timelineOutString,
                    duration: durationString,
                    clipName: clipName,
                    roleSubrole: roleDisplay,
                    reel: reel,
                    scene: scene
                )
            }
        }
    }
}
