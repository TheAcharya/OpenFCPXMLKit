//
//  ParallelFileIO.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for optimized parallel file read and write operations.
//

import Foundation

/// Result of a parallel file operation.
@available(macOS 26.0, *)
public struct ParallelFileIOResult: Sendable {
    /// The index of the file in the original array (for maintaining order).
    public let index: Int
    
    /// The URL of the file that was read or written.
    public let url: URL
    
    /// Optional data that was read (for read operations).
    public let data: Data?
    
    /// Optional error that occurred during the operation.
    public let error: Error?
    
    /// Whether the operation succeeded.
    public var succeeded: Bool {
        error == nil
    }
    
    public init(index: Int, url: URL, data: Data? = nil, error: Error? = nil) {
        self.index = index
        self.url = url
        self.data = data
        self.error = error
    }
}

/// Protocol for optimized parallel file I/O operations.
@available(macOS 26.0, *)
public protocol ParallelFileIO: Sendable {
    /// Reads multiple files in parallel.
    ///
    /// - Parameters:
    ///   - urls: Array of file URLs to read.
    ///   - progress: Optional progress reporter.
    /// - Returns: Array of results in the same order as input URLs.
    /// - Throws: Error if any read operation fails (depending on implementation).
    func readFiles(
        from urls: [URL],
        progress: ProgressReporter?
    ) async throws -> [ParallelFileIOResult]
    
    /// Writes multiple data buffers to files in parallel.
    ///
    /// - Parameters:
    ///   - dataAndURLs: Array of tuples containing data and destination URLs.
    ///   - progress: Optional progress reporter.
    /// - Returns: Array of results in the same order as input.
    /// - Throws: Error if any write operation fails (depending on implementation).
    func writeFiles(
        dataAndURLs: [(data: Data, url: URL)],
        progress: ProgressReporter?
    ) async throws -> [ParallelFileIOResult]
}
