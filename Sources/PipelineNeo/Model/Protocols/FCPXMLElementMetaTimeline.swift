//
//  FCPXMLElementMetaTimeline.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for timeline and pseudo-timeline elements.
//

import Foundation
import SwiftExtensions
import SwiftTimecode

/// A meta protocol that all timeline and pseudo-timeline elements conform to.
///
/// This provides properties that can intelligently infer common properties such as timeline start
/// timecode or duration timecode.
public protocol FCPXMLElementMetaTimeline: FCPXMLElement {
    /// Returns the timeline model wrapped in a type-erased ``FinalCutPro/FCPXML/AnyTimeline`` instance.
    func asAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline
}

extension FCPXMLElementMetaTimeline {
    /// Returns the timeline's name.
    public var timelineName: String? {
        element.fcpName
    }
    
    /// Returns the timeline's local start as timecode.
    public func timelineStartAsTimecode() -> Timecode? {
        element._fcpTimelineStartAsTimecode()
    }
    
    /// Returns the timeline's local duration as timecode.
    public func timelineDurationAsTimecode() -> Timecode? {
        element._fcpTimelineDurationAsTimecode()
    }
}

// MARK: - XML Helpers

extension PNXMLElement {
    func _fcpTimelineStartAsTimecode() -> Timecode? {
        // Note: not fully tested for every timeline type; may need per-type handling.
        
        // check for parent project if local timeline is a sequence or spine
        if let fcpElementType,
           fcpElementType == .spine,
           let parent = parentElement,
           parent.fcpElementType == .sequence,
           var sequenceStart = parent._fcpTimelineStartAsTimecode()
        {
            if let offset = parent.fcpOffset {
                try? sequenceStart.add(.rational(offset))
            }
            return sequenceStart
        }
        
        // check for local `tcstart` or `start` attribute
        if let localTC = _fcpTCStartAsTimecode(frameRateSource: .localToElement)
            ?? _fcpStartAsTimecode(frameRateSource: .localToElement, default: nil)
        {
            return localTC
        }
        
        // check for local `offset` attribute, which transition uses
        if let fcpElementType,
           fcpElementType == .transition,
           let localOffset = _fcpOffsetAsTimecode(frameRateSource: .localToElement, default: nil)
        {
            return localOffset
        }
        
        // cascade to inner resource timelines which may be necessary for clips like `ref-clip`
        return fcpResource()?
            ._fcpFirstChildTimelineElement()?
            .fcpAsAnyTimeline?
            .timelineStartAsTimecode()
    }
    
    /// Returns the timeline's local duration as timecode.
    /// Should only be used on elements that are timelines.
    func _fcpTimelineDurationAsTimecode() -> Timecode? {
        if let localTC = _fcpDurationAsTimecode(frameRateSource: .localToElement) {
            return localTC
        }
        
        // cascade to inner timelines which may be necessary for clips like `ref-clip`
        return fcpResource()?
            ._fcpFirstChildTimelineElement()?
            .fcpAsAnyTimeline?
            .timelineDurationAsTimecode()
    }
}
