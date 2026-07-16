//
//  MediaChannel.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Resolved media channel identity for timeline projection.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// A physical media channel resolved from an ``Asset`` (and related resources).
    ///
    /// One asset may expose multiple video and/or audio channels (`videoSources` /
    /// `audioSources`). Projection emits one ``MediaUsageWindow`` per channel usage.
    public struct MediaChannel: Hashable, Sendable, Equatable {
        /// Channel kind.
        public enum Kind: String, Hashable, Sendable, Equatable {
            case video
            case audio
        }

        /// Resource id of the source asset (for example `"r2"`).
        public var resourceID: String

        /// Asset or clip display name when known.
        public var name: String?

        /// Whether this channel carries video or audio.
        public var kind: Kind

        /// 1-based source index within the asset (`src` / multi-source numbering).
        public var sourceIndex: Int

        /// Original-media representation URL when present.
        public var originalMediaURL: URL?

        /// Proxy-media representation URL when present.
        public var proxyMediaURL: URL?

        /// Native media start on the asset timeline, when known.
        public var nativeStart: Fraction?

        /// Native media duration on the asset timeline, when known.
        public var nativeDuration: Fraction?

        public init(
            resourceID: String,
            name: String? = nil,
            kind: Kind,
            sourceIndex: Int,
            originalMediaURL: URL? = nil,
            proxyMediaURL: URL? = nil,
            nativeStart: Fraction? = nil,
            nativeDuration: Fraction? = nil
        ) {
            self.resourceID = resourceID
            self.name = name
            self.kind = kind
            self.sourceIndex = sourceIndex
            self.originalMediaURL = originalMediaURL
            self.proxyMediaURL = proxyMediaURL
            self.nativeStart = nativeStart
            self.nativeDuration = nativeDuration
        }
    }
}
