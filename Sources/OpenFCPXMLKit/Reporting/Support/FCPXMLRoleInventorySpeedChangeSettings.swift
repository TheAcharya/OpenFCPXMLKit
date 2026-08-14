//
// FCPXMLRoleInventorySpeedChangeSettings.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Speed Change Settings cell values for Role Inventory rows.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Resolves Speed Change Settings strings for inventory rows (Projection-first).
    ///
    /// Uses the same ``SpeedChangeFormatting`` percent labels as the Speed Change Effects
    /// sheet (`50.0%`, `-100.0%`, …). Blank when the clip has no non-identity retime.
    enum RoleInventorySpeedChangeSettings {
        /// Formatted retime settings for an inventory clip, or `""` when none.
        static func formattedSettings(
            for extracted: ExtractedElement,
            clipContext: ExtractedElement,
            usesAudioTimelineBounds: Bool,
            projectionWindows: [MediaUsageWindow]?,
            windowIndex: ProjectionWindowIndex?
        ) -> String {
            if let projectionWindows, !projectionWindows.isEmpty {
                let index = windowIndex ?? ProjectionWindowIndex(windows: projectionWindows)
                let subjectWindows = matchingWindows(
                    for: extracted,
                    usesAudioTimelineBounds: usesAudioTimelineBounds,
                    index: index
                )
                let changed = subjectWindows.filter { SpeedChangeFormatting.isSpeedChange($0.retiming) }
                if !changed.isEmpty {
                    let preferred = changed.filter { $0.channel.kind == .video }
                    let pool = preferred.isEmpty ? changed : preferred
                    let ordered = pool.sorted {
                        $0.timelineIn.doubleValue < $1.timelineIn.doubleValue
                    }
                    if let retime = SpeedChangeFormatting.retimeDisplay(
                        aggregating: ordered.map(\.retiming)
                    ) {
                        return retime.settings
                    }
                }
            }

            guard let timeMap: TimeMap = clipContext.element.firstChild(whereFCPElement: .timeMap),
                  let retime = SpeedChangeFormatting.retimeDisplay(from: timeMap)
            else {
                return ""
            }
            return retime.settings
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
    }
}
