//
//  FCPXMLRoleInventoryDuplicateFrames.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Source-range reuse duration for inventory Duplicate Frames cells.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Computes optimistic Duplicate Frames values from projected media windows.
    ///
    /// For each subject window’s media range, intersects with other windows that share the
    /// same ``MediaChannel/resourceID`` (excluding the subject windows themselves), then
    /// unions those intersections. Blank when there is no reusable source overlap.
    enum RoleInventoryDuplicateFrames {
        /// Formatted reused source duration for an inventory clip, or `""` when none.
        static func formattedDuration(
            for extracted: ExtractedElement,
            usesAudioTimelineBounds: Bool,
            projectionWindows: [MediaUsageWindow]?,
            windowIndex: ProjectionWindowIndex?,
            timecodeFormat: ReportTimecodeFormat
        ) -> String {
            guard let projectionWindows, !projectionWindows.isEmpty else { return "" }
            
            let index = windowIndex ?? ProjectionWindowIndex(windows: projectionWindows)
            let subjectWindows = matchingWindows(
                for: extracted,
                usesAudioTimelineBounds: usesAudioTimelineBounds,
                index: index
            )
            guard !subjectWindows.isEmpty else { return "" }
            
            let subjectKeys = Set(subjectWindows.map(WindowIdentity.init))
            var overlapIntervals: [TimelineOccupancyIndex.Interval] = []
            
            for subject in subjectWindows {
                let resourceID = subject.channel.resourceID
                guard !resourceID.isEmpty else { continue }
                
                let subjectStart = min(subject.mediaIn.doubleValue, subject.mediaOut.doubleValue)
                let subjectEnd = max(subject.mediaIn.doubleValue, subject.mediaOut.doubleValue)
                guard subjectEnd > subjectStart + .ulpOfOne else { continue }
                
                for other in projectionWindows {
                    guard other.channel.resourceID == resourceID else { continue }
                    guard !subjectKeys.contains(WindowIdentity(other)) else { continue }
                    
                    let otherStart = min(other.mediaIn.doubleValue, other.mediaOut.doubleValue)
                    let otherEnd = max(other.mediaIn.doubleValue, other.mediaOut.doubleValue)
                    let start = max(subjectStart, otherStart)
                    let end = min(subjectEnd, otherEnd)
                    guard end > start + .ulpOfOne else { continue }
                    overlapIntervals.append(
                        TimelineOccupancyIndex.Interval(start: start, end: end)
                    )
                }
            }
            
            let seconds = TimelineOccupancyIndex.unionDuration(overlapIntervals)
            guard seconds > .ulpOfOne else { return "" }
            
            guard let durationTimecode = try? extracted.element._fcpTimecode(
                fromRealTime: seconds,
                frameRateSource: .mainTimeline,
                breadcrumbs: extracted.breadcrumbs,
                resources: extracted.resources
            ) else { return "" }
            
            return ReportFormatting.timecodeString(durationTimecode, format: timecodeFormat)
        }
        
        private static func matchingWindows(
            for extracted: ExtractedElement,
            usesAudioTimelineBounds: Bool,
            index: ProjectionWindowIndex
        ) -> [MediaUsageWindow] {
            guard let absoluteStart = extracted.value(forContext: .absoluteStart) else {
                return []
            }
            
            let clipName = extracted.displayClipName()
            let expectedStart: TimeInterval
            if usesAudioTimelineBounds,
               extracted.element.fcpAudioDuration != nil
            {
                let clipStart = extracted.element.fcpStart?.doubleValue ?? 0
                let audioStart = extracted.element.fcpAudioStart?.doubleValue ?? clipStart
                expectedStart = absoluteStart + (audioStart - clipStart)
            } else {
                expectedStart = absoluteStart
            }
            
            return index.windows(
                clipName: clipName,
                expectedStart: expectedStart
            )
        }
        
        private struct WindowIdentity: Hashable {
            let resourceID: String
            let kind: MediaChannel.Kind
            let sourceIndex: Int
            let timelineIn: Double
            let timelineOut: Double
            let mediaIn: Double
            let mediaOut: Double
            
            init(_ window: MediaUsageWindow) {
                resourceID = window.channel.resourceID
                kind = window.channel.kind
                sourceIndex = window.channel.sourceIndex
                timelineIn = window.timelineIn.doubleValue
                timelineOut = window.timelineOut.doubleValue
                mediaIn = window.mediaIn.doubleValue
                mediaOut = window.mediaOut.doubleValue
            }
        }
    }
}

