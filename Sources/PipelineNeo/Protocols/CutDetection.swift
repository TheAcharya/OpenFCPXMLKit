//
//  CutDetection.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
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
@available(macOS 12.0, *)
public protocol CutDetection: Sendable {

    /// Detects all edit points in the first project spine found in the document.
    /// - Parameter document: Parsed FCPXML document.
    /// - Returns: Result with edit points and counts.
    func detectCuts(in document: any PNXMLDocument) -> CutDetectionResult

    /// Detects all edit points in the first project spine found in the document (async).
    func detectCuts(in document: any PNXMLDocument) async -> CutDetectionResult

    /// Detects all edit points in the given spine element.
    /// - Parameter spine: An FCPXML `spine` PNXMLElement.
    /// - Returns: Result with edit points and counts.
    func detectCuts(inSpine spine: any PNXMLElement) -> CutDetectionResult

    /// Detects all edit points in the given spine element (async).
    func detectCuts(inSpine spine: any PNXMLElement) async -> CutDetectionResult
}
