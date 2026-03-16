//
//  MediaExtraction.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for extracting media references from FCPXML and copying them to a location.
//

import Foundation

/// Extracts media file references from FCPXML documents and can copy those files to a destination.
@available(macOS 12.0, *)
public protocol MediaExtraction: Sendable {

    /// Extracts all media references (asset media-rep src, locator url) from the document.
    /// - Parameters:
    ///   - document: Parsed FCPXML document.
    ///   - baseURL: Optional base URL to resolve relative src (e.g. URL of the .fcpxml file or .fcpxmld bundle).
    /// - Returns: Result with references; urls may be nil for relative src when baseURL is nil.
    func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL?) -> MediaExtractionResult

    /// Extracts media references (async).
    func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL?) async -> MediaExtractionResult

    /// Copies all referenced media files (file URLs only) to the destination directory.
    /// Deduplicates by source URL; uses suggestedFilename or lastPathComponent; uniquifies on conflict.
    /// - Parameters:
    ///   - document: Parsed FCPXML document.
    ///   - destinationURL: Directory to copy files into (e.g. /path/to/Media).
    ///   - baseURL: Optional base URL to resolve relative src.
    ///   - progress: Optional reporter called once per processed file (e.g. CLI progress bar).
    /// - Returns: Result with copied, skipped, and failed entries.
    func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL?, progress: (any ProgressReporter)?) -> MediaCopyResult

    /// Copies referenced media (async).
    func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL?, progress: (any ProgressReporter)?) async -> MediaCopyResult
}
