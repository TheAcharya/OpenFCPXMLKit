//
//  SpineProjection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Recursive spine / anchored-story walk for timeline projection.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Walks story elements (primary spine, nested spines, anchored children,
    /// multicam angles, ref-clip sequences, auditions) emitting ``MediaUsageWindow``
    /// values for resolved media leaves.
    enum SpineProjection {
        static func projectStoryElements(
            _ elements: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            ancestors: [any OFKXMLElement] = [],
            parentRetimings: [RetimingSegment] = [],
            lanePath: LanePath,
            parentAbsoluteStart: Fraction,
            parentLocalStart: Fraction?,
            channelFilter: ChannelKindFilter = .all,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void,
            depth: Int = 0
        ) throws {
            // Guard against pathological nesting (cyclic media refs, etc.).
            guard depth < 64 else { return }

            for element in elements {
                try projectStoryElement(
                    element,
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

        private static func shouldEmitWindows(
            for element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            options: TimelineProjectionOptions
        ) -> Bool {
            guard options.excludeFullyOccluded else { return true }
            return element._fcpEffectiveOcclusion(ancestors: ancestors) != .fullyOccluded
        }

        private static func projectStoryElement(
            _ element: any OFKXMLElement,
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
            let nextDepth = depth + 1
            let childAncestors = [element] + ancestors
            let elementLanePath = lanePath.appending(element.fcpLane)
            let absoluteStart = ProjectionTiming.absoluteStart(
                offset: element.fcpOffset,
                parentAbsoluteStart: parentAbsoluteStart,
                parentLocalStart: parentLocalStart
            )
            let emitWindows = shouldEmitWindows(
                for: element,
                ancestors: ancestors,
                options: options
            )

            if let assetClip = element.fcpAsAssetClip {
                if emitWindows, assetClip.enabled || options.includeDisabled {
                    try emitAssetClipWindows(
                        assetClip: assetClip,
                        element: element,
                        ancestors: ancestors,
                        parentRetimings: parentRetimings,
                        resources: resources,
                        lanePath: elementLanePath,
                        absoluteStart: absoluteStart,
                        channelFilter: channelFilter,
                        options: options,
                        onWindow: onWindow
                    )
                    emitClipAnnotationsIfNeeded(
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        absoluteStart: absoluteStart,
                        options: options
                    )
                }
                if assetClip.enabled || options.includeDisabled {
                    try projectStoryElements(
                        element.fcpStoryElements,
                        resources: resources,
                        ancestors: childAncestors,
                        parentRetimings: parentRetimings,
                        lanePath: elementLanePath,
                        parentAbsoluteStart: absoluteStart,
                        parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                        channelFilter: ChannelKindFilter.intersecting(
                            channelFilter,
                            .from(srcEnable: assetClip.srcEnable)
                        ),
                        options: options,
                        onWindow: onWindow,
                        depth: nextDepth
                    )
                }
                return
            }

            if let video = element.fcpAsVideo {
                if emitWindows, video.enabled || options.includeDisabled {
                    try emitVideoWindows(
                        video: video,
                        element: element,
                        ancestors: ancestors,
                        parentRetimings: parentRetimings,
                        resources: resources,
                        lanePath: elementLanePath,
                        absoluteStart: absoluteStart,
                        channelFilter: channelFilter,
                        options: options,
                        onWindow: onWindow
                    )
                    emitClipAnnotationsIfNeeded(
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        absoluteStart: absoluteStart,
                        options: options
                    )
                }
                if video.enabled || options.includeDisabled {
                    try projectStoryElements(
                        element.fcpStoryElements,
                        resources: resources,
                        ancestors: childAncestors,
                        parentRetimings: parentRetimings,
                        lanePath: elementLanePath,
                        parentAbsoluteStart: absoluteStart,
                        parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                        channelFilter: channelFilter,
                        options: options,
                        onWindow: onWindow,
                        depth: nextDepth
                    )
                }
                return
            }

            if let audio = element.fcpAsAudio {
                if emitWindows, audio.enabled || options.includeDisabled {
                    try emitAudioWindows(
                        audio: audio,
                        element: element,
                        ancestors: ancestors,
                        parentRetimings: parentRetimings,
                        resources: resources,
                        lanePath: elementLanePath,
                        absoluteStart: absoluteStart,
                        channelFilter: channelFilter,
                        options: options,
                        onWindow: onWindow
                    )
                    emitClipAnnotationsIfNeeded(
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        absoluteStart: absoluteStart,
                        options: options
                    )
                }
                if audio.enabled || options.includeDisabled {
                    try projectStoryElements(
                        element.fcpStoryElements,
                        resources: resources,
                        ancestors: childAncestors,
                        parentRetimings: parentRetimings,
                        lanePath: elementLanePath,
                        parentAbsoluteStart: absoluteStart,
                        parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                        channelFilter: channelFilter,
                        options: options,
                        onWindow: onWindow,
                        depth: nextDepth
                    )
                }
                return
            }

            if let spine = element.fcpAsSpine {
                try projectStoryElements(
                    spine.storyElements,
                    resources: resources,
                    ancestors: childAncestors,
                    parentRetimings: parentRetimings,
                    lanePath: elementLanePath,
                    parentAbsoluteStart: absoluteStart,
                    parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                    channelFilter: channelFilter,
                    options: options,
                    onWindow: onWindow,
                    depth: nextDepth
                )
                return
            }

            if let audition = element.fcpAsAudition {
                let clips: [any OFKXMLElement]
                switch options.auditions {
                case .active:
                    clips = [audition.activeClip].compactMap { $0 }
                case .all:
                    clips = Array(audition.clips)
                }
                try projectStoryElements(
                    clips,
                    resources: resources,
                    ancestors: childAncestors,
                    parentRetimings: parentRetimings,
                    lanePath: elementLanePath,
                    parentAbsoluteStart: absoluteStart,
                    parentLocalStart: nil,
                    channelFilter: channelFilter,
                    options: options,
                    onWindow: onWindow,
                    depth: nextDepth
                )
                return
            }

            if let mcClip = element.fcpAsMCClip {
                guard mcClip.enabled || options.includeDisabled else { return }
                try MulticamProjection.project(
                    mcClip: mcClip,
                    element: element,
                    resources: resources,
                    ancestors: childAncestors,
                    parentRetimings: parentRetimings,
                    lanePath: elementLanePath,
                    absoluteStart: absoluteStart,
                    channelFilter: channelFilter,
                    options: options,
                    onWindow: onWindow,
                    depth: nextDepth
                )
                return
            }

            if let refClip = element.fcpAsRefClip {
                guard refClip.enabled || options.includeDisabled else { return }
                try RefClipProjection.project(
                    refClip: refClip,
                    element: element,
                    resources: resources,
                    ancestors: childAncestors,
                    parentRetimings: parentRetimings,
                    lanePath: elementLanePath,
                    absoluteStart: absoluteStart,
                    channelFilter: channelFilter,
                    options: options,
                    onWindow: onWindow,
                    depth: nextDepth
                )
                return
            }

            // Titles have no media channel but still need clip annotations (title text,
            // markers, keywords) even when they have no nested story children.
            if let title = element.fcpAsTitle {
                guard title.enabled || options.includeDisabled else { return }
                if emitWindows {
                    emitClipAnnotationsIfNeeded(
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        absoluteStart: absoluteStart,
                        options: options
                    )
                }
                try projectStoryElements(
                    title.storyElements,
                    resources: resources,
                    ancestors: childAncestors,
                    parentRetimings: parentRetimings,
                    lanePath: elementLanePath,
                    parentAbsoluteStart: absoluteStart,
                    parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                    channelFilter: channelFilter,
                    options: options,
                    onWindow: onWindow,
                    depth: nextDepth
                )
                return
            }

            // Transitions have no media channel but still need transition (+ marker) annotations
            // even when they have no nested story children.
            if let transition = element.fcpAsTransition {
                if emitWindows {
                    emitClipAnnotationsIfNeeded(
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        absoluteStart: absoluteStart,
                        options: options
                    )
                }
                try projectStoryElements(
                    transition.storyElements,
                    resources: resources,
                    ancestors: childAncestors,
                    parentRetimings: parentRetimings,
                    lanePath: elementLanePath,
                    parentAbsoluteStart: absoluteStart,
                    parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                    channelFilter: channelFilter,
                    options: options,
                    onWindow: onWindow,
                    depth: nextDepth
                )
                return
            }

            // Gaps, sync-clip / clip shells: no leaf media here,
            // but anchored / nested story children may still project.
            // Skip annotation-only story elements (markers, keywords, captions).
            if let type = element.fcpElementType, type.isAnnotation {
                return
            }

            let childElements = element.fcpStoryElements
            guard !childElements.isEmpty else { return }

            let includeSubtree: Bool = {
                if let clip = element.fcpAsClip { return clip.enabled || options.includeDisabled }
                if let sync = element.fcpAsSyncClip { return sync.enabled || options.includeDisabled }
                if let gap = element.fcpAsGap { return gap.enabled || options.includeDisabled }
                return true
            }()
            guard includeSubtree else { return }

            // Sync-clip / clip shells may host markers and keywords without media leaves.
            if emitWindows {
                emitClipAnnotationsIfNeeded(
                    element: element,
                    ancestors: ancestors,
                    resources: resources,
                    absoluteStart: absoluteStart,
                    options: options
                )
            }

            try projectStoryElements(
                childElements,
                resources: resources,
                ancestors: childAncestors,
                parentRetimings: parentRetimings,
                lanePath: elementLanePath,
                parentAbsoluteStart: absoluteStart,
                parentLocalStart: ProjectionTiming.localStartForChildren(of: element),
                channelFilter: channelFilter,
                options: options,
                onWindow: onWindow,
                depth: nextDepth
            )
        }

        private static func emitAssetClipWindows(
            assetClip: AssetClip,
            element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            parentRetimings: [RetimingSegment],
            resources: (any OFKXMLElement)?,
            lanePath: LanePath,
            absoluteStart: Fraction,
            channelFilter: ChannelKindFilter,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) throws {
            guard let asset = element.fcpResource(forID: assetClip.ref, in: resources)?.fcpAsAsset
            else { return }

            let filter = ChannelKindFilter.intersecting(
                channelFilter,
                .from(srcEnable: assetClip.srcEnable)
            )
            let channels = AssetChannelExpansion.channels(
                from: asset,
                filter: filter,
                expandAllSourceChannels: options.expandAllSourceChannels
            )
            guard !channels.isEmpty else { return }

            let videoDuration = assetClip.duration ?? .zero
            let videoMediaStart = assetClip.start ?? asset.start ?? .zero
            let channelSegments = AudioSplitRetiming.segments(
                timeMap: assetClip.timeMap,
                absoluteStart: absoluteStart,
                videoDuration: videoDuration,
                videoMediaStart: videoMediaStart,
                clipStartAttribute: assetClip.start,
                audioStart: assetClip.audioStart,
                audioDuration: assetClip.audioDuration
            )
            let displayName = assetClip.name ?? asset.name

            for channel in channels {
                let retimings = channel.kind == .audio ? channelSegments.audio : channelSegments.video
                for retiming in retimings {
                    try emitComposedWindows(
                        channel: channel,
                        lanePath: lanePath,
                        retiming: retiming,
                        parentRetimings: parentRetimings,
                        displayName: displayName,
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        options: options,
                        onWindow: onWindow
                    )
                }
            }
        }

        private static func emitVideoWindows(
            video: Video,
            element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            parentRetimings: [RetimingSegment],
            resources: (any OFKXMLElement)?,
            lanePath: LanePath,
            absoluteStart: Fraction,
            channelFilter: ChannelKindFilter,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) throws {
            guard channelFilter.allows(.video) else { return }
            guard let asset = element.fcpResource(forID: video.ref, in: resources)?.fcpAsAsset
            else { return }

            let channels = AssetChannelExpansion.channels(
                from: asset,
                kind: .video,
                sourceIndex: AssetChannelExpansion.sourceIndex(fromSrcID: video.srcID)
            )
            guard !channels.isEmpty else { return }

            let mediaStart = video.start ?? asset.start ?? .zero
            let retimings = ClipRetiming.segments(
                timeMap: video.timeMap,
                clipOffset: absoluteStart,
                clipDuration: video.duration,
                mediaStart: mediaStart
            )
            let displayName = video.name ?? asset.name

            for channel in channels {
                for retiming in retimings {
                    try emitComposedWindows(
                        channel: channel,
                        lanePath: lanePath,
                        retiming: retiming,
                        parentRetimings: parentRetimings,
                        displayName: displayName,
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        options: options,
                        onWindow: onWindow
                    )
                }
            }
        }

        private static func emitAudioWindows(
            audio: Audio,
            element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            parentRetimings: [RetimingSegment],
            resources: (any OFKXMLElement)?,
            lanePath: LanePath,
            absoluteStart: Fraction,
            channelFilter: ChannelKindFilter,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) throws {
            guard channelFilter.allows(.audio) else { return }
            guard let asset = element.fcpResource(forID: audio.ref, in: resources)?.fcpAsAsset
            else { return }

            let channels = AssetChannelExpansion.channels(
                from: asset,
                kind: .audio,
                sourceIndex: AssetChannelExpansion.sourceIndex(fromSrcID: audio.srcID)
            )
            guard !channels.isEmpty else { return }

            let mediaStart = audio.start ?? asset.start ?? .zero
            let retimings = ClipRetiming.segments(
                timeMap: audio.timeMap,
                clipOffset: absoluteStart,
                clipDuration: audio.duration,
                mediaStart: mediaStart
            )
            let displayName = audio.name ?? asset.name

            for channel in channels {
                for retiming in retimings {
                    try emitComposedWindows(
                        channel: channel,
                        lanePath: lanePath,
                        retiming: retiming,
                        parentRetimings: parentRetimings,
                        displayName: displayName,
                        element: element,
                        ancestors: ancestors,
                        resources: resources,
                        options: options,
                        onWindow: onWindow
                    )
                }
            }
        }

        private static func emitComposedWindows(
            channel: MediaChannel,
            lanePath: LanePath,
            retiming: RetimingSegment,
            parentRetimings: [RetimingSegment],
            displayName: String?,
            element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            options: TimelineProjectionOptions,
            onWindow: (MediaUsageWindow) throws -> Void
        ) throws {
            let composed = RetimingSegment.composing(parents: parentRetimings, child: retiming)
            let annotations = WindowAnnotationBuilder.annotations(
                for: element,
                ancestors: ancestors,
                resources: resources,
                options: options,
                channelKind: channel.kind
            )
            for segment in composed {
                try onWindow(
                    MediaUsageWindow(
                        channel: channel,
                        lanePath: lanePath,
                        retiming: segment,
                        clipDisplayName: displayName,
                        roles: annotations.roles,
                        effects: annotations.effects,
                        breadcrumbs: annotations.breadcrumbs
                    )
                )
            }
        }

        /// Emits clip/title annotations once per host when a collector is installed.
        static func emitClipAnnotationsIfNeeded(
            element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            absoluteStart: Fraction,
            options: TimelineProjectionOptions
        ) {
            guard options.includeAnnotations,
                  let collector = TimelineProjectionLocals.clipAnnotationCollector,
                  let annotations = WindowAnnotationBuilder.clipAnnotations(
                      for: element,
                      ancestors: ancestors,
                      resources: resources,
                      absoluteStart: absoluteStart,
                      options: options
                  )
            else { return }
            collector.append(annotations)
        }
    }
}
