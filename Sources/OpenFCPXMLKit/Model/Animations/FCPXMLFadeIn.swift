//
//  FCPXMLFadeIn.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Fade in effect model for parameter animations.
//

import Foundation
import CoreMedia

extension FinalCutPro.FCPXML {
    /// A fade in effect that animates a parameter from its min value to its implied value over a specified duration.
    ///
    /// - SeeAlso: [FCPXML Fade In Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/fadein
    ///   )
    public struct FadeIn: Sendable, Equatable, Hashable, Codable {
        /// The type of the fade in effect.
        public var type: FadeType
        
        /// The duration of the fade in effect.
        public var duration: CMTime
        
        private enum CodingKeys: String, CodingKey {
            case type
            case duration
        }
        
        /// Initializes a new fade in effect.
        /// - Parameters:
        ///   - type: The type of the fade in effect (default: `.easeIn`).
        ///   - duration: The duration of the fade in effect.
        public init(type: FadeType = .easeIn, duration: CMTime) {
            self.type = type
            self.duration = duration
        }
        
        /// Creates a fade in from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(FadeType.self, forKey: .type) ?? .easeIn
            // Decode duration as FCPXML time string
            let durationString = try container.decode(String.self, forKey: .duration)
            duration = CMTime.fcpxmlTime(from: durationString)
        }
        
        /// Encodes the fade in to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if type != .easeIn {
                try container.encode(type, forKey: .type)
            }
            try container.encode(duration.fcpxmlString, forKey: .duration)
        }
    }
}

// MARK: - CMTime FCPXML Time String Helper

extension CMTime {
    /// Creates a CMTime from an FCPXML time string.
    /// - Parameter timeString: The FCPXML time string (e.g., "7200/2400s" or "5s").
    /// - Returns: A CMTime value parsed from the string.
    static func fcpxmlTime(from timeString: String) -> CMTime {
        // Strip trailing "s" suffix
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
            return CMTime(seconds: seconds, preferredTimescale: 600)
        }
        return .zero
    }
}
