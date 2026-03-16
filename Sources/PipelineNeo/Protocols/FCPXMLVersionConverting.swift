//
//  FCPXMLVersionConverting.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Protocol for converting an FCPXML document to a target format version.
//

import Foundation

/// Converts an FCPXML document to a target format version.
///
/// Conversion sets the document root `version` attribute to the target version
/// and returns a new document. Content is preserved; for strict compatibility
/// with older versions you may need to remove or transform elements that were
/// introduced in later versions.
@available(macOS 12.0, *)
public protocol FCPXMLVersionConverting: Sendable {

    /// Converts the document to the target FCPXML version.
    ///
    /// - Parameters:
    ///   - document: Parsed FCPXML document.
    ///   - targetVersion: Desired version (e.g. `.v1_10`).
    /// - Returns: A new document with root `version` set to `targetVersion.stringValue`.
    /// - Throws: If the document cannot be serialized or copied.
    func convert(_ document: any PNXMLDocument, to targetVersion: FCPXMLVersion) throws -> any PNXMLDocument

    /// Converts the document to the target FCPXML version (async).
    func convert(_ document: any PNXMLDocument, to targetVersion: FCPXMLVersion) async throws -> any PNXMLDocument
}
