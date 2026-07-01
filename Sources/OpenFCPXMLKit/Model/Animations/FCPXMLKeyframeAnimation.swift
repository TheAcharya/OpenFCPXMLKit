//
//  FCPXMLKeyframeAnimation.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Keyframe animation model for animation curves.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A keyframe animation that describes an animation curve using contained keyframe elements.
    ///
    /// - SeeAlso: [FCPXML Keyframe Animation Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/keyframeanimation
    ///   )
    public struct KeyframeAnimation: Sendable, Equatable, Hashable, Codable {
        /// The keyframes of the keyframe animation.
        public var keyframes: [Keyframe]
        
        private enum CodingKeys: String, CodingKey {
            case keyframes = "keyframe"
        }
        
        /// Initializes a new keyframe animation.
        /// - Parameter keyframes: The keyframes of the keyframe animation (default: `[]`).
        public init(keyframes: [Keyframe] = []) {
            self.keyframes = keyframes
        }
    }
}
