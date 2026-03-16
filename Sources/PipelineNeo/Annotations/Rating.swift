//
//  Rating.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Rating annotation value type for FCPXML creation.
//

import Foundation
import CoreMedia

/// A rating (favorite or rejected) for a clip or range.
///
/// Produces FCPXML `<rating start="..." duration="..." value="favorite|rejected" note="..."/>`.
@available(macOS 12.0, *)
public struct Rating: Sendable, Equatable, Hashable {

    /// Rating value.
    public enum RatingValue: String, Sendable, Equatable, Hashable, Codable {
        case favorite = "favorite"
        case rejected = "rejected"
    }

    /// Start of the rated range.
    public let start: CMTime

    /// Duration of the range.
    public let duration: CMTime

    /// Rating value.
    public let value: RatingValue

    /// Optional note.
    public let note: String?

    public init(
        start: CMTime,
        duration: CMTime,
        value: RatingValue,
        note: String? = nil
    ) {
        self.start = start
        self.duration = duration
        self.value = value
        self.note = note
    }

    /// Builds the FCPXML `<rating>` element.
    public func xmlElement(factory: any PNXMLFactory = PNXMLDefaultFactory()) -> any PNXMLElement {
        let utility = FCPXMLUtility.defaultForExtensions
        let element = factory.makeElement(name: "rating")
        element.addSafeAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: start))
        element.addSafeAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: duration))
        element.addSafeAttribute(name: "value", value: value.rawValue)
        if let note = note {
            element.addSafeAttribute(name: "note", value: note)
        }
        return element
    }
}
