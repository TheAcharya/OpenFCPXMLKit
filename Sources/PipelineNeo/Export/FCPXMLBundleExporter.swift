//
//  FCPXMLBundleExporter.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Creates .fcpxmld bundles on disk with FCPXML and media files.
//

import Foundation
import CoreMedia

/// Errors that can occur during bundle export.
@available(macOS 12.0, *)
public enum FCPXMLBundleExportError: Error, LocalizedError, Sendable {
    case bundleCreationFailed(reason: String)
    case mediaCopyFailed(assetId: String, underlying: Error?)
    case writeFailed(reason: String)
    /// Saving as .fcpxmld bundle is only supported for FCPXML version 1.10 or higher.
    case bundleRequiresVersion1_10OrHigher(currentVersion: String)

    public var errorDescription: String? {
        switch self {
        case .bundleCreationFailed(let reason): return "Bundle creation failed: \(reason)"
        case .mediaCopyFailed(let id, let err): return "Failed to copy media for asset '\(id)': \(err?.localizedDescription ?? "unknown")"
        case .writeFailed(let reason): return "Write failed: \(reason)"
        case .bundleRequiresVersion1_10OrHigher(let v): return "Saving as .fcpxmld bundle requires FCPXML version 1.10 or higher; document version is \(v)"
        }
    }
}

/// Exports a Timeline and assets to a Final Cut Pro .fcpxmld bundle (directory with Info.fcpxml, Info.plist, Media/).
@available(macOS 12.0, *)
public struct FCPXMLBundleExporter: Sendable {

    public var version: FCPXMLVersion
    public var includeMedia: Bool

    public init(version: FCPXMLVersion = .default, includeMedia: Bool = true) {
        self.version = version
        self.includeMedia = includeMedia
    }

    /// Exports the timeline to a .fcpxmld bundle at the given directory.
    ///
    /// - Parameters:
    ///   - timeline: The timeline to export.
    ///   - assets: Assets referenced by timeline clips (by `assetRef` = `id`).
    ///   - to: Directory in which to create the bundle (e.g. `/path/to/output`).
    ///   - bundleName: Name of the bundle without extension (e.g. `"My Project"` → `My Project.fcpxmld`).
    ///   - libraryName: FCPXML library element name.
    ///   - eventName: FCPXML event element name.
    ///   - projectName: FCPXML project name (default: timeline name).
    /// - Returns: URL of the created bundle directory.
    public func exportBundle(
        timeline: Timeline,
        assets: [FCPXMLExportAsset],
        to outputDirectory: URL,
        bundleName: String? = nil,
        libraryName: String = "Exported Library",
        eventName: String = "Exported Event",
        projectName: String? = nil
    ) throws -> URL {
        let name = bundleName ?? timeline.name
        let bundleDir = outputDirectory.appendingPathComponent("\(name).fcpxmld", isDirectory: true)

        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)

        var assetsForXml = assets
        if includeMedia {
            let mediaURL = bundleDir.appendingPathComponent("Media", isDirectory: true)
            try FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)
            assetsForXml = try copyMedia(assets: assets, to: mediaURL)
        }

        let exporter = FCPXMLExporter(version: version)
        let xmlString = try exporter.export(
            timeline: timeline,
            assets: assetsForXml,
            libraryName: libraryName,
            eventName: eventName,
            projectName: projectName ?? timeline.name
        )

        let infoFcpxml = bundleDir.appendingPathComponent("Info.fcpxml")
        guard let data = xmlString.data(using: .utf8) else {
            throw FCPXMLBundleExportError.writeFailed(reason: "FCPXML string encoding failed")
        }
        try data.write(to: infoFcpxml)

        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.apple.FinalCut.FCPXML",
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: bundleDir.appendingPathComponent("Info.plist"))

        return bundleDir
    }

    /// Minimum FCPXML version required to save as a .fcpxmld bundle.
    public static let minimumVersionForBundle: FCPXMLVersion = .v1_10

    /// Saves an existing FCPXML document as a .fcpxmld bundle.
    ///
    /// The document's root `version` attribute must be 1.10 or higher; otherwise
    /// `bundleRequiresVersion1_10OrHigher` is thrown.
    ///
    /// - Parameters:
    ///   - document: Parsed FCPXML document (e.g. after conversion to a target version).
    ///   - outputDirectory: Parent directory in which to create the bundle.
    ///   - bundleName: Name of the bundle without extension (e.g. `"My Project"` → `My Project.fcpxmld`).
    /// - Returns: URL of the created bundle directory.
    /// - Throws: `FCPXMLBundleExportError.bundleRequiresVersion1_10OrHigher` if document version is below 1.10; or write errors.
    public func saveDocumentAsBundle(
        _ document: any PNXMLDocument,
        to outputDirectory: URL,
        bundleName: String
    ) throws -> URL {
        let versionString = document.rootElement()?.attribute(forName: "version") ?? "1.0"
        guard let docVersion = FCPXMLVersion(string: versionString),
              docVersion.isAtLeast(Self.minimumVersionForBundle) else {
            throw FCPXMLBundleExportError.bundleRequiresVersion1_10OrHigher(currentVersion: versionString)
        }
        let bundleDir = outputDirectory.appendingPathComponent("\(bundleName).fcpxmld", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
        let infoFcpxml = bundleDir.appendingPathComponent("Info.fcpxml")
        let data = document.xmlData
        do {
            try data.write(to: infoFcpxml)
        } catch {
            throw FCPXMLBundleExportError.writeFailed(reason: error.localizedDescription)
        }
        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.apple.FinalCut.FCPXML",
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: bundleDir.appendingPathComponent("Info.plist"))
        return bundleDir
    }

    /// Copies each asset's file into Media/ and returns assets with relativePath set to "Media/filename".
    private func copyMedia(assets: [FCPXMLExportAsset], to mediaURL: URL) throws -> [FCPXMLExportAsset] {
        var result: [FCPXMLExportAsset] = []
        for asset in assets {
            let filename = uniqueFilename(for: asset, existing: result.map(\.relativePath))
            let dest = mediaURL.appendingPathComponent(filename)
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: asset.src, to: dest)
            } catch {
                throw FCPXMLBundleExportError.mediaCopyFailed(assetId: asset.id, underlying: error)
            }
            var copy = asset
            copy.relativePath = "Media/\(filename)"
            result.append(copy)
        }
        return result
    }

    private func uniqueFilename(for asset: FCPXMLExportAsset, existing: [String?]) -> String {
        let base = asset.src.lastPathComponent.isEmpty ? "asset_\(asset.id)" : asset.src.lastPathComponent
        let set = Set(existing.compactMap { $0?.split(separator: "/").last.map(String.init) })
        if !set.contains(base) { return base }
        let ext = (base as NSString).pathExtension
        let stem = (base as NSString).deletingPathExtension
        var n = 1
        while true {
            let candidate = ext.isEmpty ? "\(stem)_\(n)" : "\(stem)_\(n).\(ext)"
            if !set.contains(candidate) { return candidate }
            n += 1
        }
    }
}
