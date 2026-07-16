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
    
    /// Concatenated title text using the reference export segment separator.
    public func concatenatedDisplayText(separator: String = "  |  ") -> String {
        let segments = typedTextSegments
        guard !segments.isEmpty else { return "" }
        guard segments.count > 1 else { return segments[0].text }
        
        return segments
            .map(\.text)
            .joined(separator: separator)
    }
    
    /// Comma-separated font specifications for each styled text segment.
    public func displayFontSpecifications(separator: String = ", ") -> String {
        let styleDefinitions = styleDefinitionElementsByID
        
        let fontSpecs = typedTextSegments.compactMap { segment -> String? in
            guard let styleReference = segment.styleReference,
                  let styleElement = styleDefinitions[styleReference]
            else { return nil }
            
            return FinalCutPro.FCPXML.TextStyle.displayFontSpecification(from: styleElement)
        }
        
        return fontSpecs.joined(separator: separator)
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
