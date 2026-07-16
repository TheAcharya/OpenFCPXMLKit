//
//  FCPXMLTextStyle.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
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
        
        /// Workbook-style font specification (for example `Helvetica Neue 105.0, Medium`).
        public var displayFontSpecification: String? {
            Self.displayFontSpecification(
                font: font,
                fontSize: fontSize,
                fontFace: fontFace
            )
        }
        
        /// Workbook-style font specification parsed from a `text-style` XML element.
        public static func displayFontSpecification(from styleElement: any OFKXMLElement) -> String? {
            displayFontSpecification(
                font: styleElement.stringValue(forAttributeNamed: "font"),
                fontSizeString: styleElement.stringValue(forAttributeNamed: "fontSize"),
                fontFace: styleElement.stringValue(forAttributeNamed: "fontFace")
            )
        }
        
        private static func displayFontSpecification(
            font: String?,
            fontSize: Int?,
            fontFace: String?
        ) -> String? {
            displayFontSpecification(
                font: font,
                fontSizeString: fontSize.map(String.init),
                fontFace: fontFace
            )
        }
        
        private static func displayFontSpecification(
            font: String?,
            fontSizeString: String?,
            fontFace: String?
        ) -> String? {
            guard let font, !font.isEmpty else { return nil }
            
            var spec = font
            if let fontSizeString, !fontSizeString.isEmpty {
                spec += " \(displayFontSize(fontSizeString))"
            }
            if let fontFace, !fontFace.isEmpty {
                spec += ", \(fontFace)"
            }
            
            return spec
        }
        
        private static func displayFontSize(_ fontSize: String) -> String {
            guard let value = Double(fontSize) else { return fontSize }
            
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.1f", value)
            }
            
            return fontSize
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

        /// Parses a `text-style` element into a typed model (all DTD attributes).
        public static func parse(from element: any OFKXMLElement) -> FinalCutPro.FCPXML.TextStyle? {
            let ref = element.fcpRef
            let value = element.stringValue
            let font = element.stringValue(forAttributeNamed: "font")
            let fontSize = element.stringValue(forAttributeNamed: "fontSize").flatMap { Int($0) }
            let fontFace = element.stringValue(forAttributeNamed: "fontFace")
            let fontColor = element.stringValue(forAttributeNamed: "fontColor")
            let backgroundColor = element.stringValue(forAttributeNamed: "backgroundColor")
            let isBold = element.stringValue(forAttributeNamed: "bold").map { $0 == "1" }
            let isItalic = element.stringValue(forAttributeNamed: "italic").map { $0 == "1" }
            let strokeColor = element.stringValue(forAttributeNamed: "strokeColor")
            let strokeWidth = element.stringValue(forAttributeNamed: "strokeWidth").flatMap { Double($0) }
            let baseline = element.stringValue(forAttributeNamed: "baseline").flatMap { Double($0) }
            let shadowColor = element.stringValue(forAttributeNamed: "shadowColor")
            let shadowOffset = element.stringValue(forAttributeNamed: "shadowOffset")
            let shadowBlurRadius = element.stringValue(forAttributeNamed: "shadowBlurRadius").flatMap { Double($0) }
            let kerning = element.stringValue(forAttributeNamed: "kerning").flatMap { Double($0) }
            let alignment = element.stringValue(forAttributeNamed: "alignment")
                .flatMap { FinalCutPro.FCPXML.TextAlignment(rawValue: $0) }
            let lineSpacing = element.stringValue(forAttributeNamed: "lineSpacing").flatMap { Double($0) }
            let tabStops = element.stringValue(forAttributeNamed: "tabStops").flatMap { Double($0) }
            let baselineOffset = element.stringValue(forAttributeNamed: "baselineOffset").flatMap { Double($0) }
            let isUnderlined = element.stringValue(forAttributeNamed: "underline").map { $0 == "1" }
            let parameters = Array(element.childElements
                .filter { $0.name == "param" }
                .compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })

            var textStyle = FinalCutPro.FCPXML.TextStyle(referenceID: ref, value: value, parameters: parameters)
            textStyle.font = font
            textStyle.fontSize = fontSize
            textStyle.fontFace = fontFace
            textStyle.fontColor = fontColor
            textStyle.backgroundColor = backgroundColor
            textStyle.isBold = isBold
            textStyle.isItalic = isItalic
            textStyle.strokeColor = strokeColor
            textStyle.strokeWidth = strokeWidth
            textStyle.baseline = baseline
            textStyle.shadowColor = shadowColor
            textStyle.shadowOffset = shadowOffset
            textStyle.shadowBlurRadius = shadowBlurRadius
            textStyle.kerning = kerning
            textStyle.alignment = alignment
            textStyle.lineSpacing = lineSpacing
            textStyle.tabStops = tabStops
            textStyle.baselineOffset = baselineOffset
            textStyle.isUnderlined = isUnderlined
            return textStyle
        }

        /// Builds a `text-style` XML element from a typed model.
        public static func makeElement(from textStyle: FinalCutPro.FCPXML.TextStyle) -> any OFKXMLElement {
            let element = OFKXMLDefaultFactory().makeElement(name: "text-style")
            if let ref = textStyle.referenceID { element.fcpRef = ref }
            if let value = textStyle.value { element.stringValue = value }
            if let font = textStyle.font { element.addAttribute(name: "font", value: font) }
            if let fontSize = textStyle.fontSize {
                element.addAttribute(name: "fontSize", value: String(fontSize))
            }
            if let fontFace = textStyle.fontFace {
                element.addAttribute(name: "fontFace", value: fontFace)
            }
            if let fontColor = textStyle.fontColor {
                element.addAttribute(name: "fontColor", value: fontColor)
            }
            if let backgroundColor = textStyle.backgroundColor {
                element.addAttribute(name: "backgroundColor", value: backgroundColor)
            }
            if let isBold = textStyle.isBold {
                element.addAttribute(name: "bold", value: isBold ? "1" : "0")
            }
            if let isItalic = textStyle.isItalic {
                element.addAttribute(name: "italic", value: isItalic ? "1" : "0")
            }
            if let strokeColor = textStyle.strokeColor {
                element.addAttribute(name: "strokeColor", value: strokeColor)
            }
            if let strokeWidth = textStyle.strokeWidth {
                element.addAttribute(name: "strokeWidth", value: String(strokeWidth))
            }
            if let baseline = textStyle.baseline {
                element.addAttribute(name: "baseline", value: String(baseline))
            }
            if let shadowColor = textStyle.shadowColor {
                element.addAttribute(name: "shadowColor", value: shadowColor)
            }
            if let shadowOffset = textStyle.shadowOffset {
                element.addAttribute(name: "shadowOffset", value: shadowOffset)
            }
            if let shadowBlurRadius = textStyle.shadowBlurRadius {
                element.addAttribute(name: "shadowBlurRadius", value: String(shadowBlurRadius))
            }
            if let kerning = textStyle.kerning {
                element.addAttribute(name: "kerning", value: String(kerning))
            }
            if let alignment = textStyle.alignment {
                element.addAttribute(name: "alignment", value: alignment.rawValue)
            }
            if let lineSpacing = textStyle.lineSpacing {
                element.addAttribute(name: "lineSpacing", value: String(lineSpacing))
            }
            if let tabStops = textStyle.tabStops {
                element.addAttribute(name: "tabStops", value: String(tabStops))
            }
            if let baselineOffset = textStyle.baselineOffset {
                element.addAttribute(name: "baselineOffset", value: String(baselineOffset))
            }
            if let isUnderlined = textStyle.isUnderlined {
                element.addAttribute(name: "underline", value: isUnderlined ? "1" : "0")
            }
            for param in textStyle.parameters {
                let paramElement = OFKXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: "name", value: param.name)
                if let key = param.key { paramElement.addAttribute(name: "key", value: key) }
                if let value = param.value { paramElement.addAttribute(name: "value", value: value) }
                if let auxValue = param.auxValue {
                    paramElement.addAttribute(name: "auxValue", value: auxValue)
                }
                if !param.isEnabled {
                    paramElement.addAttribute(name: "enabled", value: "0")
                }
                element.addChild(paramElement)
            }
            return element
        }
    }
}
