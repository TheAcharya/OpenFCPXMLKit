//
//  ErrorHandling.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for error handling and formatting.
//

import Foundation

/// Protocol defining error formatting operations.
///
/// All methods are synchronous since they only format error messages
/// (no I/O or blocking work). They are safe to call from any context,
/// including async functions.
@available(macOS 26.0, *)
public protocol ErrorHandling: Sendable {
    /// Formats a parsing error into a descriptive message.
    /// - Parameter error: The error to handle
    /// - Returns: Formatted error message
    func handleParsingError(_ error: Error) -> String
    
    /// Formats a validation error into a descriptive message.
    /// - Parameter error: The error to handle
    /// - Returns: Formatted error message
    func handleValidationError(_ error: Error) -> String
    
    /// Formats a timecode conversion error into a descriptive message.
    /// - Parameter error: The error to handle
    /// - Returns: Formatted error message
    func handleTimecodeError(_ error: Error) -> String
}
