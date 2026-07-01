//
//  FCPXMLParsing.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocols for FCPXML parsing and element filtering operations.
//

import Foundation

/// Protocol defining FCPXML parsing operations
@available(macOS 26.0, *)
public protocol FCPXMLParsing: Sendable {
    /// Parses FCPXML data into a OFKXMLDocument
    /// - Parameter data: The FCPXML data to parse
    /// - Returns: A OFKXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(_ data: Data) throws -> any OFKXMLDocument

    /// Parses FCPXML from a URL
    /// - Parameter url: The URL containing FCPXML data
    /// - Returns: A OFKXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(from url: URL) throws -> any OFKXMLDocument

    /// Checks whether the document has a valid fcpxml root element.
    ///
    /// This is a lightweight structural check, not full DTD validation.
    /// For semantic validation use `FCPXMLValidator`; for DTD validation use `FCPXMLDTDValidator`.
    ///
    /// - Parameter document: The OFKXMLDocument to check
    /// - Returns: True if the root element is `fcpxml`, false otherwise
    func validate(_ document: any OFKXMLDocument) -> Bool

    // MARK: - Async Methods

    /// Asynchronously parses FCPXML data into a OFKXMLDocument
    /// - Parameter data: The FCPXML data to parse
    /// - Returns: A OFKXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(_ data: Data) async throws -> any OFKXMLDocument

    /// Asynchronously parses FCPXML from a URL
    /// - Parameter url: The URL containing FCPXML data
    /// - Returns: A OFKXMLDocument representation
    /// - Throws: FCPXMLError if parsing fails
    func parse(from url: URL) async throws -> any OFKXMLDocument

    /// Asynchronously checks whether the document has a valid fcpxml root element.
    /// - Parameter document: The OFKXMLDocument to check
    /// - Returns: True if the root element is `fcpxml`, false otherwise
    func validate(_ document: any OFKXMLDocument) async -> Bool
}

/// Protocol defining FCPXML element filtering operations
@available(macOS 26.0, *)
public protocol FCPXMLElementFiltering: Sendable {
    /// Filters elements by type
    /// - Parameters:
    ///   - elements: Array of OFKXMLElements to filter
    ///   - types: Array of FCPXMLElementType to match
    /// - Returns: Filtered array of OFKXMLElements
    func filter(elements: [any OFKXMLElement], ofTypes types: [FCPXMLElementType]) -> [any OFKXMLElement]

    /// Finds elements by resource ID
    /// - Parameters:
    ///   - elements: Array of OFKXMLElements to search
    ///   - resourceID: The resource ID to match
    /// - Returns: Array of matching OFKXMLElements
    func findElements(withResourceID resourceID: String, in elements: [any OFKXMLElement]) -> [any OFKXMLElement]

    // MARK: - Async Methods

    /// Asynchronously filters elements by type
    /// - Parameters:
    ///   - elements: Array of OFKXMLElements to filter
    ///   - types: Array of FCPXMLElementType to match
    /// - Returns: Filtered array of OFKXMLElements
    func filter(elements: [any OFKXMLElement], ofTypes types: [FCPXMLElementType]) async -> [any OFKXMLElement]

    /// Asynchronously finds elements by resource ID
    /// - Parameters:
    ///   - elements: Array of OFKXMLElements to search
    ///   - resourceID: The resource ID to match
    /// - Returns: Array of matching OFKXMLElements
    func findElements(withResourceID resourceID: String, in elements: [any OFKXMLElement]) async -> [any OFKXMLElement]
} 
