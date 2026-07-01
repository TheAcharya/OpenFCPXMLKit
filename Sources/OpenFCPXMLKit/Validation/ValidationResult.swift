//
//  ValidationResult.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Validation result container with errors and warnings.
//

import Foundation

/// Result of validating an FCPXML document or timeline.
@available(macOS 26.0, *)
public struct ValidationResult: Sendable, Equatable {

    /// Whether the document/timeline is valid (no errors).
    public let isValid: Bool

    /// Validation errors (empty when valid).
    public let errors: [ValidationError]

    /// Warnings (may be non-empty even when valid).
    public let warnings: [ValidationWarning]

    public init(errors: [ValidationError] = [], warnings: [ValidationWarning] = []) {
        self.errors = errors
        self.warnings = warnings
        self.isValid = errors.isEmpty
    }

    /// Successful result with no errors or warnings.
    public static let success = ValidationResult()

    /// Result with a single error.
    public static func error(_ error: ValidationError) -> ValidationResult {
        ValidationResult(errors: [error])
    }

    /// Result with a single warning.
    public static func warning(_ warning: ValidationWarning) -> ValidationResult {
        ValidationResult(warnings: [warning])
    }

    /// Short summary string.
    public var summary: String {
        if isValid {
            if warnings.isEmpty {
                return "Validation passed with no warnings"
            } else {
                return "Validation passed with \(warnings.count) warning(s)"
            }
        } else {
            return "Validation failed with \(errors.count) error(s) and \(warnings.count) warning(s)"
        }
    }

    /// Full description of all errors and warnings.
    public var detailedDescription: String {
        var lines: [String] = []
        if !errors.isEmpty {
            lines.append("Errors:")
            for (index, error) in errors.enumerated() {
                lines.append("  \(index + 1). [\(error.type.rawValue)] \(error.message)")
                for (key, value) in error.context.sorted(by: { $0.key < $1.key }) {
                    lines.append("     - \(key): \(value)")
                }
            }
        }
        if !warnings.isEmpty {
            if !errors.isEmpty { lines.append("") }
            lines.append("Warnings:")
            for (index, warning) in warnings.enumerated() {
                lines.append("  \(index + 1). [\(warning.type.rawValue)] \(warning.message)")
                for (key, value) in warning.context.sorted(by: { $0.key < $1.key }) {
                    lines.append("     - \(key): \(value)")
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}
