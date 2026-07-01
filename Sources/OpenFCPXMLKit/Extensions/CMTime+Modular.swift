//
//  CMTime+Modular.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Modular CMTime extensions with dependency-injected timecode conversion.
//

import Foundation
import CoreMedia
import SwiftTimecode

/// Modular CMTime extensions using dependency injection
@available(macOS 26.0, *)
public extension CMTime {
    
    /// Converts CMTime to SwiftTimecode Timecode using injected converter
    /// - Parameters:
    ///   - frameRate: Target frame rate
    ///   - converter: Timecode converter service
    /// - Returns: Timecode or nil
    func timecode(frameRate: TimecodeFrameRate, using converter: TimecodeConversion) -> Timecode? {
        return converter.timecode(from: self, frameRate: frameRate)
    }
    
    /// Converts CMTime to FCPXML time string using injected converter
    /// - Parameter converter: Timecode converter service
    /// - Returns: FCPXML formatted time string
    func fcpxmlTime(using converter: FCPXMLTimeStringConversion) -> String {
        return converter.fcpxmlTime(fromCMTime: self)
    }
    
    /// Conforms time to frame boundary using injected converter
    /// - Parameters:
    ///   - frameDuration: Target frame duration
    ///   - converter: Time conforming service
    /// - Returns: Conformed CMTime
    func conformed(toFrameDuration frameDuration: CMTime, using converter: TimeConforming) -> CMTime {
        return converter.conform(time: self, toFrameDuration: frameDuration)
    }
} 
