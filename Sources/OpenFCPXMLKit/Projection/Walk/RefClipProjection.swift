//
// RefClipProjection.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Unfolds ref-clip (compound clip) into its media sequence spine.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Projects a `ref-clip` by walking local anchors and unfolding
    /// ``RefClip/mediaSequence``.
    enum RefClipProjection {
        static func project(
            refClip: RefClip,
            element: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            ancestors: [any OFKXMLElement],
            parentRetimings: [RetimingSegment],
            lanePath: LanePath,
            absoluteStart: Fraction,
            channelFilter: ChannelKindFilter,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void,
            depth: Int = 0
        ) throws {
            let clipFilter = ChannelKindFilter.intersecting(
                channelFilter,
                .from(srcEnable: refClip.srcEnable)
            )

            // Local anchors on the ref-clip itself.
            try SpineProjection.projectStoryElements(
                element.fcpStoryElements,
                resources: resources,
                ancestors: ancestors,
                parentRetimings: parentRetimings,
                lanePath: lanePath,
                parentAbsoluteStart: absoluteStart,
                parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                channelFilter: clipFilter,
                options: options,
                onWindow: onWindow,
                depth: depth
            )

            guard let sequence = refClip.mediaSequence else { return }

            // Nested sequence spine: child offsets are relative to the compound
            // clip's local `start` (and sequence `tcStart` when composing further).
            let nestedLocalStart = refClip.start ?? sequence.tcStart
            let duration = refClip.duration
            let mediaStart = nestedLocalStart ?? .zero

            // When the ref-clip has a timeMap, children compose through it.
            var childParents = parentRetimings
            let containerSegments = ClipRetiming.segments(
                timeMap: refClip.timeMap,
                clipOffset: absoluteStart,
                clipDuration: duration,
                mediaStart: mediaStart
            )
            let isNonIdentity = containerSegments.contains {
                abs($0.scale - 1) > 0.000_1 || $0.isReversed || containerSegments.count > 1
            }
            if isNonIdentity || refClip.timeMap != nil {
                childParents.append(contentsOf: containerSegments)
            }

            try SpineProjection.projectStoryElements(
                sequence.spine.storyElements,
                resources: resources,
                ancestors: ancestors,
                parentRetimings: childParents,
                lanePath: lanePath,
                parentAbsoluteStart: absoluteStart,
                parentLocalStart: nestedLocalStart,
                channelFilter: clipFilter,
                options: options,
                onWindow: onWindow,
                depth: depth
            )
        }
    }
}
