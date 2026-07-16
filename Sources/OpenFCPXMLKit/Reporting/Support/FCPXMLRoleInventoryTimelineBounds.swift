//
//  FCPXMLRoleInventoryTimelineBounds.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Timeline span helpers for role inventory rows (split edits / J-L cuts).
//

import Foundation

extension FinalCutPro.FCPXML {
    enum RoleInventoryTimelineBounds {
        static func usesAudioTimelineBounds(
            category: ReportClipCategory,
            element: any OFKXMLElement
        ) -> Bool {
            switch category {
            case .primaryAudio, .connectedAudio, .secondaryAudio:
                break
            case .connectedClip where element.fcpElementType == .mcClip:
                if element.fcpIsAudioOnlyMulticamInventoryHost() {
                    return element.fcpDuration != nil
                }
                break
            default:
                return false
            }
            
            guard element.fcpAudioDuration != nil else { return false }
            
            guard let videoDuration = element.fcpDuration?.doubleValue,
                  let audioDuration = element.fcpAudioDuration?.doubleValue
            else { return false }
            
            let clipStart = element.fcpStart?.doubleValue ?? 0
            let audioStart = element.fcpAudioStart?.doubleValue ?? clipStart
            let audioHeadOffset = audioStart - clipStart
            
            return audioHeadOffset != 0
                || abs(audioDuration - videoDuration) > 0.000_001
        }
        
        static func mainTimelineSpan(
            for extracted: ExtractedElement,
            usesAudioTimelineBounds: Bool,
            projectionWindows: [MediaUsageWindow]? = nil,
            windowIndex: ProjectionWindowIndex? = nil
        ) -> (start: TimeInterval, end: TimeInterval)? {
            if let projected = projectedSpan(
                for: extracted,
                usesAudioTimelineBounds: usesAudioTimelineBounds,
                windows: projectionWindows,
                windowIndex: windowIndex
            ) {
                return projected
            }

            guard let absoluteStart = extracted.value(forContext: .absoluteStart) else {
                return nil
            }

            if usesAudioTimelineBounds {
                if let audioDuration = extracted.element.fcpAudioDuration?.doubleValue {
                    let clipStart = extracted.element.fcpStart?.doubleValue ?? 0
                    let audioStart = extracted.element.fcpAudioStart?.doubleValue ?? clipStart
                    let audioTimelineStart = absoluteStart + (audioStart - clipStart)
                    return (audioTimelineStart, audioTimelineStart + audioDuration)
                }

                if extracted.element.fcpIsAudioOnlyMulticamInventoryHost(),
                   let duration = extracted.element.fcpDuration?.doubleValue
                {
                    return (absoluteStart, absoluteStart + duration)
                }
            }

            guard let duration = extracted.element.fcpDuration?.doubleValue else {
                return nil
            }

            if let absoluteEnd = extracted.value(forContext: .absoluteEnd) {
                return (absoluteStart, absoluteEnd)
            }

            return (absoluteStart, absoluteStart + duration)
        }

        /// Matches a projected window to an inventory entry for timing overlay.
        private static func projectedSpan(
            for extracted: ExtractedElement,
            usesAudioTimelineBounds: Bool,
            windows: [MediaUsageWindow]?,
            windowIndex: ProjectionWindowIndex?
        ) -> (start: TimeInterval, end: TimeInterval)? {
            let index: ProjectionWindowIndex?
            if let windowIndex {
                index = windowIndex
            } else if let windows, !windows.isEmpty {
                index = ProjectionWindowIndex(windows: windows)
            } else {
                index = nil
            }
            guard let index else { return nil }
            guard let absoluteStart = extracted.value(forContext: .absoluteStart) else {
                return nil
            }

            let clipName = extracted.displayClipName()
            let preferAudio = usesAudioTimelineBounds
            let expectedStart: TimeInterval
            if preferAudio, let audioDuration = extracted.element.fcpAudioDuration?.doubleValue {
                let clipStart = extracted.element.fcpStart?.doubleValue ?? 0
                let audioStart = extracted.element.fcpAudioStart?.doubleValue ?? clipStart
                expectedStart = absoluteStart + (audioStart - clipStart)
                _ = audioDuration
            } else {
                expectedStart = absoluteStart
            }

            guard let best = index.match(
                clipName: clipName,
                expectedStart: expectedStart,
                preferAudio: preferAudio
            ) else {
                return nil
            }

            return (best.timelineIn.doubleValue, best.timelineOut.doubleValue)
        }
        
        /// Caption inventory rows floor fractional timeline in/out to frame boundaries.
        static func usesFlooredTimelineStart(
            for extracted: ExtractedElement,
            category: ReportClipCategory
        ) -> Bool {
            category == .caption
        }
        
        /// Connected `mc-clip` and caption inventory rows derive timeline out from a frame-floored duration.
        static func usesFlooredTimelineEnd(
            for extracted: ExtractedElement,
            category: ReportClipCategory
        ) -> Bool {
            if category == .caption {
                return true
            }
            
            return category == .connectedClip
                && extracted.element.fcpElementType == .mcClip
        }
    }
}
