//
//  FCPXMLStructuralValidator.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Cross-platform structural validator for FCPXML documents.
//	Performs structural checks using PNXMLDocument / PNXMLElement protocols
//	WITHOUT requiring Foundation DTD validation.
//

import Foundation

/// A lightweight cross-platform structural validator for FCPXML documents.
///
/// Performs structural checks (root element name, version attribute, required children,
/// element name allowlist) using protocol types and does NOT require Foundation XML
/// or DTD files. This makes it suitable for iOS and other platforms where DTD
/// validation is unavailable.
@available(macOS 12.0, *)
public struct FCPXMLStructuralValidator: Sendable {

    public init() {}

    // MARK: - Public API

    /// Validates the structural correctness of an FCPXML document.
    ///
    /// Checks performed:
    /// 1. Root element is named `fcpxml`
    /// 2. Root element has a valid `version` attribute
    /// 3. Root has a `resources` child and at least one of `library`, `event`, or `project`
    /// 4. All element names in the document are in the FCPXML allowlist
    ///
    /// - Parameter document: The FCPXML document to validate.
    /// - Returns: A `ValidationResult` with any errors and warnings.
    public func validate(_ document: any PNXMLDocument) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Add a warning that this is structural-only validation (no DTD).
        warnings.append(ValidationWarning(
            type: .structuralValidationOnly,
            message: "Structural validation only; full DTD validation was not performed"
        ))

        // 1. Root element must be named "fcpxml"
        guard let root = findFCPXMLRoot(in: document) else {
            errors.append(ValidationError(
                type: .missingRequiredElement,
                message: "Root element 'fcpxml' not found"
            ))
            return ValidationResult(errors: errors, warnings: warnings)
        }

        // 2. Version attribute must be present and valid
        validateVersionAttribute(of: root, errors: &errors)

        // 3. Required children: resources, and at least one of library/event/project
        validateRequiredChildren(of: root, errors: &errors)

        // 4. Element name allowlist check
        validateElementNames(from: root, errors: &errors)

        return ValidationResult(errors: errors, warnings: warnings)
    }

    // MARK: - Private Helpers

    /// Locates the `fcpxml` root element in the document.
    private func findFCPXMLRoot(in document: any PNXMLDocument) -> (any PNXMLElement)? {
        if let root = document.rootElement(), root.name == "fcpxml" {
            return root
        }
        // Fallback: scan top-level children
        guard let children = document.children else { return nil }
        for child in children {
            if child.name == "fcpxml", let element = child as? (any PNXMLElement) {
                return element
            }
        }
        return nil
    }

    /// Validates that the root fcpxml element has a valid `version` attribute.
    private func validateVersionAttribute(of root: any PNXMLElement, errors: inout [ValidationError]) {
        guard let version = root.attribute(forName: "version") else {
            errors.append(ValidationError(
                type: .invalidAttributeValue,
                message: "Root 'fcpxml' element is missing required 'version' attribute",
                context: ["element": "fcpxml"]
            ))
            return
        }

        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            errors.append(ValidationError(
                type: .invalidAttributeValue,
                message: "Root 'fcpxml' element has an empty 'version' attribute",
                context: ["element": "fcpxml", "version": version]
            ))
            return
        }

        // Validate version format: should be a recognized FCPXML version (major.minor)
        if !Self.knownVersions.contains(trimmed) {
            // Not a hard error, but we accept any numeric x.y pattern
            let parts = trimmed.split(separator: ".")
            let isNumericVersion = parts.count == 2
                && parts.allSatisfy({ $0.allSatisfy(\.isNumber) })
            if !isNumericVersion {
                errors.append(ValidationError(
                    type: .invalidAttributeValue,
                    message: "Root 'fcpxml' element has an invalid 'version' attribute: '\(trimmed)'",
                    context: ["element": "fcpxml", "version": trimmed]
                ))
            }
        }
    }

    /// Validates that the root has a `resources` child and at least one content child.
    private func validateRequiredChildren(of root: any PNXMLElement, errors: inout [ValidationError]) {
        let childNames = Set(root.childElements.compactMap(\.name))

        if !childNames.contains("resources") {
            errors.append(ValidationError(
                type: .missingRequiredElement,
                message: "Missing required 'resources' element as child of 'fcpxml'",
                context: ["element": "fcpxml"]
            ))
        }

        let contentElements: Set<String> = ["library", "event", "project"]
        if childNames.isDisjoint(with: contentElements) {
            errors.append(ValidationError(
                type: .missingRequiredElement,
                message: "Root 'fcpxml' element must contain at least one of: library, event, or project",
                context: ["element": "fcpxml"]
            ))
        }
    }

    /// Recursively checks all element names against the FCPXML allowlist.
    private func validateElementNames(from element: any PNXMLElement, errors: inout [ValidationError]) {
        if let name = element.name, !Self.allowedElementNames.contains(name) {
            errors.append(ValidationError(
                type: .unknownElementName,
                message: "Unknown FCPXML element '\(name)'",
                context: ["element": name]
            ))
        }
        for child in element.childElements {
            validateElementNames(from: child, errors: &errors)
        }
    }

    // MARK: - Known Versions

    /// Known FCPXML version strings (1.5 through 1.14).
    static let knownVersions: Set<String> = [
        "1.5", "1.6", "1.7", "1.8", "1.9",
        "1.10", "1.11", "1.12", "1.13", "1.14",
    ]

    // MARK: - FCPXML Element Name Allowlist

    /// The set of all known FCPXML element names (versions 1.5 through 1.14).
    static let allowedElementNames: Set<String> = [
        // Document structure
        "fcpxml", "resources", "library", "event", "project",

        // Sequences and spines
        "sequence", "spine",

        // Clip types
        "asset-clip", "clip", "audio", "video", "gap", "title",
        "mc-clip", "sync-clip", "compound-clip", "audition", "ref-clip",

        // Transitions
        "transition",

        // Resources
        "asset", "effect", "format", "media",

        // Multicam
        "multicam", "mc-angle", "mc-source",

        // Collections
        "collection-folder", "keyword-collection", "smart-collection", "match",

        // Text and captions
        "text", "text-style", "text-style-def", "caption",

        // Parameters
        "param",

        // Filters and effects
        "filter-video", "filter-video-mask", "filter-audio",

        // Rate and timing
        "rate-conform", "conform-rate", "timeMap", "timept",

        // Transform and crop
        "crop", "trim", "pan",

        // Metadata
        "metadata", "md",

        // Audio
        "audio-role-source", "audio-channel-source", "conform-audio", "audio-layout",

        // Markers and annotations
        "note", "keyword", "marker", "chapter-marker", "rating",

        // Adjustments
        "adjust-crop", "adjust-corners", "adjust-conform",
        "adjust-transform", "adjust-blend", "adjust-volume", "adjust-panner",
        "adjust-noiseReduction", "adjust-hueAndSaturation", "adjust-exposure",
        "adjust-colorBoard", "adjust-colorWheels", "adjust-colorCurves",

        // Info and options
        "info", "import-options", "option", "bookmark", "reserved",

        // Sync and intrinsic
        "sync-source", "intrinsic-params",

        // Spine groups
        "spine-group",

        // Media representation
        "media-rep",

        // Masking
        "mask-shape", "mask-shape-source",

        // Roles
        "role",

        // Color processing
        "color-processing-info",

        // Chains
        "chain", "chain-item",

        // Object tracking
        "object-tracker", "tracking-shape", "analysis-mark",

        // Live drawing (FCP 11+)
        "live-drawing",

        // Additional known elements
        "adjust-loudness", "adjust-EQ", "adjust-matchEQ",
        "conform-rate", "story",
    ]
}
