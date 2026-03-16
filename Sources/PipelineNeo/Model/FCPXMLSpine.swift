//
//  FCPXMLSpine.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Spine element model for sequentially ordered elements.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Contains elements ordered sequentially in time.
    public struct Spine: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .spine

        public static let supportedElementTypes: Set<ElementType> = [.spine]

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

extension FinalCutPro.FCPXML.Spine {
    public init(
        name: String? = nil,
        format: String? = nil,
        // Anchorable Attributes
        lane: Int? = nil,
        offset: Fraction? = nil
    ) {
        self.init()
        
        self.name = name
        self.format = format
        
        // Anchorable Attributes
        self.lane = lane
        self.offset = offset
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Spine {
    public enum Attributes: String {
        // Element-Specific Attributes
        case name
        case format
        
        // Anchorable Attributes
        case lane
        case offset
    }
    
    // contains clips
    // contains transitions
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Spine {
    public var name: String? {
        get { element.fcpName }
        nonmutating set { element.fcpName = newValue }
    }
    
    public var format: String? {
        get { element.fcpFormat }
        nonmutating set { element.fcpFormat = newValue }
    }
}

extension FinalCutPro.FCPXML.Spine: FCPXMLElementAnchorableAttributes { }

// MARK: - Children

extension FinalCutPro.FCPXML.Spine {
    /// Returns child story elements.
    public var storyElements: [any PNXMLElement] {
        element.fcpStoryElements
    }

    /// Get or set child elements.
    public var contents: [any PNXMLElement] {
        get { element.childElements }
        nonmutating set {
            element.removeAllChildren()
            element.addChildren(newValue)
        }
    }
}

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.Spine: FCPXMLElementMetaTimeline { 
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .spine(self) }
}

// MARK: - Typing

// Spine
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Spine`` model object.
    /// Call this on a `spine` element only.
    public var fcpAsSpine: FinalCutPro.FCPXML.Spine? {
        .init(element: self)
    }
}
