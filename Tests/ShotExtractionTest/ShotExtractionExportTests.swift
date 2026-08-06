//
// ShotExtractionExportTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Exports CSV / Notion Shot Extraction artefacts from a local FCPXML fixture.
//

import Foundation
import OpenFCPXMLKit
import Testing

@Suite("Shot Extraction export")
struct ShotExtractionExportTests {

    /// Writes PNG + CSV under `Output/`, copies manifest to `OFK-Shots.csv`.
    @Test("Extract CSV with icon")
    func extractCSVWithIcon() async throws {
        let fixtureURL = try ShotExtractionFixture.requireFixtureURL()
        let outputDir = ShotExtractionFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let fcpxml = try ShotExtractionFixture.loadFCPXML(from: fixtureURL)
        let sceneNumber = ShotExtractionFixture.sceneNumber(for: fcpxml)
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: sceneNumber,
            extractFormat: .csv,
            outputDir: outputDir,
            folderFormat: .long,
            mediaBaseURL: ShotExtractionFixture.mediaBaseURL(for: fixtureURL),
            icon: "🎬",
            now: ShotExtractionFixture.fixedNow
        )

        let result = try await ShotExtractionFixture.extractOrCancel(fcpxml, options: options)

        #expect(result.extractFormat == .csv)
        #expect(!result.shots.isEmpty)
        #expect(result.imagePaths.count == result.shots.count)
        #expect(result.manifestPath.pathExtension == "csv")
        #expect(FileManager.default.fileExists(atPath: result.manifestPath.path))
        for imageURL in result.imagePaths {
            #expect(FileManager.default.fileExists(atPath: imageURL.path))
        }

        let csv = try String(contentsOf: result.manifestPath, encoding: .utf8)
        #expect(csv.contains("Shot ID"))
        #expect(csv.contains("Icon Image"))
        #expect(csv.contains("🎬"))
        #expect(csv.contains(result.shots[0].shotID))

        // Shot ID order: first data row matches first planned shot.
        let alias = try ShotExtractionFixture.copyAlias(
            from: result.manifestPath,
            named: ShotExtractionFixture.csvAliasFileName,
            to: outputDir
        )
        #expect(FileManager.default.fileExists(atPath: alias.path))

        for (index, shot) in result.shots.enumerated() {
            let expected = FinalCutPro.FCPXML.ShotRecord.makeShotID(
                sceneNumber: sceneNumber,
                shotNumber: index + 1
            )
            #expect(shot.shotID == expected)
            #expect(shot.shotNumber == index + 1)
        }
    }

    /// Writes PNG + Notion JSON under `Output/`, copies manifest to `OFK-Shots.json`.
    @Test("Extract Notion JSON with CSV column key order")
    func extractNotionJSONWithCSVColumnKeyOrder() async throws {
        let fixtureURL = try ShotExtractionFixture.requireFixtureURL()
        let outputDir = ShotExtractionFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let fcpxml = try ShotExtractionFixture.loadFCPXML(from: fixtureURL)
        let sceneNumber = ShotExtractionFixture.sceneNumber(for: fcpxml)
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: sceneNumber,
            extractFormat: .notion,
            outputDir: outputDir,
            folderFormat: .long,
            mediaBaseURL: ShotExtractionFixture.mediaBaseURL(for: fixtureURL),
            icon: "🎬",
            now: ShotExtractionFixture.fixedNow
        )

        let result = try await ShotExtractionFixture.extractOrCancel(fcpxml, options: options)

        #expect(result.extractFormat == .notion)
        #expect(!result.shots.isEmpty)
        #expect(result.manifestPath.pathExtension == "json")

        let data = try Data(contentsOf: result.manifestPath)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        #expect(json.count == result.shots.count)
        #expect(json[0]["Shot ID"] as? String == result.shots[0].shotID)
        #expect(json[0]["Icon Image"] as? String == "🎬")
        #expect(json[0]["Image Filename"] as? String == result.shots[0].imageFilename)

        // Array order = Shot ID order.
        for (index, shot) in result.shots.enumerated() {
            #expect(json[index]["Shot ID"] as? String == shot.shotID)
        }

        // Key order matches CSV schema (Shot ID before Shot Number before Image Filename).
        let text = try #require(String(data: data, encoding: .utf8))
        let orderedKeys = ["Shot ID", "Shot Number", "Scene Location", "Shot Duration", "Image Filename"]
        var searchFrom = text.startIndex
        for key in orderedKeys {
            let needle = "\"\(key)\""
            let match = try #require(
                text.range(of: needle, range: searchFrom..<text.endIndex),
                "Missing or out-of-order Notion JSON key: \(key)"
            )
            searchFrom = match.upperBound
        }

        let alias = try ShotExtractionFixture.copyAlias(
            from: result.manifestPath,
            named: ShotExtractionFixture.notionAliasFileName,
            to: outputDir
        )
        #expect(FileManager.default.fileExists(atPath: alias.path))
    }

    /// Dry-run validates and plans shots without writing PNGs or a manifest.
    @Test("Dry-run plans shots without writing")
    func dryRunPlansShotsWithoutWriting() async throws {
        let fixtureURL = try ShotExtractionFixture.requireFixtureURL()
        let outputDir = ShotExtractionFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let marker = outputDir.appendingPathComponent(
            "OFK-Shots-dry-run-should-not-exist-\(UUID().uuidString)",
            isDirectory: true
        )

        let fcpxml = try ShotExtractionFixture.loadFCPXML(from: fixtureURL)
        let sceneNumber = ShotExtractionFixture.sceneNumber(for: fcpxml)
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: sceneNumber,
            extractFormat: .csv,
            outputDir: marker,
            folderFormat: .short,
            mediaBaseURL: ShotExtractionFixture.mediaBaseURL(for: fixtureURL),
            now: ShotExtractionFixture.fixedNow
        )

        let plan = try await ShotExtractionFixture.planOrCancel(fcpxml, options: options)

        #expect(plan.isValid)
        #expect(!plan.shots.isEmpty)
        #expect(plan.sceneNumber == sceneNumber)
        #expect(!FileManager.default.fileExists(atPath: marker.path))
    }

    /// Writes a MarkersExtractor-style result JSON beside the CSV export.
    @Test("Extract CSV with result file")
    func extractCSVWithResultFile() async throws {
        let fixtureURL = try ShotExtractionFixture.requireFixtureURL()
        let outputDir = ShotExtractionFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let resultURL = outputDir.appendingPathComponent(
            ShotExtractionFixture.resultFileName,
            isDirectory: false
        )
        if FileManager.default.fileExists(atPath: resultURL.path) {
            try FileManager.default.removeItem(at: resultURL)
        }

        let fcpxml = try ShotExtractionFixture.loadFCPXML(from: fixtureURL)
        let sceneNumber = ShotExtractionFixture.sceneNumber(for: fcpxml)
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: sceneNumber,
            extractFormat: .csv,
            outputDir: outputDir,
            folderFormat: .long,
            resultFilePath: resultURL,
            mediaBaseURL: ShotExtractionFixture.mediaBaseURL(for: fixtureURL),
            now: ShotExtractionFixture.fixedNow
        )

        let result = try await ShotExtractionFixture.extractOrCancel(fcpxml, options: options)

        #expect(FileManager.default.fileExists(atPath: resultURL.path))
        let data = try Data(contentsOf: resultURL)
        let dict = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(dict["profile"] == "CSV")
        #expect(dict["shotCount"] == String(result.shots.count))
        #expect(dict["timelineName"] == result.timelineName)
        #expect(dict["manifestPath"] == result.manifestPath.path)
    }
}
