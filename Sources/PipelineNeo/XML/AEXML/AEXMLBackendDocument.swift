//
//  AEXMLBackendDocument.swift
//  Pipeline Neo
//
//  Cross-platform XML document backend powered by AEXML.
//  Wraps `AEXMLDocument` and conforms to `PNXMLDocument`.
//
//  AEXML API differences handled here:
//  - `rootElement()` → `document.root` — checks `root.error` for the error
//    sentinel; returns `nil` when no root element exists.
//  - `xmlData(options:)` → serializes via `.xml` (pretty) or `.xmlCompact`
//    (compact) and encodes to UTF-8.
//  - `characterEncoding` → stored separately (AEXML's `options` is immutable
//    after init; the header encoding is baked into `AEXMLOptions`).
//  - `version` → stored separately for the same reason.
//  - `isStandalone` → stored separately; mapped to "yes"/"no" for the header.
//  - `setRootElement(_:)` → AEXML has no direct setter; implemented by clearing
//    children and re-adding.
//  - `validate()` → throws `PNXMLError.dtdValidationUnavailable` (AEXML has
//    no DTD support).
//

import Foundation
import AEXML

// MARK: - AEXMLBackendDocument

/// A cross-platform XML document that wraps an `AEXMLDocument` from the AEXML
/// library and conforms to `PNXMLDocument`.
///
/// This is the AEXML backend's document type, used on iOS and other platforms
/// where Foundation's `XMLDocument` is not available.
public final class AEXMLBackendDocument: PNXMLDocument {

    // MARK: - Underlying Storage

    /// The wrapped AEXML document.
    /// Exposed for interop with code that needs direct AEXML access.
    public let underlyingDocument: AEXMLDocument

    // MARK: - Metadata Storage

    // AEXML's `options` property is `let` (immutable after init), so we store
    // document metadata separately and use it when serializing the header.

    /// The character encoding of the document (e.g., `"UTF-8"`).
    public var characterEncoding: String?

    /// The XML version string (e.g., `"1.0"`).
    public var version: String?

    /// Whether the document declares itself as standalone.
    public var isStandalone: Bool = false

    /// The kind of content this document represents.
    public var documentContentKind: PNXMLDocumentContentKind = .xml

    // MARK: - Internal Init (wraps existing AEXMLDocument)

    /// Wraps an existing `AEXMLDocument`.
    ///
    /// Extracts initial metadata from the document's `options.documentHeader`.
    ///
    /// - Parameter document: The AEXML document to wrap.
    public init(wrapping document: AEXMLDocument) {
        self.underlyingDocument = document
        // Seed metadata from the AEXML options header.
        self.version = String(document.options.documentHeader.version)
        self.characterEncoding = document.options.documentHeader.encoding
        self.isStandalone = (document.options.documentHeader.standalone == "yes")
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
            let aeOptions = AEXMLBackendDocument.aeOptions(from: options)
            let doc = try AEXMLDocument(xml: data, options: aeOptions)
            self.init(wrapping: doc)
        } catch let error as PNXMLError {
            throw error
        } catch {
            throw PNXMLError.parsingFailure(
                message: "Failed to parse XML data: \(error.localizedDescription)"
            )
        }
    }

    /// Initializes a document by parsing the contents of a URL.
    ///
    /// - Parameters:
    ///   - url: The URL to load XML data from.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    public convenience init(contentsOf url: URL, options: PNXMLDocumentOptions) throws {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw PNXMLError.parsingFailure(
                message: "Failed to load data from URL \(url): \(error.localizedDescription)"
            )
        }
        try self.init(data: data, options: options)
    }

    /// Initializes a document by parsing an XML string.
    ///
    /// - Parameters:
    ///   - xmlString: The XML string to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    public convenience init(xmlString: String, options: PNXMLDocumentOptions) throws {
        guard let data = xmlString.data(using: .utf8) else {
            throw PNXMLError.parsingFailure(
                message: "Failed to encode XML string to UTF-8 data."
            )
        }
        try self.init(data: data, options: options)
    }

    /// Initializes an empty document.
    public convenience init() {
        self.init(wrapping: AEXMLDocument())
    }

    // MARK: - PNXMLNode Conformance

    /// The name of the document node.
    ///
    /// AEXML sets the document name to `"AEXMLDocument"` internally.
    /// We expose it via the protocol but it is not typically meaningful.
    public var name: String? {
        get { underlyingDocument.name }
        set { underlyingDocument.name = newValue ?? "" }
    }

    /// The text content of the document.
    public var stringValue: String? {
        get { underlyingDocument.value }
        set { underlyingDocument.value = newValue }
    }

    /// The full XML string representation of this document (header + root).
    public var xmlString: String {
        buildXMLString(prettyPrint: true)
    }

    /// Documents have no parent element.
    public var parent: (any PNXMLElement)? { nil }

    /// The child nodes of the document (typically just the root element).
    ///
    /// Error sentinel elements are filtered out.
    public var children: [any PNXMLNode]? {
        underlyingDocument.children
            .filter { $0.error == nil }
            .map { AEXMLBackendElement(wrapping: $0) }
    }

    // MARK: - PNXMLDocument: Document Structure

    /// Returns the root element of the document, or `nil` if none exists.
    ///
    /// Checks AEXML's error sentinel: if `root.error` is non-nil,
    /// the document has no valid root element.
    public func rootElement() -> (any PNXMLElement)? {
        let root = underlyingDocument.root
        guard root.error == nil else { return nil }
        return AEXMLBackendElement(wrapping: root)
    }

    /// Sets the root element of the document.
    ///
    /// AEXML does not have a direct `setRootElement` method. This implementation
    /// removes all existing children and adds the new root.
    public func setRootElement(_ root: any PNXMLElement) {
        // Remove all existing children from the document.
        for child in underlyingDocument.children {
            child.removeFromParent()
        }

        // Add the new root.
        if let aeElement = root as? AEXMLBackendElement {
            _ = underlyingDocument.addChild(aeElement.underlyingElement)
        } else {
            // Fallback: create a new AEXML element from the root's properties.
            let newRoot = AEXMLElement(
                name: root.name ?? "",
                value: root.stringValue
            )
            // Copy attributes
            for attr in root.attributes {
                newRoot.attributes[attr.name] = attr.value
            }
            _ = underlyingDocument.addChild(newRoot)
        }
    }

    // MARK: - PNXMLDocument: Serialization

    /// Returns the document serialized as XML data.
    ///
    /// - Parameter options: Options controlling serialization output.
    /// - Returns: The XML document as `Data`.
    ///
    /// If `prettyPrint` is set, uses AEXML's `.xml` (indented) output.
    /// Otherwise, uses `.xmlCompact` (no whitespace formatting).
    public func xmlData(options: PNXMLDocumentOptions) -> Data {
        let prettyPrint = options.contains(.prettyPrint)
        let xmlStr = buildXMLString(prettyPrint: prettyPrint)
        return xmlStr.data(using: .utf8) ?? Data()
    }

    /// The raw XML data with default pretty-printed formatting.
    public var xmlData: Data {
        xmlData(options: [])
    }

    // MARK: - PNXMLDocument: DTD (platform-conditional)

    #if canImport(FoundationXML) || os(macOS)
    /// DTD is not supported by the AEXML backend.
    /// Always returns `nil` on get; ignores set.
    public var dtd: (any PNXMLDTDProtocol)? {
        get { nil }
        set { /* AEXML does not support DTD — ignored */ }
    }

    /// Validates the document against its DTD.
    ///
    /// AEXML has no DTD support, so this always throws.
    ///
    /// - Throws: `PNXMLError.dtdValidationUnavailable`.
    public func validate() throws {
        throw PNXMLError.dtdValidationUnavailable
    }
    #endif

    // MARK: - Private Helpers

    /// Builds the XML string with a custom header reflecting the current metadata.
    ///
    /// The header is reconstructed from `version`, `characterEncoding`, and
    /// `isStandalone` so that mutations to those properties are reflected in
    /// serialized output.
    private func buildXMLString(prettyPrint: Bool) -> String {
        let versionStr = version ?? "1.0"
        let encodingStr = characterEncoding ?? "utf-8"
        let standaloneStr = isStandalone ? "yes" : "no"
        let header = "<?xml version=\"\(versionStr)\" encoding=\"\(encodingStr)\" standalone=\"\(standaloneStr)\"?>"

        let root = underlyingDocument.root
        guard root.error == nil else {
            // No root element — return just the header.
            return header
        }

        let body: String
        if prettyPrint {
            body = root.xml
        } else {
            body = root.xmlCompact
        }

        return "\(header)\n\(body)"
    }

    /// Maps `PNXMLDocumentOptions` to `AEXMLOptions`.
    ///
    /// Currently maps the `preserveWhitespace` option to the parser settings
    /// (inverted: preserveWhitespace means don't trim). AEXML's options mainly
    /// control parser behavior and the document header, not serialization format.
    private static func aeOptions(from options: PNXMLDocumentOptions) -> AEXMLOptions {
        var aeOptions = AEXMLOptions()

        // If preserveWhitespace is requested, tell the parser not to trim.
        if options.contains(.preserveWhitespace) {
            aeOptions.parserSettings.shouldTrimWhitespace = false
        }

        return aeOptions
    }
}
