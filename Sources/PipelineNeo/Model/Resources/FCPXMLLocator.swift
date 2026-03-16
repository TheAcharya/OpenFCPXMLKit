//
//  FCPXMLLocator.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Locator shared resource model for URL-based resources.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Locator shared resource.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > Describe a URL-based resource.
    /// >
    /// > Use the `locator` element to describe the location of data files associated with another
    /// > FCPXML element.
    /// >
    /// > See [`locator`](https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/locator).
    public struct Locator: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .locator

        public static let supportedElementTypes: Set<ElementType> = [.locator]

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

extension FinalCutPro.FCPXML.Locator {
    public init(
        id: String,
        url: URL? = nil
    ) {
        self.init()
        
        self.id = id
        self.url = url
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Locator {
    public enum Attributes: String {
        /// Required.
        /// Identifier.
        case id
        
        /// Required.
        /// Absolute URL or relative URL to library path.
        case url
    }
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Locator {
    /// Required.
    /// Identifier.
    public var id: String {
        get { element.fcpID ?? "" }
        nonmutating set { element.fcpID = newValue }
    }
    
    /// Required.
    /// Absolute URL or relative URL to library path.
    public var url: URL? {
        get { element.getURL(forAttribute: Attributes.url.rawValue) }
        nonmutating set { element.set(url: newValue, forAttribute: Attributes.url.rawValue) }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Locator: FCPXMLElementBookmarkChild { }

// MARK: - Typing

// Locator
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Locator`` model object.
    /// Call this on a `locator` element only.
    public var fcpAsLocator: FinalCutPro.FCPXML.Locator? {
        .init(element: self)
    }
}
