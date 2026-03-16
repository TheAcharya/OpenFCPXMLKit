//
//  FCPXMLDTDValidator.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	DTD schema validator for FCPXML documents.
//

import Foundation

/// Validates an FCPXML document against the DTD for a given FCPXML version.
///
/// On macOS and Linux (platforms with Foundation XML support), the validator performs
/// full DTD validation against the version-specific DTD schema.
///
/// On other platforms (e.g. iOS), the validator delegates to ``FCPXMLStructuralValidator``
/// and returns a `.structuralValidationOnly` warning instead of the DTD-unavailable error.
/// If structural validation finds errors, those errors are returned.
@available(macOS 12.0, *)
public struct FCPXMLDTDValidator: Sendable {

    public init() {}

    /// Validates the document against the specified version's DTD.
    ///
    /// - Parameters:
    ///   - document: The FCPXML document to validate.
    ///   - version: The FCPXML version whose DTD to use.
    /// - Returns: `.success` if valid; otherwise a result with errors (and possibly warnings).
    public func validate(_ document: any PNXMLDocument, version: FCPXMLVersion) -> ValidationResult {
        #if canImport(FoundationXML) || os(macOS)
        guard let foundationDoc = document as? FoundationXMLDocument else {
            return .error(ValidationError(
                type: .dtdValidation,
                message: "DTD validation requires a Foundation-backed document",
                context: ["version": version.stringValue]
            ))
        }
        do {
            try foundationDoc.validateFCPXMLAgainst(version: version)
            return .success
        } catch {
            return .error(ValidationError(
                type: .dtdValidation,
                message: error.localizedDescription,
                context: ["version": version.stringValue]
            ))
        }
        #else
        // On platforms without Foundation XML / DTD support, delegate to
        // the cross-platform structural validator instead of failing outright.
        let structuralResult = FCPXMLStructuralValidator().validate(document)

        if !structuralResult.isValid {
            // Structural validation found errors — return them directly.
            return structuralResult
        }

        // Structural validation passed. Return a warning indicating that only
        // structural checks were performed (no full DTD validation).
        // The structural validator already includes this warning, so we can
        // return its result as-is.
        return structuralResult
        #endif
    }
}
