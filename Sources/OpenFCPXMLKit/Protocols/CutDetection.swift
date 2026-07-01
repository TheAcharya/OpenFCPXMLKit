//
//  CutDetection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for detecting edit points (cuts) in FCPXML spines.
//

import Foundation

/// Detects edit points (cuts) in FCPXML documents or spines.
///
/// Each edit point is classified by boundary type (hard cut, transition, gap)
/// and by source relationship (same-clip cut vs different-clips cut).
@available(macOS 26.0, *)
public protocol CutDetection: Sendable {

    /// Detects all edit points in the first project spine found in the document.
    /// - Parameter document: Parsed FCPXML document.
    /// - Returns: Result with edit points and counts.
    func detectCuts(in document: any OFKXMLDocument) -> CutDetectionResult

    /// Detects all edit points in the first project spine found in the document (async).
    func detectCuts(in document: any OFKXMLDocument) async -> CutDetectionResult

    /// Detects all edit points in the given spine element.
    /// - Parameter spine: An FCPXML `spine` OFKXMLElement.
    /// - Returns: Result with edit points and counts.
    func detectCuts(inSpine spine: any OFKXMLElement) -> CutDetectionResult

    /// Detects all edit points in the given spine element (async).
    func detectCuts(inSpine spine: any OFKXMLElement) async -> CutDetectionResult
}
