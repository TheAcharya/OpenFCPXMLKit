//
//  AssetDurationMeasurement.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for measuring duration of media assets (audio, video, images).
//

import Foundation
import CoreMedia
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Media type classification for assets.
@available(macOS 26.0, *)
public enum MediaType: Sendable, Equatable {
    /// Audio media (has duration).
    case audio
    
    /// Video media (has duration).
    case video
    
    /// Image media (no duration, static).
    case image
    
    /// Unknown or unsupported media type.
    case unknown
}

/// Result of asset duration measurement.
@available(macOS 26.0, *)
public struct DurationMeasurementResult: Sendable, Equatable {
    /// The detected media type.
    public let mediaType: MediaType
    
    /// Duration in seconds (nil for images or if measurement failed).
    public let duration: Double?
    
    /// Whether the asset has a measurable duration.
    public var hasDuration: Bool {
        duration != nil
    }
    
    /// Whether the asset is an image (static, no duration).
    public var isImage: Bool {
        mediaType == .image
    }
    
    public init(mediaType: MediaType, duration: Double?) {
        self.mediaType = mediaType
        self.duration = duration
    }
}

#if canImport(AVFoundation)
/// Protocol for measuring duration of media assets.
@available(macOS 26.0, *)
public protocol AssetDurationMeasurement: Sendable {
    /// Measures the duration of a media asset.
    ///
    /// - Parameters:
    ///   - url: URL to the media file.
    ///   - progress: Optional progress reporter.
    /// - Returns: Result containing media type and duration.
    /// - Throws: Error if measurement fails.
    func measureDuration(
        at url: URL,
        progress: ProgressReporter?
    ) async throws -> DurationMeasurementResult
}

/// Synchronous version of asset duration measurement protocol.
@available(macOS 26.0, *)
public protocol AssetDurationMeasurementSync: Sendable {
    /// Measures the duration of a media asset (synchronous).
    ///
    /// - Parameter url: URL to the media file.
    /// - Returns: Result containing media type and duration.
    /// - Throws: Error if measurement fails.
    func measureDuration(at url: URL) throws -> DurationMeasurementResult
}
#endif
