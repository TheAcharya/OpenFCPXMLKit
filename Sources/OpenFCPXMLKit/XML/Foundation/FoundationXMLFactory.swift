//
//  FoundationXMLFactory.swift
//  OpenFCPXMLKit
//
//  Foundation backend factory that creates FoundationXMLDocument and
//  FoundationXMLElement instances through the OFKXMLFactory protocol.
//
//  This file is conditionally compiled for platforms where Foundation XML is available.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation

// MARK: - FoundationXMLFactory

/// A factory that creates Foundation-backed XML documents and elements.
///
/// Conforms to `OFKXMLFactory` and produces `FoundationXMLDocument` and
/// `FoundationXMLElement` instances. Use this factory on macOS and Linux
/// (with FoundationXML) to get full XMLDocument/XMLElement behavior
/// including DTD validation.
public struct FoundationXMLFactory: OFKXMLFactory {

    // MARK: - Initialization

    /// Creates a new Foundation XML factory.
    public init() {}

    // MARK: - Document Creation

    public func makeDocument() -> any OFKXMLDocument {
        FoundationXMLDocument()
    }

    public func makeDocument(data: Data, options: OFKXMLDocumentOptions) throws -> any OFKXMLDocument {
        try FoundationXMLDocument(data: data, options: options)
    }

    public func makeDocument(contentsOf url: URL, options: OFKXMLDocumentOptions) throws -> any OFKXMLDocument {
        try FoundationXMLDocument(contentsOf: url, options: options)
    }

    public func makeDocument(xmlString: String, options: OFKXMLDocumentOptions) throws -> any OFKXMLDocument {
        try FoundationXMLDocument(xmlString: xmlString, options: options)
    }

    // MARK: - Element Creation

    public func makeElement(name: String) -> any OFKXMLElement {
        FoundationXMLElement(name: name)
    }

    public func makeElement(xmlString: String) throws -> any OFKXMLElement {
        try FoundationXMLElement(xmlString: xmlString)
    }

    // MARK: - DTD Creation

    public func makeDTD() -> any OFKXMLDTDProtocol {
        FoundationXMLDTD()
    }

    public func makeDTD(contentsOf url: URL, options: OFKXMLDocumentOptions) throws -> any OFKXMLDTDProtocol {
        try FoundationXMLDTD(contentsOf: url, options: options)
    }
}

#endif
