//
//  FCPXMLFileLoader.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Loads FCPXML from .fcpxml files and .fcpxmld bundles.
//

import Foundation

/// Errors that can occur when loading FCPXML from a URL.
///
/// Parse failures are surfaced as `FCPXMLError.parsingFailed` rather than a separate type,
/// so consumers only need to handle one "parse failed" error across the framework.
@available(macOS 12.0, *)
public enum FCPXMLLoadError: Error, LocalizedError, Sendable {
    case notAFile(reason: String)
    case readFailed(underlying: Error?)

    public var errorDescription: String? {
        switch self {
        case .notAFile(let reason): return "Not a loadable FCPXML file or bundle: \(reason)"
        case .readFailed(let err): return "Failed to read data: \(err?.localizedDescription ?? "unknown")"
        }
    }
}

/// Loads FCPXML document from a URL, supporting both `.fcpxml` (single file) and `.fcpxmld` (bundle) formats.
@available(macOS 12.0, *)
public struct FCPXMLFileLoader: Sendable {

    private nonisolated(unsafe) let factory: any PNXMLFactory

    /// Creates a new file loader.
    /// - Parameter factory: XML factory for creating documents (default: `PNXMLDefaultFactory()`).
    public init(factory: any PNXMLFactory = PNXMLDefaultFactory()) {
        self.factory = factory
    }

    /// Resolves the URL to the actual FCPXML XML file.
    /// - If `url` is a directory (e.g. `Project.fcpxmld`), returns `url.appendingPathComponent("Info.fcpxml")`.
    /// - Otherwise returns `url` unchanged.
    /// - Throws if the resolved file does not exist or is not readable.
    public func resolveFCPXMLFileURL(from url: URL) throws -> URL {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            throw FCPXMLLoadError.notAFile(reason: "URL does not exist")
        }
        if isDir.boolValue {
            let infoFcpxml = url.appendingPathComponent("Info.fcpxml")
            guard FileManager.default.fileExists(atPath: infoFcpxml.path) else {
                throw FCPXMLLoadError.notAFile(reason: "Bundle does not contain Info.fcpxml")
            }
            return infoFcpxml
        }
        return url
    }

    /// Loads FCPXML raw data from the given URL.
    /// For a `.fcpxmld` bundle, reads `Info.fcpxml` inside the bundle.
    public func loadData(from url: URL) throws -> Data {
        let fileURL = try resolveFCPXMLFileURL(from: url)
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw FCPXMLLoadError.readFailed(underlying: error)
        }
    }

    /// Loads an FCPXML document from the given URL.
    /// For a `.fcpxmld` bundle, reads `Info.fcpxml` inside the bundle.
    public func loadDocument(from url: URL) throws -> any PNXMLDocument {
        let data = try loadData(from: url)
        do {
            return try factory.makeDocument(data: data)
        } catch {
            throw FCPXMLError.parsingFailed(error)
        }
    }

    /// Loads an FCPXML document using Pipeline Neo's FCPXML parsing options (preserve whitespace, pretty print).
    public func loadFCPXMLDocument(from url: URL) throws -> any PNXMLDocument {
        let data = try loadData(from: url)
        do {
            return try factory.makeDocument(data: data, options: .fcpxmlDefaults)
        } catch {
            throw FCPXMLError.parsingFailed(error)
        }
    }

    /// Loads an FCPXML document from the given URL with an async calling convention.
    ///
    /// Provides an `async` entry point so callers can avoid blocking the calling actor.
    /// The underlying file read is synchronous. For `.fcpxmld` bundles, reads `Info.fcpxml` inside the bundle.
    ///
    /// - Parameter url: URL of a `.fcpxml` file or `.fcpxmld` bundle.
    /// - Returns: Parsed XML document.
    public func load(from url: URL) async throws -> any PNXMLDocument {
        try loadFCPXMLDocument(from: url)
    }
}
