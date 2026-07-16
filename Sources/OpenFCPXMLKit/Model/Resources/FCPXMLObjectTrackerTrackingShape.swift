//
// FCPXMLObjectTrackerTrackingShape.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
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
    /// > See [`tracking-shape`](
    /// > https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/tracking-shape
    /// > ).
    public struct TrackingShape: FCPXMLElement {
        public let element: any OFKXMLElement

        public let elementType: FinalCutPro.FCPXML.ElementType = .trackingShape

        public static let supportedElementTypes: Set<FinalCutPro.FCPXML.ElementType> = [.trackingShape]

        public init() {
            element = OFKXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }

        public init?(element: any OFKXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
    }
}

// MARK: - Analysis method

extension FinalCutPro.FCPXML.ObjectTracker.TrackingShape {
    /// DTD `analysisMethod` values for `tracking-shape`.
    public enum AnalysisMethod: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
        case automatic
        case combined
        case machineLearning
        case pointCloud
    }
}

// MARK: - Parameterized init

extension FinalCutPro.FCPXML.ObjectTracker.TrackingShape {
    public init(
        id: String,
        name: String? = nil,
        offsetEnabled: Bool = false,
        analysisMethod: AnalysisMethod = .automatic,
        dataLocator: String? = nil
    ) {
        self.init()
        self.id = id
        self.name = name
        self.offsetEnabled = offsetEnabled
        self.analysisMethod = analysisMethod
        self.dataLocator = dataLocator
    }
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

extension FinalCutPro.FCPXML.ObjectTracker.TrackingShape {
    /// Required tracking-shape identifier.
    public var id: String {
        get { element.fcpID ?? "" }
        nonmutating set { element.fcpID = newValue }
    }

    /// Optional display name.
    public var name: String? {
        get { element.fcpName }
        nonmutating set { element.fcpName = newValue }
    }

    /// Whether offset tracking is enabled (DTD default `0`).
    public var offsetEnabled: Bool {
        get {
            element.getBool(forAttribute: Attributes.offsetEnabled.rawValue) ?? false
        }
        nonmutating set {
            element.set(
                bool: newValue,
                forAttribute: Attributes.offsetEnabled.rawValue,
                defaultValue: false,
                removeIfDefault: true,
                useInt: true
            )
        }
    }

    /// Shape analysis method (DTD default `automatic`).
    public var analysisMethod: AnalysisMethod {
        get {
            guard let raw = element.stringValue(forAttributeNamed: Attributes.analysisMethod.rawValue),
                  let method = AnalysisMethod(rawValue: raw)
            else { return .automatic }
            return method
        }
        nonmutating set {
            if newValue == .automatic {
                element.removeAttribute(forName: Attributes.analysisMethod.rawValue)
            } else {
                element.addAttribute(name: Attributes.analysisMethod.rawValue, value: newValue.rawValue)
            }
        }
    }

    /// Optional locator IDREF for tracking data.
    public var dataLocator: String? {
        get { element.stringValue(forAttributeNamed: Attributes.dataLocator.rawValue) }
        nonmutating set {
            if let newValue {
                element.addAttribute(name: Attributes.dataLocator.rawValue, value: newValue)
            } else {
                element.removeAttribute(forName: Attributes.dataLocator.rawValue)
            }
        }
    }
}

// MARK: - Typing

extension OFKXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/ObjectTracker/TrackingShape``
    /// model object.
    public var fcpAsTrackingShape: FinalCutPro.FCPXML.ObjectTracker.TrackingShape? {
        .init(element: self)
    }
}
