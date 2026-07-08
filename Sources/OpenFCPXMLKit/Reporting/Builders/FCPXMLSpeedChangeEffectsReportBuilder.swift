//
//  FCPXMLSpeedChangeEffectsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Speed Change Effects report section from FCPXML time maps.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Builds retime rows from clips that carry a `timeMap`.
    enum SpeedChangeEffectsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) async -> SpeedChangeEffectsReportSection {
            let extracted = await timeline.fcpExtract(
                types: .allClipCases,
                scope: .reportMainTimelineVisible(modifying: scope)
            )
            
            let rows = extracted
                .compactMap {
                    speedChangeRow(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    )
                }
                .sorted { sortSpeedChangeRows($0, $1, timecodeFormat: timecodeFormat) }
            
            return SpeedChangeEffectsReportSection(rows: rows)
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
