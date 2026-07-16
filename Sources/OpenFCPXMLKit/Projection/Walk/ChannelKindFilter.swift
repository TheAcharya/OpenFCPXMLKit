//
//  ChannelKindFilter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Filters MediaChannel kinds during nested projection walks (srcEnable / angles).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Limits which ``MediaChannel/Kind`` values may emit windows in a walk subtree.
    struct ChannelKindFilter: Sendable, Equatable {
        /// Allowed kinds, or `nil` for both video and audio.
        var allowed: Set<MediaChannel.Kind>?

        static let all = ChannelKindFilter(allowed: nil)
        static let videoOnly = ChannelKindFilter(allowed: [.video])
        static let audioOnly = ChannelKindFilter(allowed: [.audio])

        func allows(_ kind: MediaChannel.Kind) -> Bool {
            allowed?.contains(kind) ?? true
        }

        /// Intersection of two filters (`nil` = unconstrained).
        static func intersecting(_ lhs: ChannelKindFilter, _ rhs: ChannelKindFilter) -> ChannelKindFilter {
            switch (lhs.allowed, rhs.allowed) {
            case (nil, nil):
                return .all
            case (nil, let rhs?):
                return ChannelKindFilter(allowed: rhs)
            case (let lhs?, nil):
                return ChannelKindFilter(allowed: lhs)
            case (let lhs?, let rhs?):
                return ChannelKindFilter(allowed: lhs.intersection(rhs))
            }
        }

        /// Maps clip `srcEnable` to a channel filter.
        static func from(srcEnable: ClipSourceEnable) -> ChannelKindFilter {
            switch srcEnable {
            case .all: return .all
            case .video: return .videoOnly
            case .audio: return .audioOnly
            }
        }
    }
}
