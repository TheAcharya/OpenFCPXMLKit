//
//  FCPXMLAuthoringError.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Errors for detached authoring encode/decode.
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// Errors raised while building or parsing authored FCPXML value graphs.
    public enum Error: Swift.Error, LocalizedError, Sendable, Equatable {
        case missingRootElement
        case invalidRootName(String)
        case missingOrInvalidVersion(String?)
        case missingResources
        case missingLibrary
        case missingProject
        case missingSequence
        case missingSpine

        public var errorDescription: String? {
            switch self {
            case .missingRootElement:
                return "Authored document has no root element."
            case .invalidRootName(let name):
                return "Expected root element 'fcpxml', found '\(name)'."
            case .missingOrInvalidVersion(let value):
                return "Missing or unsupported FCPXML version attribute: \(value ?? "nil")."
            case .missingResources:
                return "Authored document is missing a resources element."
            case .missingLibrary:
                return "Authored document is missing a library element."
            case .missingProject:
                return "Authored library/event is missing a project element."
            case .missingSequence:
                return "Authored project is missing a sequence element."
            case .missingSpine:
                return "Authored sequence is missing a spine element."
            }
        }
    }
}
