//
//  FCPXMLEffectsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Video & Audio Effects report section from FCPXML.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Builds video and audio effect report rows from a timeline element.
    enum EffectsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) async -> EffectsReportSection {
            let extractedEffects = await EffectsExtractionPreset().perform(
                on: timeline,
                scope: scope
            )
            
            let rows = extractedEffects
                .filter { EffectsReportPolicy.shouldInclude($0) }
                .compactMap {
                    EffectReportRow(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference
                    )
                }
                .removingDuplicateEffectRows()
                .sorted(by: sortEffectRows)
            
            return EffectsReportSection(rows: rows)
        }
        
        private static func sortEffectRows(
            _ lhs: EffectReportRow,
            _ rhs: EffectReportRow
        ) -> Bool {
            let timelineCompare = lhs.timelineIn.localizedStandardCompare(rhs.timelineIn)
            if timelineCompare != .orderedSame {
                return timelineCompare == .orderedAscending
            }
            
            let durationCompare = rhs.timelineOut.localizedStandardCompare(lhs.timelineOut)
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
