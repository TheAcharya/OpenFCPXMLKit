//
//  FCPXMLTransitionsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Transitions report section from FCPXML.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds transition report rows from a timeline element.
    enum TransitionsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope
        ) async -> TransitionsReportSection {
            let extracted = await timeline.fcpExtract(
                types: [.transition],
                scope: scope
            )
            
            let rows = extracted
                .sortedByAbsoluteStartTimecode()
                .compactMap { transitionRow(from: $0) }
            
            return TransitionsReportSection(rows: rows)
        }
        
        private static func transitionRow(
            from extracted: ExtractedElement
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
                timelineIn: ReportFormatting.timecodeString(timelineIn),
                timelineOut: ReportFormatting.timecodeString(timelineOut),
                duration: ReportFormatting.timecodeString(duration)
            )
        }
    }
}
