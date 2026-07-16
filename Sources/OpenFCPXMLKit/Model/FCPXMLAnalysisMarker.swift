//
// FCPXMLAnalysisMarker.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Analysis-marker element model (shot-type / stabilization-type children).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// An FCPXML `analysis-marker` produced by media analysis.
    ///
    /// DTD: `analysis-marker (shot-type | stabilization-type)+` with optional `start` / `duration`.
    public struct AnalysisMarker: FCPXMLElement, Equatable, Hashable {
        public let element: any OFKXMLElement

        public let elementType: ElementType = .analysisMarker

        public static let supportedElementTypes: Set<ElementType> = [.analysisMarker]

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

extension FinalCutPro.FCPXML.AnalysisMarker {
    public init(
        start: Fraction? = nil,
        duration: Fraction? = nil,
        shotTypes: [FinalCutPro.FCPXML.ShotType] = [],
        stabilizationTypes: [FinalCutPro.FCPXML.StabilizationType] = []
    ) {
        self.init()
        self.start = start
        self.duration = duration
        self.shotTypes = shotTypes
        self.stabilizationTypes = stabilizationTypes
    }
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.AnalysisMarker {
    public enum Attributes: String {
        case start
        case duration
    }
}

extension FinalCutPro.FCPXML.AnalysisMarker: FCPXMLElementOptionalStart { }

extension FinalCutPro.FCPXML.AnalysisMarker: FCPXMLElementOptionalDuration { }

// MARK: - Children

extension FinalCutPro.FCPXML.AnalysisMarker {
    /// Child `shot-type` values.
    public var shotTypes: [FinalCutPro.FCPXML.ShotType] {
        get {
            element.childElements
                .filter { $0.name == "shot-type" }
                .compactMap { child -> FinalCutPro.FCPXML.ShotType? in
                    guard let raw = child.stringValue(forAttributeNamed: "value"),
                          let value = FinalCutPro.FCPXML.ShotType.Value(rawValue: raw)
                    else { return nil }
                    return FinalCutPro.FCPXML.ShotType(value: value)
                }
        }
        nonmutating set {
            element.removeChildren { $0.name == "shot-type" }
            for shot in newValue {
                let child = OFKXMLDefaultFactory().makeElement(name: "shot-type")
                child.addAttribute(name: "value", value: shot.value.rawValue)
                element.addChild(child)
            }
        }
    }

    /// Child `stabilization-type` values.
    public var stabilizationTypes: [FinalCutPro.FCPXML.StabilizationType] {
        get {
            element.childElements
                .filter { $0.name == "stabilization-type" }
                .compactMap { child -> FinalCutPro.FCPXML.StabilizationType? in
                    guard let raw = child.stringValue(forAttributeNamed: "value"),
                          let value = FinalCutPro.FCPXML.StabilizationType.Value(rawValue: raw)
                    else { return nil }
                    return FinalCutPro.FCPXML.StabilizationType(value: value)
                }
        }
        nonmutating set {
            element.removeChildren { $0.name == "stabilization-type" }
            for stab in newValue {
                let child = OFKXMLDefaultFactory().makeElement(name: "stabilization-type")
                child.addAttribute(name: "value", value: stab.value.rawValue)
                element.addChild(child)
            }
        }
    }

    /// Display name synthesised from analysis children (for Markers report).
    public var displayName: String {
        let shots = shotTypes.map(\.value.rawValue)
        let stabs = stabilizationTypes.map(\.value.rawValue)
        let parts = shots + stabs
        if parts.isEmpty { return "Analysis" }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Typing

extension OFKXMLElement {
    /// FCPXML: Returns the element wrapped as ``FinalCutPro/FCPXML/AnalysisMarker``.
    public var fcpAsAnalysisMarker: FinalCutPro.FCPXML.AnalysisMarker? {
        .init(element: self)
    }
}
