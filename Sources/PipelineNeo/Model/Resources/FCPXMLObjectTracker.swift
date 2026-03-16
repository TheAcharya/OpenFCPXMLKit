//
//  FCPXMLObjectTracker.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Object tracker shared resource model.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Object tracker shared resource.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > Describe a tracked object such as a face or other moving object in a video clip.
    /// >
    /// > Users can track moving objects in video clips to match their movement to a clip, title,
    /// > logo, generator, or a still image, by using the object-tracker feature in Final Cut Pro.
    /// > They can also track the shape mask of a video effect, for example a blur, highlight, or
    /// > color effect, to a moving object in a video clip.
    /// >
    /// > See [`object-tracker`](https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/object-tracker).
    public struct ObjectTracker: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .objectTracker

        public static let supportedElementTypes: Set<ElementType> = [.objectTracker]

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

extension FinalCutPro.FCPXML.ObjectTracker {
    public init(
        trackingShapes: [TrackingShape]
    ) {
        self.init()
        
        element._addChildren(trackingShapes)
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.ObjectTracker {
    // no Attributes
    
    // contains 1 or more `tracking-shape`
}

// MARK: - Children

extension FinalCutPro.FCPXML.ObjectTracker {
    /// Returns child `tracking-shape` elements.
    public var trackingShapes: LazyFCPXMLChildrenSequence<TrackingShape> {
        element.children(whereFCPElement: .trackingShape)
    }
}

// MARK: - Typing

// ObjectTracker
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/ObjectTracker`` model object.
    /// Call this on a `object-tracker` element only.
    public var fcpAsObjectTracker: FinalCutPro.FCPXML.ObjectTracker? {
        .init(element: self)
    }
}
