//
//  FCPXMLAdjustmentStabilization.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Stabilization adjustment model for video stabilization.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A stabilization adjustment that reduces camera shake in video.
    ///
    /// - SeeAlso: [FCPXML Stabilization Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-stabilization
    ///   )
    public struct StabilizationAdjustment: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible modes of a stabilization adjustment.
        public enum Mode: String, Sendable, Equatable, Hashable, Codable {
            case automatic
            case inertiaCam
            case smoothCam
        }
        
        /// The type of the stabilization adjustment.
        public var type: Mode
        
        private enum CodingKeys: String, CodingKey {
            case type
        }
        
        /// Initializes a stabilization adjustment.
        /// - Parameter type: The type of the stabilization adjustment (default: `.automatic`).
        public init(type: Mode = .automatic) {
            self.type = type
        }
    }
}
