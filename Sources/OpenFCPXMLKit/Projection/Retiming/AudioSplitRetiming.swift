//
//  AudioSplitRetiming.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	J/L-cut (split edit) retiming for video vs audio projection channels.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Resolves video and audio retiming segment lists for a clip, including
    /// `audioStart` / `audioDuration` split edits.
    enum AudioSplitRetiming {
        /// Video and audio retiming segments for one clip placement.
        struct ChannelSegments: Equatable, Sendable {
            var video: [RetimingSegment]
            var audio: [RetimingSegment]
        }

        /// `true` when audio timeline occupancy differs from the video clip span.
        static func hasSplitEdit(
            videoStart: Fraction?,
            videoDuration: Fraction,
            audioStart: Fraction?,
            audioDuration: Fraction?
        ) -> Bool {
            guard let audioDuration else { return false }
            let clipStart = videoStart ?? .zero
            let resolvedAudioStart = audioStart ?? clipStart
            return resolvedAudioStart != clipStart || audioDuration != videoDuration
        }

        /// Builds channel-specific segments for an asset-clip placement.
        ///
        /// - Video uses ``ClipRetiming`` on the video timeline span (`absoluteStart` +
        ///   `videoDuration` / `videoMediaStart`).
        /// - When a split edit is present, audio uses an identity window on
        ///   `audioTimelineStart`…+`audioDuration` reading media from `audioStart`.
        /// - Without a split, audio reuses the video segments (including any `timeMap`).
        ///
        /// - Parameter clipStartAttribute: The clip's `start` attribute (local media origin
        ///   for scheduling), used for J/L detection. Not the asset resource start fallback.
        static func segments(
            timeMap: TimeMap?,
            absoluteStart: Fraction,
            videoDuration: Fraction,
            videoMediaStart: Fraction,
            clipStartAttribute: Fraction?,
            audioStart: Fraction?,
            audioDuration: Fraction?
        ) -> ChannelSegments {
            let video = ClipRetiming.segments(
                timeMap: timeMap,
                clipOffset: absoluteStart,
                clipDuration: videoDuration,
                mediaStart: videoMediaStart
            )

            guard hasSplitEdit(
                videoStart: clipStartAttribute,
                videoDuration: videoDuration,
                audioStart: audioStart,
                audioDuration: audioDuration
            ),
                let audioDuration
            else {
                return ChannelSegments(video: video, audio: video)
            }

            let clipStart = clipStartAttribute ?? .zero
            let resolvedAudioStart = audioStart ?? clipStart
            let audioTimelineStart = ProjectionTiming.adding(
                absoluteStart,
                ProjectionTiming.subtracting(resolvedAudioStart, clipStart)
            )
            let audio = [
                RetimingSegment.identity(
                    timelineStart: audioTimelineStart,
                    duration: audioDuration,
                    mediaStart: resolvedAudioStart
                )
            ]
            return ChannelSegments(video: video, audio: audio)
        }
    }
}
