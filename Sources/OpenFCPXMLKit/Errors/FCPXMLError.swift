//
//  FCPXMLError.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Error types for FCPXML parsing, validation, and processing failures.
//

import Foundation

/// Errors that can occur during FCPXML processing
@available(macOS 26.0, *)
public enum FCPXMLError: Error, LocalizedError, Sendable {
    
    /// Parsing failed with underlying error
    case parsingFailed(Error)
    
    /// Invalid FCPXML format
    case invalidFormat
    
    /// Unsupported FCPXML version
    case unsupportedVersion
    
    /// Validation failed
    case validationFailed(String)
    
    /// Timecode conversion failed
    case timecodeConversionFailed(String)
    
    /// Document operation failed
    case documentOperationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .parsingFailed(let error):
            return "FCPXML parsing failed: \(error.localizedDescription)"
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
} 
