//
//  XMLDocumentManager.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Implementation of XML document creation, resource management, and save operations.
//

import Foundation

/// Default implementation of `XMLDocumentOperations` and `XMLElementOperations`.
///
/// Creates FCPXML documents, manages resources and sequences, and provides
/// element creation and attribute manipulation.
@available(macOS 26.0, *)
public final class XMLDocumentManager: XMLDocumentOperations, XMLElementOperations, Sendable {

    private nonisolated(unsafe) let factory: any OFKXMLFactory

    /// Creates a new XML document manager.
    /// - Parameter factory: XML factory for creating documents and elements (default: `OFKXMLDefaultFactory()`).
    public init(factory: any OFKXMLFactory = OFKXMLDefaultFactory()) {
        self.factory = factory
    }

    // MARK: - Internal Sync Implementations

    private func _createFCPXMLDocument(version: String) -> any OFKXMLDocument {
        let rootElement = factory.makeElement(name: "fcpxml")
        rootElement.addAttribute(name: "version", value: version)
        let document = factory.makeDocument()
        document.setRootElement(rootElement)
        return document
    }

    private func _addResource(_ resource: any OFKXMLElement, to document: any OFKXMLDocument) {
        guard let rootElement = document.rootElement() else { return }
        let resourcesElement: any OFKXMLElement
        if let existing = rootElement.firstChildElement(named: "resources") {
            resourcesElement = existing
        } else {
            let newResources = factory.makeElement(name: "resources")
            rootElement.addChild(newResources)
            resourcesElement = newResources
        }
        resourcesElement.addChild(resource)
    }

    private func _addSequence(_ sequence: any OFKXMLElement, to document: any OFKXMLDocument) {
        guard let rootElement = document.rootElement() else { return }
        rootElement.addChild(sequence)
    }

    private func _saveDocument(_ document: any OFKXMLDocument, to url: URL) throws {
        let data = document.xmlData
        do {
            try data.write(to: url)
        } catch {
            throw FCPXMLError.documentOperationFailed("Failed to save document to \(url.path): \(error.localizedDescription)")
        }
    }

    private func _createElement(name: String, attributes: [String: String]) -> any OFKXMLElement {
        let element = factory.makeElement(name: name)
        for (key, value) in attributes {
            element.addAttribute(name: key, value: value)
        }
        return element
    }

    private func _setAttribute(name: String, value: String, on element: any OFKXMLElement) {
        element.removeAttribute(forName: name)
        element.addAttribute(name: name, value: value)
    }

    // MARK: - XMLDocumentOperations (Sync)

    /// Creates a new FCPXML document with the given version attribute.
    public func createFCPXMLDocument(version: String) -> any OFKXMLDocument {
        _createFCPXMLDocument(version: version)
    }

    /// Adds a resource element to the document's resources container.
    public func addResource(_ resource: any OFKXMLElement, to document: any OFKXMLDocument) {
        _addResource(resource, to: document)
    }

    /// Adds a sequence element to the document root.
    public func addSequence(_ sequence: any OFKXMLElement, to document: any OFKXMLDocument) {
        _addSequence(sequence, to: document)
    }

    /// Saves the document XML data to a file URL.
    public func saveDocument(_ document: any OFKXMLDocument, to url: URL) throws {
        try _saveDocument(document, to: url)
    }

    // MARK: - XMLDocumentOperations (Async)

    /// Creates a new FCPXML document asynchronously.
    public func createFCPXMLDocument(version: String) async -> any OFKXMLDocument {
        _createFCPXMLDocument(version: version)
    }

    /// Adds a resource element asynchronously.
    public func addResource(_ resource: any OFKXMLElement, to document: any OFKXMLDocument) async {
        _addResource(resource, to: document)
    }

    /// Adds a sequence element asynchronously.
    public func addSequence(_ sequence: any OFKXMLElement, to document: any OFKXMLDocument) async {
        _addSequence(sequence, to: document)
    }

    /// Saves the document asynchronously.
    public func saveDocument(_ document: any OFKXMLDocument, to url: URL) async throws {
        try _saveDocument(document, to: url)
    }

    // MARK: - XMLElementOperations (Sync)

    /// Creates a new XML element with the given name and attributes.
    public func createElement(name: String, attributes: [String: String]) -> any OFKXMLElement {
        _createElement(name: name, attributes: attributes)
    }

    /// Appends a child element to a parent element.
    public func addChild(_ child: any OFKXMLElement, to parent: any OFKXMLElement) {
        parent.addChild(child)
    }

    /// Sets an attribute on an element, replacing any existing value.
    public func setAttribute(name: String, value: String, on element: any OFKXMLElement) {
        _setAttribute(name: name, value: value, on: element)
    }

    /// Returns the string value of a named attribute on an element.
    public func getAttribute(name: String, from element: any OFKXMLElement) -> String? {
        element.stringValue(forAttributeNamed: name)
    }

    // MARK: - XMLElementOperations (Async)

    /// Creates a new XML element asynchronously.
    public func createElement(name: String, attributes: [String: String]) async -> any OFKXMLElement {
        _createElement(name: name, attributes: attributes)
    }

    /// Appends a child element asynchronously.
    public func addChild(_ child: any OFKXMLElement, to parent: any OFKXMLElement) async {
        parent.addChild(child)
    }

    /// Sets an attribute on an element asynchronously.
    public func setAttribute(name: String, value: String, on element: any OFKXMLElement) async {
        _setAttribute(name: name, value: value, on: element)
    }

    /// Returns the string value of a named attribute asynchronously.
    public func getAttribute(name: String, from element: any OFKXMLElement) async -> String? {
        element.stringValue(forAttributeNamed: name)
    }
}
