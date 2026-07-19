//
//  FCPXMLAuthoredSpineItems.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Detached spine story items (gap, title, transition, video, audio, compounds) + SpineItem.
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// Detached volume adjustment (`adjust-volume`).
    public struct VolumeAdjustment: Element, Hashable {
        /// Amount string as written in FCPXML (e.g. `"0dB"`, `"-3dB"`).
        public var amount: String

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(amount: String = "0dB") {
            self.amount = amount
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "adjust-volume")
            element.addAttribute(name: "amount", value: amount)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> VolumeAdjustment? {
            guard element.name == "adjust-volume" else { return nil }
            return VolumeAdjustment(
                amount: element.stringValue(forAttributeNamed: "amount") ?? "0dB"
            )
        }
    }

    /// Detached `<gap>`.
    public struct Gap: Element, Hashable {
        public var name: String?
        public var offset: String
        public var duration: String

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(offset: String, duration: String, name: String? = nil) {
            self.name = name
            self.offset = offset
            self.duration = duration
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "gap")
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Gap? {
            guard element.name == "gap",
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            return Gap(
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name")
            )
        }
    }

    /// Detached `<title>` (generator/title effect instance).
    public struct Title: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "title")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Title? {
            guard element.name == "title",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            return Title(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start")
            )
        }
    }

    /// Detached `<transition>`.
    public struct Transition: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "transition")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Transition? {
            guard element.name == "transition",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            return Transition(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name")
            )
        }
    }

    /// Detached `<video>` leaf.
    public struct Video: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        public var srcID: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            srcID: String? = nil
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.srcID = srcID
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "video")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let srcID { element.addAttribute(name: "srcID", value: srcID) }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Video? {
            guard element.name == "video",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            return Video(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                srcID: element.stringValue(forAttributeNamed: "srcID")
            )
        }
    }

    /// Detached `<audio>` leaf.
    public struct Audio: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        public var srcID: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            srcID: String? = nil
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.srcID = srcID
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "audio")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let srcID { element.addAttribute(name: "srcID", value: srcID) }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Audio? {
            guard element.name == "audio",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            return Audio(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                srcID: element.stringValue(forAttributeNamed: "srcID")
            )
        }
    }

    /// Polymorphic spine child for detached authoring.
    public indirect enum SpineItem: Element, Hashable {
        case assetClip(AssetClip)
        case gap(Gap)
        case title(Title)
        case transition(Transition)
        case video(Video)
        case audio(Audio)
        case caption(Caption)
        case syncClip(SyncClip)
        case refClip(RefClip)
        case mcClip(MCClip)
        case audition(Audition)

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            switch self {
            case .assetClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .gap(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .title(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .transition(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .video(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .audio(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .caption(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .syncClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .refClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .mcClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .audition(let value): try value.encodeIfAvailable(into: parent, context: context)
            }
        }

        static func decode(from element: any OFKXMLElement) -> SpineItem? {
            if let clip = AssetClip.decode(from: element) { return .assetClip(clip) }
            if let gap = Gap.decode(from: element) { return .gap(gap) }
            if let title = Title.decode(from: element) { return .title(title) }
            if let transition = Transition.decode(from: element) { return .transition(transition) }
            if let video = Video.decode(from: element) { return .video(video) }
            if let audio = Audio.decode(from: element) { return .audio(audio) }
            if let caption = Caption.decode(from: element) { return .caption(caption) }
            if let syncClip = SyncClip.decode(from: element) { return .syncClip(syncClip) }
            if let refClip = RefClip.decode(from: element) { return .refClip(refClip) }
            if let mcClip = MCClip.decode(from: element) { return .mcClip(mcClip) }
            if let audition = Audition.decode(from: element) { return .audition(audition) }
            return nil
        }
    }
}
