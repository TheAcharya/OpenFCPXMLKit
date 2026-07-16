//
//  MulticamProjection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Unfolds mc-clip into active (or all) multicam angle storylines.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Projects an `mc-clip` by walking local anchors and unfolding
    /// ``Media/Multicam`` angles selected by ``TimelineProjectionOptions/mcClipAngles``.
    enum MulticamProjection {
        static func project(
            mcClip: MCClip,
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
                .from(srcEnable: mcClip.srcEnable)
            )

            // Local anchors / nested story children on the mc-clip itself.
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

            guard let multicam = mcClip.multicamResource else { return }

            let parentLocalStart = mcClip.start
            switch options.mcClipAngles {
            case .active:
                let (audioAngle, videoAngle) = mcClip.audioVideoMCAngles
                if let videoAngle,
                   let audioAngle,
                   videoAngle.angleID == audioAngle.angleID
                {
                    try projectAngle(
                        videoAngle,
                        resources: resources,
                        ancestors: ancestors,
                        parentRetimings: parentRetimings,
                        lanePath: lanePath,
                        parentAbsoluteStart: absoluteStart,
                        parentLocalStart: parentLocalStart,
                        channelFilter: clipFilter,
                        options: options,
                        onWindow: onWindow,
                        depth: depth
                    )
                } else {
                    if let videoAngle {
                        try projectAngle(
                            videoAngle,
                            resources: resources,
                            ancestors: ancestors,
                        parentRetimings: parentRetimings,
                            lanePath: lanePath,
                            parentAbsoluteStart: absoluteStart,
                            parentLocalStart: parentLocalStart,
                            channelFilter: ChannelKindFilter.intersecting(clipFilter, .videoOnly),
                            options: options,
                            onWindow: onWindow,
                            depth: depth
                        )
                    }
                    if let audioAngle {
                        try projectAngle(
                            audioAngle,
                            resources: resources,
                            ancestors: ancestors,
                        parentRetimings: parentRetimings,
                            lanePath: lanePath,
                            parentAbsoluteStart: absoluteStart,
                            parentLocalStart: parentLocalStart,
                            channelFilter: ChannelKindFilter.intersecting(clipFilter, .audioOnly),
                            options: options,
                            onWindow: onWindow,
                            depth: depth
                        )
                    }
                }

            case .all:
                for angle in multicam.angles {
                    try projectAngle(
                        angle,
                        resources: resources,
                        ancestors: ancestors,
                        parentRetimings: parentRetimings,
                        lanePath: lanePath,
                        parentAbsoluteStart: absoluteStart,
                        parentLocalStart: parentLocalStart,
                        channelFilter: clipFilter,
                        options: options,
                        onWindow: onWindow,
                        depth: depth
                    )
                }
            }
        }

        private static func projectAngle(
            _ angle: Media.Multicam.Angle,
            resources: (any OFKXMLElement)?,
            ancestors: [any OFKXMLElement],
            parentRetimings: [RetimingSegment],
            lanePath: LanePath,
            parentAbsoluteStart: Fraction,
            parentLocalStart: Fraction?,
            channelFilter: ChannelKindFilter,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void,
            depth: Int
        ) throws {
            try SpineProjection.projectStoryElements(
                angle.element.fcpStoryElements,
                resources: resources,
                ancestors: ancestors,
                parentRetimings: parentRetimings,
                lanePath: lanePath,
                parentAbsoluteStart: parentAbsoluteStart,
                parentLocalStart: parentLocalStart,
                channelFilter: channelFilter,
                options: options,
                onWindow: onWindow,
                depth: depth
            )
        }
    }
}
