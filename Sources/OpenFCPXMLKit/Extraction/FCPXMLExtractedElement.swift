//
//  FCPXMLExtractedElement.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for extracted elements with contextual properties.
//

import Foundation
import SwiftTimecode

/// Protocol for extracted elements that adds contextual properties.
public protocol FCPXMLExtractedElement where Self: Sendable {
    /// The extracted XML element.
    var element: any OFKXMLElement { get }

    /// XML breadcrumbs that were followed during the extraction process.
    ///
    /// This provides necessary element traversal history needed to infer context values
    /// that cannot be provided from the XML document layout.
    var breadcrumbs: [any OFKXMLElement] { get }

    /// Resources. If `nil`, resources will be acquired from the XML document.
    var resources: (any OFKXMLElement)? { get }

    /// Audition mask used when resolving inherited / local roles.
    var auditions: FinalCutPro.FCPXML.Audition.AuditionMask { get }

    /// Multicam angle mask used when resolving inherited / local roles.
    var mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask { get }
    
    /// Return the a context value for the element.
    func value<Value>(
        forContext contextKey: FinalCutPro.FCPXML.ElementContext<Value>
    ) -> Value
}

// MARK: - Default role masks

extension FCPXMLExtractedElement {
    public var auditions: FinalCutPro.FCPXML.Audition.AuditionMask { .active }
    public var mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask { .active }
}

// MARK: - Convenience Properties

extension FCPXMLExtractedElement {
    /// Absolute timecode position within the outermost timeline.
    public func timecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .mainTimeline
    ) -> Timecode? {
        value(forContext: .absoluteStartAsTimecode(frameRateSource: frameRateSource))
    }
    
    /// Duration expressed as a length of timecode.
    public func duration(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .mainTimeline
    ) -> Timecode? {
        guard let duration = element.fcpDuration else { return nil }
        return try? element._fcpTimecode(
            fromRational: duration,
            frameRateSource: frameRateSource,
            breadcrumbs: breadcrumbs,
            resources: resources
        )
    }
    
    /// Returns the nearest ancestor clip hosting this element.
    public func ancestorClipElement() -> (any OFKXMLElement)? {
        element.fcpAncestorClip(ancestors: breadcrumbs, includingSelf: false)
            ?? element.fcpAncestorClip(ancestors: breadcrumbs, includingSelf: true)
    }
    
    /// Context sliced to a specific clip for role and metadata resolution.
    public func extractedContext(
        forClip clip: any OFKXMLElement
    ) -> FinalCutPro.FCPXML.ExtractedElement {
        let clipBreadcrumbs: [any OFKXMLElement]
        if let index = breadcrumbs.firstIndex(where: { $0 === clip }) {
            clipBreadcrumbs = Array(breadcrumbs.dropFirst(index + 1))
        } else {
            clipBreadcrumbs = breadcrumbs
        }
        
        return FinalCutPro.FCPXML.ExtractedElement(
            element: clip,
            breadcrumbs: clipBreadcrumbs,
            resources: resources,
            auditions: auditions,
            mcClipAngles: mcClipAngles
        )
    }
    
    /// Context for the ancestor clip hosting this element.
    public func ancestorClipContext() -> FinalCutPro.FCPXML.ExtractedElement? {
        guard let clip = ancestorClipElement() else { return nil }
        return extractedContext(forClip: clip)
    }
    
    /// Timeline range for a keyword, clamped to the ancestor clip's visible main-timeline span.
    public func visibleKeywordRangeOnMainTimeline() -> (
        timelineIn: Timecode,
        timelineOut: Timecode,
        duration: Timecode
    )? {
        guard element.fcpElementType == .keyword,
              let clipContext = ancestorClipContext(),
              let keywordStart = timecode(),
              let keywordDuration = duration(frameRateSource: .mainTimeline)
        else { return nil }
        
        let keywordEnd = keywordStart + keywordDuration
        
        guard let clipStart = clipContext.timecode() else {
            return (keywordStart, keywordEnd, keywordDuration)
        }
        
        guard keywordEnd >= clipStart else { return nil }
        
        let visibleIn = max(keywordStart, clipStart)
        let visibleOut = visibleIn + keywordDuration
        
        return (visibleIn, visibleOut, keywordDuration)
    }
    
    /// Workbook-style clip name for this extracted element.
    public func displayClipName() -> String {
        FinalCutPro.FCPXML.DisplayClipName.name(for: self)
    }
    
    /// Clip element used when resolving effect role columns.
    public func effectHostClipElement() -> (any OFKXMLElement)? {
        if let elementType = element.fcpElementType,
           FinalCutPro.FCPXML.reportClipHostTypes.contains(elementType)
        {
            return element
        }
        return ancestorClipElement()
    }
    
    /// Inherited roles for the given display context.
    public func inheritedRoles(
        for context: FinalCutPro.FCPXML.RoleDisplayPreference.Context
    ) -> [FinalCutPro.FCPXML.AnyInterpolatedRole] {
        switch context {
        case .markers:
            if element.fcpElementType == .title {
                return value(forContext: .inheritedRoles)
            }
            return ancestorClipContext()?.value(forContext: .inheritedRoles) ?? []
        case .videoEffects, .audioEffects:
            guard let clip = effectHostClipElement() else { return [] }
            return extractedContext(forClip: clip).value(forContext: .inheritedRoles)
        }
    }
    
    /// Preferred inherited role for the given display context.
    public func preferredRole(
        for context: FinalCutPro.FCPXML.RoleDisplayPreference.Context,
        using preferences: FinalCutPro.FCPXML.RoleDisplayPreference = .builtIn
    ) -> FinalCutPro.FCPXML.AnyInterpolatedRole? {
        let roles = inheritedRoles(for: context)
        // Do not fall back to `roles.first` — that reintroduces cross-type picks
        // (e.g. Dialogue for a video filter) when the priority table misses.
        return preferences.preferredRole(from: roles, context: context)
    }
    
    /// Inherited roles from the ancestor clip hosting a keyword or annotation.
    public func keywordInheritedRoles() -> [FinalCutPro.FCPXML.AnyInterpolatedRole] {
        ancestorClipContext()?.value(forContext: .inheritedRoles) ?? []
    }
}

// MARK: - Sequence Methods

extension Sequence where Element: FCPXMLExtractedElement {
    /// Sort collection by absolute start timecode.
    public func sortedByAbsoluteStartTimecode(thenByName: Bool = true) -> [Element] {
        sorted { lhs, rhs in
            guard let lhsTimecode = lhs.timecode(),
                  let rhsTimecode = rhs.timecode()
            else {
                // sort by `start` attribute as fallback
                return lhs.element.fcpStart ?? .zero < rhs.element.fcpStart ?? .zero
            }
            
            if lhsTimecode == rhsTimecode, 
                thenByName,
               let lhsName = lhs.element.fcpName ?? lhs.element.fcpValue,
               let rhsName = rhs.element.fcpName ?? rhs.element.fcpValue
            {
                return lhsName.localizedStandardCompare(rhsName) == .orderedAscending
            } else {
                return lhsTimecode < rhsTimecode
            }
        }
    }
    
    /// Sort collection by element `name`.
    /// If no `name` attribute exists, the `value` attribute will be used.
    public func sortedByName() -> [Element] {
        sorted { lhs, rhs in
            if let lhsName = lhs.element.fcpName,
               let rhsName = rhs.element.fcpName
            {
                return lhsName.localizedStandardCompare(rhsName) == .orderedAscending
            }
            if let lhsValue = lhs.element.fcpValue,
               let rhsValue = rhs.element.fcpValue
            {
                return lhsValue.localizedStandardCompare(rhsValue) == .orderedAscending
            }
            return true
        }
    }
}
