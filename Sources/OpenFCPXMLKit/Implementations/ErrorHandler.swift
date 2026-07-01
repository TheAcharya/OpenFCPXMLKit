//
//  ErrorHandler.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Implementation of error handling and formatting.
//

import Foundation

/// Default implementation of the `ErrorHandling` protocol.
///
/// Formats FCPXML errors into human-readable messages, with specific handling
/// for each `FCPXMLError` case.
@available(macOS 26.0, *)
public final class ErrorHandler: ErrorHandling, Sendable {
    
    /// Creates a new error handler.
    public init() {}
    
    // MARK: - ErrorHandling Implementation
    
    /// Formats a parsing error into a descriptive message.
    public func handleParsingError(_ error: Error) -> String {
        if let fcpxmlError = error as? FCPXMLError {
            switch fcpxmlError {
            case .parsingFailed(let underlyingError):
                return "FCPXML parsing failed: \(underlyingError.localizedDescription)"
            case .invalidFormat:
                return "Invalid FCPXML format"
            case .unsupportedVersion:
                return "Unsupported FCPXML version"
            case .validationFailed(let message):
                return "Validation failed: \(message)"
            case .timecodeConversionFailed(let message):
                return "Timecode conversion failed: \(message)"
            case .documentOperationFailed(let message):
                return "Document operation failed: \(message)"
            }
        }
        return "Parsing error: \(error.localizedDescription)"
    }
    
    /// Formats a validation error into a descriptive message.
    public func handleValidationError(_ error: Error) -> String {
        return "Validation error: \(error.localizedDescription)"
    }
    
    /// Formats a timecode conversion error into a descriptive message.
    public func handleTimecodeError(_ error: Error) -> String {
        return "Timecode conversion error: \(error.localizedDescription)"
    }
} 
