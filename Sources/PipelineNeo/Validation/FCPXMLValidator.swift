//
//  FCPXMLValidator.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Semantic validator for FCPXML documents: root, resources, ref resolution.
//

import Foundation

/// Semantic validator for FCPXML documents: root element, resources, ref resolution, non-negative times.
@available(macOS 12.0, *)
public struct FCPXMLValidator: Sendable {

    public init() {}

    /// Validates the document for semantic consistency.
    ///
    /// Checks: root is `fcpxml`, has `resources`; every `ref` attribute resolves to a resource id;
    /// optional checks for non-negative duration/offset/start where present.
    ///
    /// - Parameter document: The FCPXML document to validate.
    /// - Returns: ValidationResult with errors and optional warnings.
    public func validate(_ document: any PNXMLDocument) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Find the fcpxml root element
        let root: (any PNXMLElement)? = {
            // Try rootElement() first -- for well-formed documents the root is <fcpxml>
            if let r = document.rootElement(), r.name == "fcpxml" {
                return r
            }
            // Fallback: scan children for <fcpxml>
            guard let children = document.children else { return nil }
            for child in children {
                if child.name == "fcpxml", let el = child as? (any PNXMLElement) {
                    return el
                }
            }
            return nil
        }()

        guard let root else {
            errors.append(ValidationError(
                type: .missingRequiredElement,
                message: "Root element 'fcpxml' not found",
                context: [:]
            ))
            return ValidationResult(errors: errors, warnings: warnings)
        }

        // Check for resources element
        let resourcesElement = root.firstChildElement(named: "resources")
        if resourcesElement == nil {
            errors.append(ValidationError(
                type: .missingRequiredElement,
                message: "Missing 'resources' element",
                context: [:]
            ))
        }

        // Collect all element IDs in the document (resources + text-style-def, etc.).
        // Refs can point to top-level resources or to elements like <text-style-def id="ts1"> inside titles/captions.
        var resourceIDs: Set<String> = []
        collectIDs(from: root, into: &resourceIDs)

        var refs: [String] = []
        collectRefs(from: root, into: &refs)

        for ref in refs {
            if !resourceIDs.contains(ref) {
                errors.append(ValidationError(
                    type: .missingAssetReference,
                    message: "Reference '\(ref)' does not match any resource id",
                    context: ["ref": ref]
                ))
            }
        }

        // Check for negative time attributes (duration, offset, start).
        collectNegativeTimeWarnings(from: root, into: &warnings)

        return ValidationResult(errors: errors, warnings: warnings)
    }

    private func collectRefs(from element: any PNXMLElement, into refs: inout [String]) {
        if let ref = element.attribute(forName: "ref"), !ref.isEmpty {
            refs.append(ref)
        }
        for child in element.childElements {
            collectRefs(from: child, into: &refs)
        }
    }

    /// Recursively collects all element `id` attribute values (resources, text-style-def, etc.).
    private func collectIDs(from element: any PNXMLElement, into ids: inout Set<String>) {
        if let id = element.attribute(forName: "id"), !id.isEmpty {
            ids.insert(id)
        }
        for child in element.childElements {
            collectIDs(from: child, into: &ids)
        }
    }

    /// Recursively collects warnings for time attributes whose rational value is negative.
    private func collectNegativeTimeWarnings(from element: any PNXMLElement, into warnings: inout [ValidationWarning]) {
        let timeAttributes = ["duration", "offset", "start"]
        for attr in timeAttributes {
            if let value = element.attribute(forName: attr),
               isNegativeTimeString(value) {
                warnings.append(ValidationWarning(
                    type: .negativeTimeAttribute,
                    message: "Element '\(element.name ?? "unknown")' has negative \(attr): \(value)"
                ))
            }
        }
        for child in element.childElements {
            collectNegativeTimeWarnings(from: child, into: &warnings)
        }
    }

    /// Checks whether an FCPXML time string (e.g. "-100/2400s") represents a negative value.
    private func isNegativeTimeString(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("-")
    }
}
