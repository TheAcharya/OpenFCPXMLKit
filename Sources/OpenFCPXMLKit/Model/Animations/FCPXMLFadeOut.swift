//
//  FCPXMLFadeOut.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Fade out effect model for parameter animations.
//

import Foundation
import CoreMedia

extension FinalCutPro.FCPXML {
    /// A fade out effect that animates a parameter from its implied value to its min value over a specified duration.
    ///
    /// - SeeAlso: [FCPXML Fade Out Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/fadeout
    ///   )
    public struct FadeOut: Sendable, Equatable, Hashable, Codable {
        /// The type of the fade out effect.
        public var type: FadeType
        
        /// The duration of the fade out effect.
        public var duration: CMTime
        
        private enum CodingKeys: String, CodingKey {
            case type
            case duration
        }
        
        /// Initializes a new fade out effect.
        /// - Parameters:
        ///   - type: The type of the fade out effect (default: `.easeOut`).
        ///   - duration: The duration of the fade out effect.
        public init(type: FadeType = .easeOut, duration: CMTime) {
            self.type = type
            self.duration = duration
        }
        
        /// Creates a fade out from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(FadeType.self, forKey: .type) ?? .easeOut
            // Decode duration as FCPXML time string
            let durationString = try container.decode(String.self, forKey: .duration)
            duration = CMTime.fcpxmlTime(from: durationString)
        }
        
        /// Encodes the fade out to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if type != .easeOut {
                try container.encode(type, forKey: .type)
            }
            try container.encode(duration.fcpxmlString, forKey: .duration)
        }
    }
}
