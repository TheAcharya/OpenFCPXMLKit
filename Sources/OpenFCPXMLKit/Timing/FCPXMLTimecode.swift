//
//  FCPXMLTimecode.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Rational time representation for FCPXML using SwiftTimecode Fraction.
//

import Foundation
import CoreMedia
import SwiftTimecode

/// Represents a point in time or duration using rational numbers for FCPXML.
///
/// FCPXML uses rational time values (numerator/denominator) for frame-accurate timing.
/// This type wraps SwiftTimecode's `Fraction` type to provide convenient FCPXML-specific operations.
///
/// ## FCPXML Format
///
/// Time values in FCPXML are expressed as rational numbers with an 's' suffix:
/// - `"1001/30000s"` - One frame at 29.97fps
/// - `"100/2400s"` - One frame at 24fps
/// - `"5s"` - Five seconds (simplified)
///
/// ## Usage
///
/// ```swift
/// // From seconds
/// let fiveSeconds = FCPXMLTimecode(seconds: 5.0)
///
/// // From rational value
/// let oneFrame = FCPXMLTimecode(value: 1001, timescale: 30000)
///
/// // From CMTime
/// let cmTime = CMTime(value: 1001, timescale: 30000)
/// let timecode = FCPXMLTimecode(cmTime: cmTime)
///
/// // Arithmetic
/// let total = clipA.duration + clipB.duration
/// ```
@available(macOS 26.0, *)
public struct FCPXMLTimecode: Sendable, Equatable, Hashable, Codable {
    
    // MARK: - Properties
    
    /// The underlying rational time value.
    internal let fraction: Fraction
    
    /// The numerator of the rational time value.
    public var value: Int64 {
        Int64(fraction.numerator)
    }
    
    /// The denominator of the rational time value (ticks per second).
    public var timescale: Int32 {
        Int32(fraction.denominator)
    }
    
    // MARK: - Computed Properties
    
    /// The time value in seconds.
    public var seconds: Double {
        fraction.doubleValue
    }
    
    /// The FCPXML string representation.
    ///
    /// Returns simplified format when possible:
    /// - `"0s"` for zero
    /// - `"5s"` for whole seconds
    /// - `"1001/30000s"` for fractional values
    public var fcpxmlString: String {
        if fraction.numerator == 0 {
            return "0s"
        }
        // Check if it's a whole number of seconds
        if fraction.denominator == 1 {
            return "\(fraction.numerator)s"
        }
        // Use Fraction's string representation and add 's' suffix
        let fractionString = "\(fraction.numerator)/\(fraction.denominator)"
        return "\(fractionString)s"
    }
    
    // MARK: - Static Properties
    
    /// Zero timecode.
    public static let zero = FCPXMLTimecode(value: 0, timescale: 1)
    
    // MARK: - Initialization
    
    /// Creates a timecode from a `Fraction`.
    ///
    /// - Parameter fraction: The rational time value.
    internal init(fraction: Fraction) {
        self.fraction = fraction
    }
    
    /// Creates a timecode from a rational value.
    ///
    /// - Parameters:
    ///   - value: The numerator (number of ticks).
    ///   - timescale: The denominator (ticks per second).
    public init(value: Int64, timescale: Int32) {
        precondition(timescale > 0, "Timescale must be positive")
        self.fraction = Fraction(Int(value), Int(timescale))
    }
    
    /// Creates a timecode from seconds.
    ///
    /// - Parameters:
    ///   - seconds: The time in seconds.
    ///   - preferredTimescale: The timescale to use (default: 600, divisible by common frame rates).
    public init(seconds: Double, preferredTimescale: Int32 = 600) {
        precondition(preferredTimescale > 0, "Timescale must be positive")
        let value = Int(seconds * Double(preferredTimescale))
        self.fraction = Fraction(value, Int(preferredTimescale))
    }
    
    /// Creates a timecode from a CMTime.
    ///
    /// - Parameter cmTime: The CMTime value to convert.
    public init(cmTime: CMTime) {
        guard CMTIME_IS_VALID(cmTime), cmTime.timescale > 0 else {
            self.fraction = Fraction(0, 1)
            return
        }
        self.fraction = Fraction(Int(cmTime.value), Int(cmTime.timescale))
    }
    
    /// Creates a timecode from a frame count and frame rate.
    ///
    /// - Parameters:
    ///   - frames: The number of frames.
    ///   - frameRate: The frame rate.
    public init(frames: Int, frameRate: TimecodeFrameRate) {
        // Calculate frame duration based on frame rate
        let frameDuration = frameRate.frameDuration
        let frameDurationCMTime = CMTime(
            value: Int64(frameDuration.numerator),
            timescale: Int32(frameDuration.denominator)
        )
        let totalCMTime = CMTimeMultiply(frameDurationCMTime, multiplier: Int32(frames))
        self.init(cmTime: totalCMTime)
    }
    
    // MARK: - CMTime Conversion
    
    /// Converts this timecode to a CMTime.
    ///
    /// - Returns: A CMTime representation of this timecode.
    public func toCMTime() -> CMTime {
        CMTime(value: value, timescale: timescale)
    }
}

// MARK: - Arithmetic

extension FCPXMLTimecode {
    /// Adds two timecodes.
    public static func + (lhs: FCPXMLTimecode, rhs: FCPXMLTimecode) -> FCPXMLTimecode {
        FCPXMLTimecode(fraction: lhs.fraction + rhs.fraction)
    }
    
    /// Subtracts two timecodes.
    public static func - (lhs: FCPXMLTimecode, rhs: FCPXMLTimecode) -> FCPXMLTimecode {
        FCPXMLTimecode(fraction: lhs.fraction - rhs.fraction)
    }
    
    /// Multiplies a timecode by a scalar.
    public static func * (lhs: FCPXMLTimecode, rhs: Int) -> FCPXMLTimecode {
        FCPXMLTimecode(fraction: lhs.fraction * Fraction(rhs, 1))
    }
    
    /// Multiplies a timecode by a scalar.
    public static func * (lhs: Int, rhs: FCPXMLTimecode) -> FCPXMLTimecode {
        rhs * lhs
    }
}

// MARK: - Comparable

extension FCPXMLTimecode: Comparable {
    public static func < (lhs: FCPXMLTimecode, rhs: FCPXMLTimecode) -> Bool {
        lhs.fraction < rhs.fraction
    }
}

// MARK: - CustomStringConvertible

extension FCPXMLTimecode: CustomStringConvertible {
    public var description: String {
        fcpxmlString
    }
}

// MARK: - Parsing

extension FCPXMLTimecode {
    /// Creates a timecode from an FCPXML string.
    ///
    /// - Parameter fcpxmlString: A string like "1001/30000s" or "5s".
    /// - Returns: The parsed timecode, or nil if parsing fails.
    public init?(fcpxmlString: String) {
        guard let frac = Fraction(fcpxmlString: fcpxmlString) else {
            return nil
        }
        self.fraction = frac
    }
}

// MARK: - Frame Alignment

extension FCPXMLTimecode {
    /// Creates a frame-aligned timecode from seconds using a specific frame rate.
    ///
    /// This ensures the resulting timecode aligns with frame boundaries, which is required
    /// for FCPXML export. The timecode is rounded to the nearest frame.
    ///
    /// - Parameters:
    ///   - seconds: The time in seconds.
    ///   - frameRate: The frame rate to align to.
    /// - Returns: A timecode aligned to frame boundaries.
    public static func frameAligned(seconds: Double, frameRate: TimecodeFrameRate) -> FCPXMLTimecode {
        // Calculate the number of frames (rounded to nearest)
        let frameDuration = frameRate.frameDuration
        let frameDurationSeconds = Double(frameDuration.numerator) / Double(frameDuration.denominator)
        let fps = 1.0 / frameDurationSeconds
        let frameCount = Int((seconds * fps).rounded())
        
        // Create timecode from frame count
        return FCPXMLTimecode(frames: frameCount, frameRate: frameRate)
    }
    
    /// Converts this timecode to a frame-aligned timecode for the given frame rate.
    ///
    /// This rounds the timecode to the nearest frame boundary.
    ///
    /// - Parameter frameRate: The frame rate to align to.
    /// - Returns: A frame-aligned timecode.
    public func aligned(to frameRate: TimecodeFrameRate) -> FCPXMLTimecode {
        FCPXMLTimecode.frameAligned(seconds: self.seconds, frameRate: frameRate)
    }
}

// MARK: - Codable

extension FCPXMLTimecode {
    enum CodingKeys: String, CodingKey {
        case value
        case timescale
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(Int64.self, forKey: .value)
        let timescale = try container.decode(Int32.self, forKey: .timescale)
        self.fraction = Fraction(Int(value), Int(timescale))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(timescale, forKey: .timescale)
    }
}
