//
//  FCPXMLMarkerClipBoundary.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Host-media-range checks for markers outside clip duration (FCP-hidden markers).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Utilities for detecting markers whose `start` lies outside the host clip’s media range.
    ///
    /// Final Cut Pro hides such markers from the timeline and Tags list while still emitting them
    /// in FCPXML. The inclusive media window is `[hostStart, hostStart + hostDuration)`.
    public enum MarkerClipBoundary {
        /// Returns `true` when `markerStart` is strictly before the host start or at/after the host end.
        ///
        /// When `hostDuration` is missing, returns `false` (cannot determine bounds).
        public static func isOutsideHostMediaRange(
            markerStart: Fraction,
            hostStart: Fraction?,
            hostDuration: Fraction?
        ) -> Bool {
            guard let hostDuration else { return false }
            let start = hostStart ?? .zero
            let end = ProjectionTiming.adding(start, hostDuration)
            let marker = markerStart.doubleValue
            return marker < start.doubleValue || marker >= end.doubleValue
        }
    }
}
