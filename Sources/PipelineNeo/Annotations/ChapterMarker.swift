//
//  ChapterMarker.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Chapter marker value type for FCPXML creation.
//

import Foundation
import CoreMedia

/// A chapter marker for navigation and chapters.
///
/// Produces FCPXML `<chapter-marker start="..." value="..." posterOffset="..." note="..."/>`.
///
/// This is a creation-oriented value type. For parsing chapter markers from existing FCPXML,
/// see `FinalCutPro.FCPXML.Marker` with `Configuration.chapter`.
@available(macOS 12.0, *)
public struct ChapterMarker: Sendable, Equatable, Hashable {

    /// Start time relative to parent.
    public let start: CMTime

    /// Chapter title.
    public let value: String

    /// Optional poster frame offset (relative to start).
    public let posterOffset: CMTime?

    /// Optional note.
    public let note: String?

    public init(
        start: CMTime,
        value: String,
        posterOffset: CMTime? = nil,
        note: String? = nil
    ) {
        self.start = start
        self.value = value
        self.posterOffset = posterOffset
        self.note = note
    }

    /// Builds the FCPXML `<chapter-marker>` element.
    public func xmlElement(factory: any PNXMLFactory = PNXMLDefaultFactory()) -> any PNXMLElement {
        let utility = FCPXMLUtility.defaultForExtensions
        let element = factory.makeElement(name: "chapter-marker")
        element.addSafeAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: start))
        element.addSafeAttribute(name: "value", value: value)
        if let posterOffset = posterOffset {
            element.addSafeAttribute(name: "posterOffset", value: utility.fcpxmlTime(fromCMTime: posterOffset))
        }
        if let note = note {
            element.addSafeAttribute(name: "note", value: note)
        }
        return element
    }
}
