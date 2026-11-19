//
//  FCPXMLVersionConverter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of FCPXMLVersionConverting: sets root version, strips elements and attributes not in the target version's DTD (bulletproof when DTD available), and returns a copy.
//

import Foundation

/// Default implementation of `FCPXMLVersionConverting`.
///
/// Produces a copy of the document with the root `version` attribute set to the
/// target version. Elements and attributes that are not defined in the target
/// version’s DTD (e.g. `adjust-colorConform` in 1.11+, `param` `auxValue` in 1.11+,
/// `format` `heroEye` and `asset` `heroEyeOverride` in 1.13+) are automatically
/// removed so the output validates in Final Cut Pro and remains backward compatible
/// with FCPXML 1.5.
@available(macOS 26.0, *)
public final class FCPXMLVersionConverter: FCPXMLVersionConverting, Sendable {

    private nonisolated(unsafe) let factory: any OFKXMLFactory

    /// Creates a new version converter.
    /// - Parameter factory: XML factory for creating documents (default: `OFKXMLDefaultFactory()`).
    public init(factory: any OFKXMLFactory = OFKXMLDefaultFactory()) {
        self.factory = factory
    }

    // MARK: - FCPXMLVersionConverting (Sync)

    public func convert(_ document: any OFKXMLDocument, to targetVersion: FCPXMLVersion) throws -> any OFKXMLDocument {
        try _convert(document, to: targetVersion)
    }

    // MARK: - FCPXMLVersionConverting (Async)

    public func convert(_ document: any OFKXMLDocument, to targetVersion: FCPXMLVersion) async throws -> any OFKXMLDocument {
        try _convert(document, to: targetVersion)
    }

    /// Elements introduced after a given version (per ``FinalCutPro/FCPXML/VersionFeatureGate``).
    /// When converting to a target version, any element not available at that version is stripped.
    private static func elementNamesToStrip(whenConvertingTo target: FCPXMLVersion) -> Set<String> {
        FinalCutPro.FCPXML.VersionFeatureGate.elementNamesToOmit(at: target)
    }

    /// Attribute names to remove from the given element when converting to `target`.
    private static func attributeNamesToStrip(forElement elementName: String, whenConvertingTo target: FCPXMLVersion) -> Set<String> {
        FinalCutPro.FCPXML.VersionFeatureGate.attributeNamesToOmit(
            onElement: elementName,
            at: target
        )
    }

    private func _convert(_ document: any OFKXMLDocument, to targetVersion: FCPXMLVersion) throws -> any OFKXMLDocument {
        let data = document.xmlData
        let copy = try factory.makeDocument(data: data, options: .fcpxmlDefaults)
        copy.rootElement()?.addAttribute(name: "version", value: targetVersion.stringValue)

        guard let root = copy.rootElement() else {
            #if DEBUG
            assertionFailure("FCPXMLVersionConverter: Document copy has no root element. Stripping skipped.")
            #endif
            return copy
        }

        // When converting to 1.5–1.8, asset has src directly; in 1.9+ src is on media-rep. Promote first media-rep src onto asset before stripping so the result is valid.
        if targetVersion.usesAssetSrcDirectly {
            promoteMediaRepSrcToAsset(in: root)
        }

        // Prefer DTD-derived allowlist (from embedded or bundle DTD) for bulletproof stripping.
        if let dtdData = EmbeddedDTDProvider.dtdData(forResourceName: targetVersion.dtdResourceName) {
            let (allowedElements, allowedAttributesByElement) = FCPXMLDTDAllowlistGenerator.allowlist(fromDTDContent: dtdData)
            stripElementsNotInAllowlist(in: root, allowedNames: allowedElements)
            stripAttributesNotInAllowlist(in: root, allowedAttributesByElement: allowedAttributesByElement)
        } else {
            // Fallback: hand-maintained lists when DTD not available.
            let elementNamesToStrip = Self.elementNamesToStrip(whenConvertingTo: targetVersion)
            if !elementNamesToStrip.isEmpty {
                stripElements(in: root, names: elementNamesToStrip)
            }
            stripUnsupportedAttributes(in: root, targetVersion: targetVersion)
        }

        if targetVersion.isOlder(than: .v1_15) {
            normalizeEnumerationsIntroducedIn1_15(in: root)
        }
        if targetVersion.isOlder(than: .v1_13) {
            normalizeConformSourceFrameRatesIntroducedIn1_13(in: root)
        }

        return copy
    }

    /// DTD allowlists name `srcFrameRate`, not its tokens. FCPXML 1.13 added
    /// `90`, `100`, `119.88`, and `120`. Drop those tokens below 1.13 so the
    /// attribute falls back to omitted (`#IMPLIED`).
    private func normalizeConformSourceFrameRatesIntroducedIn1_13(in element: any OFKXMLElement) {
        if element.name == "conform-rate",
           let rate = element.attribute(forName: "srcFrameRate"),
           Self.conformSourceFrameRatesIntroducedIn1_13.contains(rate)
        {
            element.removeAttribute(forName: "srcFrameRate")
        }
        for child in element.childElements {
            normalizeConformSourceFrameRatesIntroducedIn1_13(in: child)
        }
    }

    /// DTD allowlists name attributes, not enumeration tokens. FCPXML 1.15 widened
    /// `keyframe` `interp` and `frameSampling`. Drop tokens the older DTD cannot accept
    /// so the attribute falls back to its DTD default (`linear` / `floor`).
    private func normalizeEnumerationsIntroducedIn1_15(in element: any OFKXMLElement) {
        switch element.name {
        case "keyframe":
            if let interp = element.attribute(forName: "interp"),
               !Self.keyframeInterpolationsBefore1_15.contains(interp)
            {
                element.removeAttribute(forName: "interp")
            }
        case "conform-rate", "timeMap":
            if element.attribute(forName: "frameSampling") == "vsa-motion-blur" {
                element.removeAttribute(forName: "frameSampling")
            }
        default:
            break
        }
        for child in element.childElements {
            normalizeEnumerationsIntroducedIn1_15(in: child)
        }
    }

    /// When converting to 1.5–1.8, the DTD has asset with src on the element; in 1.9+ src is on media-rep. Promotes the first media-rep's src onto each asset that lacks src so that after we strip media-rep the asset still has required src.
    private func promoteMediaRepSrcToAsset(in element: any OFKXMLElement) {
        if element.name == "asset", element.attribute(forName: "src") == nil {
            let mediaReps = element.childElements.filter { $0.name == "media-rep" }
            if let firstMediaRep = mediaReps.first,
               let src = firstMediaRep.attribute(forName: "src"), !src.isEmpty {
                element.addAttribute(name: "src", value: src)
            }
        }
        for child in element.childElements {
            promoteMediaRepSrcToAsset(in: child)
        }
    }

    /// Recursively removes direct children whose name is not in `allowedNames` (DTD-derived allowlist).
    private func stripElementsNotInAllowlist(in element: any OFKXMLElement, allowedNames: Set<String>) {
        let children = element.children ?? []
        var indicesToRemove: [Int] = []
        for (index, node) in children.enumerated() {
            guard node.asElement != nil, let name = node.name else { continue }
            if !allowedNames.contains(name) {
                indicesToRemove.append(index)
            }
        }
        for index in indicesToRemove.reversed() {
            element.removeChild(at: index)
        }
        for child in element.childElements {
            stripElementsNotInAllowlist(in: child, allowedNames: allowedNames)
        }
    }

    /// Recursively removes attributes not in the DTD-derived allowlist for each element.
    /// Elements with no ATTLIST in the DTD have an empty allowlist, so all attributes are removed.
    private func stripAttributesNotInAllowlist(in element: any OFKXMLElement, allowedAttributesByElement: [String: Set<String>]) {
        if let name = element.name {
            let allowedAttrs = allowedAttributesByElement[name] ?? []
            let attrNames = element.attributes.map { $0.name }
            for attrName in attrNames where !allowedAttrs.contains(attrName) {
                element.removeAttribute(forName: attrName)
            }
        }
        for child in element.childElements {
            stripAttributesNotInAllowlist(in: child, allowedAttributesByElement: allowedAttributesByElement)
        }
    }

    /// Recursively removes direct children whose name is in `names` (fallback when DTD not available).
    private func stripElements(in element: any OFKXMLElement, names: Set<String>) {
        let children = element.children ?? []
        var indicesToRemove: [Int] = []
        for (index, node) in children.enumerated() {
            guard node.asElement != nil, let name = node.name, names.contains(name) else { continue }
            indicesToRemove.append(index)
        }
        for index in indicesToRemove.reversed() {
            element.removeChild(at: index)
        }
        for child in element.childElements {
            stripElements(in: child, names: names)
        }
    }

    private static let keyframeInterpolationsBefore1_15: Set<String> = [
        "linear", "ease", "easeIn", "easeOut",
    ]

    private static let conformSourceFrameRatesIntroducedIn1_13: Set<String> = [
        "90", "100", "119.88", "120",
    ]

    /// Recursively removes attributes not supported by the target version (fallback when DTD not available).
    private func stripUnsupportedAttributes(in element: any OFKXMLElement, targetVersion: FCPXMLVersion) {
        if let name = element.name {
            let toStrip = Self.attributeNamesToStrip(forElement: name, whenConvertingTo: targetVersion)
            for attrName in toStrip {
                element.removeAttribute(forName: attrName)
            }
        }
        for child in element.childElements {
            stripUnsupportedAttributes(in: child, targetVersion: targetVersion)
        }
    }
}

// MARK: - FCPXMLVersion ordering

@available(macOS 26.0, *)
private extension FCPXMLVersion {
    /// Returns `true` if this version is strictly older than `other` (e.g. 1.10 is older than 1.11).
    func isOlder(than other: FCPXMLVersion) -> Bool {
        guard let selfIndex = FCPXMLVersion.allCases.firstIndex(of: self),
              let otherIndex = FCPXMLVersion.allCases.firstIndex(of: other) else {
            return false
        }
        return selfIndex < otherIndex
    }

    /// True for 1.5–1.8 where asset has `src` on the element; false for 1.9+ where `src` is on media-rep.
    var usesAssetSrcDirectly: Bool {
        switch self {
        case .v1_5, .v1_6, .v1_7, .v1_8: return true
        default: return false
        }
    }
}
