//
//  FCPXMLParseError.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Parse error enum for the FinalCutPro FCPXML parsing layer.
//

import Foundation

@available(macOS 26.0, *)
extension FinalCutPro.FCPXML {
    /// Final Cut Pro FCPXML file parsing error.
    public enum ParseError: Error, LocalizedError, Sendable {
        case general(String)
        
        public var errorDescription: String? {
            switch self {
            case .general(let message): return "FCPXML parse error: \(message)"
            }
        }
    }
}
