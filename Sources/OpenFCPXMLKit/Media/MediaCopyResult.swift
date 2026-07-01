//
//  MediaCopyResult.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License

//
//
//	Result of copying referenced media files to a destination.
//

import Foundation

/// Outcome of copying one media file.
@available(macOS 26.0, *)
public enum MediaCopyEntry: Sendable, Equatable {

    /// File was copied successfully.
    case copied(source: URL, destination: URL)

    /// Skipped (e.g. not a file URL, file missing, or duplicate).
    case skipped(source: URL, reason: String)

    /// Copy failed.
    case failed(source: URL, error: String)

    public var sourceURL: URL {
        switch self {
        case .copied(let src, _), .skipped(let src, _), .failed(let src, _):
            return src
        }
    }
}

/// Result of copying all referenced media from an FCPXML document to a destination directory.
@available(macOS 26.0, *)
public struct MediaCopyResult: Sendable, Equatable {

    /// Per-file outcome (copied, skipped, or failed).
    public let entries: [MediaCopyEntry]

    /// Successfully copied pairs (source, destination).
    public var copied: [(source: URL, destination: URL)] {
        entries.compactMap { entry in
            if case .copied(let src, let dest) = entry { return (src, dest) }
            return nil
        }
    }

    /// Sources that were skipped.
    public var skipped: [MediaCopyEntry] {
        entries.filter { if case .skipped = $0 { return true }; return false }
    }

    /// Sources that failed to copy.
    public var failed: [MediaCopyEntry] {
        entries.filter { if case .failed = $0 { return true }; return false }
    }

    public init(entries: [MediaCopyEntry]) {
        self.entries = entries
    }

    public static let empty = MediaCopyResult(entries: [])
}
