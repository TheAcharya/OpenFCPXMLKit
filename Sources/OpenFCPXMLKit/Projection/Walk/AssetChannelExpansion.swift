//
//  AssetChannelExpansion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Expands an Asset into video and audio MediaChannel values.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds ``MediaChannel`` values from an ``Asset``.
    ///
    /// Uses `videoSources` / `audioSources` when set; otherwise emits a single channel
    /// when `hasVideo` / `hasAudio` is true. Source indices are 1-based.
    enum AssetChannelExpansion {
        static func channels(from asset: Asset) -> [MediaChannel] {
            let originalURL = mediaURL(in: asset, kind: .originalMedia)
            let proxyURL = mediaURL(in: asset, kind: .proxyMedia)
            let videoCount = max(asset.videoSources, asset.hasVideo ? 1 : 0)
            let audioCount = max(asset.audioSources, asset.hasAudio ? 1 : 0)

            var result: [MediaChannel] = []
            result.reserveCapacity(videoCount + audioCount)

            if videoCount > 0 {
                for index in 1 ... videoCount {
                    result.append(
                        MediaChannel(
                            resourceID: asset.id,
                            name: asset.name,
                            kind: .video,
                            sourceIndex: index,
                            originalMediaURL: originalURL,
                            proxyMediaURL: proxyURL,
                            nativeStart: asset.start,
                            nativeDuration: asset.duration
                        )
                    )
                }
            }

            if audioCount > 0 {
                for index in 1 ... audioCount {
                    result.append(
                        MediaChannel(
                            resourceID: asset.id,
                            name: asset.name,
                            kind: .audio,
                            sourceIndex: index,
                            originalMediaURL: originalURL,
                            proxyMediaURL: proxyURL,
                            nativeStart: asset.start,
                            nativeDuration: asset.duration
                        )
                    )
                }
            }

            return result
        }

        /// Channels from an asset, limited by ``ChannelKindFilter``.
        static func channels(
            from asset: Asset,
            filter: ChannelKindFilter,
            expandAllSourceChannels: Bool = true
        ) -> [MediaChannel] {
            var matched = channels(from: asset).filter { filter.allows($0.kind) }
            if !expandAllSourceChannels {
                matched = matched.filter { $0.sourceIndex == 1 }
            }
            return matched
        }

        /// Channels of a single kind, optionally restricted to a 1-based `srcID` index.
        static func channels(
            from asset: Asset,
            kind: MediaChannel.Kind,
            sourceIndex: Int? = nil
        ) -> [MediaChannel] {
            let matched = channels(from: asset).filter { $0.kind == kind }
            guard let sourceIndex else { return matched }
            return matched.filter { $0.sourceIndex == sourceIndex }
        }

        /// Parses a `srcID` attribute string to a 1-based source index.
        static func sourceIndex(fromSrcID srcID: String?) -> Int? {
            guard let srcID, let value = Int(srcID), value > 0 else { return nil }
            return value
        }

        private static func mediaURL(
            in asset: Asset,
            kind: MediaRep.Kind
        ) -> URL? {
            asset.mediaReps.first(where: { $0.kind == kind })?.src
                ?? (kind == .originalMedia ? asset.mediaRep.src : nil)
        }
    }
}
