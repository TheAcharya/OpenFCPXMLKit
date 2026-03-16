//
//  FCPXMLGap.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Gap element model as a placeholder with no audio or video.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Gap element.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > Defines a placeholder element that has no intrinsic audio or video data.
    public struct Gap: FCPXMLElement {
        public let element: any PNXMLElement
        
        public let elementType: ElementType = .gap
        
        public static let supportedElementTypes: Set<ElementType> = [.gap]
        
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

extension FinalCutPro.FCPXML.Gap {
    public init(
        // Anchorable Attributes
        // (no lane)
        offset: Fraction? = nil,
        // Clip Attributes
        name: String? = nil,
        start: Fraction? = nil,
        duration: Fraction,
        enabled: Bool = true,
        // Note child
        note: String? = nil,
        // Metadata
        metadata: FinalCutPro.FCPXML.Metadata? = nil
    ) {
        self.init()
        
        // Anchorable Attributes
        // (no lane)
        self.offset = offset
        
        // Clip Attributes
        self.name = name
        self.start = start
        self.duration = duration
        self.enabled = enabled
        
        // Note child
        self.note = note
        
        // Metadata
        self.metadata = metadata
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Gap {
    public enum Attributes: String {
        // Anchorable Attributes
        // (no lane)
        case offset
        
        // Clip Attributes
        case name
        case start
        case duration
        case enabled
    }
    
    // can contain DTD anchor_item*
    // can contain markers
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Gap: FCPXMLElementClipAttributes {
    // A kludge since Gap uses 5 of the 6 clip attributes, except `lane`.
    @available(*, deprecated, message: "Can't set lane attribute on gap clip.")
    public var lane: Int? {
        get { nil }
        nonmutating set {
            // Intentionally ignored: gaps do not support a lane attribute.
        }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Gap {
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

extension FinalCutPro.FCPXML.Gap: FCPXMLElementMetadataChild { }

extension FinalCutPro.FCPXML.Gap: FCPXMLElementNoteChild { }

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.Gap: FCPXMLElementMetaTimeline {
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .gap(self) }
}


// MARK: - Typing

// Gap
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Gap`` model object.
    /// Call this on a `gap` element only.
    public var fcpAsGap: FinalCutPro.FCPXML.Gap? {
        .init(element: self)
    }
}
