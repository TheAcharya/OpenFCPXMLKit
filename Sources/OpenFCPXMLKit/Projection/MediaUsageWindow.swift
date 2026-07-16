//
//  MediaUsageWindow.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Atomic playable media usage on a projected timeline.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// One usage of a ``MediaChannel`` on a timeline after nesting and visibility filters.
    ///
    /// A single FCPXML clip may produce zero or many windows (multi-source A/V, multi-point
    /// time maps, nested unfolds). Reporting builders should prefer windows over raw XML
    /// walks for occupancy and timing accuracy.
    public struct MediaUsageWindow: Hashable, Sendable, Equatable {
        /// Resolved media channel for this usage.
        public var channel: MediaChannel

        /// Nested lane placement (empty = primary spine).
        public var lanePath: LanePath

        /// Timeline ↔ media mapping for this window.
        public var retiming: RetimingSegment

        /// Absolute (sequence-local) timeline in / out from ``retiming``.
        public var timelineIn: Fraction { retiming.timelineStart }

        /// Absolute (sequence-local) timeline out from ``retiming``.
        public var timelineOut: Fraction { retiming.timelineEnd }

        /// Media in from ``retiming``.
        public var mediaIn: Fraction { retiming.mediaStart }

        /// Media out from ``retiming``.
        public var mediaOut: Fraction { retiming.mediaEnd }

        /// Clip display name when known.
        public var clipDisplayName: String?

        /// Inherited roles for this window (empty unless ``TimelineProjectionOptions/includeAnnotations``).
        public var roles: [AnyInterpolatedRole]

        /// Lightweight effect / adjustment facts (empty unless annotations are enabled).
        public var effects: [WindowEffectAnnotation]

        /// Story path furthest-ancestor → leaf (empty unless annotations are enabled).
        public var breadcrumbs: [WindowBreadcrumb]

        public init(
            channel: MediaChannel,
            lanePath: LanePath = .primary,
            retiming: RetimingSegment,
            clipDisplayName: String? = nil,
            roles: [AnyInterpolatedRole] = [],
            effects: [WindowEffectAnnotation] = [],
            breadcrumbs: [WindowBreadcrumb] = []
        ) {
            self.channel = channel
            self.lanePath = lanePath
            self.retiming = retiming
            self.clipDisplayName = clipDisplayName
            self.roles = roles
            self.effects = effects
            self.breadcrumbs = breadcrumbs
        }
    }
}
