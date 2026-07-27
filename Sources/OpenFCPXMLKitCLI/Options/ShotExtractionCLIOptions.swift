//
// ShotExtractionCLIOptions.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	CLI options for still-image Shot Extraction.
//

import ArgumentParser
import Foundation
import OpenFCPXMLKit

struct ShotExtractionCLIOptions: ParsableArguments {
    @Flag(
        name: .long,
        help: "Extract primary-timeline still-image shots to PNG + CSV/JSON (rejects timelines with video media)."
    )
    var extractShots: Bool = false

    @Option(
        name: .customLong("extract-format"),
        help: "Shot Extraction manifest format: csv | notion (JSON). Requires --extract-shots."
    )
    var extractFormat: String?

    @Option(
        name: .customLong("scene-number"),
        help: "Scene number for Shot ID / Scene Number columns (required with --extract-shots)."
    )
    var sceneNumber: String?

    @Option(
        name: .customLong("folder-format"),
        help: "Shot Extraction folder naming: short | medium | long (default: medium). Requires --extract-shots."
    )
    var folderFormat: String?

    @Option(
        name: .customLong("result-file-path"),
        help: "Optional JSON result file path for Shot Extraction. Requires --extract-shots.",
        transform: URL.init(fileURLWithPath:)
    )
    var resultFilePath: URL?

    @Option(
        name: .customLong("extract-project"),
        help: "Optional project / timeline name filter for Shot Extraction. Requires --extract-shots."
    )
    var extractProject: String?

    @Option(
        name: .long,
        help: "Optional emoji (or any text) for the Icon Image column on every shot row. Requires --extract-shots."
    )
    var icon: String?

    var hasAnyModifier: Bool {
        extractFormat != nil
            || sceneNumber != nil
            || folderFormat != nil
            || resultFilePath != nil
            || extractProject != nil
            || icon != nil
    }

    func resolvedFormat() throws -> FinalCutPro.FCPXML.ShotExtractionFormat {
        let raw = (extractFormat ?? FinalCutPro.FCPXML.ShotExtractionFormat.csv.rawValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let format = FinalCutPro.FCPXML.ShotExtractionFormat(rawValue: raw) else {
            throw ValidationError(
                "Invalid --extract-format '\(extractFormat ?? "")'. Use csv or notion."
            )
        }
        return format
    }

    func resolvedFolderFormat() throws -> FinalCutPro.FCPXML.ShotExtractionFolderFormat {
        let raw = (folderFormat ?? FinalCutPro.FCPXML.ShotExtractionFolderFormat.medium.rawValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let format = FinalCutPro.FCPXML.ShotExtractionFolderFormat(rawValue: raw) else {
            throw ValidationError(
                "Invalid --folder-format '\(folderFormat ?? "")'. Use short, medium, or long."
            )
        }
        return format
    }

    func makeLibraryOptions(outputDir: URL, mediaBaseURL: URL?) throws -> FinalCutPro.FCPXML.ShotExtractionOptions {
        let scene = sceneNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !scene.isEmpty else {
            throw ValidationError("--scene-number is required when using --extract-shots.")
        }
        return FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: scene,
            extractFormat: try resolvedFormat(),
            outputDir: outputDir,
            folderFormat: try resolvedFolderFormat(),
            resultFilePath: resultFilePath,
            projectName: extractProject,
            mediaBaseURL: mediaBaseURL,
            icon: icon
        )
    }
}
