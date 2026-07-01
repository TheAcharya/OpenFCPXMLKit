//
//  FCPXMLFilterVideo.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Video filter model for applying video effects to clips.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A video filter that applies a video effect to a clip or transition.
    ///
    /// Video filters reference an `Effect` resource and can have parameters and data.
    ///
    /// - SeeAlso: [FCPXML Video Filter Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/filter-video
    ///   )
    public struct VideoFilter: Sendable, Equatable, Hashable, Codable {
        /// The identifier of the `Effect` resource referenced by this video filter.
        public let effectID: String
        
        /// The name of the video filter.
        public var name: String?
        
        /// A Boolean value indicating whether the video filter is enabled.
        public var isEnabled: Bool
        
        /// The data associated with the video filter.
        public var data: [KeyedData]
        
        /// The parameters associated with the video filter.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case effectID = "ref"
            case name
            case isEnabled = "enabled"
            case data
            case parameters = "param"
        }
        
        /// Initializes a new video filter.
        /// - Parameters:
        ///   - effectID: The identifier of the `Effect` resource referenced by this video filter.
        ///   - name: The name of the video filter (default: `nil`).
        ///   - isEnabled: Whether the filter is enabled (default: `true`).
        ///   - data: Associated data (default: `[]`).
        ///   - parameters: Filter parameters (default: `[]`).
        public init(
            effectID: String,
            name: String? = nil,
            isEnabled: Bool = true,
            data: [KeyedData] = [],
            parameters: [FilterParameter] = []
        ) {
            self.effectID = effectID
            self.name = name
            self.isEnabled = isEnabled
            self.data = data
            self.parameters = parameters
        }
    }
}
