//
//  FCPXMLTextStyle.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Text style element model for formatted text strings.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Text alignment options for FCPXML text styles.
    public enum TextAlignment: String, Sendable, Codable {
        case left = "left"
        case center = "center"
        case right = "right"
        case justified = "justified"
    }
}

extension FinalCutPro.FCPXML {
    /// A text style that defines formatting for text strings.
    ///
    /// - SeeAlso: [FCPXML Text Style Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/text-style
    ///   )
    public struct TextStyle: Sendable, Equatable, Hashable, Codable {
        /// The value/content of the text style (text content).
        public var value: String?
        
        /// The reference identifier of the text style.
        public var referenceID: String?
        
        /// The font name.
        public var font: String?
        
        /// The font size.
        public var fontSize: Int?
        
        /// The font face.
        public var fontFace: String?
        
        /// The font color as a space-separated RGBA string (e.g., "1.0 1.0 1.0 1.0").
        public var fontColor: String?
        
        /// The background color as a space-separated RGBA string (e.g., "0.0 0.0 0.0 1.0").
        public var backgroundColor: String?
        
        /// A Boolean value indicating whether the text is bold.
        public var isBold: Bool?
        
        /// A Boolean value indicating whether the text is italic.
        public var isItalic: Bool?
        
        /// The stroke color as a space-separated RGBA string.
        public var strokeColor: String?
        
        /// The stroke width.
        public var strokeWidth: Double?
        
        /// The baseline value.
        public var baseline: Double?
        
        /// The shadow color as a space-separated RGBA string.
        public var shadowColor: String?
        
        /// The shadow offset as a space-separated string (e.g., "5.0 315.0").
        public var shadowOffset: String?
        
        /// The shadow blur radius.
        public var shadowBlurRadius: Double?
        
        /// The kerning value.
        public var kerning: Double?
        
        /// The alignment of the text style.
        public var alignment: FinalCutPro.FCPXML.TextAlignment?
        
        /// The line spacing.
        public var lineSpacing: Double?
        
        /// The tab stops.
        public var tabStops: Double?
        
        /// The baseline offset.
        public var baselineOffset: Double?
        
        /// A Boolean value indicating whether the text is underlined.
        public var isUnderlined: Bool?
        
        /// The parameters associated with the text style.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case value = ""
            case referenceID = "ref"
            case font
            case fontSize
            case fontFace
            case fontColor
            case backgroundColor
            case isBold = "bold"
            case isItalic = "italic"
            case strokeColor
            case strokeWidth
            case baseline
            case shadowColor
            case shadowOffset
            case shadowBlurRadius
            case kerning
            case alignment
            case lineSpacing
            case tabStops
            case baselineOffset
            case isUnderlined = "underline"
            case parameters = "param"
        }
        
        /// Initializes a new text style.
        /// - Parameters:
        ///   - referenceID: The reference identifier of the text style (default: `nil`).
        ///   - value: The value/content of the text style (default: `nil`).
        ///   - parameters: The parameters associated with the text style (default: `[]`).
        public init(
            referenceID: String? = nil,
            value: String? = nil,
            parameters: [FilterParameter] = []
        ) {
            self.referenceID = referenceID
            self.value = value
            self.parameters = parameters
        }
        
        /// Creates a text style from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            value = try container.decodeIfPresent(String.self, forKey: .value)
            referenceID = try container.decodeIfPresent(String.self, forKey: .referenceID)
            font = try container.decodeIfPresent(String.self, forKey: .font)
            fontSize = try container.decodeIfPresent(Int.self, forKey: .fontSize)
            fontFace = try container.decodeIfPresent(String.self, forKey: .fontFace)
            fontColor = try container.decodeIfPresent(String.self, forKey: .fontColor)
            backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
            if let boldString = try container.decodeIfPresent(String.self, forKey: .isBold) {
                isBold = boldString == "1"
            }
            if let italicString = try container.decodeIfPresent(String.self, forKey: .isItalic) {
                isItalic = italicString == "1"
            }
            strokeColor = try container.decodeIfPresent(String.self, forKey: .strokeColor)
            strokeWidth = try container.decodeIfPresent(Double.self, forKey: .strokeWidth)
            baseline = try container.decodeIfPresent(Double.self, forKey: .baseline)
            shadowColor = try container.decodeIfPresent(String.self, forKey: .shadowColor)
            shadowOffset = try container.decodeIfPresent(String.self, forKey: .shadowOffset)
            shadowBlurRadius = try container.decodeIfPresent(Double.self, forKey: .shadowBlurRadius)
            kerning = try container.decodeIfPresent(Double.self, forKey: .kerning)
            if let alignmentString = try container.decodeIfPresent(String.self, forKey: .alignment) {
                alignment = FinalCutPro.FCPXML.TextAlignment(rawValue: alignmentString)
            }
            lineSpacing = try container.decodeIfPresent(Double.self, forKey: .lineSpacing)
            tabStops = try container.decodeIfPresent(Double.self, forKey: .tabStops)
            baselineOffset = try container.decodeIfPresent(Double.self, forKey: .baselineOffset)
            if let underlineString = try container.decodeIfPresent(String.self, forKey: .isUnderlined) {
                isUnderlined = underlineString == "1"
            }
            parameters = try container.decodeIfPresent([FilterParameter].self, forKey: .parameters) ?? []
        }
        
        /// Encodes the text style to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(value, forKey: .value)
            try container.encodeIfPresent(referenceID, forKey: .referenceID)
            try container.encodeIfPresent(font, forKey: .font)
            try container.encodeIfPresent(fontSize, forKey: .fontSize)
            try container.encodeIfPresent(fontFace, forKey: .fontFace)
            try container.encodeIfPresent(fontColor, forKey: .fontColor)
            try container.encodeIfPresent(backgroundColor, forKey: .backgroundColor)
            if let isBold = isBold {
                try container.encode(isBold ? "1" : "0", forKey: .isBold)
            }
            if let isItalic = isItalic {
                try container.encode(isItalic ? "1" : "0", forKey: .isItalic)
            }
            try container.encodeIfPresent(strokeColor, forKey: .strokeColor)
            try container.encodeIfPresent(strokeWidth, forKey: .strokeWidth)
            try container.encodeIfPresent(baseline, forKey: .baseline)
            try container.encodeIfPresent(shadowColor, forKey: .shadowColor)
            try container.encodeIfPresent(shadowOffset, forKey: .shadowOffset)
            try container.encodeIfPresent(shadowBlurRadius, forKey: .shadowBlurRadius)
            try container.encodeIfPresent(kerning, forKey: .kerning)
            try container.encodeIfPresent(alignment?.rawValue, forKey: .alignment)
            try container.encodeIfPresent(lineSpacing, forKey: .lineSpacing)
            try container.encodeIfPresent(tabStops, forKey: .tabStops)
            try container.encodeIfPresent(baselineOffset, forKey: .baselineOffset)
            if let isUnderlined = isUnderlined {
                try container.encode(isUnderlined ? "1" : "0", forKey: .isUnderlined)
            }
            try container.encodeIfPresent(parameters.isEmpty ? nil : parameters, forKey: .parameters)
        }
    }
}
