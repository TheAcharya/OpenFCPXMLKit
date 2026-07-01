//
//  FCPXMLAdjustmentNoiseReduction.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Noise reduction adjustment model for audio noise reduction.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A noise reduction adjustment that reduces audio noise.
    ///
    /// - SeeAlso: [FCPXML Noise Reduction Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-noiseReduction
    ///   )
    public struct NoiseReductionAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The amount of the noise reduction.
        public var amount: Double
        
        private enum CodingKeys: String, CodingKey {
            case amount
        }
        
        /// Initializes a new noise reduction adjustment.
        /// - Parameter amount: The amount of the noise reduction.
        public init(amount: Double) {
            self.amount = amount
        }
    }
}
