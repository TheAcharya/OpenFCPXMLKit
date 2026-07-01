//
//  FCPXMLKeywordsReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Keywords report section from FCPXML.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds keyword report rows from a timeline element.
    enum KeywordsReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) async -> KeywordsReportSection {
            var keywordScope = scope
            keywordScope.includeDisabled = true
            keywordScope.occlusions = .allCases
            
            let extracted = await timeline.fcpExtract(
                types: [.keyword],
                scope: keywordScope
            )
            
            let rows = extracted
                .flatMap { keywordRows(from: $0, roleDisplayPreference: roleDisplayPreference) }
                .sorted {
                    $0.timelineIn.localizedStandardCompare($1.timelineIn) == .orderedAscending
                }
            
            return KeywordsReportSection(rows: rows)
        }
        
        private static func keywordRows(
            from extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
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
            
            let timelineInString = ReportFormatting.timecodeString(timelineRange.timelineIn)
            let timelineOutString = ReportFormatting.timecodeString(timelineRange.timelineOut)
            let durationString = ReportFormatting.timecodeString(timelineRange.duration)
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
