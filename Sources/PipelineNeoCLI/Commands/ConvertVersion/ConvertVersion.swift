//
//  ConvertVersion.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License

//
//
//  Convert FCPXML document to a target version and save (used by --convert-version).
//

import Foundation
import PipelineNeo

enum ConvertVersion {
    /// Loads the FCPXML at the given URL, converts it to the target version, and writes to output-dir.
    /// Uses `extensionType` (default .fcpxmld); for target versions 1.5–1.9, .fcpxml is always used.
    static func run(fcpxmlPath: URL, targetVersionString: String, outputDir: URL, extensionType: OutputExtensionType = .fcpxmld, logger: PipelineLogger = NoOpPipelineLogger()) throws {
        guard let targetVersion = FCPXMLVersion(string: targetVersionString) else {
            throw ConvertVersionError.unsupportedVersion(targetVersionString)
        }

        let service = FCPXMLService(logger: logger)
        let document = try service.parseFCPXML(from: fcpxmlPath)
        let converted = try service.convertToVersion(document, targetVersion: targetVersion)

        let validationResult = service.validateDocumentAgainstDTD(converted, version: targetVersion)
        if !validationResult.isValid {
            throw ConvertVersionError.dtdValidationFailed(
                version: targetVersion.rawValue,
                message: validationResult.detailedDescription
            )
        }

        let baseName = fcpxmlPath.deletingPathExtension().lastPathComponent
        let displayName = "\(baseName) (Converted-\(targetVersion.rawValue))"

        // Set project name(s) inside the document to match the converted filename.
        if let root = converted.rootElement() {
            func findProjects(in element: any PNXMLElement) -> [any PNXMLElement] {
                var result: [any PNXMLElement] = []
                for child in element.childElements {
                    if child.name == "project" {
                        result.append(child)
                    }
                    result.append(contentsOf: findProjects(in: child))
                }
                return result
            }
            let projects = findProjects(in: root)
            for project in projects {
                project.addAttribute(name: "name", value: displayName)
            }
        }

        let useBundle = (extensionType == .fcpxmld) && targetVersion.supportsBundleFormat
        if useBundle {
            let bundleURL = try service.saveAsBundle(converted, to: outputDir, bundleName: displayName)
            print(bundleURL.path)
            logger.log(level: .info, message: "Wrote \(bundleURL.path)", metadata: ["version": targetVersion.rawValue])
        } else {
            let outputFileName = "\(displayName).fcpxml"
            let outputURL = outputDir.appendingPathComponent(outputFileName)
            try service.saveAsFCPXML(converted, to: outputURL)
            print(outputURL.path)
            logger.log(level: .info, message: "Wrote \(outputURL.path)", metadata: ["version": targetVersion.rawValue])
        }
    }
}

enum ConvertVersionError: Error, LocalizedError {
    case unsupportedVersion(String)
    case dtdValidationFailed(version: String, message: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return "Unsupported FCPXML version: '\(v)'. Use a version between 1.5 and 1.14 (e.g. 1.10, 1.14)."
        case .dtdValidationFailed(let version, let message):
            return "DTD validation failed for FCPXML version \(version). The converted document does not conform to the schema.\n\(message)"
        }
    }
}
