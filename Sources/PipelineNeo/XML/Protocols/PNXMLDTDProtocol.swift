//
//  PNXMLDTDProtocol.swift
//  Pipeline Neo
//
//  Platform-conditional DTD protocol.
//  Only available on macOS and platforms where FoundationXML is importable,
//  since AEXML (the cross-platform backend) does not support DTD validation.
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation

// MARK: - PNXMLDTDProtocol

/// A platform-agnostic protocol representing an XML Document Type Definition (DTD).
///
/// On macOS the conforming type wraps Foundation's `XMLDTD`.
/// This protocol is only available on platforms that support DTD validation
/// (macOS, Linux with FoundationXML).
///
/// This protocol is intentionally **not** `Sendable`. Operations protocols
/// that wrap DTD instances may add `Sendable` conformance where appropriate.
public protocol PNXMLDTDProtocol: AnyObject {

    // MARK: - Properties

    /// The name of the DTD (e.g., `"fcpxml"`).
    ///
    /// Mirrors `XMLDTD.name`.
    var name: String? { get set }

    // MARK: - Factory Initializers

    /// Initializes an empty DTD.
    ///
    /// Mirrors `XMLDTD()`.
    init()

    /// Initializes a DTD from the contents of a URL.
    ///
    /// - Parameters:
    ///   - url: The URL pointing to the DTD file.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if the DTD cannot be parsed.
    ///
    /// Mirrors `XMLDTD(contentsOf:options:)`.
    init(contentsOf url: URL, options: PNXMLDocumentOptions) throws

    /// Initializes a DTD from raw data.
    ///
    /// - Parameters:
    ///   - data: The raw DTD data to parse.
    ///   - options: Options controlling parsing behavior.
    /// - Throws: `PNXMLError.parsingFailure` if the DTD cannot be parsed.
    ///
    /// Mirrors `XMLDTD(data:options:)`.
    init(data: Data, options: PNXMLDocumentOptions) throws
}

#endif
