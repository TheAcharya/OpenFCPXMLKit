//
//  MIMETypeDetection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for detecting MIME types from file URLs.
//

import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Protocol for detecting MIME types from file URLs.
@available(macOS 26.0, *)
public protocol MIMETypeDetection: Sendable {
    /// Detects the MIME type of a file at the given URL.
    ///
    /// Uses multiple strategies:
    /// 1. UTType from file extension
    /// 2. AVFoundation asset inspection (for media files)
    /// 3. File extension fallback
    ///
    /// - Parameter url: The file URL to inspect.
    /// - Returns: The detected MIME type string (e.g., "video/mp4", "audio/mpeg", "image/jpeg"), or nil if detection fails.
    func detectMIMEType(at url: URL) async -> String?
}

/// Synchronous version of MIME type detection protocol.
@available(macOS 26.0, *)
public protocol MIMETypeDetectionSync: Sendable {
    /// Detects the MIME type of a file at the given URL (synchronous).
    ///
    /// - Parameter url: The file URL to inspect.
    /// - Returns: The detected MIME type string, or nil if detection fails.
    func detectMIMETypeSync(at url: URL) -> String?
}
