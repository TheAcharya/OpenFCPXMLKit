//
//  TimecodeConversion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocols for timecode conversion, FCPXML time strings, and time conforming.
//

import Foundation
import CoreMedia
import SwiftTimecode

/// Protocol defining timecode conversion operations
@available(macOS 26.0, *)
public protocol TimecodeConversion: Sendable {
    /// Converts CMTime to SwiftTimecode Timecode
    /// - Parameters:
    ///   - time: The CMTime to convert
    ///   - frameRate: The target frame rate
    /// - Returns: SwiftTimecode Timecode or nil if conversion fails
    func timecode(from time: CMTime, frameRate: TimecodeFrameRate) -> Timecode?
    
    /// Converts SwiftTimecode Timecode to CMTime
    /// - Parameter timecode: The Timecode to convert
    /// - Returns: CMTime representation
    func cmTime(from timecode: Timecode) -> CMTime
    
    /// Converts timecode components to CMTime
    /// - Parameters:
    ///   - hours: Hours component
    ///   - minutes: Minutes component
    ///   - seconds: Seconds component
    ///   - frames: Frames component
    ///   - frameDuration: Frame duration
    /// - Returns: CMTime representation
    func cmTimeFrom(timecodeHours: Int, timecodeMinutes: Int, timecodeSeconds: Int, timecodeFrames: Int, frameDuration: CMTime) -> CMTime
    
    // MARK: - Async Methods
    
    /// Asynchronously converts CMTime to SwiftTimecode Timecode
    /// - Parameters:
    ///   - time: The CMTime to convert
    ///   - frameRate: The target frame rate
    /// - Returns: SwiftTimecode Timecode or nil if conversion fails
    func timecode(from time: CMTime, frameRate: TimecodeFrameRate) async -> Timecode?
    
    /// Asynchronously converts SwiftTimecode Timecode to CMTime
    /// - Parameter timecode: The Timecode to convert
    /// - Returns: CMTime representation
    func cmTime(from timecode: Timecode) async -> CMTime
    
    /// Asynchronously converts timecode components to CMTime
    /// - Parameters:
    ///   - hours: Hours component
    ///   - minutes: Minutes component
    ///   - seconds: Seconds component
    ///   - frames: Frames component
    ///   - frameDuration: Frame duration
    /// - Returns: CMTime representation
    func cmTimeFrom(timecodeHours: Int, timecodeMinutes: Int, timecodeSeconds: Int, timecodeFrames: Int, frameDuration: CMTime) async -> CMTime
}

/// Protocol defining FCPXML time string operations
@available(macOS 26.0, *)
public protocol FCPXMLTimeStringConversion: Sendable {
    /// Converts FCPXML time string to CMTime
    /// - Parameter timeString: FCPXML formatted time string
    /// - Returns: CMTime representation
    func cmTime(fromFCPXMLTime timeString: String) -> CMTime
    
    /// Converts CMTime to FCPXML time string
    /// - Parameter time: CMTime to convert
    /// - Returns: FCPXML formatted time string
    func fcpxmlTime(fromCMTime time: CMTime) -> String
    
    // MARK: - Async Methods
    
    /// Asynchronously converts FCPXML time string to CMTime
    /// - Parameter timeString: FCPXML formatted time string
    /// - Returns: CMTime representation
    func cmTime(fromFCPXMLTime timeString: String) async -> CMTime
    
    /// Asynchronously converts CMTime to FCPXML time string
    /// - Parameter time: CMTime to convert
    /// - Returns: FCPXML formatted time string
    func fcpxmlTime(fromCMTime time: CMTime) async -> String
}

/// Protocol defining time conforming operations
@available(macOS 26.0, *)
public protocol TimeConforming: Sendable {
    /// Conforms time to frame boundary
    /// - Parameters:
    ///   - time: Time to conform
    ///   - frameDuration: Target frame duration
    /// - Returns: Conformed CMTime
    func conform(time: CMTime, toFrameDuration frameDuration: CMTime) -> CMTime
    
    // MARK: - Async Methods
    
    /// Asynchronously conforms time to frame boundary
    /// - Parameters:
    ///   - time: Time to conform
    ///   - frameDuration: Target frame duration
    /// - Returns: Conformed CMTime
    func conform(time: CMTime, toFrameDuration frameDuration: CMTime) async -> CMTime
} 
