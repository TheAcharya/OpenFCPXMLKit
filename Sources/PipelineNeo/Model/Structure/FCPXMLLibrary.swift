//
//  FCPXMLLibrary.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Library element model for library location on disk.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Represents a library location on disk.
    public struct Library: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .library

        public static let supportedElementTypes: Set<ElementType> = [.library]

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

extension FinalCutPro.FCPXML.Library {
    /// Initialize an empty library with a location URL.
    public init(
        location: URL
    ) {
        self.init()
        
        self.location = location
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Library {
    public enum Attributes: String {
        /// Specifies the URL of a library on export; Final Cut Pro ignores this option during the
        /// XML import. To specify the target library for the XML import, see the `library` location
        /// key listed under the `[import-options`](
        /// https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/import-options
        /// ) attributes.
        case location
        
        /// Specifies whether the library supports `standard`, `wide`, or `wide-hdr` color gamut.
        /// The default is `standard`.
        case colorProcessing
    }
    
    // can contain `event`s
    // can contain `smart-collection`s
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Library {
    /// Specifies the URL of a library on export; Final Cut Pro ignores this option during the
    /// XML import. To specify the target library for the XML import, see the `library` location
    /// key listed under the `[import-options`](
    /// https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/import-options
    /// ) attributes.
    public var location: URL? {
        get { element.fcpLibraryLocation }
        nonmutating set { element.fcpLibraryLocation = newValue }
    }
    
    /// Specifies whether the library supports `standard`, `wide`, or `wide-hdr` color gamut.
    /// The default is `standard`.
    public var colorProcessing: String? {
        get {
            element.stringValue(forAttributeNamed: Attributes.colorProcessing.rawValue)
        }
        nonmutating set {
            element.addAttribute(name: Attributes.colorProcessing.rawValue, value: newValue)
        }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Library {
    /// Multiple `event` elements may exist within the `library` element.
    public var events: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Event> {
        element.children(whereFCPElement: .event)
    }
    
    /// Multiple `smart-collection` elements may exist within the `library` element.
    public var smartCollections: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.SmartCollection> {
        element.children(whereFCPElement: FinalCutPro.FCPXML.SmartCollection.self)
    }
}

// MARK: - Properties

extension FinalCutPro.FCPXML.Library {
    /// Returns the library name, derived from the `location` URL.
    public var name: String? {
        element.fcpLibraryName
    }
}

// Library
extension PNXMLElement {
    /// FCPXML: Returns the library name, derived from the `location` URL.
    /// Call on a `library` element.
    public var fcpLibraryName: String? {
        guard let libraryLocation = fcpLibraryLocation else { return nil }
        
        // will be a file URL that is URL encoded
        let libName = libraryLocation
            .deletingPathExtension()
            .lastPathComponent
        
        // decode URL encoding
        let libNameDecoded = libName.removingPercentEncoding ?? libName
        
        return libNameDecoded
    }
    
    /// FCPXML: Get or set the library `location` URL.
    /// Call on a `library` element.
    public var fcpLibraryLocation: URL? {
        get { getURL(forAttribute: "location") }
        set { set(url: newValue, forAttribute: "location") }
    }
}

// MARK: - Typing

// Library
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Library`` model object.
    /// Call this on a `library` element only.
    public var fcpAsLibrary: FinalCutPro.FCPXML.Library? {
        .init(element: self)
    }
}
