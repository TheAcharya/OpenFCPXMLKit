//
//  FCPXMLAdjustmentLoudness.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Loudness adjustment model for audio loudness control.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A loudness adjustment that modifies audio loudness and uniformity.
    ///
    /// - SeeAlso: [FCPXML Loudness Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-loudness
    ///   )
    public struct LoudnessAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The amount of the loudness adjustment.
        public var amount: Double
        
        /// The uniformity of the loudness adjustment.
        public var uniformity: Double
        
        private enum CodingKeys: String, CodingKey {
            case amount, uniformity
        }
        
        /// Initializes a new loudness adjustment.
        /// - Parameters:
        ///   - amount: The amount of the loudness adjustment.
        ///   - uniformity: The uniformity of the loudness adjustment.
        public init(amount: Double, uniformity: Double) {
            self.amount = amount
            self.uniformity = uniformity
        }
    }
}
