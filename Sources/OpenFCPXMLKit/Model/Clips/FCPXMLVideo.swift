//
//  FCPXMLVideo.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Video element model referencing video data.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Video element.
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > References video data from an `asset` or `effect` element.
    public struct Video: FCPXMLElement {
        public let element: any OFKXMLElement
        
        public let elementType: ElementType = .video
        
        public static let supportedElementTypes: Set<ElementType> = [.video]
        
        public init() {
            element = OFKXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }
        
        public init?(element: any OFKXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
    }
}

// MARK: - Parameterized init

extension FinalCutPro.FCPXML.Video {
    public init(
        ref: String,
        role: FinalCutPro.FCPXML.VideoRole? = nil,
        srcID: String? = nil,
        // Anchorable Attributes
        lane: Int? = nil,
        offset: Fraction? = nil,
        // Clip Attributes
        name: String? = nil,
        start: Fraction? = nil,
        duration: Fraction,
        enabled: Bool = true,
        // Note child
        note: String? = nil
    ) {
        self.init()
        
        self.ref = ref
        self.role = role
        self.srcID = srcID
        
        // Anchorable Attributes
        self.lane = lane
        self.offset = offset
        
        // Clip Attributes
        self.name = name
        self.start = start
        self.duration = duration
        self.enabled = enabled
        
        // Note child
        self.note = note
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Video {
    public enum Attributes: String {
        /// Required.
        /// Resource ID.
        case ref
        case role
        /// Source/track identifier in asset (if not '1').
        case srcID
        
        // Anchorable Attributes
        case lane
        case offset
        
        // Clip Attributes
        case name
        case start
        case duration
        case enabled
    }
    
    // can contain DTD param*
    // contains DTD %timing-params
    // contains DTD %intrinsic-params-primitive-video (FCPXML 1.15+; includes adjust-natural-motion-blur)
    // can contain DTD %anchor_item*
    // can contain markers
    // can contain DTD %video_filter_item*
    // con contain one or zero DTD reserved?
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Video {
    /// Resource ID. (Required)
    public var ref: String {
        get { element.fcpRef ?? "" }
        nonmutating set { element.fcpRef = newValue }
    }
    
    /// Video role. (Default: Video)
    public var role: FinalCutPro.FCPXML.VideoRole? {
        get { element.fcpRole(as: FinalCutPro.FCPXML.VideoRole.self) }
        nonmutating set { element.fcpSet(role: newValue) }
    }
    
    /// Source/track identifier in asset (if not '1').
    public var srcID: String? {
        get { element.stringValue(forAttributeNamed: Attributes.srcID.rawValue) }
        nonmutating set { element.addAttribute(name: Attributes.srcID.rawValue, value: newValue) }
    }
}

extension FinalCutPro.FCPXML.Video: FCPXMLElementClipAttributes { }

// MARK: - Children

extension FinalCutPro.FCPXML.Video {
    /// Get or set child elements.
    public var contents: [any OFKXMLElement] {
        get { element.childElements }
        nonmutating set {
            element.removeAllChildren()
            element.addChildren(newValue)
        }
    }
    
    /// Returns child story elements.
    public var storyElements: [any OFKXMLElement] {
        element.fcpStoryElements
    }
}

extension FinalCutPro.FCPXML.Video: FCPXMLElementNoteChild { }

extension FinalCutPro.FCPXML.Video: FCPXMLElementTimingParams { }

extension FinalCutPro.FCPXML.Video {
    /// Natural Motion Blur. FCPXML 1.15+. Valid only on a primitive `<video>` element.
    public var naturalMotionBlurAdjustment: FinalCutPro.FCPXML.NaturalMotionBlurAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-natural-motion-blur") else {
                return nil
            }
            let enabledString = adjustElement.stringValue(forAttributeNamed: "enabled") ?? "1"
            let parameters = Array(
                adjustElement.childElements
                    .filter { $0.name == "param" }
                    .compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) }
            )
            return FinalCutPro.FCPXML.NaturalMotionBlurAdjustment(
                isEnabled: enabledString == "1",
                amount: adjustElement.stringValue(forAttributeNamed: "amount"),
                parameters: parameters
            )
        }
        nonmutating set {
            element.removeChildren { $0.name == "adjust-natural-motion-blur" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-natural-motion-blur")
            if !adjustment.isEnabled {
                adjustElement.addAttribute(name: "enabled", value: "0")
            }
            if let amount = adjustment.amount {
                adjustElement.addAttribute(name: "amount", value: amount)
            }
            for param in adjustment.parameters {
                let paramElement = OFKXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: "name", value: param.name)
                if let key = param.key { paramElement.addAttribute(name: "key", value: key) }
                if let value = param.value { paramElement.addAttribute(name: "value", value: value) }
                if let aux = param.auxValue { paramElement.addAttribute(name: "auxValue", value: aux) }
                if !param.isEnabled { paramElement.addAttribute(name: "enabled", value: "0") }
                adjustElement.addChild(paramElement)
            }
            element.addChild(adjustElement)
        }
    }
}

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.Video: FCPXMLElementMetaTimeline {
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .video(self) }
}

// MARK: - Typing

// Video
extension OFKXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Video`` model object.
    /// Call this on a `video` element only.
    public var fcpAsVideo: FinalCutPro.FCPXML.Video? {
        .init(element: self)
    }
}
