//
//  ClipRetiming.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Resolves RetimingSegment lists for a clip from timeMap and/or identity placement.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds retiming segments for a story element that exposes timing params.
    enum ClipRetiming {
        /// Resolves one or more ``RetimingSegment`` values for a clip placement.
        ///
        /// Priority:
        /// 1. ``TimeMap`` with ≥ 2 points → one segment per consecutive pair (normalized onto
        ///    `clipOffset`…`clipOffset+clipDuration`)
        /// 2. Otherwise a single identity segment
        ///
        /// - Note: Clip `offset` / `start` / `duration` from model getters already apply
        ///   `conform-rate` scaling when present. Pass those values here; do not re-apply
        ///   ``ConformRate/applyingConform(to:timelineFrameRate:)`` on top of scaled getters.
        ///   Use ``ConformRate`` helpers only with unscaled fractions or to read the factor.
        static func segments(
            timeMap: TimeMap?,
            clipOffset: Fraction,
            clipDuration: Fraction,
            mediaStart: Fraction
        ) -> [RetimingSegment] {
            if let timeMap {
                let mapped = timeMap.retimingSegments(
                    clipOffset: clipOffset,
                    clipDuration: clipDuration
                )
                if !mapped.isEmpty { return mapped }
            }

            return [
                RetimingSegment.identity(
                    timelineStart: clipOffset,
                    duration: clipDuration,
                    mediaStart: mediaStart
                )
            ]
        }
    }
}
