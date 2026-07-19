//
//  RetimingSegment.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Linear timeline↔media mapping segment for projection windows.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// One linear mapping between container (timeline) time and media time.
    ///
    /// Timeline periods are always forward (`timelineStart` ≤ `timelineEnd`).
    /// Media spans may reverse (`mediaEnd` &lt; `mediaStart`) when playback is reversed.
    ///
    /// Identity segments are emitted when no usable ``TimeMap`` is present.
    /// When a ``TimeMap`` has multiple `timept` entries, one segment is emitted per
    /// consecutive pair (normalized onto clip duration), including reverse playback.
    public struct RetimingSegment: Hashable, Sendable, Equatable {
        /// Inclusive timeline start (sequence-local unless composed further).
        public var timelineStart: Fraction

        /// Exclusive timeline end.
        public var timelineEnd: Fraction

        /// Media start (may be greater than ``mediaEnd`` when reversed).
        public var mediaStart: Fraction

        /// Media end.
        public var mediaEnd: Fraction

        /// Playback speed magnitude: `abs(mediaDelta / remappedTimeDelta)`.
        /// Identity is `1`; hold approaches `0`; `2` means roughly 200% media rate.
        public var scale: Double

        /// Whether media plays in reverse over this segment (`mediaEnd` &lt; `mediaStart`
        /// while timeline occupancy advances).
        public var isReversed: Bool

        public init(
            timelineStart: Fraction,
            timelineEnd: Fraction,
            mediaStart: Fraction,
            mediaEnd: Fraction,
            scale: Double = 1,
            isReversed: Bool = false
        ) {
            self.timelineStart = timelineStart
            self.timelineEnd = timelineEnd
            self.mediaStart = mediaStart
            self.mediaEnd = mediaEnd
            self.scale = scale
            self.isReversed = isReversed
        }

        /// Forward timeline occupancy length in seconds (`max(0, timelineEnd − timelineStart)`).
        public var timelineDuration: Double {
            max(0, timelineEnd.doubleValue - timelineStart.doubleValue)
        }

        /// Absolute media span length in seconds (`abs(mediaEnd − mediaStart)`).
        ///
        /// Hold / freeze segments approach `0` even when timeline occupancy is positive.
        public var mediaDuration: Double {
            abs(mediaEnd.doubleValue - mediaStart.doubleValue)
        }

        /// `true` when media does not advance over a positive timeline span (hold / freeze).
        public var isHold: Bool {
            timelineDuration > .ulpOfOne && mediaDuration <= .ulpOfOne
        }

        /// `true` when `timeline` lies in the half-open occupancy `[timelineStart, timelineEnd)`.
        public func containsTimeline(_ timeline: Fraction) -> Bool {
            let t = timeline.doubleValue
            return t >= timelineStart.doubleValue && t < timelineEnd.doubleValue
        }

        /// `true` when this segment’s timeline occupancy overlaps `[start, end)`.
        public func intersectsTimeline(start: Fraction, end: Fraction) -> Bool {
            let queryStart = min(start.doubleValue, end.doubleValue)
            let queryEnd = max(start.doubleValue, end.doubleValue)
            return timelineStart.doubleValue < queryEnd && queryStart < timelineEnd.doubleValue
        }

        /// Returns a copy clipped to the overlapping timeline range `[start, end)`, remapping
        /// media endpoints through ``mediaPoint(forTimeline:)``.
        ///
        /// Returns `nil` when there is no positive overlap.
        public func clipped(toTimelineStart start: Fraction, timelineEnd end: Fraction) -> RetimingSegment? {
            let queryStart = min(start.doubleValue, end.doubleValue)
            let queryEnd = max(start.doubleValue, end.doubleValue)
            let overlapLo = max(timelineStart.doubleValue, queryStart)
            let overlapHi = min(timelineEnd.doubleValue, queryEnd)
            guard overlapHi > overlapLo + .ulpOfOne else { return nil }

            let clippedStart = Fraction(double: overlapLo)
            let clippedEnd = Fraction(double: overlapHi)
            let clippedMediaStart = mediaPoint(forTimeline: clippedStart)
            let clippedMediaEnd = mediaPoint(forTimeline: clippedEnd)
            return RetimingSegment(
                timelineStart: clippedStart,
                timelineEnd: clippedEnd,
                mediaStart: clippedMediaStart,
                mediaEnd: clippedMediaEnd,
                scale: scale,
                isReversed: clippedMediaEnd.doubleValue < clippedMediaStart.doubleValue
            )
        }

        /// Identity mapping: clip occupies `[timelineStart, timelineStart + duration)` and
        /// reads media `[mediaStart, mediaStart + duration)`.
        public static func identity(
            timelineStart: Fraction,
            duration: Fraction,
            mediaStart: Fraction
        ) -> RetimingSegment {
            // Use Double-backed composition: conform-scaled model fractions mixed with
            // literal FCPXML rationals can trap on Int overflow in Fraction `+`.
            RetimingSegment(
                timelineStart: timelineStart,
                timelineEnd: ProjectionTiming.adding(timelineStart, duration),
                mediaStart: mediaStart,
                mediaEnd: ProjectionTiming.adding(mediaStart, duration),
                scale: 1,
                isReversed: false
            )
        }

        /// Composes a child segment through a parent container segment.
        ///
        /// Parent maps outer timeline ↔ nested sequence (media) time. Child maps nested
        /// timeline ↔ asset media. Overlap is taken in the nested-time domain (parent media
        /// axis vs child timeline axis). Returns an empty array when there is no overlap.
        public static func composing(
            parent: RetimingSegment,
            child: RetimingSegment
        ) -> [RetimingSegment] {
            let parentMediaLo = min(parent.mediaStart.doubleValue, parent.mediaEnd.doubleValue)
            let parentMediaHi = max(parent.mediaStart.doubleValue, parent.mediaEnd.doubleValue)
            let childTimelineLo = min(child.timelineStart.doubleValue, child.timelineEnd.doubleValue)
            let childTimelineHi = max(child.timelineStart.doubleValue, child.timelineEnd.doubleValue)

            let overlapLo = max(parentMediaLo, childTimelineLo)
            let overlapHi = min(parentMediaHi, childTimelineHi)
            guard overlapHi > overlapLo + .ulpOfOne else { return [] }

            let outerStart = parent.timelinePoint(forMedia: Fraction(double: overlapLo))
            let outerEnd = parent.timelinePoint(forMedia: Fraction(double: overlapHi))
            let timelineStart = min(outerStart, outerEnd)
            let timelineEnd = max(outerStart, outerEnd)
            guard timelineEnd.doubleValue > timelineStart.doubleValue + .ulpOfOne else { return [] }

            let childMediaAtLo = child.mediaPoint(forTimeline: Fraction(double: overlapLo))
            let childMediaAtHi = child.mediaPoint(forTimeline: Fraction(double: overlapHi))

            let composedScale = max(0, parent.scale) * max(0, child.scale)
            let composedReversed = parent.isReversed != child.isReversed

            return [
                RetimingSegment(
                    timelineStart: timelineStart,
                    timelineEnd: timelineEnd,
                    mediaStart: childMediaAtLo,
                    mediaEnd: childMediaAtHi,
                    scale: composedScale,
                    isReversed: composedReversed
                )
            ]
        }

        /// Maps a media-axis point through this segment onto the timeline axis.
        public func timelinePoint(forMedia media: Fraction) -> Fraction {
            let mediaSpan = mediaEnd.doubleValue - mediaStart.doubleValue
            let timelineSpan = timelineEnd.doubleValue - timelineStart.doubleValue
            guard abs(mediaSpan) > .ulpOfOne else { return timelineStart }
            let t = (media.doubleValue - mediaStart.doubleValue) / mediaSpan
            return Fraction(double: timelineStart.doubleValue + t * timelineSpan)
        }

        /// Maps a timeline-axis point through this segment onto the media axis.
        public func mediaPoint(forTimeline timeline: Fraction) -> Fraction {
            let timelineSpan = timelineEnd.doubleValue - timelineStart.doubleValue
            let mediaSpan = mediaEnd.doubleValue - mediaStart.doubleValue
            guard abs(timelineSpan) > .ulpOfOne else { return mediaStart }
            let t = (timeline.doubleValue - timelineStart.doubleValue) / timelineSpan
            return Fraction(double: mediaStart.doubleValue + t * mediaSpan)
        }

        /// Composes `child` through each overlapping parent segment.
        ///
        /// `parents` is ordered outermost → innermost (same as walk push order).
        public static func composing(
            parents: [RetimingSegment],
            child: RetimingSegment
        ) -> [RetimingSegment] {
            guard !parents.isEmpty else { return [child] }
            var current = [child]
            // Innermost parent first.
            for parent in parents.reversed() {
                current = current.flatMap { composing(parent: parent, child: $0) }
            }
            return current
        }

        /// Composes every child through the parent chain (outermost → innermost).
        ///
        /// Useful when both a container and a nested clip expose multi-point ``TimeMap``
        /// segments: each child is composed independently, then results are concatenated.
        public static func composing(
            parents: [RetimingSegment],
            children: [RetimingSegment]
        ) -> [RetimingSegment] {
            guard !children.isEmpty else { return [] }
            guard !parents.isEmpty else { return children }
            return children.flatMap { composing(parents: parents, child: $0) }
        }
    }
}
