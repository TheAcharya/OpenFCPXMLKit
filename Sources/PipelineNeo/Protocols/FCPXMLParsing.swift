//
//  FCPXMLParsing.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocols for FCPXML parsing and element filtering operations.
//

import Foundation

/// Protocol defining FCPXML parsing operations
@available(macOS 12.0, *)
public protocol FCPXMLParsing: Sendable {
    /// Parses FCPXML data into a PNXMLDocument
    /// - Parameter data: The FCPXML data to parse
    /// - Returns: A PNXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(_ data: Data) throws -> any PNXMLDocument

    /// Parses FCPXML from a URL
    /// - Parameter url: The URL containing FCPXML data
    /// - Returns: A PNXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(from url: URL) throws -> any PNXMLDocument

    /// Checks whether the document has a valid fcpxml root element.
    ///
    /// This is a lightweight structural check, not full DTD validation.
    /// For semantic validation use `FCPXMLValidator`; for DTD validation use `FCPXMLDTDValidator`.
    ///
    /// - Parameter document: The PNXMLDocument to check
    /// - Returns: True if the root element is `fcpxml`, false otherwise
    func validate(_ document: any PNXMLDocument) -> Bool

    // MARK: - Async Methods

    /// Asynchronously parses FCPXML data into a PNXMLDocument
    /// - Parameter data: The FCPXML data to parse
    /// - Returns: A PNXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(_ data: Data) async throws -> any PNXMLDocument

    /// Asynchronously parses FCPXML from a URL
    /// - Parameter url: The URL containing FCPXML data
    /// - Returns: A PNXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(from url: URL) async throws -> any PNXMLDocument

    /// Asynchronously checks whether the document has a valid fcpxml root element.
    /// - Parameter document: The PNXMLDocument to check
    /// - Returns: True if the root element is `fcpxml`, false otherwise
    func validate(_ document: any PNXMLDocument) async -> Bool
}

/// Protocol defining FCPXML element filtering operations
@available(macOS 12.0, *)
public protocol FCPXMLElementFiltering: Sendable {
    /// Filters elements by type
    /// - Parameters:
    ///   - elements: Array of PNXMLElements to filter
    ///   - types: Array of FCPXMLElementType to match
    /// - Returns: Filtered array of PNXMLElements
    func filter(elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) -> [any PNXMLElement]

    /// Finds elements by resource ID
    /// - Parameters:
    ///   - elements: Array of PNXMLElements to search
    ///   - resourceID: The resource ID to match
    /// - Returns: Array of matching PNXMLElements
    func findElements(withResourceID resourceID: String, in elements: [any PNXMLElement]) -> [any PNXMLElement]

    // MARK: - Async Methods

    /// Asynchronously filters elements by type
    /// - Parameters:
    ///   - elements: Array of PNXMLElements to filter
    ///   - types: Array of FCPXMLElementType to match
    /// - Returns: Filtered array of PNXMLElements
    func filter(elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) async -> [any PNXMLElement]

    /// Asynchronously finds elements by resource ID
    /// - Parameters:
    ///   - elements: Array of PNXMLElements to search
    ///   - resourceID: The resource ID to match
    /// - Returns: Array of matching PNXMLElements
    func findElements(withResourceID resourceID: String, in elements: [any PNXMLElement]) async -> [any PNXMLElement]
} 
