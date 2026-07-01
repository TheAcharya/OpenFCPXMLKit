//
//  CutDetector.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of CutDetection: finds edit points on a spine and classifies them by boundary type and source relationship.
//	

import Foundation

/// Default implementation of `CutDetection`.
@available(macOS 26.0, *)
public final class CutDetector: CutDetection, Sendable {

    public init() {}

    // MARK: - CutDetection (Sync)

    public func detectCuts(in document: any OFKXMLDocument) -> CutDetectionResult {
        guard let spine = _firstProjectSpine(in: document) else {
            return .empty
        }
        return detectCuts(inSpine: spine)
    }

    public func detectCuts(inSpine spine: any OFKXMLElement) -> CutDetectionResult {
        _detectCuts(inSpine: spine)
    }

    // MARK: - CutDetection (Async)

    public func detectCuts(in document: any OFKXMLDocument) async -> CutDetectionResult {
        guard let spine = _firstProjectSpine(in: document) else { return .empty }
        return _detectCuts(inSpine: spine)
    }

    public func detectCuts(inSpine spine: any OFKXMLElement) async -> CutDetectionResult {
        _detectCuts(inSpine: spine)
    }

    // MARK: - Private

    private func _firstProjectSpine(in document: any OFKXMLDocument) -> (any OFKXMLElement)? {
        guard let root = document.rootElement(), root.name == "fcpxml" else { return nil }
        guard let project = _firstProjectUnder(root) else { return nil }
        return project.fcpxProjectSpine
    }

    private func _firstProjectUnder(_ element: any OFKXMLElement) -> (any OFKXMLElement)? {
        if element.fcpxType == .project { return element }
        for child in element.childElements {
            if let found = _firstProjectUnder(child) { return found }
        }
        return nil
    }

    private func _detectCuts(inSpine spine: any OFKXMLElement) -> CutDetectionResult {
        let storyElements = Array(spine.fcpStoryElements)
        guard storyElements.count >= 2 else { return .empty }

        let clipIndices = storyElements.indices.filter { storyElements[$0].fcpxRef != nil }
        guard clipIndices.count >= 2 else { return .empty }

        var editPoints: [EditPoint] = []
        for k in 0 ..< clipIndices.count - 1 {
            let outIdx = clipIndices[k]
            let inIdx = clipIndices[k + 1]
            let outgoing = storyElements[outIdx]
            let incoming = storyElements[inIdx]

            let editType: EditPoint.EditType
            let transitionName: String?
            
            // Check if clips are directly adjacent (no elements between them)
            if inIdx == outIdx + 1 {
                // Clips are adjacent - hard cut with no transition or gap
                editType = .hardCut
                transitionName = nil
            } else {
                // There are elements between the clips - check all of them
                // Elements between clips are in the range (outIdx + 1)..<inIdx
                let elementsBetween = Array(storyElements[(outIdx + 1)..<inIdx])
                
                // Prioritize transitions over gaps (if both exist, it's a transition)
                let transition = elementsBetween.first { $0.fcpxType == .transition }
                let gap = elementsBetween.first { $0.fcpxType == .gap }
                
                if let transition = transition {
                    editType = .transition
                    transitionName = transition.fcpxName ?? transition.getElementAttribute("name")
                } else if gap != nil {
                    editType = .gapCut
                    transitionName = nil
                } else {
                    // No transition or gap found - hard cut
                    editType = .hardCut
                    transitionName = nil
                }
            }

            let timelineOffset = incoming.getElementAttribute("offset") ?? "0s"
            let outRef = outgoing.fcpxRef
            let inRef = incoming.fcpxRef
            let sourceRelationship: EditPoint.SourceRelationship =
                (outRef != nil && inRef != nil && outRef == inRef) ? .sameClip : .differentClips

            let point = EditPoint(
                index: editPoints.count,
                timelineOffset: timelineOffset,
                editType: editType,
                sourceRelationship: sourceRelationship,
                transitionName: transitionName,
                outgoingClipName: outgoing.fcpxName,
                incomingClipName: incoming.fcpxName,
                outgoingClipRef: outRef,
                incomingClipRef: inRef
            )
            editPoints.append(point)
        }
        return CutDetectionResult(editPoints: editPoints)
    }
}
