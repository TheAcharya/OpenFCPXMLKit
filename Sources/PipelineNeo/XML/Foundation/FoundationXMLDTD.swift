//
//  FoundationXMLDTD.swift
//  Pipeline Neo
//
//  Foundation backend adapter for PNXMLDTDProtocol.
//  Wraps Foundation's XMLDTD and delegates all operations to it.
//
//  This file is conditionally compiled for platforms where Foundation XML is available.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation

// MARK: - FoundationXMLDTD

/// A Foundation-backed XML DTD that conforms to `PNXMLDTDProtocol`.
///
/// Wraps Foundation's `XMLDTD` and delegates all calls to it.
/// This is a reference type (class) so that mutations to the wrapped DTD
/// are visible through all references, matching Foundation's `XMLDTD` semantics.
///
/// Use `underlyingDTD` for direct access to the wrapped `XMLDTD`
/// during incremental migration.
public final class FoundationXMLDTD: PNXMLDTDProtocol {

    // MARK: - Escape Hatch

    /// The underlying Foundation `XMLDTD` for direct access during incremental migration.
    public let underlyingDTD: XMLDTD

    // MARK: - Internal Init (wraps existing XMLDTD)

    /// Wraps an existing Foundation `XMLDTD`.
    ///
    /// - Parameter dtd: The Foundation `XMLDTD` to wrap.
    public init(_ dtd: XMLDTD) {
        self.underlyingDTD = dtd
    }

    // MARK: - PNXMLDTDProtocol Conformance

    /// Initializes an empty DTD.
    public convenience init() {
        self.init(XMLDTD())
    }

    /// Initializes a DTD from the contents of a URL.
    ///
    /// - Parameters:
    ///   - url: The URL pointing to the DTD file.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if the DTD cannot be parsed.
    public convenience init(contentsOf url: URL, options: PNXMLDocumentOptions) throws {
        do {
            var foundationOptions: XMLNode.Options = []
            if options.contains(.preserveWhitespace) {
                foundationOptions.insert(.nodePreserveWhitespace)
            }
            if options.contains(.prettyPrint) {
                foundationOptions.insert(.nodePrettyPrint)
            }
            if options.contains(.compactEmptyElements) {
                foundationOptions.insert(.nodeCompactEmptyElement)
            }
            let dtd = try XMLDTD(contentsOf: url, options: foundationOptions)
            self.init(dtd)
        } catch {
            throw PNXMLError.parsingFailure(message: error.localizedDescription)
        }
    }

    /// Initializes a DTD from raw data.
    ///
    /// - Parameters:
    ///   - data: The raw DTD data to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if the DTD cannot be parsed.
    public convenience init(data: Data, options: PNXMLDocumentOptions) throws {
        do {
            var foundationOptions: XMLNode.Options = []
            if options.contains(.preserveWhitespace) {
                foundationOptions.insert(.nodePreserveWhitespace)
            }
            if options.contains(.prettyPrint) {
                foundationOptions.insert(.nodePrettyPrint)
            }
            if options.contains(.compactEmptyElements) {
                foundationOptions.insert(.nodeCompactEmptyElement)
            }
            let dtd = try XMLDTD(data: data, options: foundationOptions)
            self.init(dtd)
        } catch {
            throw PNXMLError.parsingFailure(message: error.localizedDescription)
        }
    }

    // MARK: - Properties

    public var name: String? {
        get { underlyingDTD.name }
        set { underlyingDTD.name = newValue }
    }
}

#endif
