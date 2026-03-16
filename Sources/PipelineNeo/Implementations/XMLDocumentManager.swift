//
//  XMLDocumentManager.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
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
@available(macOS 12.0, *)
public final class XMLDocumentManager: XMLDocumentOperations, XMLElementOperations, Sendable {

    private nonisolated(unsafe) let factory: any PNXMLFactory

    /// Creates a new XML document manager.
    /// - Parameter factory: XML factory for creating documents and elements (default: `PNXMLDefaultFactory()`).
    public init(factory: any PNXMLFactory = PNXMLDefaultFactory()) {
        self.factory = factory
    }

    // MARK: - Internal Sync Implementations

    private func _createFCPXMLDocument(version: String) -> any PNXMLDocument {
        let rootElement = factory.makeElement(name: "fcpxml")
        rootElement.addAttribute(name: "version", value: version)
        let document = factory.makeDocument()
        document.setRootElement(rootElement)
        return document
    }

    private func _addResource(_ resource: any PNXMLElement, to document: any PNXMLDocument) {
        guard let rootElement = document.rootElement() else { return }
        let resourcesElement: any PNXMLElement
        if let existing = rootElement.firstChildElement(named: "resources") {
            resourcesElement = existing
        } else {
            let newResources = factory.makeElement(name: "resources")
            rootElement.addChild(newResources)
            resourcesElement = newResources
        }
        resourcesElement.addChild(resource)
    }

    private func _addSequence(_ sequence: any PNXMLElement, to document: any PNXMLDocument) {
        guard let rootElement = document.rootElement() else { return }
        rootElement.addChild(sequence)
    }

    private func _saveDocument(_ document: any PNXMLDocument, to url: URL) throws {
        let data = document.xmlData
        do {
            try data.write(to: url)
        } catch {
            throw FCPXMLError.documentOperationFailed("Failed to save document to \(url.path): \(error.localizedDescription)")
        }
    }

    private func _createElement(name: String, attributes: [String: String]) -> any PNXMLElement {
        let element = factory.makeElement(name: name)
        for (key, value) in attributes {
            element.addAttribute(name: key, value: value)
        }
        return element
    }

    private func _setAttribute(name: String, value: String, on element: any PNXMLElement) {
        element.removeAttribute(forName: name)
        element.addAttribute(name: name, value: value)
    }

    // MARK: - XMLDocumentOperations (Sync)

    /// Creates a new FCPXML document with the given version attribute.
    public func createFCPXMLDocument(version: String) -> any PNXMLDocument {
        _createFCPXMLDocument(version: version)
    }

    /// Adds a resource element to the document's resources container.
    public func addResource(_ resource: any PNXMLElement, to document: any PNXMLDocument) {
        _addResource(resource, to: document)
    }

    /// Adds a sequence element to the document root.
    public func addSequence(_ sequence: any PNXMLElement, to document: any PNXMLDocument) {
        _addSequence(sequence, to: document)
    }

    /// Saves the document XML data to a file URL.
    public func saveDocument(_ document: any PNXMLDocument, to url: URL) throws {
        try _saveDocument(document, to: url)
    }

    // MARK: - XMLDocumentOperations (Async)

    /// Creates a new FCPXML document asynchronously.
    public func createFCPXMLDocument(version: String) async -> any PNXMLDocument {
        _createFCPXMLDocument(version: version)
    }

    /// Adds a resource element asynchronously.
    public func addResource(_ resource: any PNXMLElement, to document: any PNXMLDocument) async {
        _addResource(resource, to: document)
    }

    /// Adds a sequence element asynchronously.
    public func addSequence(_ sequence: any PNXMLElement, to document: any PNXMLDocument) async {
        _addSequence(sequence, to: document)
    }

    /// Saves the document asynchronously.
    public func saveDocument(_ document: any PNXMLDocument, to url: URL) async throws {
        try _saveDocument(document, to: url)
    }

    // MARK: - XMLElementOperations (Sync)

    /// Creates a new XML element with the given name and attributes.
    public func createElement(name: String, attributes: [String: String]) -> any PNXMLElement {
        _createElement(name: name, attributes: attributes)
    }

    /// Appends a child element to a parent element.
    public func addChild(_ child: any PNXMLElement, to parent: any PNXMLElement) {
        parent.addChild(child)
    }

    /// Sets an attribute on an element, replacing any existing value.
    public func setAttribute(name: String, value: String, on element: any PNXMLElement) {
        _setAttribute(name: name, value: value, on: element)
    }

    /// Returns the string value of a named attribute on an element.
    public func getAttribute(name: String, from element: any PNXMLElement) -> String? {
        element.stringValue(forAttributeNamed: name)
    }

    // MARK: - XMLElementOperations (Async)

    /// Creates a new XML element asynchronously.
    public func createElement(name: String, attributes: [String: String]) async -> any PNXMLElement {
        _createElement(name: name, attributes: attributes)
    }

    /// Appends a child element asynchronously.
    public func addChild(_ child: any PNXMLElement, to parent: any PNXMLElement) async {
        parent.addChild(child)
    }

    /// Sets an attribute on an element asynchronously.
    public func setAttribute(name: String, value: String, on element: any PNXMLElement) async {
        _setAttribute(name: name, value: value, on: element)
    }

    /// Returns the string value of a named attribute asynchronously.
    public func getAttribute(name: String, from element: any PNXMLElement) async -> String? {
        element.stringValue(forAttributeNamed: name)
    }
}
