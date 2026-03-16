//
//  PNXMLError.swift
//  Pipeline Neo
//
//  Common XML errors for the platform-agnostic XML abstraction layer.
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

import Foundation

// MARK: - PNXMLError

/// Errors that can occur during XML operations in the PipelineNeo XML abstraction layer.
///
/// This enum is `Sendable` and `Equatable` so it can be safely shared across
/// concurrency domains and used in test assertions.
public enum PNXMLError: Error, Sendable, Equatable {

    /// XML data could not be parsed.
    ///
    /// - Parameter message: A human-readable description of what went wrong.
    case parsingFailure(message: String)

    /// DTD validation is not available on this platform.
    ///
    /// Thrown by the AEXML (cross-platform) backend when DTD validation is
    /// requested, since AEXML does not support DTD validation.
    case dtdValidationUnavailable

    /// A required XML element was not found.
    ///
    /// - Parameter elementName: The name of the element that was expected but missing.
    case elementNotFound(elementName: String)

    /// XML serialization failed.
    ///
    /// - Parameter message: A human-readable description of the serialization failure.
    case serializationFailure(message: String)

    /// An attribute was expected but not found on an element.
    ///
    /// - Parameters:
    ///   - attributeName: The name of the missing attribute.
    ///   - elementName: The name of the element that was expected to contain the attribute.
    case attributeNotFound(attributeName: String, elementName: String)

    /// A child index was out of bounds.
    ///
    /// - Parameters:
    ///   - index: The requested index.
    ///   - childCount: The actual number of children.
    case indexOutOfBounds(index: Int, childCount: Int)
}

// MARK: - LocalizedError

extension PNXMLError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parsingFailure(let message):
            return "XML parsing failure: \(message)"
        case .dtdValidationUnavailable:
            return "DTD validation is not available on this platform."
        case .elementNotFound(let elementName):
            return "XML element not found: '\(elementName)'."
        case .serializationFailure(let message):
            return "XML serialization failure: \(message)"
        case .attributeNotFound(let attributeName, let elementName):
            return "Attribute '\(attributeName)' not found on element '\(elementName)'."
        case .indexOutOfBounds(let index, let childCount):
            return "Child index \(index) out of bounds (child count: \(childCount))."
        }
    }
}
