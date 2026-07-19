//
//  FCPXMLAuthoredResources.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Detached resource value types for authoring (format, asset, media-rep).
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// Detached `<format>` resource.
    public struct Format: Element, Hashable {
        public var id: String
        public var name: String?
        public var frameDuration: String
        public var width: Int
        public var height: Int
        public var colorSpace: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            id: String,
            frameDuration: String,
            width: Int,
            height: Int,
            name: String? = nil,
            colorSpace: String? = nil
        ) {
            self.id = id
            self.name = name
            self.frameDuration = frameDuration
            self.width = width
            self.height = height
            self.colorSpace = colorSpace
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "format")
            element.addAttribute(name: "id", value: id)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "frameDuration", value: frameDuration)
            element.addAttribute(name: "width", value: String(width))
            element.addAttribute(name: "height", value: String(height))
            if let colorSpace { element.addAttribute(name: "colorSpace", value: colorSpace) }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Format? {
            guard element.name == "format",
                  let id = element.stringValue(forAttributeNamed: "id"),
                  let frameDuration = element.stringValue(forAttributeNamed: "frameDuration"),
                  let width = Int(element.stringValue(forAttributeNamed: "width") ?? ""),
                  let height = Int(element.stringValue(forAttributeNamed: "height") ?? "")
            else {
                return nil
            }
            return Format(
                id: id,
                frameDuration: frameDuration,
                width: width,
                height: height,
                name: element.stringValue(forAttributeNamed: "name"),
                colorSpace: element.stringValue(forAttributeNamed: "colorSpace")
            )
        }
    }

    /// Detached `<media-rep>` under an asset.
    public struct MediaRep: Element, Hashable {
        public var kind: String
        public var src: String

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(kind: String = "original-media", src: String) {
            self.kind = kind
            self.src = src
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "media-rep")
            element.addAttribute(name: "kind", value: kind)
            element.addAttribute(name: "src", value: src)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> MediaRep? {
            guard element.name == "media-rep",
                  let src = element.stringValue(forAttributeNamed: "src")
            else {
                return nil
            }
            return MediaRep(
                kind: element.stringValue(forAttributeNamed: "kind") ?? "original-media",
                src: src
            )
        }
    }

    /// Detached `<asset>` resource.
    public struct Asset: Element, Hashable {
        public var id: String
        public var name: String?
        public var hasVideo: Bool
        public var hasAudio: Bool
        public var duration: String?
        public var formatID: String?
        public var mediaReps: [MediaRep]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            id: String,
            name: String? = nil,
            hasVideo: Bool = true,
            hasAudio: Bool = false,
            duration: String? = nil,
            formatID: String? = nil,
            mediaReps: [MediaRep] = []
        ) {
            self.id = id
            self.name = name
            self.hasVideo = hasVideo
            self.hasAudio = hasAudio
            self.duration = duration
            self.formatID = formatID
            self.mediaReps = mediaReps
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "asset")
            element.addAttribute(name: "id", value: id)
            if let name { element.addAttribute(name: "name", value: name) }
            if hasVideo { element.addAttribute(name: "hasVideo", value: "1") }
            if hasAudio { element.addAttribute(name: "hasAudio", value: "1") }
            if let duration { element.addAttribute(name: "duration", value: duration) }
            if let formatID { element.addAttribute(name: "format", value: formatID) }
            for rep in mediaReps {
                try rep.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Asset? {
            guard element.name == "asset",
                  let id = element.stringValue(forAttributeNamed: "id")
            else {
                return nil
            }
            let reps = element.childElements.compactMap { MediaRep.decode(from: $0) }
            return Asset(
                id: id,
                name: element.stringValue(forAttributeNamed: "name"),
                hasVideo: (element.stringValue(forAttributeNamed: "hasVideo") ?? "0") == "1",
                hasAudio: (element.stringValue(forAttributeNamed: "hasAudio") ?? "0") == "1",
                duration: element.stringValue(forAttributeNamed: "duration"),
                formatID: element.stringValue(forAttributeNamed: "format"),
                mediaReps: reps
            )
        }
    }

    /// Detached `<effect>` resource (titles, transitions, filters).
    public struct Effect: Element, Hashable {
        public var id: String
        public var name: String?
        public var uid: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(id: String, name: String? = nil, uid: String? = nil) {
            self.id = id
            self.name = name
            self.uid = uid
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "effect")
            element.addAttribute(name: "id", value: id)
            if let name { element.addAttribute(name: "name", value: name) }
            if let uid { element.addAttribute(name: "uid", value: uid) }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Effect? {
            guard element.name == "effect",
                  let id = element.stringValue(forAttributeNamed: "id")
            else {
                return nil
            }
            return Effect(
                id: id,
                name: element.stringValue(forAttributeNamed: "name"),
                uid: element.stringValue(forAttributeNamed: "uid")
            )
        }
    }

    /// Detached `<resources>` container.
    public struct Resources: Element, Hashable {
        public var formats: [Format]
        public var assets: [Asset]
        public var effects: [Effect]
        public var media: [Media]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            formats: [Format] = [],
            assets: [Asset] = [],
            effects: [Effect] = [],
            media: [Media] = []
        ) {
            self.formats = formats
            self.assets = assets
            self.effects = effects
            self.media = media
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "resources")
            for format in formats {
                try format.encodeIfAvailable(into: element, context: context)
            }
            for asset in assets {
                try asset.encodeIfAvailable(into: element, context: context)
            }
            for effect in effects {
                try effect.encodeIfAvailable(into: element, context: context)
            }
            for mediaResource in media {
                try mediaResource.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Resources? {
            guard element.name == "resources" else { return nil }
            return Resources(
                formats: element.childElements.compactMap { Format.decode(from: $0) },
                assets: element.childElements.compactMap { Asset.decode(from: $0) },
                effects: element.childElements.compactMap { Effect.decode(from: $0) },
                media: element.childElements.compactMap { Media.decode(from: $0) }
            )
        }
    }
}
