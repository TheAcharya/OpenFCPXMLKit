//
//  TimelineProjector.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Default timeline projector: nested story walk with multicam / compound unfold.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Default ``TimelineProjecting`` implementation.
    ///
    /// Emits ``MediaUsageWindow`` values for playable timeline content (one window per
    /// resolved media channel). When an ``AssetClip`` has a ``TimeMap`` with ≥ 2 points,
    /// each retiming segment (and channel) becomes its own window; reverse playback and
    /// multi-point maps are expressed via ``RetimingSegment``. Without a usable timeMap,
    /// identity placement is used (`offset` / `duration` / `start` from model getters,
    /// which already apply `conform-rate` scaling when present).
    ///
    /// Recursively walks nested spines and anchored story children, composing
    /// ``LanePath`` and absolute timeline starts relative to parent `start` / sequence
    /// `tcStart`. Split edits via `audioStart` / `audioDuration` emit separate audio
    /// windows when occupancy differs from video.
    ///
    /// Unfolds ``MCClip`` angles (``TimelineProjectionOptions/mcClipAngles``),
    /// ``RefClip`` media sequences, sync-clip / clip shells, ``Audition`` alternatives
    /// (``TimelineProjectionOptions/auditions``), and `video` / `audio` leaves with
    /// channel kind filtering via `srcEnable` and active angle selection.
    public struct TimelineProjector: TimelineProjecting, Sendable {
        public init() {}

        public func project(
            from source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) async throws {
            // OFKXML / Model types are not Sendable: walk synchronously inside the async body.
            try projectSync(from: source, fcpxml: fcpxml, options: options, onWindow: onWindow)
        }

        /// Synchronous walk used by the async API (and tests that prefer sync).
        public func projectSync(
            from source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) throws {
            let sequence = source.sequence
            let tcStart = sequence.tcStart ?? .zero
            // Seed as if sequence `tcStart` were already visited: children compose
            // absolute = tcStart + (offset − tcStart) when tcStart is present, else
            // absolute = offset when parentLocalStart is nil.
            let parentLocalStart: Fraction? = sequence.tcStart != nil ? tcStart : nil
            try SpineProjection.projectStoryElements(
                sequence.spine.storyElements,
                resources: fcpxml.root.resources,
                lanePath: .primary,
                parentAbsoluteStart: parentLocalStart != nil ? tcStart : .zero,
                parentLocalStart: parentLocalStart,
                channelFilter: .all,
                options: options,
                onWindow: onWindow
            )
        }

        /// Projects media windows and clip-level marker/keyword annotations together.
        public func projectDetailed(
            from source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: TimelineProjectionOptions = .init()
        ) async throws -> TimelineProjectionResult {
            let collector = ClipAnnotationCollector()
            var windows: [MediaUsageWindow] = []
            try TimelineProjectionLocals.$clipAnnotationCollector.withValue(collector) {
                try projectSync(from: source, fcpxml: fcpxml, options: options) { window in
                    windows.append(window)
                }
            }
            return TimelineProjectionResult(
                windows: windows,
                clipAnnotations: collector.items
            )
        }
    }
}

extension FinalCutPro.FCPXML {
    /// Convenience: project the first report timeline source using ``TimelineProjector``.
    public func projectTimeline(
        options: TimelineProjectionOptions = .init(),
        using projector: some TimelineProjecting = TimelineProjector()
    ) async throws -> [MediaUsageWindow] {
        guard let source = allReportTimelineSources().first else { return [] }
        return try await projector.project(from: source, fcpxml: self, options: options)
    }
}

extension FinalCutPro.FCPXML.TimelineProjecting {
    /// Default detailed projection: windows only (no clip annotations) unless the
    /// concrete type is ``TimelineProjector``.
    public func projectDetailed(
        from source: FinalCutPro.FCPXML.ReportTimelineSource,
        fcpxml: FinalCutPro.FCPXML,
        options: FinalCutPro.FCPXML.TimelineProjectionOptions = .init()
    ) async throws -> FinalCutPro.FCPXML.TimelineProjectionResult {
        if let projector = self as? FinalCutPro.FCPXML.TimelineProjector {
            return try await projector.projectDetailed(from: source, fcpxml: fcpxml, options: options)
        }
        let windows = try await project(from: source, fcpxml: fcpxml, options: options)
        return FinalCutPro.FCPXML.TimelineProjectionResult(windows: windows, clipAnnotations: [])
    }
}
