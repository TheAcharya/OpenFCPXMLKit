//
//  CheckVersion.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//  Check and print FCPXML document version (used by --check-version).
//

import Foundation
import PipelineNeo

enum CheckVersion {
    /// Loads the FCPXML at the given URL and prints its document version.
    static func run(fcpxmlPath: URL, logger: PipelineLogger = NoOpPipelineLogger()) throws {
        let service = FCPXMLService(logger: logger)
        let document = try service.parseFCPXML(from: fcpxmlPath)
        let version = document.rootElement()?.attribute(forName: "version") ?? "(none)"
        print(version)
        logger.log(level: .info, message: "FCPXML version: \(version)", metadata: ["path": fcpxmlPath.path])
    }
}
