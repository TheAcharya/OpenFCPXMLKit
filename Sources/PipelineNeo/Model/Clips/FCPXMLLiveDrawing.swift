//
//  FCPXMLLiveDrawing.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Live-drawing clip element model (FCPXML 1.11+). PKDrawing/sketch content on the timeline.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Live-drawing clip (FCPXML 1.11+).
    ///
    /// Story element for drawn/sketch content. DTD: `(param*, note?, %intrinsic-params-live-drawing;, (%anchor_item;)*, (%marker_item;)*, (%video_filter_item;)*)` with clip_attrs, role, dataLocator, animationType.
    public struct LiveDrawing: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .liveDrawing

        public static let supportedElementTypes: Set<ElementType> = [.liveDrawing]

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

extension FinalCutPro.FCPXML.LiveDrawing {
    public init(
        role: String? = nil,
        dataLocator: String? = nil,
        animationType: String? = nil,
        // Anchorable Attributes
        lane: Int? = nil,
        offset: Fraction? = nil,
        // Clip Attributes
        name: String? = nil,
        start: Fraction? = nil,
        duration: Fraction,
        enabled: Bool = true,
        note: String? = nil
    ) {
        self.init()

        self.role = role
        self.dataLocator = dataLocator
        self.animationType = animationType

        self.lane = lane
        self.offset = offset

        self.name = name
        self.start = start
        self.duration = duration
        self.enabled = enabled

        self.note = note
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.LiveDrawing {
    public enum Attributes: String {
        case role
        case dataLocator
        case animationType
        case lane
        case offset
        case name
        case start
        case duration
        case enabled
    }

    // Contains param*, note?, intrinsic params, anchor_item*, marker_item*, video_filter_item*
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.LiveDrawing {
    /// Role (default 'video' per DTD).
    public var role: String? {
        get { element.attribute(forName: "role") }
        nonmutating set {
            if let v = newValue { element.addAttribute(name: "role", value: v) }
            else { element.removeAttribute(forName: "role") }
        }
    }

    /// IDREF to location of serialized PKDrawing data file; can be empty.
    public var dataLocator: String? {
        get { element.attribute(forName: "dataLocator") }
        nonmutating set {
            if let v = newValue { element.addAttribute(name: "dataLocator", value: v) }
            else { element.removeAttribute(forName: "dataLocator") }
        }
    }

    /// Animation type for the live drawing.
    public var animationType: String? {
        get { element.attribute(forName: "animationType") }
        nonmutating set {
            if let v = newValue { element.addAttribute(name: "animationType", value: v) }
            else { element.removeAttribute(forName: "animationType") }
        }
    }
}

extension FinalCutPro.FCPXML.LiveDrawing: FCPXMLElementClipAttributes { }

// MARK: - Children

extension FinalCutPro.FCPXML.LiveDrawing: FCPXMLElementNoteChild { }

// MARK: - Meta Conformances

extension FinalCutPro.FCPXML.LiveDrawing: FCPXMLElementMetaTimeline {
    public func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline { .liveDrawing(self) }
}

// MARK: - Typing

extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/LiveDrawing`` model object.
    /// Call this on a `live-drawing` element only (FCPXML 1.11+).
    public var fcpAsLiveDrawing: FinalCutPro.FCPXML.LiveDrawing? {
        .init(element: self)
    }
}
