//
//  TimelineProjecting.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Protocol for projecting FCPXML timelines into media usage windows.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Projects an FCPXML timeline into playable ``MediaUsageWindow`` values.
    ///
    /// Implementations walk the sequence and nested structures, resolve
    /// assets into channels, apply visibility filters, and emit time-mapped usage windows.
    /// Reporting builders consume windows; they should not invent timeline geometry.
    public protocol TimelineProjecting: Sendable {
        /// Collects all media usage windows for a report timeline source.
        func project(
            from source: FinalCutPro.FCPXML.ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: TimelineProjectionOptions
        ) async throws -> [MediaUsageWindow]

        /// Streams media usage windows for a report timeline source.
        func project(
            from source: FinalCutPro.FCPXML.ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) async throws
    }
}

extension FinalCutPro.FCPXML.TimelineProjecting {
    public func project(
        from source: FinalCutPro.FCPXML.ReportTimelineSource,
        fcpxml: FinalCutPro.FCPXML,
        options: FinalCutPro.FCPXML.TimelineProjectionOptions = .init()
    ) async throws -> [FinalCutPro.FCPXML.MediaUsageWindow] {
        var windows: [FinalCutPro.FCPXML.MediaUsageWindow] = []
        try await project(from: source, fcpxml: fcpxml, options: options) { window in
            windows.append(window)
        }
        return windows
    }
}
