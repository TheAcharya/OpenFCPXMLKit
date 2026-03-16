//
//  Keyword.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Keyword annotation value type for FCPXML creation.
//

import Foundation
import CoreMedia

/// A keyword tagging a clip or range.
///
/// Produces FCPXML `<keyword start="..." duration="..." value="..." note="..."/>`.
///
/// This is a creation-oriented value type. For parsing keywords from existing FCPXML,
/// see `FinalCutPro.FCPXML.Keyword`.
@available(macOS 12.0, *)
public struct Keyword: Sendable, Equatable, Hashable {

    /// Start of the keyword range.
    public let start: CMTime

    /// Duration of the range.
    public let duration: CMTime

    /// Keyword tag name.
    public let value: String

    /// Optional note.
    public let note: String?

    public init(
        start: CMTime,
        duration: CMTime,
        value: String,
        note: String? = nil
    ) {
        self.start = start
        self.duration = duration
        self.value = value
        self.note = note
    }

    /// Builds the FCPXML `<keyword>` element.
    public func xmlElement(factory: any PNXMLFactory = PNXMLDefaultFactory()) -> any PNXMLElement {
        let utility = FCPXMLUtility.defaultForExtensions
        let element = factory.makeElement(name: "keyword")
        element.addSafeAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: start))
        element.addSafeAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: duration))
        element.addSafeAttribute(name: "value", value: value)
        if let note = note {
            element.addSafeAttribute(name: "note", value: note)
        }
        return element
    }
}
