//
//  ParallelFileIOExecutor.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of parallel file I/O using TaskGroup with optimized FileHandle writes.
//

import Foundation

/// Default implementation of parallel file I/O operations.
///
/// Uses `withThrowingTaskGroup` for parallel execution and FileHandle
/// optimization for faster writes on macOS.
@available(macOS 26.0, *)
public struct ParallelFileIOExecutor: ParallelFileIO, Sendable {
    
    /// Task priority for I/O operations (default: high for better performance).
    public let taskPriority: TaskPriority
    
    /// Whether to use FileHandle optimization for writes (default: true on macOS).
    public let useFileHandleOptimization: Bool
    
    /// Whether to pre-allocate file space on macOS (default: true).
    public let preallocateFileSpace: Bool
    
    public init(
        taskPriority: TaskPriority = .high,
        useFileHandleOptimization: Bool = true,
        preallocateFileSpace: Bool = true
    ) {
        self.taskPriority = taskPriority
        self.useFileHandleOptimization = useFileHandleOptimization
        self.preallocateFileSpace = preallocateFileSpace
    }
    
    // MARK: - Parallel Read
    
    /// Reads multiple files in parallel.
    ///
    /// Uses TaskGroup to read files concurrently, maintaining order in results.
    ///
    /// - Parameters:
    ///   - urls: Array of file URLs to read.
    ///   - progress: Optional progress reporter.
    /// - Returns: Array of results in the same order as input URLs.
    /// - Throws: Error if any read operation fails.
    public func readFiles(
        from urls: [URL],
        progress: ProgressReporter? = nil
    ) async throws -> [ParallelFileIOResult] {
        return try await withThrowingTaskGroup(of: ParallelFileIOResult.self) { group in
            var results: [Int: ParallelFileIOResult] = [:]
            
            // Start all read tasks
            for (index, url) in urls.enumerated() {
                group.addTask(priority: taskPriority) {
                    do {
                        let data = try Data(contentsOf: url)
                        return ParallelFileIOResult(index: index, url: url, data: data, error: nil)
                    } catch {
                        return ParallelFileIOResult(index: index, url: url, data: nil, error: error)
                    }
                }
            }
            
            // Collect results maintaining order
            for try await result in group {
                results[result.index] = result
                
                // Update progress
                progress?.advance(by: 1)
            }
            
            // Return results in original order
            return urls.indices.compactMap { results[$0] }
        }
    }
    
    // MARK: - Parallel Write
    
    /// Writes multiple data buffers to files in parallel.
    ///
    /// Uses TaskGroup with FileHandle optimization for faster writes on macOS.
    /// Pre-allocates file space to reduce fragmentation.
    ///
    /// - Parameters:
    ///   - dataAndURLs: Array of tuples containing data and destination URLs.
    ///   - progress: Optional progress reporter.
    /// - Returns: Array of results in the same order as input.
    /// - Throws: Error if any write operation fails.
    public func writeFiles(
        dataAndURLs: [(data: Data, url: URL)],
        progress: ProgressReporter? = nil
    ) async throws -> [ParallelFileIOResult] {
        return try await withThrowingTaskGroup(of: ParallelFileIOResult.self) { group in
            var results: [Int: ParallelFileIOResult] = [:]
            
            // Start all write tasks
            for (index, dataAndURL) in dataAndURLs.enumerated() {
                group.addTask(priority: taskPriority) {
                    do {
                        if self.useFileHandleOptimization {
                            try await self.writeWithFileHandle(
                                data: dataAndURL.data,
                                to: dataAndURL.url
                            )
                        } else {
                            try dataAndURL.data.write(to: dataAndURL.url, options: .atomic)
                        }
                        
                        return ParallelFileIOResult(index: index, url: dataAndURL.url, data: nil, error: nil)
                    } catch {
                        return ParallelFileIOResult(index: index, url: dataAndURL.url, data: nil, error: error)
                    }
                }
            }
            
            // Collect results maintaining order
            for try await result in group {
                results[result.index] = result
                
                // Update progress
                progress?.advance(by: 1)
            }
            
            // Return results in original order
            return dataAndURLs.indices.compactMap { results[$0] }
        }
    }
    
    // MARK: - FileHandle Optimization
    
    /// Writes data using FileHandle for optimized I/O.
    ///
    /// On macOS, pre-allocates file space to reduce fragmentation.
    ///
    /// - Parameters:
    ///   - data: Data to write.
    ///   - url: Destination URL.
    private func writeWithFileHandle(data: Data, to url: URL) async throws {
        // Create parent directory if needed
        let parentDir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        
        // Create empty file
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        
        let fileHandle = try FileHandle(forWritingTo: url)
        defer {
            try? fileHandle.close()
        }
        
        // Pre-allocate file space on macOS (reduces fragmentation, faster writes)
        #if os(macOS)
        if preallocateFileSpace {
            let fd = fileHandle.fileDescriptor
            let fileSize = Int64(data.count)
            ftruncate(fd, fileSize)
        }
        #endif
        
        // Write data in one operation
        try fileHandle.write(contentsOf: data)
    }
}
