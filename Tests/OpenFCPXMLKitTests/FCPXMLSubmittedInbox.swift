//
//  FCPXMLSubmittedInbox.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared discovery for the private Submitted FCPXML inbox (framework-agnostic).
//

import Foundation

enum FCPXMLSubmittedInbox {
    /// Directory for private user-supplied FCPXML exports (gitignored contents).
    static func directory(
        relativeToFile fileURL: URL = URL(fileURLWithPath: #filePath)
    ) -> URL {
        packageRoot(relativeToFile: fileURL)
            .appendingPathComponent("Tests", isDirectory: true)
            .appendingPathComponent("Submitted FCPXML", isDirectory: true)
            .appendingPathComponent("Inbox", isDirectory: true)
    }

    /// Lists `.fcpxml` files and `.fcpxmld` bundles in the submitted inbox (non-recursive).
    static func items(
        relativeToFile fileURL: URL = URL(fileURLWithPath: #filePath)
    ) -> [URL] {
        let dir = directory(relativeToFile: fileURL)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents
            .filter { url in
                let ext = url.pathExtension.lowercased()
                if ext == "fcpxml" { return true }
                if ext == "fcpxmld" {
                    var isDir: ObjCBool = false
                    return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                        && isDir.boolValue
                }
                return false
            }
            .sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
    }
}
