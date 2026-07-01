//
//  FCPXMLAdjustmentHumReduction.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Hum reduction adjustment model for audio hum reduction.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Specifies the possible frequencies of a hum reduction adjustment.
    public enum HumReductionFrequency: String, Sendable, Equatable, Hashable, Codable {
        /// 50 Hz frequency.
        case hz50 = "50"
        
        /// 60 Hz frequency.
        case hz60 = "60"
    }
    
    /// A hum reduction adjustment that reduces audio hum at a specific frequency.
    ///
    /// - SeeAlso: [FCPXML Hum Reduction Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-humReduction
    ///   )
    public struct HumReductionAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The frequency of the hum reduction.
        public var frequency: HumReductionFrequency
        
        private enum CodingKeys: String, CodingKey {
            case frequency
        }
        
        /// Initializes a new hum reduction adjustment.
        /// - Parameter frequency: The frequency of the hum reduction.
        public init(frequency: HumReductionFrequency) {
            self.frequency = frequency
        }
    }
}
