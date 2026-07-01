//
//  AssetDurationMeasurer.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of asset duration measurement using AVFoundation.
//

#if canImport(AVFoundation)
import Foundation
import CoreMedia
import AVFoundation
import UniformTypeIdentifiers

/// Default implementation of asset duration measurement using AVFoundation.
@available(macOS 26.0, *)
public struct AssetDurationMeasurer: AssetDurationMeasurement, AssetDurationMeasurementSync, Sendable {
    
    public init() {}
    
    // MARK: - Media Type Detection
    
    /// Detects media type from file extension or MIME type.
    private func detectMediaType(from url: URL) -> MediaType {
        // Try to detect from file extension using UTType
        #if canImport(UniformTypeIdentifiers)
        if let utType = UTType(filenameExtension: url.pathExtension) {
            if utType.conforms(to: .audio) {
                return .audio
            } else if utType.conforms(to: .movie) || utType.conforms(to: .video) {
                return .video
            } else if utType.conforms(to: .image) {
                return .image
            }
        }
        #endif
        
        // Fallback to extension-based detection
        let ext = url.pathExtension.lowercased()
        let audioExtensions = ["mp3", "m4a", "aac", "wav", "aiff", "caf", "mp4", "m4v"] // m4v/mp4 can be audio-only
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "mpg", "mpeg"]
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "tiff", "tif", "heic", "heif", "webp"]
        
        if audioExtensions.contains(ext) {
            // Need to check if it's actually video by loading asset
            return .audio // Will be refined by AVAsset if needed
        } else if videoExtensions.contains(ext) {
            return .video
        } else if imageExtensions.contains(ext) {
            return .image
        }
        
        return .unknown
    }
    
    // MARK: - Async Implementation
    
    /// Measures the duration of a media asset.
    ///
    /// Uses AVFoundation to measure duration for audio and video files.
    /// Images are detected but return nil duration.
    ///
    /// - Parameters:
    ///   - url: URL to the media file.
    ///   - progress: Optional progress reporter.
    /// - Returns: Result containing media type and duration.
    /// - Throws: Error if measurement fails.
    public func measureDuration(
        at url: URL,
        progress: ProgressReporter? = nil
    ) async throws -> DurationMeasurementResult {
        // Detect media type first
        var detectedType = detectMediaType(from: url)
        
        // Images don't have duration
        if detectedType == .image {
            return DurationMeasurementResult(mediaType: .image, duration: nil)
        }
        
        // Try to load as AVAsset for audio/video
        let asset = AVURLAsset(url: url)
        
        // Check if asset is readable
        let isReadable = try await asset.load(.isReadable)
        guard isReadable else {
            return DurationMeasurementResult(mediaType: detectedType, duration: nil)
        }
        
        // Determine actual media type by checking tracks
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        
        if !videoTracks.isEmpty {
            // Has video tracks - it's video
            detectedType = .video
        } else if !audioTracks.isEmpty {
            // Has audio tracks but no video - it's audio
            detectedType = .audio
        } else {
            // No tracks found - might be image or unsupported
            if detectedType == .unknown {
                return DurationMeasurementResult(mediaType: .unknown, duration: nil)
            }
            // If we detected it as audio/video but no tracks, return unknown
            return DurationMeasurementResult(mediaType: .unknown, duration: nil)
        }
        
        // Measure duration
        progress?.advance(by: 1)
        let duration = try await asset.load(.duration).seconds
        progress?.advance(by: 1)
        
        return DurationMeasurementResult(mediaType: detectedType, duration: duration)
    }
    
    // MARK: - Sync Implementation
    
    /// Measures the duration of a media asset (synchronous).
    ///
    /// This is a convenience wrapper that runs the async version synchronously.
    /// For better performance and cancellation support, use the async version.
    ///
    /// - Parameter url: URL to the media file.
    /// - Returns: Result containing media type and duration.
    /// - Throws: Error if measurement fails.
    public func measureDuration(at url: URL) throws -> DurationMeasurementResult {
        // Use a thread-safe wrapper to bridge async to sync
        final class ResultBox: @unchecked Sendable {
            var result: DurationMeasurementResult?
            var error: Error?
        }
        
        let box = ResultBox()
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                box.result = try await measureDuration(at: url, progress: nil)
            } catch {
                box.error = error
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = box.error {
            throw error
        }
        
        guard let result = box.result else {
            throw FCPXMLError.documentOperationFailed("Duration measurement failed")
        }
        
        return result
    }
}
#endif
