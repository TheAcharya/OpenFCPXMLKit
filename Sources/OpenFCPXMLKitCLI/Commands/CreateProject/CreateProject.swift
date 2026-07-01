//
//  CreateProject.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Create a new empty FCPXML project with given format (used by --create-project).
//

import Foundation
import CoreMedia
import OpenFCPXMLKit

enum CreateProject {
    /// Creates an empty FCPXML project with the given dimensions and frame rate, and writes it to the output directory.
    ///
    /// - Parameters:
    ///   - width: Frame width in pixels.
    ///   - height: Frame height in pixels.
    ///   - rate: Frame rate (e.g. 24, 25, 29.97, 30, 23.976, 50, 59.94, 60).
    ///   - outputDir: Directory in which to write the project file (e.g. "Project.fcpxml").
    ///   - version: FCPXML document version (e.g. 1.5–1.14). Default: .default (1.14).
    ///   - projectName: Optional project name; if nil, derived as "width x height @ rate p" (e.g. "640x480@25p").
    ///   - logger: Logger for messages.
    static func run(
        width: Int,
        height: Int,
        rate: Double,
        outputDir: URL,
        version: FCPXMLVersion = .default,
        projectName: String? = nil,
        logger: ServiceLogger = NoOpServiceLogger()
    ) throws {
        let name = projectName ?? Self.projectName(width: width, height: height, rate: rate)
        let frameDuration = Self.frameDuration(forRate: rate)
        let format = TimelineFormat(
            width: width,
            height: height,
            frameDuration: frameDuration,
            colorSpace: .rec709
        )
        let timeline = Timeline(
            name: name,
            format: format,
            clips: [],
            markers: [],
            chapterMarkers: [],
            keywords: [],
            ratings: [],
            metadata: nil
        )

        let exporter = FCPXMLExporter(version: version)
        let xmlString = try exporter.export(
            timeline: timeline,
            assets: [],
            libraryName: "Library",
            eventName: "Event",
            projectName: name,
            includeDefaultSmartCollections: true
        )

        guard let data = xmlString.data(using: .utf8) else {
            throw CreateProjectError.encodingFailed
        }

        let service = FCPXMLService(logger: logger)
        let document = try service.parseFCPXML(from: data)
        let validationResult = service.validateDocumentAgainstDTD(document, version: version)
        if !validationResult.isValid {
            throw CreateProjectError.dtdValidationFailed(
                version: version.stringValue,
                message: validationResult.detailedDescription
            )
        }

        let sanitized = name.replacingOccurrences(of: "/", with: "-")
        let fileName = "\(sanitized.isEmpty ? "Untitled Project" : sanitized).fcpxml"
        let outputURL = outputDir.appendingPathComponent(fileName)
        try data.write(to: outputURL)

        print(outputURL.path)
        logger.log(level: .info, message: "Created project at \(outputURL.path)", metadata: [
            "width": "\(width)",
            "height": "\(height)",
            "rate": "\(rate)",
        ])
    }

    /// Project name from format: "width x height @ rate p" (e.g. "640x480@25p").
    private static func projectName(width: Int, height: Int, rate: Double) -> String {
        let rateStr = rate == Double(Int(rate)) ? "\(Int(rate))" : "\(rate)"
        return "\(width)x\(height)@\(rateStr)p"
    }

    /// Maps a frame-rate value to FCPXML-style frame duration (CMTime).
    private static func frameDuration(forRate rate: Double) -> CMTime {
        // Match common FCP rates with exact rationals where needed.
        let tol = 0.01
        if abs(rate - 23.976) < tol { return CMTime(value: 1001, timescale: 24000) }
        if abs(rate - 29.97) < tol { return CMTime(value: 1001, timescale: 30000) }
        if abs(rate - 59.94) < tol { return CMTime(value: 1001, timescale: 60000) }
        let fps = max(1, Int(rate.rounded()))
        return CMTime(value: 1, timescale: CMTimeScale(fps))
    }
}

enum CreateProjectError: Error, LocalizedError {
    case invalidWidth(String)
    case invalidHeight(String)
    case invalidRate(String)
    case invalidOutputPath(String)
    case encodingFailed
    case dtdValidationFailed(version: String, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidWidth(let s): return "Invalid width: '\(s)'. Use a positive integer."
        case .invalidHeight(let s): return "Invalid height: '\(s)'. Use a positive integer."
        case .invalidRate(let s): return "Invalid frame rate: '\(s)'. Use a number (e.g. 24, 29.97)."
        case .invalidOutputPath(let s): return "Invalid output path: \(s)."
        case .encodingFailed: return "FCPXML encoding failed."
        case .dtdValidationFailed(let version, let message):
            return "DTD validation failed for FCPXML version \(version). The created document does not conform to the schema.\n\(message)"
        }
    }
}
