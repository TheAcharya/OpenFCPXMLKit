//
//  CutDetectionResult.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Aggregate result of cut detection on an FCPXML spine.
//

import Foundation

/// Result of detecting edit points (cuts) on an FCPXML spine.
///
/// Provides counts by boundary type (hard cut, transition, gap) and by source
/// relationship (same-clip cuts vs different-clips cuts).
@available(macOS 26.0, *)
public struct CutDetectionResult: Sendable, Equatable {

    /// All detected edit points in spine order.
    public let editPoints: [EditPoint]

    /// Total number of edit points.
    public var totalEditPoints: Int { editPoints.count }

    /// Number of hard cuts (adjacent clips, no transition).
    public var hardCutCount: Int {
        editPoints.filter { $0.editType == .hardCut }.count
    }

    /// Number of edit points that have a transition.
    public var transitionCount: Int {
        editPoints.filter { $0.editType == .transition }.count
    }

    /// Number of edit points where a gap separates two clips.
    public var gapCutCount: Int {
        editPoints.filter { $0.editType == .gapCut }.count
    }

    /// Number of cuts between two segments of the same source clip (same ref).
    public var sameClipCutCount: Int {
        editPoints.filter { $0.sourceRelationship == .sameClip }.count
    }

    /// Number of cuts between two different clips (different ref).
    public var differentClipsCutCount: Int {
        editPoints.filter { $0.sourceRelationship == .differentClips }.count
    }

    public init(editPoints: [EditPoint]) {
        self.editPoints = editPoints
    }

    /// Result with no edit points.
    public static let empty = CutDetectionResult(editPoints: [])
}
