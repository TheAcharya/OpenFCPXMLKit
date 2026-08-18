//
// FCPXMLTitle+Typed.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Typed display helpers for Title (text segments / fonts / Apple-supplied).
//

import Foundation

// MARK: - Display Text

extension FinalCutPro.FCPXML.Title {
    /// A segment of display text within a title's `text` children.
    public struct TextSegment: Sendable, Equatable {
        public var text: String
        public var styleReference: String?
        
        public init(text: String, styleReference: String? = nil) {
            self.text = text
            self.styleReference = styleReference
        }
    }
    
    /// Text segments from child `text` / `text-style` elements in document order.
    public var typedTextSegments: [TextSegment] {
        element.fcpTexts.flatMap { text in
            text.textStyles.map { styleElement in
                TextSegment(
                    text: styleElement.stringValue ?? "",
                    styleReference: styleElement.fcpRef
                )
            }
        }
    }
    
    /// Concatenated title text matching Final Cut Pro on-screen display.
    ///
    /// Style runs inside one `text` element join with no separator (a shot number
    /// split as `1501` + `0` displays as `15010`). Separate `text` children
    /// (paragraphs / lines) join with `separator`.
    public func concatenatedDisplayText(separator: String = "  |  ") -> String {
        let lines = element.fcpTexts.map { text in
            text.textStyles
                .compactMap(\.stringValue)
                .filter { !$0.isEmpty }
                .joined()
        }
        .filter { !$0.isEmpty }
        
        return lines.joined(separator: separator)
    }
    
    /// Comma-separated unique font specifications used by styled text segments.
    public func displayFontSpecifications(separator: String = ", ") -> String {
        let styleDefinitions = styleDefinitionElementsByID
        
        let fontSpecs = typedTextSegments.compactMap { segment -> String? in
            guard let styleReference = segment.styleReference,
                  let styleElement = styleDefinitions[styleReference]
            else { return nil }
            
            return FinalCutPro.FCPXML.TextStyle.displayFontSpecification(from: styleElement)
        }
        
        var unique: [String] = []
        var seen: Set<String> = []
        for spec in fontSpecs where seen.insert(spec).inserted {
            unique.append(spec)
        }
        
        return unique.joined(separator: separator)
    }
    
    /// True when the title's referenced Motion template is Apple-supplied.
    public func isAppleSuppliedEffect(resources: (any OFKXMLElement)?) -> Bool {
        guard let ref = element.fcpRef,
              let resource = element.fcpResource(forID: ref, in: resources),
              let effect = resource.fcpAsEffect
        else { return false }
        
        return effect.isAppleSupplied
    }
    
    private var styleDefinitionElementsByID: [String: any OFKXMLElement] {
        var lookup: [String: any OFKXMLElement] = [:]
        
        for styleDef in element.fcpTextStyleDefinitions {
            guard let id = styleDef.fcpID,
                  let style = styleDef.fcpTextStyles.first
            else { continue }
            
            lookup[id] = style
        }
        
        return lookup
    }
}
