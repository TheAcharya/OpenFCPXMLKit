//
//  TimecodeConverter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Implementation of timecode conversion, FCPXML time strings, and time conforming.
//

import Foundation
import CoreMedia
import SwiftTimecode
import SwiftExtensions

/// Default implementation of `TimecodeConversion`, `FCPXMLTimeStringConversion`, and `TimeConforming`.
///
/// Converts between CMTime, SwiftTimecode Timecode, and FCPXML time strings.
/// Uses `Int32(clamping:)` for safe integer conversion and guards against non-finite values.
@available(macOS 26.0, *)
public final class TimecodeConverter: TimecodeConversion, FCPXMLTimeStringConversion, TimeConforming, Sendable {
    
    /// Creates a new timecode converter.
    public init() {}
    
    // MARK: - Internal Sync Implementations
    
    private func _timecode(from time: CMTime, frameRate: TimecodeFrameRate) -> Timecode? {
        let seconds = CMTimeGetSeconds(time)
        guard seconds.isFinite else { return nil }
        do {
            return try Timecode(.realTime(seconds: seconds), at: frameRate)
        } catch {
            return nil
        }
    }
    
    private func _cmTime(from timecode: Timecode) -> CMTime {
        let seconds = timecode.realTimeValue
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }
    
    private func _cmTimeFrom(timecodeHours: Int, timecodeMinutes: Int, timecodeSeconds: Int, timecodeFrames: Int, frameDuration: CMTime) -> CMTime {
        let totalSeconds = Double(timecodeHours * 3600 + timecodeMinutes * 60 + timecodeSeconds)
        let frameTime = CMTimeMultiply(frameDuration, multiplier: Int32(clamping: timecodeFrames))
        return CMTime(seconds: totalSeconds, preferredTimescale: 600) + frameTime
    }
    
    private func _cmTime(fromFCPXMLTime timeString: String) -> CMTime {
        // Strip trailing "s" suffix used by FCPXML (e.g. "7200/2400s", "0s")
        let stripped = timeString.hasSuffix("s")
            ? String(timeString.dropLast())
            : timeString
        
        let components = stripped.components(separatedBy: "/")
        if components.count == 2,
           let numerator = Int64(components[0]),
           let denominator = Int32(components[1]),
           denominator != 0 {
            return CMTime(value: numerator, timescale: denominator)
        } else if components.count == 1, let seconds = Double(components[0]) {
            // Whole-second format (e.g. "0s" -> "0", "10s" -> "10")
            return CMTime(seconds: seconds, preferredTimescale: 600)
        }
        return .zero
    }
    
    private func _fcpxmlTime(fromCMTime time: CMTime) -> String {
        guard CMTIME_IS_VALID(time), time.timescale > 0 else { return "0s" }
        if time.value == 0 { return "0s" }
        return "\(time.value)/\(time.timescale)s"
    }
    
    private func _conform(time: CMTime, toFrameDuration frameDuration: CMTime) -> CMTime {
        let timeSeconds = CMTimeGetSeconds(time)
        guard timeSeconds.isFinite else { return .zero }
        let frameDurationSeconds = CMTimeGetSeconds(frameDuration)
        guard frameDurationSeconds > 0, frameDurationSeconds.isFinite else {
            return .zero
        }
        let frameCount = timeSeconds / frameDurationSeconds
        let roundedFrames = floor(frameCount)
        let clampedFrames = Int32(clamping: Int64(roundedFrames))
        return CMTimeMultiply(frameDuration, multiplier: clampedFrames)
    }
    
    // MARK: - TimecodeConversion (Sync)
    
    /// Converts a CMTime to a SwiftTimecode Timecode at the given frame rate.
    public func timecode(from time: CMTime, frameRate: TimecodeFrameRate) -> Timecode? {
        _timecode(from: time, frameRate: frameRate)
    }
    
    /// Converts a SwiftTimecode Timecode to CMTime.
    public func cmTime(from timecode: Timecode) -> CMTime {
        _cmTime(from: timecode)
    }
    
    /// Builds a CMTime from individual timecode components and a frame duration.
    public func cmTimeFrom(timecodeHours: Int, timecodeMinutes: Int, timecodeSeconds: Int, timecodeFrames: Int, frameDuration: CMTime) -> CMTime {
        _cmTimeFrom(timecodeHours: timecodeHours, timecodeMinutes: timecodeMinutes, timecodeSeconds: timecodeSeconds, timecodeFrames: timecodeFrames, frameDuration: frameDuration)
    }
    
    // MARK: - TimecodeConversion (Async)
    
    /// Converts a CMTime to a SwiftTimecode Timecode at the given frame rate asynchronously.
    public func timecode(from time: CMTime, frameRate: TimecodeFrameRate) async -> Timecode? {
        _timecode(from: time, frameRate: frameRate)
    }
    
    /// Converts a SwiftTimecode Timecode to CMTime asynchronously.
    public func cmTime(from timecode: Timecode) async -> CMTime {
        _cmTime(from: timecode)
    }
    
    /// Builds a CMTime from individual timecode components asynchronously.
    public func cmTimeFrom(timecodeHours: Int, timecodeMinutes: Int, timecodeSeconds: Int, timecodeFrames: Int, frameDuration: CMTime) async -> CMTime {
        _cmTimeFrom(timecodeHours: timecodeHours, timecodeMinutes: timecodeMinutes, timecodeSeconds: timecodeSeconds, timecodeFrames: timecodeFrames, frameDuration: frameDuration)
    }
    
    // MARK: - FCPXMLTimeStringConversion (Sync)
    
    /// Parses an FCPXML time string (e.g. "3600/2400s") into CMTime.
    public func cmTime(fromFCPXMLTime timeString: String) -> CMTime {
        _cmTime(fromFCPXMLTime: timeString)
    }
    
    /// Formats a CMTime as an FCPXML time string (e.g. "3600/2400s").
    public func fcpxmlTime(fromCMTime time: CMTime) -> String {
        _fcpxmlTime(fromCMTime: time)
    }
    
    // MARK: - FCPXMLTimeStringConversion (Async)
    
    /// Parses an FCPXML time string into CMTime asynchronously.
    public func cmTime(fromFCPXMLTime timeString: String) async -> CMTime {
        _cmTime(fromFCPXMLTime: timeString)
    }
    
    /// Formats a CMTime as an FCPXML time string asynchronously.
    public func fcpxmlTime(fromCMTime time: CMTime) async -> String {
        _fcpxmlTime(fromCMTime: time)
    }
    
    // MARK: - TimeConforming (Sync)
    
    /// Snaps a time value to the nearest frame boundary for the given frame duration.
    public func conform(time: CMTime, toFrameDuration frameDuration: CMTime) -> CMTime {
        _conform(time: time, toFrameDuration: frameDuration)
    }
    
    // MARK: - TimeConforming (Async)
    
    /// Snaps a time value to the nearest frame boundary asynchronously.
    public func conform(time: CMTime, toFrameDuration frameDuration: CMTime) async -> CMTime {
        _conform(time: time, toFrameDuration: frameDuration)
    }
}
