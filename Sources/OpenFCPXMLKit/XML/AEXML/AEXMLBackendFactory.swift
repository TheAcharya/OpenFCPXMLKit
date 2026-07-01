//
//  AEXMLBackendFactory.swift
//  OpenFCPXMLKit
//
//  Cross-platform XML factory powered by AEXML.
//  Creates AEXMLBackendDocument and AEXMLBackendElement instances
//  through the OFKXMLFactory protocol.
//
//  Use this factory on iOS and other platforms where Foundation's
//  XMLDocument/XMLElement are not available.
//

import Foundation
import AEXML

// MARK: - AEXMLBackendFactory

/// A factory that creates AEXML-backed XML documents and elements.
///
/// Conforms to `OFKXMLFactory` and produces `AEXMLBackendDocument` and
/// `AEXMLBackendElement` instances. Use this factory on iOS, tvOS, watchOS,
/// visionOS, and other platforms where Foundation XML (`XMLDocument`,
/// `XMLElement`) is not available.
///
/// DTD creation methods are conditionally compiled and always throw on
/// platforms that include them, since AEXML does not support DTD.
public struct AEXMLBackendFactory: OFKXMLFactory {

    // MARK: - Initialization

    /// Creates a new AEXML backend factory.
    public init() {}

    // MARK: - Document Creation

    /// Creates a new, empty XML document.
    public func makeDocument() -> any OFKXMLDocument {
        AEXMLBackendDocument()
    }

    /// Creates an XML document by parsing raw data with options.
    ///
    /// - Parameters:
    ///   - data: The raw XML data to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `AEXMLBackendDocument`.
    /// - Throws: `OFKXMLError.parsingFailure` if parsing fails.
    public func makeDocument(data: Data, options: OFKXMLDocumentOptions) throws -> any OFKXMLDocument {
        try AEXMLBackendDocument(data: data, options: options)
    }

    /// Creates an XML document by loading and parsing a URL with options.
    ///
    /// - Parameters:
    ///   - url: The URL to load XML data from.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `AEXMLBackendDocument`.
    /// - Throws: `OFKXMLError.parsingFailure` if parsing fails.
    public func makeDocument(contentsOf url: URL, options: OFKXMLDocumentOptions) throws -> any OFKXMLDocument {
        try AEXMLBackendDocument(contentsOf: url, options: options)
    }

    /// Creates an XML document by parsing an XML string with options.
    ///
    /// - Parameters:
    ///   - xmlString: The XML string to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `AEXMLBackendDocument`.
    /// - Throws: `OFKXMLError.parsingFailure` if parsing fails.
    public func makeDocument(xmlString: String, options: OFKXMLDocumentOptions) throws -> any OFKXMLDocument {
        try AEXMLBackendDocument(xmlString: xmlString, options: options)
    }

    // MARK: - Element Creation

    /// Creates a new XML element with the given tag name.
    ///
    /// - Parameter name: The tag name for the element.
    /// - Returns: A new `AEXMLBackendElement`.
    public func makeElement(name: String) -> any OFKXMLElement {
        AEXMLBackendElement(name: name)
    }

    /// Creates a new XML element by parsing an XML string fragment.
    ///
    /// - Parameter xmlString: An XML string representing a single element.
    /// - Returns: A new `AEXMLBackendElement`.
    /// - Throws: `OFKXMLError.parsingFailure` if the string cannot be parsed.
    public func makeElement(xmlString: String) throws -> any OFKXMLElement {
        try AEXMLBackendElement(xmlString: xmlString)
    }

    // MARK: - DTD Creation (platform-conditional)

    #if canImport(FoundationXML) || os(macOS)
    /// Creates a new, empty DTD.
    ///
    /// AEXML does not support DTD. On platforms where this method is available
    /// (macOS, Linux), callers should use `FoundationXMLFactory` instead for
    /// DTD operations. This implementation is provided for protocol conformance
    /// and will cause a runtime error if used.
    public func makeDTD() -> any OFKXMLDTDProtocol {
        fatalError(
            "AEXMLBackendFactory does not support DTD creation. "
            + "Use FoundationXMLFactory on platforms that require DTD support."
        )
    }

    /// Creates a DTD from the contents of a URL.
    ///
    /// AEXML does not support DTD. Always throws `OFKXMLError.dtdValidationUnavailable`.
    ///
    /// - Parameters:
    ///   - url: The URL pointing to the DTD file.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `OFKXMLError.dtdValidationUnavailable`.
    public func makeDTD(contentsOf url: URL, options: OFKXMLDocumentOptions) throws -> any OFKXMLDTDProtocol {
        throw OFKXMLError.dtdValidationUnavailable
    }
    #endif
}
