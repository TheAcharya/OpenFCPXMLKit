//
//  FCPXMLExportAsset.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Asset descriptor for FCPXML export workflow.
//

import Foundation
import CoreMedia

/// Describes an asset to be written as a resource in FCPXML (and optionally into a bundle).
@available(macOS 26.0, *)
public struct FCPXMLExportAsset: Sendable, Equatable {

    /// Resource ID (e.g. `"r2"`). Must match `TimelineClip.assetRef` for clips using this asset.
    public var id: String

    /// Display name (optional).
    public var name: String?

    /// URL of the media file (file:// or path). Used for `src` and for bundle Media folder.
    public var src: URL

    /// Duration of the asset (optional). If nil, omitted from asset element.
    public var duration: CMTime?

    /// Whether the asset has video.
    public var hasVideo: Bool

    /// Whether the asset has audio.
    public var hasAudio: Bool

    /// Optional path for FCPXML `src` when exporting to a bundle (e.g. `"Media/clip.mov"`). If set, exporter uses this instead of `src.absoluteString`.
    public var relativePath: String?

    public init(
        id: String,
        name: String? = nil,
        src: URL,
        duration: CMTime? = nil,
        hasVideo: Bool = true,
        hasAudio: Bool = true,
        relativePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.src = src
        self.duration = duration
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.relativePath = relativePath
    }
}
