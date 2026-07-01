//
//  FCPXMLKeywordCollection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Keyword collection model for organizing keywords.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A keyword collection for organizing clips by keywords.
    ///
    /// - SeeAlso: [FCPXML Keyword Collection Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/keyword-collection
    ///   )
    public struct KeywordCollection: Sendable, Equatable, Hashable, Codable {
        /// The name of the keyword collection.
        public var name: String
        
        private enum CodingKeys: String, CodingKey {
            case name
        }
        
        /// Initializes a new keyword collection.
        /// - Parameter name: The name of the keyword collection.
        public init(name: String) {
            self.name = name
        }
    }
}
