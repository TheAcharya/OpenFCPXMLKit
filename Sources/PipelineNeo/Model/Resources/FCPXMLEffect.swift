//
//  FCPXMLEffect.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Effect shared resource model (Motion templates, FxPlug, Audio Units).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Effect shared resource.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > Reference visual, audio, or custom effects.
    /// >
    /// > Use the `effect` element to reference an effect that can be a Motion template, a FxPlug,
    /// > an Audio Unit, or an audio effect bundle. Use a `filter-video`, `filter-video-mask`, or
    /// > `filter-audio` element to apply the effect to a story element.
    /// >
    /// > See [`effect`](
    /// > https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/effect
    /// > ).
    public struct Effect: FCPXMLElement, Equatable, Hashable, Codable {
        public let element: any PNXMLElement

        public let elementType: ElementType = .effect

        public static let supportedElementTypes: Set<ElementType> = [.effect]

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

extension FinalCutPro.FCPXML.Effect {
    public init(
        id: String,
        name: String? = nil,
        uid: String,
        src: String? = nil
    ) {
        self.init()
        
        self.id = id
        self.name = name
        self.uid = uid
        self.src = src
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Effect {
    public enum Attributes: String {
        // shared resource attributes
        /// Identifier. (Required)
        case id
        
        /// Name.
        case name
        
        // effect attributes
        
        /// UID. (Required)
        case uid // required
        
        /// Source.
        case src
    }
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Effect {
    // shared resource attributes
    
    /// Identifier. (Required)
    public var id: String {
        get { element.fcpID ?? "" }
        nonmutating set { element.fcpID = newValue }
    }
    
    /// Name.
    public var name: String? {
        get { element.fcpName }
        nonmutating set { element.fcpName = newValue }
    }
    
    // effect attributes
    
    /// UID. (Required)
    public var uid: String {
        get { element.fcpUID ?? "" }
        nonmutating set { element.fcpUID = newValue }
    }
    
    /// Source.
    public var src: String? {
        get { element.fcpSRC }
        nonmutating set { element.fcpSRC = newValue }
    }
}

// MARK: - Codable

extension FinalCutPro.FCPXML.Effect {
    private enum CodingKeys: String, CodingKey {
        case id, name, uid
        case sourceURL = "src"
    }
    
    /// Encodes the effect to a container.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(uid, forKey: .uid)
        try container.encodeIfPresent(src, forKey: .sourceURL)
    }
    
    /// Creates an effect from a decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let uid = try container.decode(String.self, forKey: .uid)
        let src = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        
        self.init(id: id, name: name, uid: uid, src: src)
    }
}

// MARK: - Equatable & Hashable

extension FinalCutPro.FCPXML.Effect {
    public static func == (lhs: FinalCutPro.FCPXML.Effect, rhs: FinalCutPro.FCPXML.Effect) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.uid == rhs.uid && lhs.src == rhs.src
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(uid)
        hasher.combine(src)
    }
}

// MARK: - Typing

// Effect
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in an ``FinalCutPro/FCPXML/Effect`` model object.
    /// Call this on an `effect` element only.
    public var fcpAsEffect: FinalCutPro.FCPXML.Effect? {
        .init(element: self)
    }
}
