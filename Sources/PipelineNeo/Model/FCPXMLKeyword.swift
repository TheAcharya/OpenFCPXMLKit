//
//  FCPXMLKeyword.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Keyword element model for the parsing layer.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Represents a keyword.
    public struct Keyword: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .keyword

        public static let supportedElementTypes: Set<ElementType> = [.keyword]

        public init() {
            element = PNXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }

        public init?(element: any PNXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
    }
}

// MARK: - Parameterized init

extension FinalCutPro.FCPXML.Keyword {
    public init(
        keywords: [String],
        start: Fraction,
        duration: Fraction? = nil,
        note: String? = nil
    ) {
        self.init()
        
        self.keywords = keywords
        self.start = start
        self.duration = duration
        self.note = note
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Keyword {
    public enum Attributes: String {
        // Element-Specific Attributes
        case start
        case duration
        case value // comma-separated list of keywords, required
        case note
    }
    
    // no children
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Keyword {
    /// Keywords.
    /// Internally this is stored in the XML as a comma-separated list.
    public var keywords: [String] {
        get {
            element.fcpValue?
                .split(separator: ",")
                .map { String($0) }
            ?? []
        }
        nonmutating set {
            if newValue.isEmpty {
                element.fcpValue = nil
            } else {
                element.fcpValue = newValue.joined(separator: ",")
            }
        }
    }
    
    /// Optional note.
    public var note: String? {
        get { element.fcpNote }
        nonmutating set { element.fcpNote = newValue }
    }
}

extension FinalCutPro.FCPXML.Keyword: FCPXMLElementRequiredStart { }

extension FinalCutPro.FCPXML.Keyword: FCPXMLElementOptionalDuration { }

// MARK: - Typing

// Keyword
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Keyword`` model object.
    /// Call this on a `keyword` element only.
    public var fcpAsKeyword: FinalCutPro.FCPXML.Keyword? {
        .init(element: self)
    }
}

// MARK: - Helpers

extension FinalCutPro.FCPXML.Keyword {
    func absoluteRangeAsTimecode(
        breadcrumbs: [any PNXMLElement]? = nil,
        resources: (any PNXMLElement)? = nil
    ) -> ClosedRange<Timecode>? {
        // find nearest timeline and determine its absolute start timecode
        guard let (timeline, timelineAncestors) = element.fcpAncestorTimeline(
            ancestors: breadcrumbs,
            includingSelf: true
        )
        else { return nil }
        
        return absoluteRangeAsTimecode(
            timeline: timeline,
            timelineAncestors: timelineAncestors,
            resources: resources
        )
    }
    
    func absoluteRangeAsTimecode(
        timeline: any PNXMLElement,
        timelineAncestors: AnySequence<any PNXMLElement>,
        resources: (any PNXMLElement)? = nil
    ) -> ClosedRange<Timecode>? {
        guard let kwAbsStart = element._fcpCalculateAbsoluteStart(
            ancestors: [timeline] + timelineAncestors,
            resources: resources
        ),
              let kwAbsStartTimecode = try? element._fcpTimecode(
                fromRealTime: kwAbsStart,
                frameRateSource: .mainTimeline,
                breadcrumbs: [timeline] + timelineAncestors,
                resources: resources
              ),
              let kwDuration = durationAsTimecode()
        else { return nil }
        
        let lbound = kwAbsStartTimecode
        let ubound = lbound + kwDuration
        
        return lbound ... ubound
    }
}

// MARK: - Collection Methods

extension Collection where Element == FinalCutPro.FCPXML.Keyword {
    /// Flattens a collection of keywords by removing duplicates and sorting.
    public func flattenedKeywords() -> [String] {
        flatMap(\.keywords)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removingDuplicates()
            .sorted()
    }
}
