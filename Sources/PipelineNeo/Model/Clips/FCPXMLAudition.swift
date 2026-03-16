//
//  FCPXMLAudition.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Audition element model with active and alternative story elements.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Contains one active story element followed by alternative story elements in the audition
    /// > container.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > When exported, the XML lists the currently active item as the first child in the audition
    /// > container.
    public struct Audition: FCPXMLElement {
        public let element: any PNXMLElement
        
        public let elementType: ElementType = .audition
        
        public static let supportedElementTypes: Set<ElementType> = [.audition]
        
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

extension FinalCutPro.FCPXML.Audition {
    public init(
        // Anchorable Attributes
        lane: Int? = nil,
        offset: Fraction? = nil,
        // Mod Date
        modDate: String? = nil
    ) {
        self.init()
        
        // Anchorable Attributes
        self.lane = lane
        self.offset = offset
        
        // Mod Date
        self.modDate = modDate
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Audition {
    public enum Attributes: String {
        // Element-Specific Attributes
        case modDate
        
        // Anchorable Attributes
        case lane
        case offset
    }
    
    // can only contain one or more clips
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Audition: FCPXMLElementAnchorableAttributes { }

extension FinalCutPro.FCPXML.Audition: FCPXMLElementOptionalModDate { }

// Note: convenience accessors; consider requiring explicit active clip access.
extension FinalCutPro.FCPXML.Audition /* Clip Attributes */ {
    /// Get or set the active clip's `name` attribute.
    public var name: String? {
        get { activeClip?.fcpName }
        nonmutating set { activeClip?.fcpName = newValue }
    }
    
    /// Get or set the active clip's `start` attribute.
    public var start: Fraction? {
        get { activeClip?.fcpStart }
        nonmutating set { activeClip?.fcpStart = newValue }
    }
    
    /// Get or set the active clip's `duration` attribute.
    public var duration: Fraction? {
        get { activeClip?.fcpDuration }
        nonmutating set { activeClip?.fcpDuration = newValue }
    }
    
    /// Get or set the active clip's `enabled` attribute.
    public var enabled: Bool {
        get { activeClip?.fcpGetEnabled(default: true) ?? true }
        nonmutating set { activeClip?.fcpSet(enabled: newValue, default: true) }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Audition {
    /// Returns the audition clips.
    /// The first clip is the active audition and subsequent clips are inactive.
    /// The convenience property ``activeClip`` is also available to return the first clip.
    public var clips: [any PNXMLElement] {
        get { element.childElements }
        nonmutating set {
            element.removeAllChildren()
            element.addChildren(newValue)
        }
    }
    
    /// Convenience to return the active audition clip.
    public var activeClip: (any PNXMLElement)? {
        get { clips.first }
        nonmutating set {
            guard let newValue = newValue else { return }
            guard !clips.isEmpty else {
                element.addChild(newValue)
                return
            }
            element.removeChild(at: 0)
            element.insertChild(newValue, at: 0)
        }
    }
    
    /// Convenience to return the inactive audition clips, if any.
    public var inactiveClips: ArraySlice<any PNXMLElement> {
        clips.dropFirst()
    }
}

// MARK: - Typing

// Audition
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Audition`` model object.
    /// Call this on a `audition` element only.
    public var fcpAsAudition: FinalCutPro.FCPXML.Audition? {
        .init(element: self)
    }
}

// MARK: - Supporting Types

extension FinalCutPro.FCPXML.Audition {
    public enum AuditionMask: Equatable, Hashable, CaseIterable, Sendable {
        case active
        case all
    }
}
