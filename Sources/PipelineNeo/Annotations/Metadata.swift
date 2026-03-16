//
//  Metadata.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Custom metadata key-value pair value type for FCPXML creation.
//

import Foundation

/// Container for custom metadata key-value pairs attachable to clips and resources.
///
/// FCPXML represents these as `<metadata>` with child `<md key="..." value="..."/>` elements.
///
/// ## Common keys
///
/// - `com.apple.proapps.studio.reel` – Reel number
/// - `com.apple.proapps.studio.scene` – Scene number
/// - `com.apple.proapps.studio.take` – Take number
/// - `com.apple.proapps.spotlight.kMDItemDescription` – Description
@available(macOS 12.0, *)
public struct Metadata: Sendable, Equatable, Hashable, Codable {

    /// Key-value entries.
    public var entries: [String: String]

    public init() {
        self.entries = [:]
    }

    public init(entries: [String: String]) {
        self.entries = entries
    }

    /// Access by key.
    public subscript(key: String) -> String? {
        get { entries[key] }
        set { entries[key] = newValue }
    }

    /// Whether there are no entries.
    public var isEmpty: Bool {
        entries.isEmpty
    }

    /// Builds the FCPXML `<metadata>` element with child `<md key="..." value="..."/>` elements.
    public func xmlElement(factory: any PNXMLFactory = PNXMLDefaultFactory()) -> any PNXMLElement {
        let element = factory.makeElement(name: "metadata")
        for key in entries.keys.sorted() {
            guard let value = entries[key] else { continue }
            let md = factory.makeElement(name: "md")
            md.addSafeAttribute(name: "key", value: key)
            md.addSafeAttribute(name: "value", value: value)
            element.addChild(md)
        }
        return element
    }
}

// MARK: - Common keys

@available(macOS 12.0, *)
extension Metadata {

    /// Common FCPXML metadata key constants.
    public enum Key {
        public static let reel = "com.apple.proapps.studio.reel"
        public static let scene = "com.apple.proapps.studio.scene"
        public static let take = "com.apple.proapps.studio.take"
        public static let description = "com.apple.proapps.spotlight.kMDItemDescription"
        public static let cameraName = "com.apple.proapps.studio.cameraName"
        public static let cameraAngle = "com.apple.proapps.studio.cameraAngle"
        public static let shotType = "com.apple.proapps.studio.shotType"
    }

    public mutating func setReel(_ value: String) { self[Key.reel] = value }
    public mutating func setScene(_ value: String) { self[Key.scene] = value }
    public mutating func setTake(_ value: String) { self[Key.take] = value }
    public mutating func setDescription(_ value: String) { self[Key.description] = value }
    public mutating func setCameraName(_ value: String) { self[Key.cameraName] = value }
    public mutating func setCameraAngle(_ value: String) { self[Key.cameraAngle] = value }
    public mutating func setShotType(_ value: String) { self[Key.shotType] = value }
}
