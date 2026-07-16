//
//  FCPXMLReportProjectionContext.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Shared timeline projection windows for report builders (projected once per source).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Playable media windows for one report timeline, built once per ``ReportBuilder`` pass.
    ///
    /// Role Inventory, Speed Change, Media Summary, Effects, and Summary prefer these for
    /// occupancy / retiming / URL facts. Markers, Keywords, Titles, Transitions, and Effects
    /// prefer ``clipAnnotations``.
    ///
    /// Not `Sendable`: held and consumed on the same async report-build task without
    /// crossing actor boundaries (same pattern as ``ReportTimelineSource``).
    public struct ReportProjectionContext {
        /// Projected media usage windows (may be empty).
        public var windows: [MediaUsageWindow]

        /// Clip/title/transition/effect-hosted annotations (once per host).
        public var clipAnnotations: [ProjectedClipAnnotations]

        /// Interval index over ``windows`` for overlap queries and occupied-duration totals.
        public var occupancy: TimelineOccupancyIndex {
            TimelineOccupancyIndex(windows: windows)
        }

        /// Fast name/start matcher for inventory and effects timing overlays.
        var windowIndex: ProjectionWindowIndex {
            ProjectionWindowIndex(windows: windows)
        }

        public init(
            windows: [MediaUsageWindow],
            clipAnnotations: [ProjectedClipAnnotations] = []
        ) {
            self.windows = windows
            self.clipAnnotations = clipAnnotations
        }
    }
}

extension FinalCutPro.FCPXML.TimelineProjectionOptions {
    /// Projection options aligned with report section visibility knobs.
    ///
    /// Role Inventory and Summary historically walk inactive audition / multicam
    /// alternatives (``.all``); other sections typically use `.active`.
    public static func forReport(
        excludeDisabledClips: Bool,
        auditions: FinalCutPro.FCPXML.Audition.AuditionMask,
        mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask,
        includeAnnotations: Bool = false,
        expandAllSourceChannels: Bool = true
    ) -> Self {
        Self(
            includeDisabled: !excludeDisabledClips,
            auditions: auditions,
            mcClipAngles: mcClipAngles,
            excludeFullyOccluded: true,
            includeAnnotations: includeAnnotations,
            expandAllSourceChannels: expandAllSourceChannels
        )
    }
}

extension FinalCutPro.FCPXML.ReportOptions {
    /// Whether any enabled section consumes ``ReportProjectionContext``.
    var consumesTimelineProjection: Bool {
        includeSpeedChangeEffects
            || includeRoleInventory
            || includeMediaSummary
            || includeEffects
            || includeSummary
            || includeMarkers
            || includeKeywords
            || includeTitlesAndGenerators
            || includeTransitions
    }
}
