//
//  FCPXMLSubmittedFCPXMLSmokeTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Optional smoke parse for private files in Tests/Submitted FCPXML/Inbox/.
//

import Foundation
import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLSubmittedFCPXMLSmokeTests: XCTestCase {

    /// Directory for private user-supplied FCPXML exports (gitignored contents).
    static func submittedInboxDirectory(
        relativeToFile fileURL: URL = URL(fileURLWithPath: #file)
    ) -> URL {
        packageRoot(relativeToFile: fileURL)
            .appendingPathComponent("Tests", isDirectory: true)
            .appendingPathComponent("Submitted FCPXML", isDirectory: true)
            .appendingPathComponent("Inbox", isDirectory: true)
    }

    /// Lists `.fcpxml` files and `.fcpxmld` bundles in the submitted inbox (non-recursive).
    static func submittedInboxItems(
        relativeToFile fileURL: URL = URL(fileURLWithPath: #file)
    ) -> [URL] {
        let dir = submittedInboxDirectory(relativeToFile: fileURL)
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
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    func testSubmittedInboxFilesParseWhenPresent() throws {
        let items = Self.submittedInboxItems()
        guard !items.isEmpty else {
            throw XCTSkip(
                "No private FCPXML in Tests/Submitted FCPXML/Inbox/ — see Tests/Submitted FCPXML/README.md"
            )
        }

        let loader = FCPXMLFileLoader()
        for url in items {
            let doc = try loader.loadDocument(from: url)
            XCTAssertEqual(
                doc.rootElement()?.name,
                "fcpxml",
                "Expected root fcpxml for \(url.lastPathComponent)"
            )

            let data: Data
            if url.pathExtension.lowercased() == "fcpxmld" {
                let info = url.appendingPathComponent("Info.fcpxml")
                data = try Data(contentsOf: info)
            } else {
                data = try Data(contentsOf: url)
            }
            let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
            XCTAssertEqual(fcpxml.root.element.name, "fcpxml", url.lastPathComponent)
        }
    }
}
