//
//  FCPXMLAuthoredStory.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Detached story value types for authoring (library → asset-clip).
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// Detached cinematic adjustment (`adjust-cinematic`, FCPXML 1.10+).
    ///
    /// Omitted automatically when encoding to versions before 1.10.
    public struct CinematicAdjustment: Element, Hashable {
        public var isEnabled: Bool
        public var aperture: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability {
            FinalCutPro.FCPXML.VersionFeatureGate.availability(forElement: "adjust-cinematic")
        }

        public init(isEnabled: Bool = true, aperture: String? = nil) {
            self.isEnabled = isEnabled
            self.aperture = aperture
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "adjust-cinematic")
            if !isEnabled {
                element.addAttribute(name: "enabled", value: "0")
            }
            if let aperture {
                element.addAttribute(name: "aperture", value: aperture)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> CinematicAdjustment? {
            guard element.name == "adjust-cinematic" else { return nil }
            let enabled = (element.stringValue(forAttributeNamed: "enabled") ?? "1") == "1"
            return CinematicAdjustment(
                isEnabled: enabled,
                aperture: element.stringValue(forAttributeNamed: "aperture")
            )
        }
    }

    /// Detached `<asset-clip>` on a spine or lane.
    public struct AssetClip: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        public var audioStart: String?
        public var audioDuration: String?
        public var cinematic: CinematicAdjustment?
        public var volume: VolumeAdjustment?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            audioStart: String? = nil,
            audioDuration: String? = nil,
            cinematic: CinematicAdjustment? = nil,
            volume: VolumeAdjustment? = nil
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.audioStart = audioStart
            self.audioDuration = audioDuration
            self.cinematic = cinematic
            self.volume = volume
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "asset-clip")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let audioStart { element.addAttribute(name: "audioStart", value: audioStart) }
            if let audioDuration { element.addAttribute(name: "audioDuration", value: audioDuration) }
            if let cinematic {
                try cinematic.encodeIfAvailable(into: element, context: context)
            }
            if let volume {
                try volume.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> AssetClip? {
            guard element.name == "asset-clip",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            let cinematic = element.childElements
                .compactMap { CinematicAdjustment.decode(from: $0) }
                .first
            let volume = element.childElements
                .compactMap { VolumeAdjustment.decode(from: $0) }
                .first
            return AssetClip(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                audioStart: element.stringValue(forAttributeNamed: "audioStart"),
                audioDuration: element.stringValue(forAttributeNamed: "audioDuration"),
                cinematic: cinematic,
                volume: volume
            )
        }
    }

    /// Detached `<spine>`.
    public struct Spine: Element, Hashable {
        /// Ordered spine children (asset-clip, gap, title, transition, video, audio, …).
        public var items: [SpineItem]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(items: [SpineItem] = []) {
            self.items = items
        }

        /// Convenience for spines that only contain asset-clips.
        public init(assetClips: [AssetClip]) {
            self.items = assetClips.map { .assetClip($0) }
        }

        /// Asset-clip children only (derived from ``items``).
        public var assetClips: [AssetClip] {
            items.compactMap {
                if case .assetClip(let clip) = $0 { return clip }
                return nil
            }
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "spine")
            for item in items {
                try item.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) throws -> Spine {
            guard element.name == "spine" else { throw Error.missingSpine }
            return Spine(
                items: element.childElements.compactMap { SpineItem.decode(from: $0) }
            )
        }
    }

    /// Detached `<sequence>`.
    public struct Sequence: Element, Hashable {
        public var formatID: String
        public var duration: String
        public var tcStart: String?
        public var spine: Spine

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            formatID: String,
            duration: String,
            tcStart: String? = "0s",
            spine: Spine = Spine()
        ) {
            self.formatID = formatID
            self.duration = duration
            self.tcStart = tcStart
            self.spine = spine
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "sequence")
            element.addAttribute(name: "format", value: formatID)
            element.addAttribute(name: "duration", value: duration)
            if let tcStart { element.addAttribute(name: "tcStart", value: tcStart) }
            try spine.encodeIfAvailable(into: element, context: context)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) throws -> Sequence {
            guard element.name == "sequence",
                  let formatID = element.stringValue(forAttributeNamed: "format"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                throw Error.missingSequence
            }
            guard let spineElement = element.firstChildElement(named: "spine") else {
                throw Error.missingSpine
            }
            return Sequence(
                formatID: formatID,
                duration: duration,
                tcStart: element.stringValue(forAttributeNamed: "tcStart"),
                spine: try Spine.decode(from: spineElement)
            )
        }
    }

    /// Detached `<project>`.
    public struct Project: Element, Hashable {
        public var name: String
        public var uid: String?
        public var sequence: Sequence

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(name: String, sequence: Sequence, uid: String? = nil) {
            self.name = name
            self.uid = uid
            self.sequence = sequence
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "project")
            element.addAttribute(name: "name", value: name)
            if let uid { element.addAttribute(name: "uid", value: uid) }
            try sequence.encodeIfAvailable(into: element, context: context)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) throws -> Project {
            guard element.name == "project",
                  let name = element.stringValue(forAttributeNamed: "name"),
                  let sequenceElement = element.firstChildElement(named: "sequence")
            else {
                throw Error.missingProject
            }
            return Project(
                name: name,
                sequence: try Sequence.decode(from: sequenceElement),
                uid: element.stringValue(forAttributeNamed: "uid")
            )
        }
    }

    /// Detached `<event>`.
    public struct Event: Element, Hashable {
        public var name: String
        public var uid: String?
        public var projects: [Project]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(name: String, projects: [Project] = [], uid: String? = nil) {
            self.name = name
            self.uid = uid
            self.projects = projects
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "event")
            element.addAttribute(name: "name", value: name)
            if let uid { element.addAttribute(name: "uid", value: uid) }
            for project in projects {
                try project.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) throws -> Event {
            guard element.name == "event",
                  let name = element.stringValue(forAttributeNamed: "name")
            else {
                throw Error.missingLibrary
            }
            let projects = try element.childElements
                .filter { $0.name == "project" }
                .map { try Project.decode(from: $0) }
            return Event(
                name: name,
                projects: projects,
                uid: element.stringValue(forAttributeNamed: "uid")
            )
        }
    }

    /// Detached `<library>`.
    public struct Library: Element, Hashable {
        public var location: String?
        public var events: [Event]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(events: [Event] = [], location: String? = nil) {
            self.location = location
            self.events = events
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "library")
            if let location { element.addAttribute(name: "location", value: location) }
            for event in events {
                try event.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) throws -> Library {
            guard element.name == "library" else { throw Error.missingLibrary }
            let events = try element.childElements
                .filter { $0.name == "event" }
                .map { try Event.decode(from: $0) }
            return Library(
                events: events,
                location: element.stringValue(forAttributeNamed: "location")
            )
        }
    }
}
