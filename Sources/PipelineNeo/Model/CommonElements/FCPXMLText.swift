//
//  FCPXMLText.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Text element model for titles and captions.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Text element.
    public struct Text: FCPXMLElement, Equatable, Hashable {
        public let element: any PNXMLElement

        public let elementType: ElementType = .text

        public static let supportedElementTypes: Set<ElementType> = [.text]

        public init() {
            element = PNXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }

        public init?(element: any PNXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
    }
}

// MARK: - Parameterized init

extension FinalCutPro.FCPXML.Text {
    public init(
        displayStyle: DisplayStyle? = nil,
        rollUpHeight: String? = nil,
        position: String? = nil,
        placement: Placement? = nil,
        alignment: Alignment? = nil,
        textStyles: [any PNXMLElement] = []
    ) {
        self.init()
        
        self.displayStyle = displayStyle
        self.rollUpHeight = rollUpHeight
        self.position = position
        self.placement = placement
        self.alignment = alignment
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Text {
    public enum Attributes: String {
        /// For a CEA-608 caption text block.
        case displayStyle = "display-style"
        
        /// For a CEA-608 caption text block with roll-up animation.
        case rollUpHeight = "roll-up-height"
        
        /// For a CEA-608 caption text block, as "x y".
        case position
        
        /// For a ITT caption text block.
        case placement
        
        /// For a CEA-608 caption text block.
        case alignment
    }
    
    // contains DTD text-style*
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Text {
    /// For a CEA-608 caption text block.
    public var displayStyle: DisplayStyle? { // used only with `text`
        get {
            guard let value = element.stringValue(forAttributeNamed: Attributes.displayStyle.rawValue)
            else { return nil }
            
            return DisplayStyle(rawValue: value)
        }
        nonmutating set {
            element.addAttribute(name: Attributes.displayStyle.rawValue, value: newValue?.rawValue)
        }
    }
    
    /// For a CEA-608 caption text block with roll-up animation.
    public var rollUpHeight: String? {
        get { element.stringValue(forAttributeNamed: Attributes.rollUpHeight.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.rollUpHeight.rawValue, value: newValue) }
    }
    
    /// For a CEA-608 caption text block, as "x y".
    public var position: String? {
        get { element.fcpPosition }
        nonmutating set { element.fcpPosition = newValue }
    }
    
    /// For a ITT caption text block.
    public var placement: Placement? { // used only with `text`
        get {
            guard let value = element.stringValue(forAttributeNamed: Attributes.placement.rawValue)
            else { return nil }
            
            return Placement(rawValue: value)
        }
        nonmutating set {
            element.addAttribute(name: Attributes.placement.rawValue, value: newValue?.rawValue)
        }
    }
    
    /// For a CEA-608 caption text block.
    public var alignment: Alignment? { // used only with `text`
        get {
            guard let value = element.stringValue(forAttributeNamed: Attributes.alignment.rawValue)
            else { return nil }
            
            return Alignment(rawValue: value)
        }
        nonmutating set {
            element.addAttribute(name: Attributes.alignment.rawValue, value: newValue?.rawValue)
        }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Text {
    /// Get or set child `text-style` elements.
    public var textStyles: [any PNXMLElement] {
        get {
            element.fcpTextStyles
        }
        nonmutating set {
            element._updateChildElements(ofType: elementType, with: newValue)
        }
    }
}

// MARK: - Properties

// `text` or `adjust-transform`
extension PNXMLElement {
    /// FCPXML: Get or set the value of the `position` attribute.
    /// Use on `text` element for a CEA-608 caption, or an `adjust-transform` element.
    public var fcpPosition: String? {
        get { stringValue(forAttributeNamed: "position") }
        set { addAttribute(name: "position", value: newValue) }
    }
}

// `text` or `text-style-def`
extension PNXMLElement {
    /// FCPXML: Returns child `text-style` elements.
    /// Use on `text` or `text-style-def` elements.
    public var fcpTextStyles: [any PNXMLElement] {
        Array(childElements.filter(whereFCPElementType: .textStyle))
    }
}

// MARK: - Typing

// Text
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Text`` model object.
    /// Call this on a `text` element only.
    public var fcpAsText: FinalCutPro.FCPXML.Text? {
        .init(element: self)
    }
}

// MARK: - Text Attribute: DisplayStyle

extension FinalCutPro.FCPXML.Text {
    /// For a CEA-608 caption text block.
    public enum DisplayStyle: String, Equatable, Hashable, CaseIterable, Sendable {
        case popOn = "pop-on"
        case paintOn = "paint-on"
        case rollUp = "roll-up"
    }
}

// MARK: - Text Attribute: Placement

extension FinalCutPro.FCPXML.Text {
    /// For a ITT caption text block.
    public enum Placement: String, Equatable, Hashable, CaseIterable, Sendable {
        case left, right, top, bottom
    }
}

// MARK: - Text Attribute: Alignment

extension FinalCutPro.FCPXML.Text {
    /// For a CEA-608 caption text block.
    public enum Alignment: String, Equatable, Hashable, CaseIterable, Sendable {
        case left, center, right
    }
}

// MARK: - Text Child: TextString

extension FinalCutPro.FCPXML.Text {
    public struct TextString: Equatable, Hashable {
        public let element: any PNXMLElement
        
        public var ref: String? {
            get { element.fcpRef }
            nonmutating set { element.fcpRef = newValue }
        }
        
        public var string: String? {
            get { element.stringValue }
            nonmutating set { element.stringValue = newValue }
        }
        
        // Note: additional attributes not yet parsed.
        
        public init(element: any PNXMLElement) {
            self.element = element
        }
    }
}

extension FinalCutPro.FCPXML.Text.TextString {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.element === rhs.element
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(element))
    }
}

extension FinalCutPro.FCPXML.Text.TextString {
    public enum Attributes: String {
        case ref // optional
    }
}
