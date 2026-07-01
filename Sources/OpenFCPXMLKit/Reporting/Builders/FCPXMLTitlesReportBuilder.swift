//
//  FCPXMLTitlesReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Titles & Generators report section from FCPXML.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds title and generator report rows from a timeline element.
    enum TitlesReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) async -> TitlesReportSection {
            let extracted = await TitlesExtractionPreset().perform(
                on: timeline,
                scope: scope
            )
            
            let rows = extracted
                .sortedByAbsoluteStartTimecode()
                .compactMap { titleRow(from: $0, roleDisplayPreference: roleDisplayPreference) }
            
            return TitlesReportSection(rows: rows)
        }
        
        private static func titleRow(
            from extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
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
                timelineIn: ReportFormatting.timecodeString(timelineIn),
                timelineOut: ReportFormatting.timecodeString(timelineOut),
                duration: ReportFormatting.timecodeString(duration),
                font: title.displayFontSpecifications(),
                titleText: title.concatenatedDisplayText()
            )
        }
    }
}
