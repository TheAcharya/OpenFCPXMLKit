//
//  FCPXMLTransitionsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Transitions report section from Projection (preferred) or Extraction.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds transition report rows from a timeline element.
    enum TransitionsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            resources: (any OFKXMLElement)? = nil
        ) async -> TransitionsReportSection {
            if let projection,
               projection.clipAnnotations.contains(where: { $0.transition != nil })
            {
                let rows = rowsFromProjection(
                    projection,
                    timeline: timeline,
                    resources: resources,
                    timecodeFormat: timecodeFormat
                )
                return TransitionsReportSection(rows: rows)
            }

            return await buildFromExtraction(
                from: timeline,
                scope: scope,
                timecodeFormat: timecodeFormat
            )
        }

        private static func buildFromExtraction(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            timecodeFormat: ReportTimecodeFormat
        ) async -> TransitionsReportSection {
            let extracted = await timeline.fcpExtract(
                types: [.transition],
                scope: scope
            )

            let rows = extracted
                .sortedByAbsoluteStartTimecode()
                .compactMap { transitionRow(from: $0, timecodeFormat: timecodeFormat) }

            return TransitionsReportSection(rows: rows)
        }

        private static func rowsFromProjection(
            _ projection: ReportProjectionContext,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> [TransitionReportRow] {
            var rows: [TransitionReportRow] = []
            for host in projection.clipAnnotations {
                guard let transition = host.transition else { continue }

                rows.append(
                    TransitionReportRow(
                        transition: transition.name,
                        category: ReportFormatting.transitionCategory(for: transition.placement),
                        isApple: ReportFormatting.appleCheckmark(
                            forAppleSupplied: transition.isAppleSupplied
                        ),
                        timelineIn: formatFraction(
                            transition.timelineIn,
                            on: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        ),
                        timelineOut: formatFraction(
                            transition.timelineOut,
                            on: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        ),
                        duration: formatFraction(
                            transition.duration,
                            on: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        )
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

        private static func transitionRow(
            from extracted: ExtractedElement,
            timecodeFormat: ReportTimecodeFormat
        ) -> TransitionReportRow? {
            guard let transition = extracted.element.fcpAsTransition,
                  let timelineIn = extracted.value(
                      forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
                  ),
                  let timelineOut = extracted.value(
                      forContext: .absoluteEndAsTimecode(frameRateSource: .mainTimeline)
                  ),
                  let duration = extracted.duration(frameRateSource: .mainTimeline)
            else { return nil }

            let name = transition.name ?? "Transition"

            return TransitionReportRow(
                transition: name,
                category: ReportFormatting.transitionCategory(
                    for: transition.spinePlacement(breadcrumbs: extracted.breadcrumbs)
                ),
                isApple: ReportFormatting.appleCheckmark(
                    forAppleSupplied: transition.isAppleSuppliedPrimaryEffect(in: extracted.resources)
                ),
                timelineIn: ReportFormatting.timecodeString(timelineIn, format: timecodeFormat),
                timelineOut: ReportFormatting.timecodeString(timelineOut, format: timecodeFormat),
                duration: ReportFormatting.timecodeString(duration, format: timecodeFormat)
            )
        }
    }
}
