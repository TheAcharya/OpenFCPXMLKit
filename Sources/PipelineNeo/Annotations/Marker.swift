//
//  Marker.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Timeline marker value type for FCPXML creation.
//

import Foundation
import CoreMedia

/// A marker that annotates a point or range on the timeline.
///
/// Produces FCPXML `<marker start="..." duration="..." value="..." note="..." completed="..."/>`.
///
/// This is a creation-oriented value type. For parsing markers from existing FCPXML,
/// see `FinalCutPro.FCPXML.Marker`.
@available(macOS 12.0, *)
public struct Marker: Sendable, Equatable, Hashable {

    /// Start time relative to parent (CMTime).
    public let start: CMTime

    /// Duration (e.g. one frame for point markers).
    public let duration: CMTime

    /// Display text.
    public let value: String

    /// Optional note.
    public let note: String?

    /// Whether marked completed (to-do style).
    public let completed: Bool

    /// Creates a marker.
    ///
    /// - Parameters:
    ///   - start: Start time.
    ///   - duration: Duration (default one frame at 24fps: 1/24s).
    ///   - value: Display text.
    ///   - note: Optional note.
    ///   - completed: Completed flag (default false).
    public init(
        start: CMTime,
        duration: CMTime = CMTime(value: 1, timescale: 24),
        value: String,
        note: String? = nil,
        completed: Bool = false
    ) {
        self.start = start
        self.duration = duration
        self.value = value
        self.note = note
        self.completed = completed
    }

    /// Builds the FCPXML `<marker>` element for this marker.
    public func xmlElement(factory: any PNXMLFactory = PNXMLDefaultFactory()) -> any PNXMLElement {
        let utility = FCPXMLUtility.defaultForExtensions
        let element = factory.makeElement(name: "marker")
        element.addSafeAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: start))
        element.addSafeAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: duration))
        element.addSafeAttribute(name: "value", value: value)
        if let note = note {
            element.addSafeAttribute(name: "note", value: note)
        }
        if completed {
            element.addSafeAttribute(name: "completed", value: "1")
        }
        return element
    }
}
