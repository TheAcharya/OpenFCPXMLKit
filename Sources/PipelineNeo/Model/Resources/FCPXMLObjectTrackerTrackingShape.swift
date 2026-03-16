//
//  FCPXMLObjectTrackerTrackingShape.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Object tracker tracking shape element model.
//

import Foundation

extension FinalCutPro.FCPXML.ObjectTracker {
    /// Tracking shape used by an object tracker resource.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > Define a shape that the `object-tracker` uses to match the movement of an object.
    /// >
    /// > In Final Cut Pro, users can track the `shape-mask` of a video effect such as a blur,
    /// > highlight, or color effect to a moving object in a video clip.
    /// >
    /// > Use the `tracking-shape` element to define the shape that the `object-tracker` element
    /// > uses to match the movement of a moving object in a video clip. Each `object-tracker`
    /// > element consists of one or more tracking shapes.
    /// >
    /// > See [`tracking-shape`](
    /// > https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/tracking-shape
    /// > ).
    public struct TrackingShape: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: FinalCutPro.FCPXML.ElementType = .trackingShape

        public static let supportedElementTypes: Set<FinalCutPro.FCPXML.ElementType> = [.trackingShape]

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

extension FinalCutPro.FCPXML.ObjectTracker.TrackingShape {
    // Note: init will be added when attribute properties are implemented.
}

// MARK: - Structure

extension FinalCutPro.FCPXML.ObjectTracker.TrackingShape {
    public enum Attributes: String {
        case id // required
        case name
        case offsetEnabled // 0 or 1, Default: 0
        case analysisMethod // enum case
        case dataLocator
    }
    
}

// MARK: - Attributes

// Note: attributes not yet implemented.

// MARK: - Typing

// ObjectTracker.TrackingShape
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/ObjectTracker/TrackingShape``
    /// model object.
    /// Call this on a `tracking-shape` element only.
    public var fcpAsTrackingShape: FinalCutPro.FCPXML.ObjectTracker.TrackingShape? {
        .init(element: self)
    }
}
