//
//  FCPXMLTitle.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Title clip element model for generated video.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Title clip.
    ///
    /// This is a FCP meta type and video is generated.
    /// Its frame rate is inferred from the sequence.
    /// Therefore, "tcFormat" (NDF/DF) attribute is not stored in `title` XML itself.
    public struct Title: FCPXMLElement {
        public let element: any PNXMLElement
        
        public let elementType: ElementType = .title
        
        public static let supportedElementTypes: Set<ElementType> = [.title]
        
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

extension FinalCutPro.FCPXML.Title {
    public init(
        ref: String,
        role: FinalCutPro.FCPXML.VideoRole? = nil,
        // Anchorable Attributes
        lane: Int? = nil,
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
        
        self.ref = ref
        self.role = role
        
        // Anchorable Attributes
        self.lane = lane
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

extension FinalCutPro.FCPXML.Title {
    public enum Attributes: String {
        case ref // effect ID for a Motion template
        case role
        
        // Anchorable Attributes
        case lane
        case offset
        
        // Clip Attributes
        case name
        case start
        case duration
        case enabled
    }
    
    // can contain DTD param*
    // contains DTD %intrinsic-params-video
    // can contain DTD %anchor_item*
    // can contain markers
    // can contain DTD %video_filter_item*
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Title {
    /// Effect ID (resource ID) for a Motion template. (Required)
    public var ref: String {
        get { element.fcpRef ?? "" }
        nonmutating set { element.fcpRef = newValue }
    }
    
    public var role: FinalCutPro.FCPXML.VideoRole? {
        get { element.fcpRole(as: FinalCutPro.FCPXML.VideoRole.self) }
        nonmutating set { element.fcpSet(role: newValue) }
    }
}

extension FinalCutPro.FCPXML.Title: FCPXMLElementClipAttributes { }

// MARK: - Children

extension FinalCutPro.FCPXML.Title {
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

extension FinalCutPro.FCPXML.Title: FCPXMLElementNoteChild { }

extension FinalCutPro.FCPXML.Title: FCPXMLElementMetadataChild { }

extension FinalCutPro.FCPXML.Title: FCPXMLElementTextChildren { }

extension FinalCutPro.FCPXML.Title: FCPXMLElementTextStyleDefinitionChildren { }

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.Title: FCPXMLElementMetaTimeline {
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .title(self) }
}

// MARK: - Typing

// Title
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Title`` model object.
    /// Call this on a `title` element only.
    public var fcpAsTitle: FinalCutPro.FCPXML.Title? {
        .init(element: self)
    }
}
