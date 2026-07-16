//
// FCPXMLMute.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Mute element model — suppresses audio for a source time range (fadeIn/fadeOut optional).
//

import Foundation
import SwiftTimecode
import CoreMedia

extension FinalCutPro.FCPXML {
    /// An FCPXML `mute` element that suppresses audio output for a range of source media time.
    ///
    /// DTD: `mute (fadeIn?, fadeOut?)` with optional `start` / `duration`.
    public struct Mute: FCPXMLElement, Equatable, Hashable {
        public let element: any OFKXMLElement

        public let elementType: ElementType = .mute

        public static let supportedElementTypes: Set<ElementType> = [.mute]

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

extension FinalCutPro.FCPXML.Mute {
    public init(
        start: Fraction? = nil,
        duration: Fraction? = nil,
        fadeIn: FinalCutPro.FCPXML.FadeIn? = nil,
        fadeOut: FinalCutPro.FCPXML.FadeOut? = nil
    ) {
        self.init()
        self.start = start
        self.duration = duration
        self.fadeIn = fadeIn
        self.fadeOut = fadeOut
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Mute {
    public enum Attributes: String {
        case start
        case duration
    }
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Mute: FCPXMLElementOptionalStart { }

extension FinalCutPro.FCPXML.Mute: FCPXMLElementOptionalDuration { }

// MARK: - Children

extension FinalCutPro.FCPXML.Mute {
    /// Optional fade-in on the mute range.
    public var fadeIn: FinalCutPro.FCPXML.FadeIn? {
        get {
            guard let fadeElement = element.firstChildElement(named: "fadeIn") else { return nil }
            let typeString = fadeElement.stringValue(forAttributeNamed: "type") ?? FinalCutPro.FCPXML.FadeType.easeIn.rawValue
            let type = FinalCutPro.FCPXML.FadeType(rawValue: typeString) ?? .easeIn
            let durationString = fadeElement.stringValue(forAttributeNamed: "duration") ?? "0s"
            return FinalCutPro.FCPXML.FadeIn(type: type, duration: CMTime.fcpxmlTime(from: durationString))
        }
        nonmutating set {
            element.removeChildren { $0.name == "fadeIn" }
            guard let fade = newValue else { return }
            let fadeElement = OFKXMLDefaultFactory().makeElement(name: "fadeIn")
            if fade.type != .easeIn {
                fadeElement.addAttribute(name: "type", value: fade.type.rawValue)
            }
            fadeElement.addAttribute(name: "duration", value: fade.duration.fcpxmlString)
            element.addChild(fadeElement)
        }
    }

    /// Optional fade-out on the mute range.
    public var fadeOut: FinalCutPro.FCPXML.FadeOut? {
        get {
            guard let fadeElement = element.firstChildElement(named: "fadeOut") else { return nil }
            let typeString = fadeElement.stringValue(forAttributeNamed: "type") ?? FinalCutPro.FCPXML.FadeType.easeOut.rawValue
            let type = FinalCutPro.FCPXML.FadeType(rawValue: typeString) ?? .easeOut
            let durationString = fadeElement.stringValue(forAttributeNamed: "duration") ?? "0s"
            return FinalCutPro.FCPXML.FadeOut(type: type, duration: CMTime.fcpxmlTime(from: durationString))
        }
        nonmutating set {
            element.removeChildren { $0.name == "fadeOut" }
            guard let fade = newValue else { return }
            let fadeElement = OFKXMLDefaultFactory().makeElement(name: "fadeOut")
            if fade.type != .easeOut {
                fadeElement.addAttribute(name: "type", value: fade.type.rawValue)
            }
            fadeElement.addAttribute(name: "duration", value: fade.duration.fcpxmlString)
            element.addChild(fadeElement)
        }
    }
}

// MARK: - Typing

extension OFKXMLElement {
    /// FCPXML: Returns the element wrapped as ``FinalCutPro/FCPXML/Mute``.
    public var fcpAsMute: FinalCutPro.FCPXML.Mute? {
        .init(element: self)
    }
}
