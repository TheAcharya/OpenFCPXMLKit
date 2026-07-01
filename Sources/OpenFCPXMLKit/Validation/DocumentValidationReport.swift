//
//  DocumentValidationReport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Result of robust document validation (semantic + DTD).
//

import Foundation

/// Result of running both semantic and DTD validation on an FCPXML document.
///
/// Use ``FCPXMLService/performValidation(_:)`` to produce a report. The document
/// is considered valid only when both semantic and DTD checks pass.
@available(macOS 26.0, *)
public struct DocumentValidationReport: Sendable, Equatable {

    /// Result of semantic validation (root, resources, ref resolution, non-negative times).
    public let semantic: ValidationResult

    /// Result of DTD validation against the document’s declared FCPXML version.
    public let dtd: ValidationResult

    /// `true` when both semantic and DTD validation passed (no errors).
    public var isValid: Bool {
        semantic.isValid && dtd.isValid
    }

    public init(semantic: ValidationResult, dtd: ValidationResult) {
        self.semantic = semantic
        self.dtd = dtd
    }

    /// Human-readable summary suitable for CLI or logs.
    public var summary: String {
        if isValid {
            return "Validation passed (semantic and DTD)."
        }
        var parts: [String] = []
        if !semantic.isValid {
            parts.append("semantic: \(semantic.errors.count) error(s)")
        }
        if !dtd.isValid {
            parts.append("DTD: \(dtd.errors.count) error(s)")
        }
        return "Validation failed: \(parts.joined(separator: ", "))."
    }

    /// Full description of all errors and warnings from both checks.
    public var detailedDescription: String {
        var lines: [String] = []
        lines.append("Semantic validation: \(semantic.summary)")
        if !semantic.errors.isEmpty || !semantic.warnings.isEmpty {
            lines.append(semantic.detailedDescription)
        }
        lines.append("")
        lines.append("DTD validation (declared version): \(dtd.summary)")
        if !dtd.errors.isEmpty || !dtd.warnings.isEmpty {
            lines.append(dtd.detailedDescription)
        }
        return lines.joined(separator: "\n")
    }
}
