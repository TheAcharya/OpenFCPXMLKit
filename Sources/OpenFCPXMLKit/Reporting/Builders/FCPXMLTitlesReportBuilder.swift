//
//  FCPXMLTitlesReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Titles & Generators report section from Projection (preferred) or Extraction.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds title and generator report rows from a timeline element.
    enum TitlesReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            resources: (any OFKXMLElement)? = nil
        ) async -> TitlesReportSection {
            if let projection,
               projection.clipAnnotations.contains(where: { $0.title != nil })
            {
                let rows = rowsFromProjection(
                    projection,
                    timeline: timeline,
                    resources: resources,
                    timecodeFormat: timecodeFormat
                )
                return TitlesReportSection(rows: rows)
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
        ) async -> TitlesReportSection {
            let extracted = await TitlesExtractionPreset().perform(
                on: timeline,
                scope: scope
            )

            let rows = extracted
                .sortedByAbsoluteStartTimecode()
                .compactMap {
                    titleRow(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    )
                }

            return TitlesReportSection(rows: rows)
        }

        private static func rowsFromProjection(
            _ projection: ReportProjectionContext,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> [TitleReportRow] {
            var rows: [TitleReportRow] = []
            for host in projection.clipAnnotations {
                guard let title = host.title else { continue }

                rows.append(
                    TitleReportRow(
                        clipName: host.clipDisplayName,
                        enabled: ReportFormatting.enabledCheckmark(forEnabled: title.enabled),
                        isApple: ReportFormatting.appleCheckmarkForTitle(
                            isAppleSupplied: title.isAppleSupplied
                        ),
                        roleSubrole: ReportFormatting.titleRoleSubrole(from: host.roles),
                        timelineIn: formatFraction(
                            title.timelineIn,
                            on: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        ),
                        timelineOut: formatFraction(
                            title.timelineOut,
                            on: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        ),
                        duration: formatFraction(
                            title.duration,
                            on: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        ),
                        font: title.font,
                        titleText: title.titleText
                    )
                )
            }

            return rows.sorted {
                ReportFormatting.compareTimelinePositions(
                    $0.timelineIn,
                    $1.timelineIn,
                    format: timecodeFormat
                ) == .orderedAscending
            }
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

        private static func titleRow(
            from extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> TitleReportRow? {
            guard let title = extracted.element.fcpAsTitle,
                  let timelineIn = extracted.value(
                      forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
                  ),
                  let timelineOut = extracted.value(
                      forContext: .absoluteEndAsTimecode(frameRateSource: .mainTimeline)
                  ),
                  let duration = extracted.duration(frameRateSource: .mainTimeline)
            else { return nil }

            return TitleReportRow(
                clipName: extracted.displayClipName(),
                enabled: ReportFormatting.enabledCheckmark(for: extracted.element),
                isApple: ReportFormatting.appleCheckmarkForTitle(
                    isAppleSupplied: title.isAppleSuppliedEffect(resources: extracted.resources)
                ),
                roleSubrole: ReportFormatting.titleRoleSubrole(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                ),
                timelineIn: ReportFormatting.timecodeString(timelineIn, format: timecodeFormat),
                timelineOut: ReportFormatting.timecodeString(timelineOut, format: timecodeFormat),
                duration: ReportFormatting.timecodeString(duration, format: timecodeFormat),
                font: title.displayFontSpecifications(),
                titleText: title.concatenatedDisplayText()
            )
        }
    }
}
