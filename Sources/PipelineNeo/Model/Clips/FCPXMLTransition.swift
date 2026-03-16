//
//  FCPXMLTransition.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Transition element model between clips.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Transition element.
    ///
    /// Transition elements may only be present within a `spine` or an `mc-angle` element.
    ///
    /// The `offset` attribute defines the start of the transition in its parent timeline.
    ///
    /// ## Final Cut Pro UI Behavior
    ///
    /// When placing a new transition between two clips in Final Cut Pro, the default transition
    /// `duration` is typically 1 second.
    ///
    /// ## FCPXML Reference
    ///
    /// > Final Cut Pro FCPXML 1.13 Reference:
    /// >
    /// > A transition element defines an effect that overlaps two adjacent story elements.
    public struct Transition: FCPXMLElement {
        public let element: any PNXMLElement
        
        public let elementType: ElementType = .transition
        
        public static let supportedElementTypes: Set<ElementType> = [.transition]
        
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

extension FinalCutPro.FCPXML.Transition {
    public init(
        // Element Attributes
        offset: Fraction? = nil,
        name: String? = nil,
        duration: Fraction,
        // Metadata
        metadata: FinalCutPro.FCPXML.Metadata? = nil
    ) {
        self.init()
        
        // Element Attributes
        self.offset = offset
        self.name = name
        self.duration = duration
        
        // Metadata
        self.metadata = metadata
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Transition {
    public enum Attributes: String {
        // Element Attributes
        case offset // optional
        case name // optional
        case duration // required
    }
    
    // can contain filter-audio
    // can contain filter-video
    // can contain markers
    // can contain metadata
    // can contain reserved
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Transition {
    /// Transition name.
    public var name: String? {
        get { element.fcpName }
        nonmutating set { element.fcpName = newValue }
    }
}

extension FinalCutPro.FCPXML.Transition: FCPXMLElementOptionalOffset { }

extension FinalCutPro.FCPXML.Transition: FCPXMLElementRequiredDuration { }

// MARK: - Children

extension FinalCutPro.FCPXML.Transition {
    /// Get or set child elements.
    public var contents: [any PNXMLElement] {
        get { element.childElements }
        nonmutating set {
            element.removeAllChildren()
            element.addChildren(newValue)
        }
    }
    
    /// Returns child story elements.
    public var storyElements: [any PNXMLElement] {
        element.fcpStoryElements
    }
}

extension FinalCutPro.FCPXML.Transition: FCPXMLElementMetadataChild { }

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.Transition: FCPXMLElementMetaTimeline {
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .transition(self) }
}

// MARK: - Typing

// Transition
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Transition`` model object.
    /// Call this on a `transition` element only.
    public var fcpAsTransition: FinalCutPro.FCPXML.Transition? {
        .init(element: self)
    }
}
