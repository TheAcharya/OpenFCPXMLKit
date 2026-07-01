//
//  CheckVersion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//  Check and print FCPXML document version (used by --check-version).
//

import Foundation
import OpenFCPXMLKit

enum CheckVersion {
    /// Loads the FCPXML at the given URL and prints its document version.
    static func run(fcpxmlPath: URL, logger: ServiceLogger = NoOpServiceLogger()) throws {
        let service = FCPXMLService(logger: logger)
        let document = try service.parseFCPXML(from: fcpxmlPath)
        let version = document.rootElement()?.attribute(forName: "version") ?? "(none)"
        print(version)
        logger.log(level: .info, message: "FCPXML version: \(version)", metadata: ["path": fcpxmlPath.path])
    }
}
