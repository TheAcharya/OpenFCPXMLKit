//
//  FCPXMLFormat.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Format shared resource model for video format definitions.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Format shared resource.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > Reference a video-format definition.
    /// >
    /// > Use this element to reference one of the video formats listed under Predefined Video
    /// > Formats through the name attribute, or use it to describe a custom video format using the
    /// > Format Element Attributes. For audio only assets, use the `FFFrameRateUndefined` format.
    /// >
    /// > When Format Element Attributes exist, they override the predefined format value identified
    /// > by the name attribute.
    /// >
    /// > See [`format`](https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/format).
    public struct Format: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .format

        public static let supportedElementTypes: Set<ElementType> = [.format]

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

extension FinalCutPro.FCPXML.Format {
    public init(
        id: String,
        name: String? = nil,
        frameDuration: Fraction? = nil,
        fieldOrder: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        paspH: Int? = nil,
        paspV: Int? = nil,
        colorSpace: String? = nil,
        projection: String? = nil,
        stereoscopic: String? = nil,
        heroEye: String? = nil  // FCPXML 1.13+; omit for 1.5–1.12
    ) {
        self.init()
        
        self.id = id
        self.name = name
        self.frameDuration = frameDuration
        self.fieldOrder = fieldOrder
        self.width = width
        self.height = height
        self.paspH = paspH
        self.paspV = paspV
        self.colorSpace = colorSpace
        self.projection = projection
        self.stereoscopic = stereoscopic
        self.heroEye = heroEye
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Format {
    public enum Attributes: String {
        // shared resource attributes
        case id // required
        case name
        
        // format attributes
        case frameDuration
        case fieldOrder // only present if video is interlaced
        case width // Int
        case height // Int
        case paspH // seems to be an Int
        case paspV // seems to be an Int
        case colorSpace
        case projection
        case stereoscopic // note that Apple docs misspell it as "sterioscopic"
        /// Hero eye for stereoscopic. FCPXML 1.13+; backward compatible with 1.5 (omit when version < 1.13). "left" | "right".
        case heroEye
    }
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Format {
    // shared resource attributes
    
    /// Identifier. (Required)
    public var id: String {
        get { element.fcpID ?? "" }
        nonmutating set { element.fcpID = newValue }
    }
    
    public var name: String? {
        get { element.fcpName }
        nonmutating set { element.fcpName = newValue }
    }
    
    // format attributes
    
    public var frameDuration: Fraction? {
        get { element.fcpFrameDuration }
        nonmutating set { element.fcpFrameDuration = newValue }
    }
    
    /// Field order. Only present if video is interlaced.
    public var fieldOrder: String? {
        get { element.stringValue(forAttributeNamed: Attributes.fieldOrder.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.fieldOrder.rawValue, value: newValue) }
    }
    
    public var width: Int? {
        get { element.getInt(forAttribute: Attributes.width.rawValue) }
        nonmutating set { element.set(int: newValue, forAttribute: Attributes.width.rawValue) }
    }
    
    public var height: Int? {
        get { element.getInt(forAttribute: Attributes.height.rawValue) }
        nonmutating set { element.set(int: newValue, forAttribute: Attributes.height.rawValue) }
    }
    
    public var paspH: Int? {
        get { element.getInt(forAttribute: Attributes.paspH.rawValue) }
        nonmutating set { element.set(int: newValue, forAttribute: Attributes.paspH.rawValue) }
    }
    
    public var paspV: Int? {
        get { element.getInt(forAttribute: Attributes.paspV.rawValue) }
        nonmutating set { element.set(int: newValue, forAttribute: Attributes.paspV.rawValue) }
    }
    
    public var colorSpace: String? {
        get { element.stringValue(forAttributeNamed: Attributes.colorSpace.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.colorSpace.rawValue, value: newValue) }
    }
    
    public var projection: String? {
        get { element.stringValue(forAttributeNamed: Attributes.projection.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.projection.rawValue, value: newValue) }
    }
    
    public var stereoscopic: String? {
        get { element.stringValue(forAttributeNamed: Attributes.stereoscopic.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.stereoscopic.rawValue, value: newValue) }
    }
    
    /// Hero eye for stereoscopic. FCPXML 1.13+; backward compatible with 1.5 (omit when version < 1.13). Values: "left" | "right".
    public var heroEye: String? {
        get { element.stringValue(forAttributeNamed: Attributes.heroEye.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.heroEye.rawValue, value: newValue) }
    }
}

// MARK: - Typing

// Format
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Format`` model object.
    /// Call this on a `format` element only.
    public var fcpAsFormat: FinalCutPro.FCPXML.Format? {
        .init(element: self)
    }
}
