//
// ExtractShots.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	CLI command: extract still-image shots from the primary timeline.
//

import Foundation
import OpenFCPXMLKit

enum ExtractShots {
    private final class Box: @unchecked Sendable {
        var result: FinalCutPro.FCPXML.ShotExtractionResult?
        var error: Error?
    }

    /// Synchronous entry point for the CLI.
    static func runSynchronously(
        fcpxmlPath: URL,
        outputDir: URL,
        options: FinalCutPro.FCPXML.ShotExtractionOptions,
        logger: ServiceLogger = NoOpServiceLogger(),
        showProgress: Bool = true
    ) throws {
        let box = Box()
        let semaphore = DispatchSemaphore(value: 0)

        Task { @MainActor in
            do {
                box.result = try await run(
                    fcpxmlPath: fcpxmlPath,
                    outputDir: outputDir,
                    options: options,
                    logger: logger,
                    showProgress: showProgress
                )
            } catch {
                box.error = error
            }
            semaphore.signal()
        }

        while semaphore.wait(timeout: .now()) == .timedOut {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        if let error = box.error {
            throw error
        }
    }

    @MainActor
    static func run(
        fcpxmlPath: URL,
        outputDir: URL,
        options: FinalCutPro.FCPXML.ShotExtractionOptions,
        logger: ServiceLogger = NoOpServiceLogger(),
        showProgress: Bool = true
    ) async throws -> FinalCutPro.FCPXML.ShotExtractionResult {
        let progress = showProgress ? ProgressBar(total: 3, desc: "Shot Extraction") : nil
        defer { progress?.finish() }

        logger.log(level: .info, message: "Shot Extraction: loading \(fcpxmlPath.path)", metadata: nil)
        progress?.update(1)

        let document = try FCPXMLFileLoader().loadFCPXMLDocument(from: fcpxmlPath)
        let fcpxml = FinalCutPro.FCPXML(fileContent: document)

        var options = options
        if options.mediaBaseURL == nil {
            options.mediaBaseURL = fcpxmlPath.hasDirectoryPath
                ? fcpxmlPath
                : fcpxmlPath.deletingLastPathComponent()
        }

        progress?.update(2)
        logger.log(
            level: .info,
            message: "Shot Extraction: scene \(options.sceneNumber), format \(options.extractFormat.rawValue)",
            metadata: nil
        )

        let result = try await fcpxml.extractShots(options: options)
        progress?.update(3)

        let message = "Shot Extraction complete: \(result.shots.count) shot(s) → \(result.exportFolder.path)"
        print(message)
        logger.log(level: .info, message: message, metadata: nil)
        print("Manifest: \(result.manifestPath.path)")
        logger.log(level: .info, message: "Manifest: \(result.manifestPath.path)", metadata: nil)
        return result
    }
}
