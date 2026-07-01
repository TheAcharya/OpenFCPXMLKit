//
//  FCPXMLRoleInventoryRowBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Maps collected clip components to Selected Roles inventory rows.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    enum RoleInventoryRowBuilder {
        static func row(from entry: RoleInventoryClipEntry) -> RoleClipReportRow? {
            let extracted = entry.extracted
            let element = extracted.element
            let resources = extracted.resources
            let breadcrumbs = extracted.breadcrumbs
            
            guard let span = RoleInventoryTimelineBounds.mainTimelineSpan(
                for: extracted,
                usesAudioTimelineBounds: entry.usesAudioTimelineBounds
            ) else { return nil }
            
            let adjustedSpan = span
            
            guard let rawTimelineIn = try? element._fcpTimecode(
                fromRealTime: adjustedSpan.start,
                frameRateSource: .mainTimeline,
                breadcrumbs: breadcrumbs,
                resources: resources
            )
            else { return nil }
            
            let spanDurationSeconds = max(0, adjustedSpan.end - adjustedSpan.start)
            let clipDuration: Timecode?
            let timelineOut: Timecode?
            let timelineIn: Timecode
            
            if entry.usesFlooredTimelineEnd,
               let rawDuration = try? element._fcpTimecode(
                   fromRealTime: spanDurationSeconds,
                   frameRateSource: .mainTimeline,
                   breadcrumbs: breadcrumbs,
                   resources: resources
               )
            {
                timelineIn = entry.usesFlooredTimelineStart
                    ? rawTimelineIn.roundedDown(toNearest: .frames)
                    : rawTimelineIn
                let flooredDuration = rawDuration.roundedDown(toNearest: .frames)
                clipDuration = flooredDuration
                timelineOut = try? timelineIn.adding(flooredDuration)
            } else if let convertedTimelineOut = try? element._fcpTimecode(
                fromRealTime: adjustedSpan.end,
                frameRateSource: .mainTimeline,
                breadcrumbs: breadcrumbs,
                resources: resources
            ) {
                timelineIn = rawTimelineIn
                timelineOut = convertedTimelineOut
                if let duration = try? element._fcpTimecode(
                    fromRealTime: spanDurationSeconds,
                    frameRateSource: .mainTimeline,
                    breadcrumbs: breadcrumbs,
                    resources: resources
                ) {
                    clipDuration = duration
                } else {
                    clipDuration = convertedTimelineOut - timelineIn
                }
            } else {
                return nil
            }
            
            guard let timelineOut, let clipDuration else { return nil }
            
            let clipContext = inventoryClipContext(for: extracted)
            let metadata = clipContext.value(forContext: .metadata)
            let sourceTimes = sourceTimecodes(for: clipContext, clipDuration: clipDuration)
            
            return RoleClipReportRow(
                roleSubrole: entry.roleSubroleField,
                clipName: displayClipName(for: entry),
                category: entry.category.workbookExportLabel,
                enabled: ReportFormatting.enabledCheckmark(for: extracted.element),
                timelineIn: ReportFormatting.timecodeString(timelineIn),
                timelineOut: ReportFormatting.timecodeString(timelineOut),
                clipDuration: ReportFormatting.timecodeString(clipDuration),
                sourceIn: sourceTimes.sourceIn,
                sourceOut: sourceTimes.sourceOut,
                sourceDuration: sourceTimes.sourceDuration,
                markers: markersDisplay(in: clipContext),
                keywords: keywordsDisplay(for: clipContext),
                effects: effectsDisplay(on: clipContext),
                notes: "",
                reel: ReportFormatting.metadataString(from: metadata, key: .reel),
                scene: ReportFormatting.metadataString(from: metadata, key: .scene)
            )
        }
        
        /// Multicam audio-component rows are named after the active audio angle, while video
        /// and default rows use the video angle. Non-multicam rows use the standard name.
        private static func displayClipName(for entry: RoleInventoryClipEntry) -> String {
            let extracted = entry.extracted
            
            guard extracted.element.fcpElementType == .mcClip,
                  entry.usesAudioAngleClipName
            else {
                return extracted.displayClipName()
            }
            
            return extracted.element.fcpWorkbookClipName(
                resources: extracted.resources,
                preferAudioAngle: true
            )
        }
        
        private static func inventoryClipContext(
            for extracted: ExtractedElement
        ) -> ExtractedElement {
            if let elementType = extracted.element.fcpElementType,
               reportClipHostTypes.contains(elementType)
            {
                return extracted
            }
            
            return extracted.ancestorClipContext() ?? extracted
        }
        
        private static func sourceTimecodes(
            for clipContext: ExtractedElement,
            clipDuration: Timecode
        ) -> (sourceIn: String, sourceOut: String, sourceDuration: String) {
            let element = clipContext.element
            let resources = clipContext.resources
            let breadcrumbs = clipContext.breadcrumbs
            
            guard let sourceInTimecode = element._fcpTimelineStartAsTimecode()
                ?? element._fcpStartAsTimecode(frameRateSource: .localToElement, default: nil)
            else {
                return ("", "", ReportFormatting.timecodeString(clipDuration))
            }
            
            let sourceOutTimecode: Timecode
            if let end = clipContext.value(
                forContext: .absoluteEndAsTimecode(frameRateSource: .localToElement)
            ) {
                sourceOutTimecode = end
            } else if let added = try? sourceInTimecode.adding(clipDuration) {
                sourceOutTimecode = added
            } else if let end = try? element._fcpTimecode(
                fromRealTime: sourceInTimecode.realTimeValue + clipDuration.realTimeValue,
                frameRateSource: .localToElement,
                breadcrumbs: breadcrumbs,
                resources: resources
            ) {
                sourceOutTimecode = end
            } else {
                return (
                    ReportFormatting.timecodeString(sourceInTimecode),
                    "",
                    ReportFormatting.timecodeString(clipDuration)
                )
            }
            
            return (
                ReportFormatting.timecodeString(sourceInTimecode),
                ReportFormatting.timecodeString(sourceOutTimecode),
                ReportFormatting.timecodeString(clipDuration)
            )
        }
        
        private static func markersDisplay(in clipContext: ExtractedElement) -> String {
            let markers = descendantElements(
                in: clipContext.element,
                types: [.marker, .chapterMarker]
            )
            
            return markers
                .compactMap { element -> String? in
                    guard let marker = element.fcpAsMarker else { return nil }
                    return ReportFormatting.inventoryMarkerLabel(
                        name: marker.name,
                        configuration: marker.configuration
                    )
                }
                .joined(separator: ", ")
        }
        
        private static func keywordsDisplay(for clipContext: ExtractedElement) -> String {
            clipContext
                .value(forContext: .keywordsFlat(constrainToKeywordRanges: false))
                .joined(separator: ", ")
        }
        
        private static func effectsDisplay(on clipContext: ExtractedElement) -> String {
            EffectsCollector
                .effects(on: clipContext)
                .map(\.name)
                .joined(separator: ", ")
        }
        
        private static func descendantElements(
            in root: any OFKXMLElement,
            types: Set<ElementType>
        ) -> [any OFKXMLElement] {
            var results: [any OFKXMLElement] = []
            
            func visit(_ element: any OFKXMLElement) {
                if let elementType = element.fcpElementType, types.contains(elementType) {
                    results.append(element)
                }
                
                for child in element.childElements {
                    visit(child)
                }
            }
            
            visit(root)
            return results
        }
    }
}

extension Sequence where Element == FinalCutPro.FCPXML.RoleInventoryClipEntry {
    func sortedByTimelinePosition() -> [FinalCutPro.FCPXML.RoleInventoryClipEntry] {
        enumerated()
            .sorted { lhs, rhs in
                let lhsEntry = lhs.element
                let rhsEntry = rhs.element
                
                guard let lhsTimecode = lhsEntry.extracted.timecode(),
                      let rhsTimecode = rhsEntry.extracted.timecode()
                else {
                    if lhs.offset != rhs.offset {
                        return lhs.offset < rhs.offset
                    }
                    return (lhsEntry.extracted.element.fcpStart ?? .zero)
                        < (rhsEntry.extracted.element.fcpStart ?? .zero)
                }
                
                if lhsTimecode != rhsTimecode {
                    return lhsTimecode < rhsTimecode
                }
                
                let lhsCategoryRank = timelineCategorySortRank(lhsEntry.category)
                let rhsCategoryRank = timelineCategorySortRank(rhsEntry.category)
                if lhsCategoryRank != rhsCategoryRank {
                    return lhsCategoryRank < rhsCategoryRank
                }
                
                let lhsLane = lhsEntry.extracted.element.fcpLane ?? 0
                let rhsLane = rhsEntry.extracted.element.fcpLane ?? 0
                if lhsLane != rhsLane {
                    return lhsLane < rhsLane
                }
                
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}

private func timelineCategorySortRank(
    _ category: FinalCutPro.FCPXML.ReportClipCategory
) -> Int {
    switch category {
    case .primaryTitle:
        return 0
    case .connectedTitle:
        return 1
    case .primaryVideo, .primaryClip:
        return 2
    case .connectedVideo, .connectedClip, .connectedGenerator:
        return 3
    case .primaryGap:
        return 4
    case .caption:
        return 5
    case .secondaryTitle:
        return 6
    case .primaryAudio, .primarySyncedAudio:
        return 7
    case .connectedAudio, .connectedSyncedAudio, .secondaryAudio:
        return 8
    }
}
