//
//  FCPXMLTestSampleError.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Framework-agnostic sample / fixture errors for the Swift Testing harness.
//

import Foundation

/// Errors from loading public samples or optional local fixtures.
///
/// Swift Testing wrappers map optional-fixture cases to `Test.cancel` and treat
/// missing **bundled** samples as hard failures.
enum FCPXMLTestSampleError: Error, CustomStringConvertible, Equatable {
    case sampleNotFound(name: String, path: String)
    case noProject(sampleName: String)
    case elementNotFound(elementName: String)
    case reportingFixtureUnavailable(String)
    case submittedInboxEmpty

    var description: String {
        switch self {
        case .sampleNotFound(let name, let path):
            "Sample not found: \(name).fcpxml at \(path)"
        case .noProject(let sampleName):
            "No project in sample \(sampleName)"
        case .elementNotFound(let elementName):
            "No descendant element named \(elementName)"
        case .reportingFixtureUnavailable(let message):
            message
        case .submittedInboxEmpty:
            "No private FCPXML in Tests/Submitted FCPXML/Inbox/ — see Tests/Submitted FCPXML/README.md"
        }
    }

    /// Whether this error should skip (cancel) a test rather than fail when the fixture is optional.
    var isOptionalFixtureAbsence: Bool {
        switch self {
        case .reportingFixtureUnavailable, .submittedInboxEmpty:
            true
        case .sampleNotFound, .noProject, .elementNotFound:
            false
        }
    }
}

