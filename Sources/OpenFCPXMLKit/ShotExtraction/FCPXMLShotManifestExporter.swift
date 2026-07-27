//
// FCPXMLShotManifestExporter.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Writes Shot Extraction CSV or Notion JSON manifests via TextFile / JSONSerialization.
//

import Foundation
import TextFile

extension FinalCutPro.FCPXML {
    enum ShotManifestExporter {
        static func write(
            shots: [ShotRecord],
            format: ShotExtractionFormat,
            timelineName: String,
            to exportFolder: URL
        ) throws -> URL {
            let safeName = timelineName.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseName = safeName.isEmpty ? "Shots" : safeName
            let manifestURL = exportFolder.appendingPathComponent(
                "\(baseName).\(format.fileExtension)",
                isDirectory: false
            )

            switch format {
            case .csv:
                try writeCSV(shots: shots, to: manifestURL)
            case .notion:
                try writeNotionJSON(shots: shots, to: manifestURL)
            }
            return manifestURL
        }

        private static func writeCSV(shots: [ShotRecord], to url: URL) throws {
            var table: StringTable = [ShotManifestSchema.columns]
            for shot in shots {
                table.append(ShotManifestSchema.rowValues(for: shot))
            }

            let data: Data
            do throws(TextFileEncodeError) {
                data = try CSV(table: table).data(encoding: .utf8, includeBOM: true)
            } catch {
                throw ShotExtractionError.manifestWriteFailed(
                    reason: error.localizedDescription
                )
            }

            do {
                try data.write(to: url, options: .atomic)
            } catch {
                throw ShotExtractionError.manifestWriteFailed(
                    reason: error.localizedDescription
                )
            }
        }

        private static func writeNotionJSON(shots: [ShotRecord], to url: URL) throws {
            let objects = shots.map { ShotManifestSchema.dictionary(for: $0) }
            let data: Data
            do {
                data = try JSONSerialization.data(
                    withJSONObject: objects,
                    options: [.prettyPrinted, .sortedKeys]
                )
            } catch {
                throw ShotExtractionError.manifestWriteFailed(
                    reason: error.localizedDescription
                )
            }

            do {
                try data.write(to: url, options: .atomic)
            } catch {
                throw ShotExtractionError.manifestWriteFailed(
                    reason: error.localizedDescription
                )
            }
        }
    }
}
