//
//  FCPXMLMediaRep.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Media representation element model (original or proxy).
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Media representation.
    ///
    /// Conforms to `Sendable` via `@unchecked Sendable` because it wraps ``PNXMLElement``, which is
    /// not `Sendable`. Safe to use across concurrency boundaries when the owning document is not
    /// shared across isolation domains (same pattern as other FCPXML element wrappers in this module).
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > References a media representation, that is either the original or a proxy media managed by Final Cut Pro.
    /// >
    /// > A media that Final Cut Pro manages in its library can have a proxy media representation,
    /// > in addition to the original media representation. Use the media-rep element to describe a
    /// > media representation, as a child element of the asset element.
    public struct MediaRep: FCPXMLElement, Equatable, Hashable, @unchecked Sendable {
        public let element: any PNXMLElement

        public let elementType: ElementType = .mediaRep

        public static let supportedElementTypes: Set<ElementType> = [.mediaRep]

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

extension FinalCutPro.FCPXML.MediaRep {
    public init(
        kind: Kind = .originalMedia,
        sig: String? = nil,
        src: URL? = nil,
        suggestedFilename: String? = nil,
        bookmark: Data? = nil
    ) {
        self.init()
        
        self.kind = kind
        self.sig = sig
        self.src = src
        self.suggestedFilename = suggestedFilename
        self.bookmarkData = bookmark
    }
    
    public init(
        kind: Kind = .originalMedia,
        sig: String? = nil,
        src: URL? = nil,
        suggestedFilename: String? = nil,
        bookmark: String
    ) {
        self.init()
        
        self.kind = kind
        self.sig = sig
        self.src = src
        self.suggestedFilename = suggestedFilename
        // Convert bookmark string to Data using lossy UTF-8 encoding. This initializer assumes
        // the provided bookmark is a textual, UTF-8–compatible representation (for example, a string
        // that was previously created from bookmark `Data`). If any code points cannot be encoded,
        // they may be replaced during conversion, which can result in an unusable bookmark. In that
        // case, or if conversion fails entirely, we fall back to empty `Data` to represent the
        // absence of a bookmark, preserving the initializer's existing semantics that a malformed
        // string is treated the same as "no bookmark".
        if let data = bookmark.data(using: .utf8, allowLossyConversion: true) {
            self.bookmarkData = data
        } else {
            // Log a warning so the failure is not completely silent, but preserve existing behavior
            NSLog("FCPXML.MediaRep: Failed to convert bookmark string to UTF-8 Data; falling back to empty Data(). Bookmark may be unusable.")
            self.bookmarkData = Data()
        }
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.MediaRep {
    public enum Attributes: String {
        /// The kind of media representation.
        /// Default: `original-media`
        case kind
        
        /// The unique identifier of a media representation, assigned by Final Cut Pro.
        case sig
        
        /// Required.
        /// May be a full absolute URL to a local `file://` or remote `https://` resource.
        /// May also be a relative URL based on the location of the FCPXML document itself, for example: `./Media/MyMovie.mov`.
        case src
        
        /// The filename string to use when Final Cut Pro manages the media representation file.
        ///
        /// See [FCPXML Reference](
        /// https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/asset/media-rep
        /// ) for details.
        case suggestedFilename
    }
    
    /// Each `media-rep` element may contain a single `bookmark` child element, representing
    /// bookmark data (for example, a security-scoped bookmark) used by Final Cut Pro to locate
    /// the underlying media file.
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.MediaRep {
    /// The kind of media representation.
    /// Default: `original-media`
    public var kind: Kind {
        get {
            let defaultValue: Kind = .originalMedia
            
            guard let value = element.stringValue(forAttributeNamed: Attributes.kind.rawValue)
            else { return defaultValue }
            
            return Kind(rawValue: value) ?? defaultValue
        }
        nonmutating set {
            element.addAttribute(name: Attributes.kind.rawValue, value: newValue.rawValue)
        }
    }
    
    /// The unique identifier of a media representation, assigned by Final Cut Pro.
    public var sig: String? {
        get { element.stringValue(forAttributeNamed: Attributes.sig.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.sig.rawValue, value: newValue) }
    }
    
    /// Required.
    /// May be a full absolute URL to a local `file://` or remote `https://` resource.
    /// May also be a relative URL based on the location of the FCPXML document itself, for example: `./Media/MyMovie.mov`.
    public var src: URL? {
        get { element.getURL(forAttribute: Attributes.src.rawValue) }
        nonmutating set { element.set(url: newValue, forAttribute: Attributes.src.rawValue) }
    }
    
    /// The filename string to use when Final Cut Pro manages the media representation file.
    ///
    /// Used when the filename should not be derived from the URL. The appropriate extension
    /// should be included.
    ///
    /// See [FCPXML Reference](
    /// https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/asset/media-rep
    /// ) for details.
    public var suggestedFilename: String? {
        get { element.stringValue(forAttributeNamed: Attributes.suggestedFilename.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.suggestedFilename.rawValue, value: newValue) }
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.MediaRep: FCPXMLElementBookmarkChild { }

// MARK: - Properties

extension FinalCutPro.FCPXML.MediaRep {
    /// Convenience method that returns the `src` filename.
    public func srcFilename() -> String? {
        src?.lastPathComponent
    }
}

// MARK: - Typing

// MediaRep
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in an ``FinalCutPro/FCPXML/MediaRep`` model object.
    /// Call this on an `media-rep` element only.
    public var fcpAsMediaRep: FinalCutPro.FCPXML.MediaRep? {
        .init(element: self)
    }
}
// MARK: - Attribute Types

extension FinalCutPro.FCPXML.MediaRep {
    public enum Kind: String, Equatable, Hashable, CaseIterable, Sendable {
        case originalMedia = "original-media"
        case proxyMedia = "proxy-media"
    }
}
