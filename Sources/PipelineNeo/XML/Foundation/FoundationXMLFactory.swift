//
//  FoundationXMLFactory.swift
//  Pipeline Neo
//
//  Foundation backend factory that creates FoundationXMLDocument and
//  FoundationXMLElement instances through the PNXMLFactory protocol.
//
//  This file is conditionally compiled for platforms where Foundation XML is available.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation

// MARK: - FoundationXMLFactory

/// A factory that creates Foundation-backed XML documents and elements.
///
/// Conforms to `PNXMLFactory` and produces `FoundationXMLDocument` and
/// `FoundationXMLElement` instances. Use this factory on macOS and Linux
/// (with FoundationXML) to get full XMLDocument/XMLElement behavior
/// including DTD validation.
public struct FoundationXMLFactory: PNXMLFactory {

    // MARK: - Initialization

    /// Creates a new Foundation XML factory.
    public init() {}

    // MARK: - Document Creation

    public func makeDocument() -> any PNXMLDocument {
        FoundationXMLDocument()
    }

    public func makeDocument(data: Data, options: PNXMLDocumentOptions) throws -> any PNXMLDocument {
        try FoundationXMLDocument(data: data, options: options)
    }

    public func makeDocument(contentsOf url: URL, options: PNXMLDocumentOptions) throws -> any PNXMLDocument {
        try FoundationXMLDocument(contentsOf: url, options: options)
    }

    public func makeDocument(xmlString: String, options: PNXMLDocumentOptions) throws -> any PNXMLDocument {
        try FoundationXMLDocument(xmlString: xmlString, options: options)
    }

    // MARK: - Element Creation

    public func makeElement(name: String) -> any PNXMLElement {
        FoundationXMLElement(name: name)
    }

    public func makeElement(xmlString: String) throws -> any PNXMLElement {
        try FoundationXMLElement(xmlString: xmlString)
    }

    // MARK: - DTD Creation

    public func makeDTD() -> any PNXMLDTDProtocol {
        FoundationXMLDTD()
    }

    public func makeDTD(contentsOf url: URL, options: PNXMLDocumentOptions) throws -> any PNXMLDTDProtocol {
        try FoundationXMLDTD(contentsOf: url, options: options)
    }
}

#endif
