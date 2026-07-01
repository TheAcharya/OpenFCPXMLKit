//
//  MediaReference.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License

//
//
//	A single media file reference extracted from FCPXML (asset media-rep or locator).
//

import Foundation

/// A media file reference extracted from an FCPXML document (asset's media-rep or locator).
@available(macOS 26.0, *)
public struct MediaReference: Sendable, Equatable {

    /// Resource ID in the FCPXML (e.g. `"r2"` for an asset).
    public let resourceID: String

    /// Resolved URL of the media file (file or remote). Nil if src was relative and could not be resolved.
    public let url: URL?

    /// Display name from the resource (e.g. asset name).
    public let name: String?

    /// Suggested filename from media-rep, or last path component of url.
    public let suggestedFilename: String?

    /// Whether this reference came from an asset (media-rep) or a locator.
    public let isLocator: Bool

    public init(
        resourceID: String,
        url: URL?,
        name: String? = nil,
        suggestedFilename: String? = nil,
        isLocator: Bool = false
    ) {
        self.resourceID = resourceID
        self.url = url
        self.name = name
        self.suggestedFilename = suggestedFilename
        self.isLocator = isLocator
    }
}
