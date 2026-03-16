//
//  FCPXMLProject.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Project element model.
//

import CoreMedia
import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Project element.
    public struct Project: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .project

        public static let supportedElementTypes: Set<ElementType> = [.project]

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

extension FinalCutPro.FCPXML.Project {
    public init(
        name: String? = nil,
        id: String? = nil,
        uid: String? = nil,
        // Mod Date
        modDate: String? = nil
    ) {
        self.init()
        
        self.name = name
        self.id = id
        self.uid = uid
        
        // Mod Date
        self.modDate = modDate
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Project {
    public enum Attributes: String {
        // Element-Specific Attributes
        case name
        case id
        case uid
        case modDate
    }
    
    // must contain one sequence
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Project {
    public var name: String? {
        get { element.fcpName }
        nonmutating set { element.fcpName = newValue }
    }
    
    public var id: String? {
        get { element.fcpID }
        nonmutating set { element.fcpID = newValue }
    }
    
    public var uid: String? {
        get { element.fcpUID }
        nonmutating set { element.fcpUID = newValue }
    }
}

extension FinalCutPro.FCPXML.Project: FCPXMLElementOptionalModDate { }

// MARK: - Children

extension FinalCutPro.FCPXML.Project {
    /// Get or set the child `sequence` element. (Required)
    public var sequence: FinalCutPro.FCPXML.Sequence {
        get {
            element.firstChild(whereFCPElement: .sequence, defaultChild: .init())
        }
        nonmutating set {
            element._updateFirstChildElement(
                ofType: .sequence,
                withChild: newValue
            )
        }
    }
}

// MARK: - Properties

extension FinalCutPro.FCPXML.Project {
    /// Convenience:
    /// Returns the start timecode of the `sequence` contained within the project.
    public func startTimecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .mainTimeline
    ) -> Timecode? {
        sequence.tcStartAsTimecode(frameRateSource: frameRateSource)
    }
}

// MARK: - Typing

// Project
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Project`` model object.
    /// Call this on a `project` element only.
    public var fcpAsProject: FinalCutPro.FCPXML.Project? {
        .init(element: self)
    }
}
