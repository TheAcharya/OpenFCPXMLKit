//
//  FCPXMLKeyframe.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Keyframe model for animation curves.
//

import Foundation
import CoreMedia

extension FinalCutPro.FCPXML {
    /// Specifies the possible interpolation modes that can be used in an individual keyframe of a keyframe animation.
    public enum KeyframeInterpolation: String, Sendable, Equatable, Hashable, Codable {
        case linear
        case ease
        case easeIn
        case easeOut
    }
    
    /// Specifies the possible curves that can be used in an individual keyframe of a keyframe animation.
    public enum KeyframeCurve: String, Sendable, Equatable, Hashable, Codable {
        case linear
        case smooth
    }
    
    /// A keyframe that describes a point along an animation curve.
    ///
    /// - SeeAlso: [FCPXML Keyframe Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/keyframe
    ///   )
    public struct Keyframe: Sendable, Equatable, Hashable, Codable {
        /// The time of the keyframe.
        public var time: CMTime
        
        /// The value of the keyframe.
        public var value: String
        
        /// The auxiliary value of the keyframe (optional).
        public var auxValue: String?
        
        /// The interpolation mode to use for the keyframe.
        public var interpolation: KeyframeInterpolation
        
        /// The curve to use for the keyframe.
        public var curve: KeyframeCurve
        
        private enum CodingKeys: String, CodingKey {
            case time
            case value
            case auxValue
            case interpolation = "interp"
            case curve
        }
        
        /// Initializes a new keyframe.
        /// - Parameters:
        ///   - time: The time of the keyframe.
        ///   - value: The value of the keyframe.
        ///   - auxValue: The auxiliary value of the keyframe (default: `nil`).
        ///   - interpolation: The interpolation mode to use for the keyframe (default: `.linear`).
        ///   - curve: The curve to use for the keyframe (default: `.smooth`).
        public init(
            time: CMTime,
            value: String,
            auxValue: String? = nil,
            interpolation: KeyframeInterpolation = .linear,
            curve: KeyframeCurve = .smooth
        ) {
            self.time = time
            self.value = value
            self.auxValue = auxValue
            self.interpolation = interpolation
            self.curve = curve
        }
        
        /// Creates a keyframe from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Decode time as FCPXML time string
            let timeString = try container.decode(String.self, forKey: .time)
            time = CMTime.fcpxmlTime(from: timeString)
            value = try container.decode(String.self, forKey: .value)
            auxValue = try container.decodeIfPresent(String.self, forKey: .auxValue)
            interpolation = try container.decodeIfPresent(KeyframeInterpolation.self, forKey: .interpolation) ?? .linear
            curve = try container.decodeIfPresent(KeyframeCurve.self, forKey: .curve) ?? .smooth
        }
        
        /// Encodes the keyframe to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(time.fcpxmlString, forKey: .time)
            try container.encode(value, forKey: .value)
            try container.encodeIfPresent(auxValue, forKey: .auxValue)
            if interpolation != .linear {
                try container.encode(interpolation, forKey: .interpolation)
            }
            if curve != .smooth {
                try container.encode(curve, forKey: .curve)
            }
        }
    }
}
