//
// FCPXMLShotManifestExporter.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Writes Shot Extraction CSV or Notion JSON manifests via TextFile / ordered JSON encoding.
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

        /// Writes a pretty-printed JSON array with object keys in ``ShotManifestSchema/columns``
        /// order (same as CSV headers). `JSONSerialization` + `Dictionary` cannot preserve that
        /// order (`.sortedKeys` is alphabetical only), so objects are encoded field-by-field.
        private static func writeNotionJSON(shots: [ShotRecord], to url: URL) throws {
            let data: Data
            do {
                data = try encodeNotionJSON(shots: shots)
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

        private static func encodeNotionJSON(shots: [ShotRecord]) throws -> Data {
            var lines: [String] = ["["]
            for (shotIndex, shot) in shots.enumerated() {
                let fields = ShotManifestSchema.orderedFields(for: shot)
                lines.append("  {")
                for (fieldIndex, field) in fields.enumerated() {
                    let keyJSON = try jsonStringLiteral(field.key)
                    let valueJSON = try jsonStringLiteral(field.value)
                    let comma = fieldIndex < fields.count - 1 ? "," : ""
                    lines.append("    \(keyJSON): \(valueJSON)\(comma)")
                }
                let shotComma = shotIndex < shots.count - 1 ? "," : ""
                lines.append("  }\(shotComma)")
            }
            lines.append("]")
            let text = lines.joined(separator: "\n") + "\n"
            guard let data = text.data(using: .utf8) else {
                throw ShotExtractionError.manifestWriteFailed(
                    reason: "Failed to encode Notion JSON as UTF-8."
                )
            }
            return data
        }

        /// Escapes a string as a JSON string literal via `JSONSerialization`
        /// (wrapped in an array because a bare `String` is not a valid top-level JSON value).
        private static func jsonStringLiteral(_ string: String) throws -> String {
            let data = try JSONSerialization.data(withJSONObject: [string], options: [])
            guard let arrayLiteral = String(data: data, encoding: .utf8),
                  arrayLiteral.hasPrefix("["),
                  arrayLiteral.hasSuffix("]")
            else {
                throw ShotExtractionError.manifestWriteFailed(
                    reason: "Failed to escape JSON string."
                )
            }
            return String(arrayLiteral.dropFirst().dropLast())
        }
    }
}
