//
//  PNXMLFactory.swift
//  Pipeline Neo
//
//  Abstract factory protocol for creating XML documents and elements.
//  Backends (Foundation, AEXML) implement this to produce their concrete types
//  without callers needing to know the underlying XML library.
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

import Foundation

// MARK: - PNXMLFactory

/// Abstract factory for creating platform-agnostic XML documents and elements.
///
/// Each backend (Foundation on macOS/Linux, AEXML on iOS/cross-platform)
/// provides its own conforming type. Callers use the factory to create
/// documents and elements without knowing the concrete type.
///
/// This protocol is intentionally **not** `Sendable`. Operations protocols
/// that wrap factory instances may add `Sendable` conformance where appropriate.
public protocol PNXMLFactory {

    // MARK: - Document Creation

    /// Creates a new, empty XML document.
    ///
    /// - Returns: An empty `PNXMLDocument`.
    func makeDocument() -> any PNXMLDocument

    /// Creates an XML document by parsing raw data.
    ///
    /// - Parameter data: The raw XML data to parse.
    /// - Returns: A parsed `PNXMLDocument`.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    func makeDocument(data: Data) throws -> any PNXMLDocument

    /// Creates an XML document by parsing raw data with options.
    ///
    /// - Parameters:
    ///   - data: The raw XML data to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `PNXMLDocument`.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    func makeDocument(data: Data, options: PNXMLDocumentOptions) throws -> any PNXMLDocument

    /// Creates an XML document by loading and parsing a URL.
    ///
    /// - Parameter url: The URL to load XML data from.
    /// - Returns: A parsed `PNXMLDocument`.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    func makeDocument(contentsOf url: URL) throws -> any PNXMLDocument

    /// Creates an XML document by loading and parsing a URL with options.
    ///
    /// - Parameters:
    ///   - url: The URL to load XML data from.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `PNXMLDocument`.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    func makeDocument(contentsOf url: URL, options: PNXMLDocumentOptions) throws -> any PNXMLDocument

    /// Creates an XML document by parsing an XML string.
    ///
    /// - Parameter xmlString: The XML string to parse.
    /// - Returns: A parsed `PNXMLDocument`.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    func makeDocument(xmlString: String) throws -> any PNXMLDocument

    /// Creates an XML document by parsing an XML string with options.
    ///
    /// - Parameters:
    ///   - xmlString: The XML string to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `PNXMLDocument`.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    func makeDocument(xmlString: String, options: PNXMLDocumentOptions) throws -> any PNXMLDocument

    // MARK: - Element Creation

    /// Creates a new XML element with the given tag name.
    ///
    /// - Parameter name: The tag name for the element.
    /// - Returns: A new `PNXMLElement`.
    func makeElement(name: String) -> any PNXMLElement

    /// Creates a new XML element with the given tag name and string value.
    ///
    /// - Parameters:
    ///   - name: The tag name for the element.
    ///   - stringValue: The text content for the element.
    /// - Returns: A new `PNXMLElement`.
    func makeElement(name: String, stringValue: String) -> any PNXMLElement

    /// Creates a new XML element with the given tag name and attributes.
    ///
    /// - Parameters:
    ///   - name: The tag name for the element.
    ///   - attributes: A dictionary of attribute name-value pairs to set.
    /// - Returns: A new `PNXMLElement` with the specified attributes.
    func makeElement(name: String, attributes: [String: String]) -> any PNXMLElement

    /// Creates a new XML element by parsing an XML string fragment.
    ///
    /// - Parameter xmlString: An XML string representing a single element.
    /// - Returns: A new `PNXMLElement`.
    /// - Throws: `PNXMLError.parsingFailure` if the string cannot be parsed as an element.
    func makeElement(xmlString: String) throws -> any PNXMLElement

    // MARK: - DTD Creation (platform-conditional)

    #if canImport(FoundationXML) || os(macOS)
    /// Creates a new, empty DTD.
    ///
    /// - Returns: A new `PNXMLDTDProtocol`.
    func makeDTD() -> any PNXMLDTDProtocol

    /// Creates a DTD from the contents of a URL.
    ///
    /// - Parameters:
    ///   - url: The URL pointing to the DTD file.
    ///   - options: Options controlling parsing behavior.
    /// - Returns: A parsed `PNXMLDTDProtocol`.
    /// - Throws: `PNXMLError.parsingFailure` if the DTD cannot be parsed.
    func makeDTD(contentsOf url: URL, options: PNXMLDocumentOptions) throws -> any PNXMLDTDProtocol
    #endif
}

// MARK: - Default Implementations

extension PNXMLFactory {

    /// Default: creates a document from data with empty options.
    public func makeDocument(data: Data) throws -> any PNXMLDocument {
        try makeDocument(data: data, options: [])
    }

    /// Default: creates a document from URL with empty options.
    public func makeDocument(contentsOf url: URL) throws -> any PNXMLDocument {
        try makeDocument(contentsOf: url, options: [])
    }

    /// Default: creates a document from XML string with empty options.
    public func makeDocument(xmlString: String) throws -> any PNXMLDocument {
        try makeDocument(xmlString: xmlString, options: [])
    }

    /// Default: creates an element with the given name and sets attributes.
    public func makeElement(name: String, attributes: [String: String]) -> any PNXMLElement {
        let element = makeElement(name: name)
        for (key, value) in attributes {
            element.addAttribute(name: key, value: value)
        }
        return element
    }

    /// Default: creates an element with the given name and sets its stringValue.
    public func makeElement(name: String, stringValue: String) -> any PNXMLElement {
        let element = makeElement(name: name)
        element.stringValue = stringValue
        return element
    }
}
