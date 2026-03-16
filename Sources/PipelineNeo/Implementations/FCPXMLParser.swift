//
//  FCPXMLParser.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Implementation of FCPXML parsing and element filtering operations.
//

import Foundation

/// Default implementation of `FCPXMLParsing` and `FCPXMLElementFiltering`.
///
/// Delegates URL loading to `FCPXMLFileLoader` for unified file/bundle handling
/// and consistent FCPXML parse options.
@available(macOS 12.0, *)
public final class FCPXMLParser: FCPXMLParsing, FCPXMLElementFiltering, Sendable {

    private nonisolated(unsafe) let factory: any PNXMLFactory

    /// Creates a new FCPXML parser.
    /// - Parameter factory: XML factory for creating documents (default: `PNXMLDefaultFactory()`).
    public init(factory: any PNXMLFactory = PNXMLDefaultFactory()) {
        self.factory = factory
    }

    // MARK: - Internal Sync Implementations

    private func _parse(_ data: Data) throws -> any PNXMLDocument {
        do {
            let document = try factory.makeDocument(data: data)
            return document
        } catch {
            throw FCPXMLError.parsingFailed(error)
        }
    }

    private func _parse(from url: URL) throws -> any PNXMLDocument {
        // Delegate to FCPXMLFileLoader for unified file/bundle loading with FCPXML-specific
        // parse options. This avoids duplicating the URL resolution and parse-option logic.
        let loader = FCPXMLFileLoader(factory: factory)
        do {
            return try loader.loadFCPXMLDocument(from: url)
        } catch let error as FCPXMLError {
            throw error
        } catch let error as FCPXMLLoadError {
            throw FCPXMLError.parsingFailed(error)
        } catch {
            throw FCPXMLError.parsingFailed(error)
        }
    }

    private func _validate(_ document: any PNXMLDocument) -> Bool {
        guard let rootElement = document.rootElement() else { return false }
        return rootElement.name == "fcpxml"
    }

    // MARK: - FCPXMLParsing (Sync)

    /// Parses FCPXML from raw data.
    public func parse(_ data: Data) throws -> any PNXMLDocument {
        try _parse(data)
    }

    /// Parses FCPXML from a file URL (supports .fcpxml and .fcpxmld bundles).
    public func parse(from url: URL) throws -> any PNXMLDocument {
        try _parse(from: url)
    }

    /// Validates that the document has an fcpxml root element.
    public func validate(_ document: any PNXMLDocument) -> Bool {
        _validate(document)
    }

    // MARK: - FCPXMLParsing (Async)

    /// Parses FCPXML from raw data asynchronously.
    public func parse(_ data: Data) async throws -> any PNXMLDocument {
        try _parse(data)
    }

    /// Parses FCPXML from a file URL asynchronously.
    public func parse(from url: URL) async throws -> any PNXMLDocument {
        try _parse(from: url)
    }

    /// Validates that the document has an fcpxml root element asynchronously.
    public func validate(_ document: any PNXMLDocument) async -> Bool {
        _validate(document)
    }

    // MARK: - FCPXMLElementFiltering (Sync)

    /// Returns the name of the first child element (used for media to multicam/compound inference).
    private static func firstChildElementName(of element: any PNXMLElement) -> String? {
        element.childElements.first.flatMap(\.name)
    }

    private static func filterElements(_ elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) -> [any PNXMLElement] {
        return elements.filter { element in
            guard let elementName = element.name else { return false }
            return types.contains { type in
                if type == .multicamResource {
                    guard elementName == "media" else { return false }
                    return Self.firstChildElementName(of: element) == "multicam"
                }
                if type == .compoundResource {
                    guard elementName == "media" else { return false }
                    return Self.firstChildElementName(of: element) == "sequence"
                }
                if type == .none { return false }
                return elementName == type.rawValue
            }
        }
    }

    /// Filters elements by their FCPXML element types.
    public func filter(elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) -> [any PNXMLElement] {
        Self.filterElements(elements, ofTypes: types)
    }

    /// Finds elements matching the given resource ID attribute.
    public func findElements(withResourceID resourceID: String, in elements: [any PNXMLElement]) -> [any PNXMLElement] {
        elements.filter { $0.stringValue(forAttributeNamed: "id") == resourceID }
    }

    // MARK: - FCPXMLElementFiltering (Async)

    /// Filters elements by their FCPXML element types asynchronously.
    public func filter(elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) async -> [any PNXMLElement] {
        Self.filterElements(elements, ofTypes: types)
    }

    /// Finds elements matching the given resource ID attribute asynchronously.
    public func findElements(withResourceID resourceID: String, in elements: [any PNXMLElement]) async -> [any PNXMLElement] {
        elements.filter { $0.stringValue(forAttributeNamed: "id") == resourceID }
    }
}
