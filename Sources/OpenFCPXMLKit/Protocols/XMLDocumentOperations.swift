//
//  XMLDocumentOperations.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocols for XML document and element manipulation operations.
//

import Foundation

/// Protocol defining XML document operations
@available(macOS 26.0, *)
public protocol XMLDocumentOperations: Sendable {
    /// Creates a new FCPXML document
    /// - Parameter version: FCPXML version to use
    /// - Returns: New OFKXMLDocument
    func createFCPXMLDocument(version: String) -> any OFKXMLDocument

    /// Adds a resource to the document
    /// - Parameters:
    ///   - resource: The resource element to add
    ///   - document: The target document
    func addResource(_ resource: any OFKXMLElement, to document: any OFKXMLDocument)

    /// Adds a sequence to the document
    /// - Parameters:
    ///   - sequence: The sequence element to add
    ///   - document: The target document
    func addSequence(_ sequence: any OFKXMLElement, to document: any OFKXMLDocument)

    /// Saves document to URL
    /// - Parameters:
    ///   - document: The document to save
    ///   - url: The target URL
    /// - Throws: Error if saving fails
    func saveDocument(_ document: any OFKXMLDocument, to url: URL) throws

    // MARK: - Async Methods

    /// Asynchronously creates a new FCPXML document
    /// - Parameter version: FCPXML version to use
    /// - Returns: New OFKXMLDocument
    func createFCPXMLDocument(version: String) async -> any OFKXMLDocument

    /// Asynchronously adds a resource to the document
    /// - Parameters:
    ///   - resource: The resource element to add
    ///   - document: The target document
    func addResource(_ resource: any OFKXMLElement, to document: any OFKXMLDocument) async

    /// Asynchronously adds a sequence to the document
    /// - Parameters:
    ///   - sequence: The sequence element to add
    ///   - document: The target document
    func addSequence(_ sequence: any OFKXMLElement, to document: any OFKXMLDocument) async

    /// Asynchronously saves document to URL
    /// - Parameters:
    ///   - document: The document to save
    ///   - url: The target URL
    /// - Throws: Error if saving fails
    func saveDocument(_ document: any OFKXMLDocument, to url: URL) async throws
}

/// Protocol defining XML element operations
@available(macOS 26.0, *)
public protocol XMLElementOperations: Sendable {
    /// Creates a new OFKXMLElement with attributes
    /// - Parameters:
    ///   - name: Element name
    ///   - attributes: Dictionary of attributes
    /// - Returns: New OFKXMLElement
    func createElement(name: String, attributes: [String: String]) -> any OFKXMLElement

    /// Adds child element to parent
    /// - Parameters:
    ///   - child: Child element to add
    ///   - parent: Parent element
    func addChild(_ child: any OFKXMLElement, to parent: any OFKXMLElement)

    /// Sets attribute on element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    ///   - element: Target element
    func setAttribute(name: String, value: String, on element: any OFKXMLElement)

    /// Gets attribute value from element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - element: Source element
    /// - Returns: Attribute value or nil
    func getAttribute(name: String, from element: any OFKXMLElement) -> String?

    // MARK: - Async Methods

    /// Asynchronously creates a new OFKXMLElement with attributes
    /// - Parameters:
    ///   - name: Element name
    ///   - attributes: Dictionary of attributes
    /// - Returns: New OFKXMLElement
    func createElement(name: String, attributes: [String: String]) async -> any OFKXMLElement

    /// Asynchronously adds child element to parent
    /// - Parameters:
    ///   - child: Child element to add
    ///   - parent: Parent element
    func addChild(_ child: any OFKXMLElement, to parent: any OFKXMLElement) async

    /// Asynchronously sets attribute on element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    ///   - element: Target element
    func setAttribute(name: String, value: String, on element: any OFKXMLElement) async

    /// Asynchronously gets attribute value from element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - element: Source element
    /// - Returns: Attribute value or nil
    func getAttribute(name: String, from element: any OFKXMLElement) async -> String?
}
