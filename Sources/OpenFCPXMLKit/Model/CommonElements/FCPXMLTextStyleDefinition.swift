//
//  FCPXMLTextStyleDefinition.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Text style definition element model for defining text styles.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A text style definition that defines styles for formatted text strings.
    ///
    /// - SeeAlso: [FCPXML Text Style Definition Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/text-style-def
    ///   )
    public struct TextStyleDefinition: Sendable, Equatable, Hashable, Codable {
        /// The text styles contained in the text style definition.
        public var textStyles: [TextStyle]
        
        /// The identifier of the text style definition (required).
        public let id: String
        
        /// The name of the text style definition.
        public var name: String?
        
        private enum CodingKeys: String, CodingKey {
            case textStyles = "text-style"
            case id
            case name
        }
        
        /// Initializes a new text style definition.
        /// - Parameters:
        ///   - id: The identifier of the text style definition (required).
        ///   - name: The name of the text style definition (default: `nil`).
        ///   - textStyles: The text styles contained in the definition (default: `[]`).
        public init(
            id: String,
            name: String? = nil,
            textStyles: [TextStyle] = []
        ) {
            self.id = id
            self.name = name
            self.textStyles = textStyles
        }
    }
}
