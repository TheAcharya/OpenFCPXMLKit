//
// WindowAnnotations.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Sendable annotation payloads attached to projected media usage windows.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// One breadcrumb step along the story path to a projected leaf (no live XML).
    public struct WindowBreadcrumb: Hashable, Sendable, Equatable {
        /// FCPXML element type raw value (for example `asset-clip`, `sync-clip`).
        public var elementType: String

        /// Display name when present.
        public var name: String?

        /// Lane attribute when present.
        public var lane: Int?

        public init(elementType: String, name: String? = nil, lane: Int? = nil) {
            self.elementType = elementType
            self.name = name
            self.lane = lane
        }
    }

    /// Lightweight effect / adjustment fact for a projected window (no live XML).
    public struct WindowEffectAnnotation: Hashable, Sendable, Equatable {
        /// Effect category for report migration.
        public enum Kind: String, Hashable, Sendable, Equatable {
            case volume
            case transform
            case crop
            case compositing
            case stabilization
            case loudness
            case noiseReduction
            case humReduction
            case equalization
            case filterVideo
            case filterAudio
            case other
        }

        /// Display name (`volume`, filter name, `Transform`, etc.).
        public var name: String

        /// Effect category.
        public var kind: Kind

        public init(name: String, kind: Kind) {
            self.name = name
            self.kind = kind
        }
    }

    /// Marker kind for Projection annotations (mapped to report types in Reporting).
    public enum WindowMarkerKind: String, Hashable, Sendable, Equatable {
        case standard
        case incompleteToDo
        case completedToDo
        case chapter
        case analysis
    }

    /// Marker fact captured during Projection (clip or title host).
    public struct WindowMarkerAnnotation: Hashable, Sendable, Equatable {
        public var name: String
        public var kind: WindowMarkerKind
        public var notes: String
        /// Absolute sequence-local timeline position.
        public var timelinePosition: Fraction
        /// Marker `start` attribute (host-local).
        public var sourcePosition: Fraction
        public var reel: String
        public var scene: String
        /// `true` when `sourcePosition` is outside the host’s media range (hidden in FCP Tags/timeline).
        public var isOutsideClipBoundaries: Bool

        public init(
            name: String,
            kind: WindowMarkerKind,
            notes: String = "",
            timelinePosition: Fraction,
            sourcePosition: Fraction,
            reel: String = "",
            scene: String = "",
            isOutsideClipBoundaries: Bool = false
        ) {
            self.name = name
            self.kind = kind
            self.notes = notes
            self.timelinePosition = timelinePosition
            self.sourcePosition = sourcePosition
            self.reel = reel
            self.scene = scene
            self.isOutsideClipBoundaries = isOutsideClipBoundaries
        }
    }

    /// Keyword fact captured during Projection (clip or title host).
    public struct WindowKeywordAnnotation: Hashable, Sendable, Equatable {
        public var keyword: String
        public var notes: String
        public var timelineIn: Fraction
        public var timelineOut: Fraction
        public var duration: Fraction
        public var reel: String
        public var scene: String

        public init(
            keyword: String,
            notes: String = "",
            timelineIn: Fraction,
            timelineOut: Fraction,
            duration: Fraction,
            reel: String = "",
            scene: String = ""
        ) {
            self.keyword = keyword
            self.notes = notes
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.duration = duration
            self.reel = reel
            self.scene = scene
        }
    }

    /// Title / generator story fact captured during Projection.
    ///
    /// Generators are also ``title`` elements that reference an effect resource;
    /// there is no separate FCPXML element type.
    public struct WindowTitleAnnotation: Hashable, Sendable, Equatable {
        public var titleText: String
        public var font: String
        public var enabled: Bool
        public var isAppleSupplied: Bool
        /// Absolute sequence-local timeline In.
        public var timelineIn: Fraction
        /// Absolute sequence-local timeline Out (`timelineIn` + `duration`).
        public var timelineOut: Fraction
        public var duration: Fraction

        public init(
            titleText: String,
            font: String = "",
            enabled: Bool = true,
            isAppleSupplied: Bool = false,
            timelineIn: Fraction,
            timelineOut: Fraction,
            duration: Fraction
        ) {
            self.titleText = titleText
            self.font = font
            self.enabled = enabled
            self.isAppleSupplied = isAppleSupplied
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.duration = duration
        }
    }

    /// Transition story fact captured during Projection.
    public struct WindowTransitionAnnotation: Hashable, Sendable, Equatable {
        public var name: String
        public var placement: Transition.SpinePlacement
        public var isAppleSupplied: Bool
        /// Absolute sequence-local timeline In.
        public var timelineIn: Fraction
        /// Absolute sequence-local timeline Out (`timelineIn` + `duration`).
        public var timelineOut: Fraction
        public var duration: Fraction

        public init(
            name: String,
            placement: Transition.SpinePlacement = .primary,
            isAppleSupplied: Bool = false,
            timelineIn: Fraction,
            timelineOut: Fraction,
            duration: Fraction
        ) {
            self.name = name
            self.placement = placement
            self.isAppleSupplied = isAppleSupplied
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.duration = duration
        }
    }

    /// Report-ready effect fact captured once per clip/title host during Projection.
    ///
    /// Distinct from lightweight ``WindowEffectAnnotation`` on media windows (name + kind only).
    /// Settings / kind align with ``ExtractedEffect`` so Reporting can format without live XML.
    public struct WindowReportEffectAnnotation: Hashable, Sendable, Equatable {
        public var name: String
        public var kind: ExtractedEffect.Kind
        public var settings: ExtractedEffect.Settings
        public var enabled: Bool
        public var isAppleSupplied: Bool
        public var sortOrder: Int
        /// Absolute sequence-local timeline In (host or nested volume context).
        public var timelineIn: Fraction
        /// Absolute sequence-local timeline Out.
        public var timelineOut: Fraction

        public init(
            name: String,
            kind: ExtractedEffect.Kind,
            settings: ExtractedEffect.Settings = .empty,
            enabled: Bool = true,
            isAppleSupplied: Bool = true,
            sortOrder: Int = 0,
            timelineIn: Fraction,
            timelineOut: Fraction
        ) {
            self.name = name
            self.kind = kind
            self.settings = settings
            self.enabled = enabled
            self.isAppleSupplied = isAppleSupplied
            self.sortOrder = sortOrder
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
        }
    }

    /// Clip-, title-, or transition-hosted annotations for one story element.
    ///
    /// Emitted once per host during Projection (not once per media channel), so title
    /// markers / titles / transitions / effects are covered without inventing a media channel.
    public struct ProjectedClipAnnotations: Hashable, Sendable, Equatable {
        public var clipDisplayName: String
        public var hostElementType: String
        public var roles: [AnyInterpolatedRole]
        public var carriesVideo: Bool
        public var carriesAudio: Bool
        public var markers: [WindowMarkerAnnotation]
        public var keywords: [WindowKeywordAnnotation]
        /// Present when the host is a ``title`` / generator story element.
        public var title: WindowTitleAnnotation?
        /// Present when the host is a ``transition`` story element.
        public var transition: WindowTransitionAnnotation?
        /// Report effects collected via ``EffectsCollector`` on extracted effect hosts.
        public var effects: [WindowReportEffectAnnotation]

        public init(
            clipDisplayName: String,
            hostElementType: String,
            roles: [AnyInterpolatedRole] = [],
            carriesVideo: Bool = false,
            carriesAudio: Bool = false,
            markers: [WindowMarkerAnnotation] = [],
            keywords: [WindowKeywordAnnotation] = [],
            title: WindowTitleAnnotation? = nil,
            transition: WindowTransitionAnnotation? = nil,
            effects: [WindowReportEffectAnnotation] = []
        ) {
            self.clipDisplayName = clipDisplayName
            self.hostElementType = hostElementType
            self.roles = roles
            self.carriesVideo = carriesVideo
            self.carriesAudio = carriesAudio
            self.markers = markers
            self.keywords = keywords
            self.title = title
            self.transition = transition
            self.effects = effects
        }

        public var isEmpty: Bool {
            markers.isEmpty
                && keywords.isEmpty
                && title == nil
                && transition == nil
                && effects.isEmpty
        }
    }

    /// Full Projection output for Reporting (media windows + clip annotations).
    public struct TimelineProjectionResult: Sendable, Equatable {
        public var windows: [MediaUsageWindow]
        public var clipAnnotations: [ProjectedClipAnnotations]

        public init(
            windows: [MediaUsageWindow] = [],
            clipAnnotations: [ProjectedClipAnnotations] = []
        ) {
            self.windows = windows
            self.clipAnnotations = clipAnnotations
        }
    }
}
