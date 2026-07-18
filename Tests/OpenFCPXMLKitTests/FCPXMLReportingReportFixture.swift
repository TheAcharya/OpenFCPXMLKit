//
//  FCPXMLReportingReportFixture.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Optional integration fixture for report builder tests.
//

import Foundation
@testable import OpenFCPXMLKit

enum FCPXMLReportingReportFixture {
    private static let infoFileName = "Info.fcpxml"
    private static let environmentVariableName = "OFK_REPORTING_FCPXML_BUNDLE"

    /// Path to a `.fcpxmld` bundle directory (set via `OFK_REPORTING_FCPXML_BUNDLE`).
    static func bundleDirectoryURL() -> URL? {
        guard let path = ProcessInfo.processInfo.environment[environmentVariableName],
              !path.isEmpty
        else {
            return nil
        }

        let url = URL(fileURLWithPath: path, isDirectory: true)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Framework-agnostic load; throws ``FCPXMLTestSampleError`` when the fixture is unset/missing.
    static func tryFCPXMLInfoURL() throws -> URL {
        guard let bundle = bundleDirectoryURL() else {
            throw FCPXMLTestSampleError.reportingFixtureUnavailable(
                "Reporting integration fixture unavailable. " +
                "Set \(environmentVariableName) to a .fcpxmld bundle path."
            )
        }

        let url = bundle.appendingPathComponent(infoFileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FCPXMLTestSampleError.reportingFixtureUnavailable(
                "Info.fcpxml not found in reporting fixture at the bundle at \(bundle.path)"
            )
        }

        return url
    }

    static func tryLoadFCPXML() throws -> FinalCutPro.FCPXML {
        let data = try Data(contentsOf: try tryFCPXMLInfoURL())
        return try FinalCutPro.FCPXML(fileContent: data)
    }

    static func tryMediaBaseURL() throws -> URL {
        try tryFCPXMLInfoURL().deletingLastPathComponent()
    }

    static func primaryProjectName(in fcpxml: FinalCutPro.FCPXML) -> String {
        fcpxml.allProjects().first?.name ?? ""
    }
}

