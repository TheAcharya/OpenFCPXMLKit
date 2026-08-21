//
//  TimelineProjectionOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Options controlling timeline projection visibility and traversal.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Options for ``TimelineProjecting``.
    ///
    /// Aligns with ``ExtractionScope`` visibility policies so Reporting can pass
    /// `excludeDisabledClips` through consistently.
    public struct TimelineProjectionOptions: Sendable, Equatable {
        /// Include clips with `enabled="0"`.
        public var includeDisabled: Bool

        /// Audition clip content filter.
        public var auditions: FinalCutPro.FCPXML.Audition.AuditionMask

        /// Multicam angle filter.
        public var mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask

        /// When `true`, omit media windows whose host is fully occluded on the main timeline
        /// (matching ``ExtractionScope/reportMainTimelineVisible(modifying:)`` discovery).
        /// Traversal into nested children still continues so partially visible descendants can emit.
        public var excludeFullyOccluded: Bool

        /// When `true`, populate ``MediaUsageWindow/roles``, ``effects``, and ``breadcrumbs``.
        /// Default `false` keeps windows lightweight for report timing overlays.
        public var includeAnnotations: Bool

        /// Collect marker annotations on hosts when ``includeAnnotations`` is true.
        /// Report builds set this from ``ReportOptions/includeMarkers``.
        public var includeMarkerAnnotations: Bool

        /// Collect keyword annotations on hosts when ``includeAnnotations`` is true.
        /// Report builds set this from ``ReportOptions/includeKeywords``. Skipping this
        /// avoids O(keywords × clip-children) work on exports that stamp thousands of
        /// keywords per clip.
        public var includeKeywordAnnotations: Bool

        /// When `true` (default), emit one window per `videoSources` / `audioSources` index.
        /// When `false`, emit only `sourceIndex == 1` for asset-clip expansions (`srcID` leaves unchanged).
        public var expandAllSourceChannels: Bool

        public init(
            includeDisabled: Bool = true,
            auditions: FinalCutPro.FCPXML.Audition.AuditionMask = .active,
            mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask = .active,
            excludeFullyOccluded: Bool = false,
            includeAnnotations: Bool = false,
            includeMarkerAnnotations: Bool = true,
            includeKeywordAnnotations: Bool = true,
            expandAllSourceChannels: Bool = true
        ) {
            self.includeDisabled = includeDisabled
            self.auditions = auditions
            self.mcClipAngles = mcClipAngles
            self.excludeFullyOccluded = excludeFullyOccluded
            self.includeAnnotations = includeAnnotations
            self.includeMarkerAnnotations = includeMarkerAnnotations
            self.includeKeywordAnnotations = includeKeywordAnnotations
            self.expandAllSourceChannels = expandAllSourceChannels
        }

        /// Options matching main-timeline extraction visibility (no disabled clips;
        /// active audition / multicam angles only; fully occluded hosts omitted).
        public static let mainTimeline = TimelineProjectionOptions(
            includeDisabled: false,
            auditions: .active,
            mcClipAngles: .active,
            excludeFullyOccluded: true
        )

        /// Active-audition / active-angle track occupancy analysis.
        ///
        /// Unfolds only the active audition leaf and active multicam angles, expands all
        /// A/V source channels, and keeps disabled clips. Matches the common “what is
        /// playable on the active mix” policy used for track-usage analysis (distinct from
        /// report inventory/summary, which may use ``Audition/AuditionMask/all`` /
        /// ``MCClip/AngleMask/all`` via ``forReport(excludeDisabledClips:auditions:mcClipAngles:includeAnnotations:includeMarkerAnnotations:includeKeywordAnnotations:expandAllSourceChannels:)``).
        public static let trackAnalysis = TimelineProjectionOptions(
            includeDisabled: true,
            auditions: .active,
            mcClipAngles: .active,
            excludeFullyOccluded: false,
            includeAnnotations: false,
            expandAllSourceChannels: true
        )
    }
}
