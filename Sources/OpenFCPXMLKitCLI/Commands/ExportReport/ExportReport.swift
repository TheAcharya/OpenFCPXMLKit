//
//  ExportReport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//  Build an Excel report workbook from FCPXML/FCPXMLD (used by --report).
//

import Foundation
import OpenFCPXMLKit

enum ExportReport {
    private final class ErrorBox: @unchecked Sendable {
        var error: Error?
    }
    
    /// Synchronous entry point for the CLI.
    static func runSynchronously(
        fcpxmlPath: URL,
        outputDir: URL,
        options: FinalCutPro.FCPXML.ReportOptions,
        logger: ServiceLogger = NoOpServiceLogger(),
        showProgress: Bool = true
    ) throws {
        let errorBox = ErrorBox()
        let semaphore = DispatchSemaphore(value: 0)
        
        Task { @MainActor in
            do {
                try await run(
                    fcpxmlPath: fcpxmlPath,
                    outputDir: outputDir,
                    options: options,
                    logger: logger,
                    showProgress: showProgress
                )
            } catch {
                errorBox.error = error
            }
            semaphore.signal()
        }
        
        while semaphore.wait(timeout: .now()) == .timedOut {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        
        if let error = errorBox.error {
            throw error
        }
    }
    
    /// Loads FCPXML, builds the requested report sections, and writes an `.xlsx` workbook.
    @MainActor
    static func run(
        fcpxmlPath: URL,
        outputDir: URL,
        options: FinalCutPro.FCPXML.ReportOptions,
        logger: ServiceLogger = NoOpServiceLogger(),
        showProgress: Bool = true
    ) async throws {
        let loader = FCPXMLFileLoader()
        let document = try loader.loadFCPXMLDocument(from: fcpxmlPath)
        let fcpxml = FinalCutPro.FCPXML(fileContent: document)
        
        var reportOptions = options
        if reportOptions.mediaBaseURL == nil {
            reportOptions.mediaBaseURL = fcpxmlPath.hasDirectoryPath
                ? fcpxmlPath
                : fcpxmlPath.deletingLastPathComponent()
        }
        
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: reportOptions)
        let progress: ProgressBar? = showProgress && !phases.isEmpty
            ? ProgressBar(total: phases.count + 1, desc: "Building report")
            : nil
        
        if progress == nil, showProgress {
            fputs("Building report…\n", stderr)
        }
        
        let report = try await fcpxml.buildReport(options: reportOptions) { phase in
            progress?.setPostfix(phase.rawValue)
            progress?.update(1)
        }
        
        let baseName = report.projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = fcpxmlPath.deletingPathExtension().lastPathComponent
        let fileStem = sanitizedFileStem(baseName.isEmpty ? fallbackName : baseName)
        let outputURL = outputDir.appendingPathComponent("\(fileStem).xlsx")
        
        progress?.setPostfix("Saving workbook")
        progress?.update(1)
        try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)
        progress?.close()
        
        print(outputURL.path)
        logger.log(level: .info, message: "Report exported to \(outputURL.path)", metadata: nil)
        
        let summary = reportSummary(for: report)
        fputs("\(summary)\n", stderr)
        logger.log(level: .info, message: summary, metadata: nil)
    }
    
    private static func sanitizedFileStem(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitized = name.unicodeScalars.map { scalar -> Character in
            if invalidCharacters.contains(scalar) || scalar.properties.isWhitespace {
                return "_"
            }
            return Character(scalar)
        }
        let stem = String(sanitized).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return stem.isEmpty ? "Report" : stem
    }
    
    private static func reportSummary(for report: FinalCutPro.FCPXML.Report) -> String {
        var parts: [String] = []
        
        if let roleInventory = report.roleInventory {
            parts.append("\(roleInventory.selectedRoles.count) selected-role row(s)")
            parts.append("\(roleInventory.roleSheets.count) role sheet(s)")
        }
        if let markers = report.markers {
            parts.append("\(markers.rows.count) marker row(s)")
        }
        if let keywords = report.keywords {
            parts.append("\(keywords.rows.count) keyword row(s)")
        }
        if let titles = report.titlesAndGenerators {
            parts.append("\(titles.rows.count) title/generator row(s)")
        }
        if let transitions = report.transitions {
            parts.append("\(transitions.rows.count) transition row(s)")
        }
        if let effects = report.effects {
            parts.append("\(effects.rows.count) effect row(s)")
        }
        if let speedChanges = report.speedChangeEffects {
            parts.append("\(speedChanges.rows.count) speed-change row(s)")
        }
        if report.summary != nil {
            parts.append("summary")
        }
        if report.mediaSummary != nil {
            parts.append("media summary")
        }
        
        if parts.isEmpty {
            return "Report exported with no sections."
        }
        
        return "Report sections: \(parts.joined(separator: ", "))."
    }
}
