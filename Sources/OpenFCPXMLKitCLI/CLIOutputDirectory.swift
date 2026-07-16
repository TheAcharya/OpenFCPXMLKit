//
// CLIOutputDirectory.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Ensures CLI output directories exist before writing reports or exports.
//

import ArgumentParser
import Foundation

enum CLIOutputDirectory {
    /// Creates `directory` (and intermediates) if needed; fails clearly if the path is a file.
    static func ensureExists(_ directory: URL) throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw ValidationError(
                    "Output path exists but is not a directory: \(directory.path)"
                )
            }
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw ValidationError(
                "Cannot create output directory '\(directory.path)': \(error.localizedDescription)"
            )
        }
    }
}
