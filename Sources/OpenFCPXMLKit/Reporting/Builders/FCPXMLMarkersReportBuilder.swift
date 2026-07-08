//
//  FCPXMLMarkersReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Markers report section from FCPXML.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds marker report rows from a timeline element.
    enum MarkersReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            includeChapterMarkers: Bool,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) async -> MarkersReportSection {
            let extracted = await timeline.fcpExtract(preset: MarkersExtractionPreset(), scope: scope)
            
            let filtered = extracted.filter { marker in
                if case .chapter = marker.configuration {
                    return includeChapterMarkers
                }
                return true
            }
            
            let rows = filtered
                .sortedByAbsoluteStartTimecode()
                .flatMap {
                    markerRows(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat
                    )
                }
            
            return MarkersReportSection(rows: rows)
        }
        
        /// Builds one report row per host component role.
        ///
        /// A marker on a clip carrying both video and audio yields two rows (for example
        /// `Video` and `Dialogue`); single-component hosts yield one row.
        private static func markerRows(
            from extracted: ExtractedMarker,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> [MarkerReportRow] {
            guard let positionTimecode = extracted.value(
                forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
            ) else { return [] }
            
            let sourcePosition: String
            if let sourceTimecode = try? extracted.element._fcpTimecode(
                fromRational: extracted.model.start,
                frameRateSource: .localToElement,
                breadcrumbs: extracted.breadcrumbs,
                resources: extracted.resources
            ) {
                sourcePosition = ReportFormatting.timecodeString(
                    sourceTimecode,
                    format: timecodeFormat
                )
            } else {
                sourcePosition = ""
            }
            
            let metadata = extracted.ancestorClipContext()?.value(forContext: .metadata) ?? []
            
            let roleDisplays = ReportFormatting.markerRoleDisplays(
                for: extracted,
                roleDisplayPreference: roleDisplayPreference
            )
            let effectiveRoleDisplays = roleDisplays.isEmpty ? [""] : roleDisplays
            
            return effectiveRoleDisplays.map { roleDisplay in
                MarkerReportRow(
                    markerName: extracted.name,
                    type: ReportFormatting.markerReportType(for: extracted.configuration),
                    notes: extracted.note ?? "",
                    position: ReportFormatting.timecodeString(
                        positionTimecode,
                        format: timecodeFormat
                    ),
                    clipName: extracted.displayClipName(),
                    roleSubrole: roleDisplay,
                    reel: ReportFormatting.metadataString(from: metadata, key: .reel),
                    scene: ReportFormatting.metadataString(from: metadata, key: .scene),
                    sourcePosition: sourcePosition
                )
            }
        }
    }
}
