//
//  FCPXMLAdjustmentBlend.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Blend adjustment model for compositing blend mode and opacity.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Modifies the compositing blend mode and opacity percentage of the visible image.
    ///
    /// - SeeAlso: [FCPXML Blend Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-blend
    ///   )
    public struct BlendAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The amount of the blend adjustment, from 0.0 to 1.0.
        public var amount: Double
        
        /// The mode of the blend adjustment.
        public var mode: String?
        
        private enum CodingKeys: String, CodingKey {
            case amount, mode
        }
        
        /// Initializes a new blend adjustment.
        /// - Parameters:
        ///   - mode: The mode of the blend adjustment (default: `nil`).
        ///   - amount: The amount of the blend adjustment (default: `1.0`).
        public init(mode: String? = nil, amount: Double = 1.0) {
            self.mode = mode
            self.amount = amount
        }
    }
}
