//
// ShotExtractionFixture.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Local FCPXML fixture resolution for Shot Extraction integration tests.
//

import Foundation
import OpenFCPXMLKit
import Testing

enum ShotExtractionFixture {
    static let preferredBundleName = "Sample.fcpxmld"
    static let preferredFileName = "Sample.fcpxml"
    static let outputDirectoryName = "Output"
    static let environmentVariableName = "OFK_SHOT_EXTRACTION_FCPXML"
    static let sceneNumberEnvironmentVariableName = "OFK_SHOT_EXTRACTION_SCENE_NUMBER"

    /// Stable CSV / Notion aliases copied beside the dated export folder.
    static let csvAliasFileName = "OFK-Shots.csv"
    static let notionAliasFileName = "OFK-Shots.json"
    static let resultFileName = "OFK-Shots-result.json"

    /// Fixed clock so `.long` export folder names stay stable across runs.
    static let fixedNow: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 6, hour: 12, minute: 0, second: 0)
        ) ?? Date(timeIntervalSince1970: 1_775_500_800)
    }()

    /// URL to a `.fcpxml` file or `.fcpxmld` bundle directory.
    static func fixtureURL() -> URL? {
        if let path = ProcessInfo.processInfo.environment[environmentVariableName],
           !path.isEmpty
        {
            let url = URL(fileURLWithPath: path)
            if isValidFixture(at: url) {
                return url
            }
        }

        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let outputDirectory = testDirectory.appendingPathComponent(outputDirectoryName, isDirectory: true)
        let preferredURLs = [
            testDirectory.appendingPathComponent(preferredBundleName, isDirectory: true),
            testDirectory.appendingPathComponent(preferredFileName),
            outputDirectory.appendingPathComponent(preferredBundleName, isDirectory: true),
            outputDirectory.appendingPathComponent(preferredFileName),
        ]

        for url in preferredURLs where isValidFixture(at: url) {
            return url
        }

        return discoverFixture(in: testDirectory)
            ?? discoverFixture(in: outputDirectory)
    }

    /// Resolves a fixture URL or cancels the current Swift Testing test when none is available.
    static func requireFixtureURL() throws -> URL {
        guard let url = fixtureURL() else {
            let message =
                "Shot Extraction fixture unavailable. Add \(preferredBundleName) or " +
                "\(preferredFileName) under Tests/ShotExtractionTest/, or set " +
                "\(environmentVariableName) to a .fcpxml file or .fcpxmld bundle path."
            try Test.cancel("\(message)")
        }
        return url
    }

    /// Base directory for resolving relative media paths.
    static func mediaBaseURL(for fixtureURL: URL) -> URL {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fixtureURL.path, isDirectory: &isDirectory) else {
            return fixtureURL.deletingLastPathComponent()
        }

        return isDirectory.boolValue
            ? fixtureURL
            : fixtureURL.deletingLastPathComponent()
    }

    static func outputDirectoryURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(outputDirectoryName, isDirectory: true)
    }

    /// Scene number from env, else digits in the first timeline display name, else `"1"`.
    static func sceneNumber(for fcpxml: FinalCutPro.FCPXML) -> String {
        if let env = ProcessInfo.processInfo.environment[sceneNumberEnvironmentVariableName]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty
        {
            return env
        }

        if let name = fcpxml.allReportTimelineSources().first?.displayName,
           let match = name.range(of: #"\d+"#, options: .regularExpression)
        {
            return String(name[match])
        }

        return "1"
    }

    static func loadFCPXML(from fixtureURL: URL) throws -> FinalCutPro.FCPXML {
        let document = try FCPXMLFileLoader().loadFCPXMLDocument(from: fixtureURL)
        return FinalCutPro.FCPXML(fileContent: document)
    }

    /// Runs extract; cancels (does not fail CI) when the fixture is unsuitable or media is missing.
    static func extractOrCancel(
        _ fcpxml: FinalCutPro.FCPXML,
        options: FinalCutPro.FCPXML.ShotExtractionOptions
    ) async throws -> FinalCutPro.FCPXML.ShotExtractionResult {
        do {
            return try await fcpxml.extractShots(options: options)
        } catch let error as FinalCutPro.FCPXML.ShotExtractionError {
            switch error {
            case .mediaFileMissing(let path):
                try Test.cancel(
                    "Shot Extraction media missing at \(path). Ensure still-image files resolve, or set \(environmentVariableName) to a fixture with reachable media."
                )
            case .containsVideoMedia, .containsTitlesOrGenerators, .containsPrimaryAudio,
                 .noStillImageShots, .invalidSceneNumber, .noTimelineFound, .timelineNotFound:
                try Test.cancel("Fixture not suitable for Shot Extraction: \(error)")
            case .imageWriteFailed, .manifestWriteFailed, .outputDirectoryFailed:
                throw error
            }
        }
    }

    /// Runs dry-run plan; cancels when the fixture is unsuitable or media is missing.
    static func planOrCancel(
        _ fcpxml: FinalCutPro.FCPXML,
        options: FinalCutPro.FCPXML.ShotExtractionOptions
    ) async throws -> FinalCutPro.FCPXML.ShotExtractionPlan {
        do {
            return try await fcpxml.planShots(options: options)
        } catch let error as FinalCutPro.FCPXML.ShotExtractionError {
            switch error {
            case .mediaFileMissing(let path):
                try Test.cancel(
                    "Shot Extraction media missing at \(path). Ensure still-image files resolve, or set \(environmentVariableName) to a fixture with reachable media."
                )
            case .containsVideoMedia, .containsTitlesOrGenerators, .containsPrimaryAudio,
                 .noStillImageShots, .invalidSceneNumber, .noTimelineFound, .timelineNotFound:
                try Test.cancel("Fixture not suitable for Shot Extraction: \(error)")
            case .imageWriteFailed, .manifestWriteFailed, .outputDirectoryFailed:
                throw error
            }
        }
    }

    static func copyAlias(from source: URL, named fileName: String, to outputDir: URL) throws -> URL {
        let destination = outputDir.appendingPathComponent(fileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private static func discoverFixture(in directory: URL) -> URL? {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let candidates = entries
            .filter { url in
                let name = url.lastPathComponent
                let ext = url.pathExtension.lowercased()
                if name == outputDirectoryName
                    || name.hasSuffix(".swift")
                    || name.hasSuffix(".md")
                    || ext == "csv"
                    || ext == "json"
                    || ext == "png"
                    || ext == "xlsx"
                    || ext == "pdf"
                {
                    return false
                }

                return isValidFixture(at: url)
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        return candidates.first
    }

    private static func isValidFixture(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }

        if isDirectory.boolValue {
            let infoURL = url.appendingPathComponent("Info.fcpxml")
            return FileManager.default.fileExists(atPath: infoURL.path)
        }

        return url.pathExtension.lowercased() == "fcpxml"
    }
}
