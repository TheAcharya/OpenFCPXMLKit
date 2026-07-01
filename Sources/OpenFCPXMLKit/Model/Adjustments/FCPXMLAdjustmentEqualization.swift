//
//  FCPXMLAdjustmentEqualization.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Equalization adjustment model for audio equalization.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Specifies the possible modes of an equalization adjustment.
    public enum EqualizationMode: String, Sendable, Equatable, Hashable, Codable {
        case flat
        case voiceEnhance = "voice_enhance"
        case musicEnhance = "music_enhance"
        case loudness
        case humReduction = "hum_reduction"
        case bassBoost = "bass_boost"
        case bassReduce = "bass_reduce"
        case trebleBoost = "treble_boost"
        case trebleReduce = "treble_reduce"
    }
    
    /// An equalization adjustment that modifies audio frequency response.
    ///
    /// - SeeAlso: [FCPXML Equalization Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-EQ
    ///   )
    public struct EqualizationAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The mode of the equalization adjustment.
        public var mode: EqualizationMode
        
        /// The parameters associated with the equalization adjustment.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case mode
            case parameters = "param"
        }
        
        /// Initializes a new equalization adjustment.
        /// - Parameters:
        ///   - mode: The mode of the equalization adjustment.
        ///   - parameters: The parameters associated with the equalization (default: `[]`).
        public init(mode: EqualizationMode, parameters: [FilterParameter] = []) {
            self.mode = mode
            self.parameters = parameters
        }
    }
    
    /// A match equalization adjustment that matches audio equalization from another clip.
    ///
    /// - SeeAlso: [FCPXML Match Equalization Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-matchEQ
    ///   )
    public struct MatchEqualizationAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The data of the match equalization adjustment.
        public var data: KeyedData
        
        private enum CodingKeys: String, CodingKey {
            case data
        }
        
        /// Initializes a new match equalization adjustment.
        /// - Parameter data: The data of the match equalization adjustment.
        public init(data: KeyedData) {
            self.data = data
        }
    }
}
