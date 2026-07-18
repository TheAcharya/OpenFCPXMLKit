//
//  FCPXMLSubmittedFCPXMLSmokeTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Optional smoke parse for private files in Tests/Submitted FCPXML/Inbox/.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Submitted FCPXML smoke")
struct FCPXMLSubmittedFCPXMLSmokeTests {

    @Test("Submitted inbox files parse when present")
    func submittedInboxFilesParseWhenPresent() throws {
        let items = try requireSubmittedInboxItems()

        let loader = FCPXMLFileLoader()
        for url in items {
            let doc = try loader.loadDocument(from: url)
            #expect(
                doc.rootElement()?.name == "fcpxml",
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
            #expect(fcpxml.root.element.name == "fcpxml", "\(url.lastPathComponent)")
        }
    }
}

