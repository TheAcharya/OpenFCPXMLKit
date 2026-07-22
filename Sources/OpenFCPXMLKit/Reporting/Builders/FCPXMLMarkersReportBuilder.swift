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
            includeMarkersOutsideClipBoundaries: Bool = false,
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
                    includeMarkersOutsideClipBoundaries: includeMarkersOutsideClipBoundaries,
                    roleDisplayPreference: roleDisplayPreference,
                    timecodeFormat: timecodeFormat
                )
                // Prefer Projection when it produced rows; if annotations existed but
                // filtering left none (e.g. formatting failure), fall back to Extraction.
                if !rows.isEmpty {
                    return MarkersReportSection(
                        rows: rows,
                        showsHiddenColumn: includeMarkersOutsideClipBoundaries
                    )
                }
            }

            return await buildFromExtraction(
                from: timeline,
                scope: scope,
                includeChapterMarkers: includeChapterMarkers,
                includeMarkersOutsideClipBoundaries: includeMarkersOutsideClipBoundaries,
                roleDisplayPreference: roleDisplayPreference,
                timecodeFormat: timecodeFormat
            )
        }

        private static func buildFromExtraction(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            includeChapterMarkers: Bool,
            includeMarkersOutsideClipBoundaries: Bool,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat
        ) async -> MarkersReportSection {
            let extracted = await timeline.fcpExtract(preset: MarkersExtractionPreset(), scope: scope)

            let filtered = extracted.filter { marker in
                if case .chapter = marker.configuration {
                    if !includeChapterMarkers { return false }
                }
                let isOutside = isOutsideClipBoundaries(extracted: marker)
                if isOutside, !includeMarkersOutsideClipBoundaries {
                    return false
                }
                return true
            }

            let rows = filtered
                .sortedByAbsoluteStartTimecode()
                .flatMap {
                    markerRows(
                        from: $0,
                        roleDisplayPreference: roleDisplayPreference,
                        timecodeFormat: timecodeFormat,
                        includeHiddenColumn: includeMarkersOutsideClipBoundaries
                    )
                }

            return MarkersReportSection(
                rows: rows,
                showsHiddenColumn: includeMarkersOutsideClipBoundaries
            )
        }

        private static func rowsFromProjection(
            _ projection: ReportProjectionContext,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            includeChapterMarkers: Bool,
            includeMarkersOutsideClipBoundaries: Bool,
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
                    if marker.isOutsideClipBoundaries, !includeMarkersOutsideClipBoundaries {
                        continue
                    }

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
                                sourcePosition: sourcePosition,
                                isHidden: marker.isOutsideClipBoundaries
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

        private static func isOutsideClipBoundaries(extracted: ExtractedMarker) -> Bool {
            let host = extracted.ancestorClipElement()
            return MarkerClipBoundary.isOutsideHostMediaRange(
                markerStart: extracted.model.start,
                hostStart: host?.fcpStart,
                hostDuration: host?.fcpDuration
            )
        }

        /// Builds one report row per host component role.
        ///
        /// A marker on a clip carrying both video and audio yields two rows (for example
        /// `Video` and `Dialogue`); single-component hosts yield one row.
        private static func markerRows(
            from extracted: ExtractedMarker,
            roleDisplayPreference: RoleDisplayPreference,
            timecodeFormat: ReportTimecodeFormat,
            includeHiddenColumn: Bool
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
            let isHidden = isOutsideClipBoundaries(extracted: extracted)

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
                    sourcePosition: sourcePosition,
                    isHidden: includeHiddenColumn ? isHidden : false
                )
            }
        }
    }
}
