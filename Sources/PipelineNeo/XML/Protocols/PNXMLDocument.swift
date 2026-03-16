//
//  PNXMLDocument.swift
//  Pipeline Neo
//
//  Platform-agnostic XML document protocol.
//  Mirrors the Foundation XMLDocument API surface used by PipelineNeo:
//  parsing inits, root element access, metadata, serialization, and DTD validation.
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

import Foundation

// MARK: - PNXMLDocumentOptions

/// Platform-agnostic option set for XML document parsing and serialization.
///
/// Maps to Foundation's `XMLNode.Options` on macOS / Linux-FoundationXML,
/// and to equivalent AEXML options on cross-platform backends.
public struct PNXMLDocumentOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Preserve whitespace in the document (maps to `XMLNode.Options.nodePreserveWhitespace`).
    public static let preserveWhitespace = PNXMLDocumentOptions(rawValue: 1 << 0)

    /// Pretty-print the output with indentation (maps to `XMLNode.Options.nodePrettyPrint`).
    public static let prettyPrint = PNXMLDocumentOptions(rawValue: 1 << 1)

    /// Use compact empty-element tags (`<br/>` instead of `<br></br>`)
    /// (maps to `XMLNode.Options.nodeCompactEmptyElement`).
    public static let compactEmptyElements = PNXMLDocumentOptions(rawValue: 1 << 2)

    /// The default options used throughout PipelineNeo for FCPXML handling.
    /// Equivalent to `[.nodePreserveWhitespace, .nodePrettyPrint, .nodeCompactEmptyElement]`.
    public static let fcpxmlDefaults: PNXMLDocumentOptions = [
        .preserveWhitespace,
        .prettyPrint,
        .compactEmptyElements,
    ]
}

// MARK: - PNXMLDocumentContentKind

/// The kind of content the document represents.
///
/// Maps to Foundation's `XMLDocument.ContentKind`.
public enum PNXMLDocumentContentKind: Sendable {
    case xml
    case xhtml
    case html
    case text
}

// MARK: - PNXMLDocument

/// A platform-agnostic protocol representing an XML document.
///
/// On macOS the conforming type wraps `XMLDocument`; on iOS / other platforms
/// the conforming type wraps an AEXML (or other cross-platform) document.
///
/// This protocol is intentionally **not** `Sendable`. Operations protocols
/// that wrap document instances may add `Sendable` conformance where appropriate.
public protocol PNXMLDocument: PNXMLNode {

    // MARK: - Parsing Initializers

    /// Initializes a document by parsing raw XML data.
    ///
    /// - Parameters:
    ///   - data: The raw XML data to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    ///
    /// Mirrors `XMLDocument(data:options:)`.
    init(data: Data, options: PNXMLDocumentOptions) throws

    /// Initializes a document by parsing the contents of a URL.
    ///
    /// - Parameters:
    ///   - url: The URL to load XML data from.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    ///
    /// Mirrors `XMLDocument(contentsOf:options:)`.
    init(contentsOf url: URL, options: PNXMLDocumentOptions) throws

    /// Initializes a document by parsing an XML string.
    ///
    /// - Parameters:
    ///   - xmlString: The XML string to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    ///
    /// Mirrors `XMLDocument(xmlString:options:)`.
    init(xmlString: String, options: PNXMLDocumentOptions) throws

    /// Initializes an empty document.
    ///
    /// Mirrors `XMLDocument()`.
    init()

    // MARK: - Document Structure

    /// Returns the root element of the document, or `nil` if the document has no root.
    ///
    /// Mirrors `XMLDocument.rootElement()`.
    func rootElement() -> (any PNXMLElement)?

    /// Sets the root element of the document.
    ///
    /// - Parameter root: The element to set as the document's root.
    ///
    /// Mirrors `XMLDocument.setRootElement(_:)`.
    func setRootElement(_ root: any PNXMLElement)

    // MARK: - Document Metadata

    /// The character encoding of the document (e.g., `"UTF-8"`).
    ///
    /// Mirrors `XMLDocument.characterEncoding`.
    var characterEncoding: String? { get set }

    /// The XML version string (e.g., `"1.0"`).
    ///
    /// Mirrors `XMLDocument.version`.
    var version: String? { get set }

    /// Whether the document declares itself as standalone.
    ///
    /// Mirrors `XMLDocument.isStandalone`.
    var isStandalone: Bool { get set }

    /// The kind of content this document represents (XML, XHTML, HTML, or text).
    ///
    /// Mirrors `XMLDocument.documentContentKind`.
    var documentContentKind: PNXMLDocumentContentKind { get set }

    // MARK: - Serialization

    /// Returns the document serialized as XML data.
    ///
    /// - Parameter options: Options controlling serialization output.
    /// - Returns: The XML document as `Data`.
    ///
    /// Mirrors `XMLDocument.xmlData(options:)`.
    func xmlData(options: PNXMLDocumentOptions) -> Data

    /// The raw XML data with no additional options.
    ///
    /// Mirrors `XMLDocument.xmlData` (property, no options).
    var xmlData: Data { get }

    // MARK: - DTD (platform-conditional)

    #if canImport(FoundationXML) || os(macOS)
    /// The DTD associated with this document, or `nil` if none is set.
    ///
    /// Mirrors `XMLDocument.dtd`.
    var dtd: (any PNXMLDTDProtocol)? { get set }

    /// Validates the document against its DTD.
    ///
    /// - Throws: `PNXMLError` if validation fails. On platforms without DTD support,
    ///   throws `PNXMLError.dtdValidationUnavailable`.
    ///
    /// Mirrors `XMLDocument.validate()`.
    func validate() throws
    #endif
}
