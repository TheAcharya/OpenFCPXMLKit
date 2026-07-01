//
//  SilenceDetection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for detecting silence in audio files.
//

import Foundation
import CoreMedia
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Result of silence detection analysis.
@available(macOS 26.0, *)
public struct SilenceDetectionResult: Sendable, Equatable {
    /// Total duration of the audio file in seconds.
    public let duration: Double
    
    /// Amount of silence to trim from the start, in seconds.
    public let trimStart: Double
    
    /// Amount of silence to trim from the end, in seconds.
    public let trimEnd: Double
    
    /// Whether the entire file is silence.
    public var isEntirelySilent: Bool {
        trimStart >= duration
    }
    
    /// Duration of actual audio content (duration minus trimStart minus trimEnd).
    public var audioDuration: Double {
        max(0, duration - trimStart - trimEnd)
    }
    
    public init(duration: Double, trimStart: Double, trimEnd: Double) {
        self.duration = duration
        self.trimStart = trimStart
        self.trimEnd = trimEnd
    }
}

#if canImport(AVFoundation)
/// Protocol for detecting silence in audio files.
@available(macOS 26.0, *)
public protocol SilenceDetection: Sendable {
    /// Detects silence at the beginning and end of an audio file.
    ///
    /// - Parameters:
    ///   - url: URL to the audio file.
    ///   - threshold: Audio level threshold in dB (default: -90dB for near-zero detection).
    ///   - progress: Optional progress reporter.
    /// - Returns: Result containing duration and trim points.
    /// - Throws: Error if detection fails.
    func detectSilence(
        at url: URL,
        threshold: Float,
        progress: ProgressReporter?
    ) async throws -> SilenceDetectionResult
}

/// Synchronous version of silence detection protocol.
@available(macOS 26.0, *)
public protocol SilenceDetectionSync: Sendable {
    /// Detects silence at the beginning and end of an audio file (synchronous).
    ///
    /// - Parameters:
    ///   - url: URL to the audio file.
    ///   - threshold: Audio level threshold in dB (default: -90dB for near-zero detection).
    /// - Returns: Result containing duration and trim points.
    /// - Throws: Error if detection fails.
    func detectSilence(
        at url: URL,
        threshold: Float
    ) throws -> SilenceDetectionResult
}
#endif
