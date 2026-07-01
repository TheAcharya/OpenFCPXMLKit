//
//  EditPoint.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Single edit point (cut) on an FCPXML spine.
//

import Foundation

/// Represents one edit point (cut) between consecutive story elements on a spine.
///
/// An edit point can be classified by:
/// - **Boundary type**: hard cut, transition, or gap.
/// - **Source relationship**: cut between two different clips (different `ref`) or
///   cut on the same clip (same `ref`, two segments of one source).
@available(macOS 26.0, *)
public struct EditPoint: Sendable, Equatable {

    /// What sits at the boundary: hard cut, transition, or gap.
    public enum EditType: String, Sendable, Equatable {
        /// Two clips are directly adjacent with no transition.
        case hardCut
        /// A transition element (e.g. Cross Dissolve) sits between two clips.
        case transition
        /// A gap element separates two clips.
        case gapCut
    }

    /// Whether the cut is between two segments of the same source (same ref) or different sources (different ref).
    public enum SourceRelationship: String, Sendable, Equatable {
        /// Same ref on both sides — cut on the same clip (two segments of one source).
        case sameClip
        /// Different ref or one side has no ref — cut between two different clips.
        case differentClips
    }

    /// Zero-based index of this edit point in the spine.
    public let index: Int

    /// Timeline position of the edit point as an FCPXML time string (e.g. `"9216/12800s"`).
    public let timelineOffset: String

    /// Boundary type at this edit point.
    public let editType: EditType

    /// Whether the cut is on the same clip or between different clips.
    public let sourceRelationship: SourceRelationship

    /// Name of the transition, if `editType == .transition`.
    public let transitionName: String?

    /// Display name of the clip ending at this edit point.
    public let outgoingClipName: String?

    /// Display name of the clip starting after this edit point.
    public let incomingClipName: String?

    /// Resource ref of the outgoing clip (for same-clip detection).
    public let outgoingClipRef: String?

    /// Resource ref of the incoming clip (for same-clip detection).
    public let incomingClipRef: String?

    public init(
        index: Int,
        timelineOffset: String,
        editType: EditType,
        sourceRelationship: SourceRelationship,
        transitionName: String? = nil,
        outgoingClipName: String? = nil,
        incomingClipName: String? = nil,
        outgoingClipRef: String? = nil,
        incomingClipRef: String? = nil
    ) {
        self.index = index
        self.timelineOffset = timelineOffset
        self.editType = editType
        self.sourceRelationship = sourceRelationship
        self.transitionName = transitionName
        self.outgoingClipName = outgoingClipName
        self.incomingClipName = incomingClipName
        self.outgoingClipRef = outgoingClipRef
        self.incomingClipRef = incomingClipRef
    }
}
