//
//  MediaExtractionResult.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License

//
//
//	Result of extracting media references from an FCPXML document.
//

import Foundation

/// Result of extracting media references from an FCPXML document.
@available(macOS 26.0, *)
public struct MediaExtractionResult: Sendable, Equatable {

    /// All media references found (assets' media-rep and locators). May contain unresolved URLs if baseURL was missing for relative src.
    public let references: [MediaReference]

    /// Base URL used to resolve relative src attributes, if any.
    public let baseURL: URL?

    /// References that have a resolvable file URL (isFileURL and optionally existing on disk).
    public var fileReferences: [MediaReference] {
        references.filter { ref in
            guard let u = ref.url else { return false }
            return u.isFileURL
        }
    }

    public init(references: [MediaReference], baseURL: URL? = nil) {
        self.references = references
        self.baseURL = baseURL
    }

    /// Empty result.
    public static let empty = MediaExtractionResult(references: [], baseURL: nil)
}
