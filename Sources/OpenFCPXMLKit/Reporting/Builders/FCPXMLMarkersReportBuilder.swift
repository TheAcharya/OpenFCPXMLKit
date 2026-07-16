//
//  FCPXMLMarkersReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Markers report section from Projection (preferred) or Extraction.
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
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            resources: (any OFKXMLElement)? = nil
        ) async -> MarkersReportSection {
            if let projection,
               projection.clipAnnotations.contains(where: { !$0.markers.isEmpty })
            {
                let rows = rowsFromProjection(
                    projection,
                    timeline: timeline,
                    resources: resources,
                    includeChapterMarkers: includeChapterMarkers,
                    roleDisplayPreference: roleDisplayPreference,
                    timecodeFormat: timecodeFormat
                )
                return MarkersReportSection(rows: rows)
            }

            return await buildFromExtraction(
                from: timeline,
                scope: scope,
                includeChapterMarkers: includeChapterMarkers,
                roleDisplayPreference: roleDisplayPreference,
                timecodeFormat: timecodeFormat
            )
        }

        private static func buildFromExtraction(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            includeChapterMarkers: Bool,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
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

        private static func rowsFromProjection(
            _ projection: ReportProjectionContext,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            includeChapterMarkers: Bool,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) -> [MarkerReportRow] {
            var rows: [MarkerReportRow] = []
            for host in projection.clipAnnotations {
                let roleDisplays = markerRoleDisplays(
                    for: host,
                    roleDisplayPreference: roleDisplayPreference
                )
                let effectiveRoles = roleDisplays.isEmpty ? [""] : roleDisplays

                for marker in host.markers {
                    if marker.kind == .chapter, !includeChapterMarkers { continue }

                    let position = formatFraction(
                        marker.timelinePosition,
                        on: timeline,
                        resources: resources,
                        timecodeFormat: timecodeFormat
                    )
                    let sourcePosition = formatFraction(
                        marker.sourcePosition,
                        on: timeline,
                        resources: resources,
                        timecodeFormat: timecodeFormat
                    )

                    for roleDisplay in effectiveRoles {
                        rows.append(
                            MarkerReportRow(
                                markerName: marker.name,
                                type: markerReportType(for: marker.kind),
                                notes: marker.notes,
                                position: position,
                                clipName: host.clipDisplayName,
                                roleSubrole: roleDisplay,
                                reel: marker.reel,
                                scene: marker.scene,
                                sourcePosition: sourcePosition
                            )
                        )
                    }
                }
            }

            return rows.sorted {
                ReportFormatting.compareTimelinePositions(
                    $0.position,
                    $1.position,
                    format: timecodeFormat
                ) == .orderedAscending
            }
        }

        private static func markerReportType(for kind: WindowMarkerKind) -> MarkerReportType {
            switch kind {
            case .standard: return .standard
            case .incompleteToDo: return .incompleteToDo
            case .completedToDo: return .completedToDo
            case .chapter: return .chapter
            case .analysis: return .analysis
            }
        }

        private static func markerRoleDisplays(
            for host: ProjectedClipAnnotations,
            roleDisplayPreference: RoleDisplayPreference
        ) -> [String] {
            if host.hostElementType == ElementType.title.rawValue {
                return ["Titles"]
            }

            if host.carriesVideo, host.carriesAudio {
                let videoDisplay = ReportFormatting.firstMainRoleDisplay(
                    in: host.roles,
                    ofType: .video
                ) ?? "Video"
                let audioDisplay = ReportFormatting.firstMainRoleDisplay(
                    in: host.roles,
                    ofType: .audio
                ) ?? "Dialogue"
                return [videoDisplay, audioDisplay]
            }

            if let preferred = roleDisplayPreference.preferredRole(
                from: host.roles,
                context: .markers
            ) ?? host.roles.first {
                let display = ReportFormatting.mainRoleDisplay(from: preferred.collapsingSubRole())
                return display.isEmpty ? [] : [display]
            }
            return []
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
