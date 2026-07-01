//
//  FCPXMLFilterAudio.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Audio filter model for applying audio effects to clips.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// An audio filter that applies an audio effect to a clip or transition.
    ///
    /// Audio filters reference an `Effect` resource and can have parameters and data.
    ///
    /// - SeeAlso: [FCPXML Audio Filter Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/filter-audio
    ///   )
    public struct AudioFilter: Sendable, Equatable, Hashable, Codable {
        /// The identifier of the `Effect` resource referenced by this audio filter.
        public let effectID: String
        
        /// The name of the audio filter.
        public var name: String?
        
        /// A Boolean value indicating whether the audio filter is enabled.
        public var isEnabled: Bool
        
        /// The preset identifier of the audio filter.
        public var presetID: String?
        
        /// The data associated with the audio filter.
        public var data: [KeyedData]
        
        /// The parameters associated with the audio filter.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case effectID = "ref"
            case name
            case isEnabled = "enabled"
            case presetID
            case data
            case parameters = "param"
        }
        
        /// Initializes a new audio filter.
        /// - Parameters:
        ///   - effectID: The identifier of the `Effect` resource referenced by this audio filter.
        ///   - name: The name of the audio filter (default: `nil`).
        ///   - isEnabled: Whether the filter is enabled (default: `true`).
        ///   - presetID: The preset identifier (default: `nil`).
        ///   - data: Associated data (default: `[]`).
        ///   - parameters: Filter parameters (default: `[]`).
        public init(
            effectID: String,
            name: String? = nil,
            isEnabled: Bool = true,
            presetID: String? = nil,
            data: [KeyedData] = [],
            parameters: [FilterParameter] = []
        ) {
            self.effectID = effectID
            self.name = name
            self.isEnabled = isEnabled
            self.presetID = presetID
            self.data = data
            self.parameters = parameters
        }
    }
}
