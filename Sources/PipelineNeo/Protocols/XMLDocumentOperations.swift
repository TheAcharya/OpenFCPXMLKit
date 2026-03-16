//
//  XMLDocumentOperations.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocols for XML document and element manipulation operations.
//

import Foundation

/// Protocol defining XML document operations
@available(macOS 12.0, *)
public protocol XMLDocumentOperations: Sendable {
    /// Creates a new FCPXML document
    /// - Parameter version: FCPXML version to use
    /// - Returns: New PNXMLDocument
    func createFCPXMLDocument(version: String) -> any PNXMLDocument

    /// Adds a resource to the document
    /// - Parameters:
    ///   - resource: The resource element to add
    ///   - document: The target document
    func addResource(_ resource: any PNXMLElement, to document: any PNXMLDocument)

    /// Adds a sequence to the document
    /// - Parameters:
    ///   - sequence: The sequence element to add
    ///   - document: The target document
    func addSequence(_ sequence: any PNXMLElement, to document: any PNXMLDocument)

    /// Saves document to URL
    /// - Parameters:
    ///   - document: The document to save
    ///   - url: The target URL
    /// - Throws: Error if saving fails
    func saveDocument(_ document: any PNXMLDocument, to url: URL) throws

    // MARK: - Async Methods

    /// Asynchronously creates a new FCPXML document
    /// - Parameter version: FCPXML version to use
    /// - Returns: New PNXMLDocument
    func createFCPXMLDocument(version: String) async -> any PNXMLDocument

    /// Asynchronously adds a resource to the document
    /// - Parameters:
    ///   - resource: The resource element to add
    ///   - document: The target document
    func addResource(_ resource: any PNXMLElement, to document: any PNXMLDocument) async

    /// Asynchronously adds a sequence to the document
    /// - Parameters:
    ///   - sequence: The sequence element to add
    ///   - document: The target document
    func addSequence(_ sequence: any PNXMLElement, to document: any PNXMLDocument) async

    /// Asynchronously saves document to URL
    /// - Parameters:
    ///   - document: The document to save
    ///   - url: The target URL
    /// - Throws: Error if saving fails
    func saveDocument(_ document: any PNXMLDocument, to url: URL) async throws
}

/// Protocol defining XML element operations
@available(macOS 12.0, *)
public protocol XMLElementOperations: Sendable {
    /// Creates a new PNXMLElement with attributes
    /// - Parameters:
    ///   - name: Element name
    ///   - attributes: Dictionary of attributes
    /// - Returns: New PNXMLElement
    func createElement(name: String, attributes: [String: String]) -> any PNXMLElement

    /// Adds child element to parent
    /// - Parameters:
    ///   - child: Child element to add
    ///   - parent: Parent element
    func addChild(_ child: any PNXMLElement, to parent: any PNXMLElement)

    /// Sets attribute on element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    ///   - element: Target element
    func setAttribute(name: String, value: String, on element: any PNXMLElement)

    /// Gets attribute value from element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - element: Source element
    /// - Returns: Attribute value or nil
    func getAttribute(name: String, from element: any PNXMLElement) -> String?

    // MARK: - Async Methods

    /// Asynchronously creates a new PNXMLElement with attributes
    /// - Parameters:
    ///   - name: Element name
    ///   - attributes: Dictionary of attributes
    /// - Returns: New PNXMLElement
    func createElement(name: String, attributes: [String: String]) async -> any PNXMLElement

    /// Asynchronously adds child element to parent
    /// - Parameters:
    ///   - child: Child element to add
    ///   - parent: Parent element
    func addChild(_ child: any PNXMLElement, to parent: any PNXMLElement) async

    /// Asynchronously sets attribute on element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    ///   - element: Target element
    func setAttribute(name: String, value: String, on element: any PNXMLElement) async

    /// Asynchronously gets attribute value from element
    /// - Parameters:
    ///   - name: Attribute name
    ///   - element: Source element
    /// - Returns: Attribute value or nil
    func getAttribute(name: String, from element: any PNXMLElement) async -> String?
}
