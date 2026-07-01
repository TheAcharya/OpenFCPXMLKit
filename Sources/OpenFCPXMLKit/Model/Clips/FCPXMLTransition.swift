//
//  FCPXMLTransition.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
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
        public let element: any OFKXMLElement
        
        public let elementType: ElementType = .transition
        
        public static let supportedElementTypes: Set<ElementType> = [.transition]
        
        public init() {
            element = OFKXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }
        
        public init?(element: any OFKXMLElement) {
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
    public var contents: [any OFKXMLElement] {
        get { element.childElements }
        nonmutating set {
            element.removeAllChildren()
            element.addChildren(newValue)
        }
    }
    
    /// Returns child story elements.
    public var storyElements: [any OFKXMLElement] {
        element.fcpStoryElements
    }
}

extension FinalCutPro.FCPXML.Transition: FCPXMLElementMetadataChild { }

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.Transition: FCPXMLElementMetaTimeline {
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .transition(self) }
}

// MARK: - Spine Placement

extension FinalCutPro.FCPXML.Transition {
    /// Whether a transition sits on the main storyline or a connected lane.
    public enum SpinePlacement: Sendable, Equatable {
        case primary
        case secondary
    }
    
    /// Classifies transition placement from its parent spine and ancestor breadcrumbs.
    public static func spinePlacement(
        parentElement: (any OFKXMLElement)?,
        breadcrumbs: [any OFKXMLElement]
    ) -> SpinePlacement {
        if let parentSpine = parentElement,
           parentSpine.fcpElementType == .spine,
           let lane = parentSpine.fcpLane,
           lane != 0
        {
            return .secondary
        }
        
        for ancestor in breadcrumbs {
            guard ancestor.fcpElementType == .spine,
                  let lane = ancestor.fcpLane,
                  lane != 0
            else { continue }
            
            return .secondary
        }
        
        return .primary
    }
    
    /// Classifies this transition's spine placement within its extraction context.
    public func spinePlacement(breadcrumbs: [any OFKXMLElement]) -> SpinePlacement {
        Self.spinePlacement(
            parentElement: element.parentElement,
            breadcrumbs: breadcrumbs
        )
    }
    
    /// True when the transition's primary `filter-video` effect is Apple-supplied.
    public func isAppleSuppliedPrimaryEffect(in resources: (any OFKXMLElement)?) -> Bool {
        guard let effectID = videoFilters.first?.effectID,
              let resource = element.fcpResource(forID: effectID, in: resources),
              let effect = resource.fcpAsEffect
        else { return false }
        
        return effect.isAppleSupplied
    }
}

// MARK: - Typing

// Transition
extension OFKXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Transition`` model object.
    /// Call this on a `transition` element only.
    public var fcpAsTransition: FinalCutPro.FCPXML.Transition? {
        .init(element: self)
    }
}
