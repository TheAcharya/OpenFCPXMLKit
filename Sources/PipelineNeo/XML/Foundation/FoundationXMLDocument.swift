//
//  FoundationXMLDocument.swift
//  Pipeline Neo
//
//  Foundation backend adapter for PNXMLDocument.
//  Wraps Foundation's XMLDocument and delegates all operations to it.
//
//  This file is conditionally compiled for platforms where Foundation XML is available.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation

// MARK: - Option Mapping

/// Maps `PNXMLDocumentOptions` to Foundation's `XMLNode.Options`.
private func foundationOptions(from options: PNXMLDocumentOptions) -> XMLNode.Options {
    var result: XMLNode.Options = []
    if options.contains(.preserveWhitespace) {
        result.insert(.nodePreserveWhitespace)
    }
    if options.contains(.prettyPrint) {
        result.insert(.nodePrettyPrint)
    }
    if options.contains(.compactEmptyElements) {
        result.insert(.nodeCompactEmptyElement)
    }
    return result
}

// MARK: - FoundationXMLDocument

/// A Foundation-backed XML document that conforms to `PNXMLDocument`.
///
/// Wraps Foundation's `XMLDocument` and delegates all calls to it.
/// This is a reference type (class) so that mutations to the wrapped document
/// are visible through all references, matching Foundation's `XMLDocument` semantics.
///
/// Use `underlyingDocument` for direct access to the wrapped `XMLDocument`
/// during incremental migration.
public final class FoundationXMLDocument: PNXMLDocument {

    // MARK: - Escape Hatch

    /// The underlying Foundation `XMLDocument` for direct access during incremental migration.
    public let underlyingDocument: XMLDocument

    // MARK: - Internal Init (wraps existing XMLDocument)

    /// Wraps an existing Foundation `XMLDocument`.
    ///
    /// - Parameter document: The Foundation `XMLDocument` to wrap.
    public init(_ document: XMLDocument) {
        self.underlyingDocument = document
    }

    // MARK: - PNXMLDocument Parsing Initializers

    /// Initializes a document by parsing raw XML data.
    ///
    /// - Parameters:
    ///   - data: The raw XML data to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    public convenience init(data: Data, options: PNXMLDocumentOptions) throws {
        do {
            let doc = try XMLDocument(data: data, options: foundationOptions(from: options))
            self.init(doc)
        } catch {
            throw PNXMLError.parsingFailure(message: error.localizedDescription)
        }
    }

    /// Initializes a document by parsing the contents of a URL.
    ///
    /// - Parameters:
    ///   - url: The URL to load XML data from.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    public convenience init(contentsOf url: URL, options: PNXMLDocumentOptions) throws {
        do {
            let doc = try XMLDocument(contentsOf: url, options: foundationOptions(from: options))
            self.init(doc)
        } catch {
            throw PNXMLError.parsingFailure(message: error.localizedDescription)
        }
    }

    /// Initializes a document by parsing an XML string.
    ///
    /// - Parameters:
    ///   - xmlString: The XML string to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    public convenience init(xmlString: String, options: PNXMLDocumentOptions) throws {
        do {
            let doc = try XMLDocument(xmlString: xmlString, options: foundationOptions(from: options))
            self.init(doc)
        } catch {
            throw PNXMLError.parsingFailure(message: error.localizedDescription)
        }
    }

    /// Initializes an empty document.
    public convenience init() {
        self.init(XMLDocument())
    }

    // MARK: - PNXMLNode Conformance

    public var name: String? {
        get { underlyingDocument.name }
        set { underlyingDocument.name = newValue }
    }

    public var stringValue: String? {
        get { underlyingDocument.stringValue }
        set { underlyingDocument.stringValue = newValue }
    }

    public var xmlString: String {
        underlyingDocument.xmlString
    }

    public var parent: (any PNXMLElement)? {
        // Documents have no parent element.
        nil
    }

    public var children: [any PNXMLNode]? {
        underlyingDocument.children?.map { child in
            if let element = child as? XMLElement {
                return FoundationXMLElement(element) as any PNXMLNode
            }
            return FoundationXMLNode(child) as any PNXMLNode
        }
    }

    // MARK: - PNXMLDocument: Document Structure

    public func rootElement() -> (any PNXMLElement)? {
        guard let root = underlyingDocument.rootElement() else { return nil }
        return FoundationXMLElement(root)
    }

    public func setRootElement(_ root: any PNXMLElement) {
        if let foundationElement = root as? FoundationXMLElement {
            underlyingDocument.setRootElement(foundationElement.underlyingElement)
        } else {
            // Fallback: parse the element's xmlString into a Foundation XMLElement
            if let parsed = try? XMLElement(xmlString: root.xmlString) {
                underlyingDocument.setRootElement(parsed)
            }
        }
    }

    // MARK: - PNXMLDocument: Metadata

    public var characterEncoding: String? {
        get { underlyingDocument.characterEncoding }
        set { underlyingDocument.characterEncoding = newValue }
    }

    public var version: String? {
        get { underlyingDocument.version }
        set { underlyingDocument.version = newValue }
    }

    public var isStandalone: Bool {
        get { underlyingDocument.isStandalone }
        set { underlyingDocument.isStandalone = newValue }
    }

    public var documentContentKind: PNXMLDocumentContentKind {
        get {
            switch underlyingDocument.documentContentKind {
            case .xml: return .xml
            case .xhtml: return .xhtml
            case .html: return .html
            case .text: return .text
            @unknown default: return .xml
            }
        }
        set {
            switch newValue {
            case .xml: underlyingDocument.documentContentKind = .xml
            case .xhtml: underlyingDocument.documentContentKind = .xhtml
            case .html: underlyingDocument.documentContentKind = .html
            case .text: underlyingDocument.documentContentKind = .text
            }
        }
    }

    // MARK: - PNXMLDocument: Serialization

    public func xmlData(options: PNXMLDocumentOptions) -> Data {
        underlyingDocument.xmlData(options: foundationOptions(from: options))
    }

    public var xmlData: Data {
        underlyingDocument.xmlData
    }

    // MARK: - PNXMLDocument: DTD

    public var dtd: (any PNXMLDTDProtocol)? {
        get {
            guard let foundationDTD = underlyingDocument.dtd else { return nil }
            return FoundationXMLDTD(foundationDTD)
        }
        set {
            if let foundationDTD = newValue as? FoundationXMLDTD {
                underlyingDocument.dtd = foundationDTD.underlyingDTD
            } else {
                underlyingDocument.dtd = nil
            }
        }
    }

    public func validate() throws {
        try underlyingDocument.validate()
    }
}

#endif
