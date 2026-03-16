//
//  FCPXMLEvent.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Event element model for a single event in a library.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Represent a single event in a library.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > An event may contain clips as story elements and projects, along with keyword collections
    /// > and smart collections. The keyword-collection and smart-collection elements organize clips
    /// > by keywords and other matching criteria listed under the Smart Collection Match Elements.
    public struct Event: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .event

        public static let supportedElementTypes: Set<ElementType> = [.event]

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

extension FinalCutPro.FCPXML.Event {
    public init(
        name: String,
        uid: String? = nil
    ) {
        self.init()
        
        self.name = name
        self.uid = uid
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Event {
    public enum Attributes: String {
        // Element-Specific Attributes
        case name
        case uid
    }
    
    // can contain one or more of any:
    //   clip | audition | mc-clip | ref-clip | sync-clip | asset-clip | project
    // can contain one or more of any DTD %collection_item:
    //   collection-folder | keyword-collection | smart-collection
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Event {
    public var name: String {
        get { element.fcpName ?? "" }
        nonmutating set { element.fcpName = newValue }
    }
    
    public var uid: String? {
        get { element.fcpUID }
        nonmutating set { element.fcpUID = newValue }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Event {
    /// Get or set child `project` elements.
    public var projects: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Project> {
        get { element.children(whereFCPElement: .project) }
        nonmutating set { element._updateChildElements(ofType: .project, with: newValue) }
    }
    
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
    
    /// Multiple `smart-collection` elements may exist within the `event` element.
    public var smartCollections: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.SmartCollection> {
        element.children(whereFCPElement: FinalCutPro.FCPXML.SmartCollection.self)
    }
}

// MARK: - Typing

// Event
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in an ``FinalCutPro/FCPXML/Event`` model object.
    /// Call this on an `event` element only.
    public var fcpAsEvent: FinalCutPro.FCPXML.Event? {
        .init(element: self)
    }
}
