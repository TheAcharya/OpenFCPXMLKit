//
// FCPXMLAuthoredCompoundClips.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Detached authoring types for sync-clip, ref-clip, mc-clip, audition, caption, and media.
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// Detached `<caption>`.
    public struct Caption: Element, Hashable {
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        public var lane: Int?
        public var role: String?
        public var note: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            lane: Int? = nil,
            role: String? = nil,
            note: String? = nil
        ) {
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.lane = lane
            self.role = role
            self.note = note
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "caption")
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let lane { element.addAttribute(name: "lane", value: String(lane)) }
            if let role { element.addAttribute(name: "role", value: role) }
            if let note {
                let noteElement = context.makeElement(name: "note")
                noteElement.stringValue = note
                element.addChild(noteElement)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Caption? {
            guard element.name == "caption",
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            let lane = element.stringValue(forAttributeNamed: "lane").flatMap(Int.init)
            let note = element.firstChildElement(named: "note")?.stringValue
            return Caption(
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                lane: lane,
                role: element.stringValue(forAttributeNamed: "role"),
                note: note
            )
        }
    }

    /// Detached `<mc-source>` on an `mc-clip`.
    public struct MCSource: Element, Hashable {
        public var angleID: String
        /// `all` | `audio` | `video` | `none` (DTD default `all`).
        public var srcEnable: String?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(angleID: String, srcEnable: String? = nil) {
            self.angleID = angleID
            self.srcEnable = srcEnable
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "mc-source")
            element.addAttribute(name: "angleID", value: angleID)
            if let srcEnable { element.addAttribute(name: "srcEnable", value: srcEnable) }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> MCSource? {
            guard element.name == "mc-source",
                  let angleID = element.stringValue(forAttributeNamed: "angleID")
            else {
                return nil
            }
            return MCSource(
                angleID: angleID,
                srcEnable: element.stringValue(forAttributeNamed: "srcEnable")
            )
        }
    }

    /// Detached `<sync-source>` on a `sync-clip`.
    public struct SyncSource: Element, Hashable {
        /// DTD: `storyline` | `connected`.
        public var sourceID: String

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(sourceID: String) {
            self.sourceID = sourceID
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "sync-source")
            element.addAttribute(name: "sourceID", value: sourceID)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> SyncSource? {
            guard element.name == "sync-source",
                  let sourceID = element.stringValue(forAttributeNamed: "sourceID")
            else {
                return nil
            }
            return SyncSource(sourceID: sourceID)
        }
    }

    /// Nested content allowed inside `<sync-clip>`.
    public indirect enum SyncClipContent: Element, Hashable {
        case spine(Spine)
        case item(SpineItem)

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            switch self {
            case .spine(let spine):
                try spine.encodeIfAvailable(into: parent, context: context)
            case .item(let item):
                try item.encodeIfAvailable(into: parent, context: context)
            }
        }

        static func decode(from element: any OFKXMLElement) -> SyncClipContent? {
            if element.name == "spine", let spine = try? Spine.decode(from: element) {
                return .spine(spine)
            }
            if let item = SpineItem.decode(from: element) {
                return .item(item)
            }
            return nil
        }
    }

    /// Detached `<sync-clip>`.
    public struct SyncClip: Element, Hashable {
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        public var formatID: String?
        public var audioStart: String?
        public var audioDuration: String?
        public var tcStart: String?
        public var tcFormat: String?
        public var contents: [SyncClipContent]
        public var syncSources: [SyncSource]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            formatID: String? = nil,
            audioStart: String? = nil,
            audioDuration: String? = nil,
            tcStart: String? = nil,
            tcFormat: String? = nil,
            contents: [SyncClipContent] = [],
            syncSources: [SyncSource] = []
        ) {
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.formatID = formatID
            self.audioStart = audioStart
            self.audioDuration = audioDuration
            self.tcStart = tcStart
            self.tcFormat = tcFormat
            self.contents = contents
            self.syncSources = syncSources
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "sync-clip")
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let formatID { element.addAttribute(name: "format", value: formatID) }
            if let audioStart { element.addAttribute(name: "audioStart", value: audioStart) }
            if let audioDuration { element.addAttribute(name: "audioDuration", value: audioDuration) }
            if let tcStart { element.addAttribute(name: "tcStart", value: tcStart) }
            if let tcFormat { element.addAttribute(name: "tcFormat", value: tcFormat) }
            for content in contents {
                try content.encodeIfAvailable(into: element, context: context)
            }
            for source in syncSources {
                try source.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> SyncClip? {
            guard element.name == "sync-clip",
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            let syncSources = element.childElements.compactMap { SyncSource.decode(from: $0) }
            let contents = element.childElements.compactMap { child -> SyncClipContent? in
                if child.name == "sync-source" { return nil }
                return SyncClipContent.decode(from: child)
            }
            return SyncClip(
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                formatID: element.stringValue(forAttributeNamed: "format"),
                audioStart: element.stringValue(forAttributeNamed: "audioStart"),
                audioDuration: element.stringValue(forAttributeNamed: "audioDuration"),
                tcStart: element.stringValue(forAttributeNamed: "tcStart"),
                tcFormat: element.stringValue(forAttributeNamed: "tcFormat"),
                contents: contents,
                syncSources: syncSources
            )
        }
    }

    /// Detached `<ref-clip>` referencing compound-clip `<media>`.
    public struct RefClip: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        /// `all` | `audio` | `video` (DTD default `all`).
        public var srcEnable: String?
        public var audioStart: String?
        public var audioDuration: String?
        public var useAudioSubroles: Bool?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            srcEnable: String? = nil,
            audioStart: String? = nil,
            audioDuration: String? = nil,
            useAudioSubroles: Bool? = nil
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.srcEnable = srcEnable
            self.audioStart = audioStart
            self.audioDuration = audioDuration
            self.useAudioSubroles = useAudioSubroles
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "ref-clip")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let srcEnable { element.addAttribute(name: "srcEnable", value: srcEnable) }
            if let audioStart { element.addAttribute(name: "audioStart", value: audioStart) }
            if let audioDuration { element.addAttribute(name: "audioDuration", value: audioDuration) }
            if let useAudioSubroles {
                element.addAttribute(name: "useAudioSubroles", value: useAudioSubroles ? "1" : "0")
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> RefClip? {
            guard element.name == "ref-clip",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            let useAudioSubroles: Bool?
            if let raw = element.stringValue(forAttributeNamed: "useAudioSubroles") {
                useAudioSubroles = raw == "1"
            } else {
                useAudioSubroles = nil
            }
            return RefClip(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                srcEnable: element.stringValue(forAttributeNamed: "srcEnable"),
                audioStart: element.stringValue(forAttributeNamed: "audioStart"),
                audioDuration: element.stringValue(forAttributeNamed: "audioDuration"),
                useAudioSubroles: useAudioSubroles
            )
        }
    }

    /// Detached `<mc-clip>` referencing multicam `<media>`.
    public struct MCClip: Element, Hashable {
        public var ref: String
        public var name: String?
        public var offset: String
        public var duration: String
        public var start: String?
        /// `all` | `audio` | `video` (DTD default `all`).
        public var srcEnable: String?
        public var audioStart: String?
        public var audioDuration: String?
        public var sources: [MCSource]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            ref: String,
            offset: String,
            duration: String,
            name: String? = nil,
            start: String? = nil,
            srcEnable: String? = nil,
            audioStart: String? = nil,
            audioDuration: String? = nil,
            sources: [MCSource] = []
        ) {
            self.ref = ref
            self.name = name
            self.offset = offset
            self.duration = duration
            self.start = start
            self.srcEnable = srcEnable
            self.audioStart = audioStart
            self.audioDuration = audioDuration
            self.sources = sources
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "mc-clip")
            element.addAttribute(name: "ref", value: ref)
            if let name { element.addAttribute(name: "name", value: name) }
            element.addAttribute(name: "offset", value: offset)
            element.addAttribute(name: "duration", value: duration)
            if let start { element.addAttribute(name: "start", value: start) }
            if let srcEnable { element.addAttribute(name: "srcEnable", value: srcEnable) }
            if let audioStart { element.addAttribute(name: "audioStart", value: audioStart) }
            if let audioDuration { element.addAttribute(name: "audioDuration", value: audioDuration) }
            for source in sources {
                try source.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> MCClip? {
            guard element.name == "mc-clip",
                  let ref = element.stringValue(forAttributeNamed: "ref"),
                  let offset = element.stringValue(forAttributeNamed: "offset"),
                  let duration = element.stringValue(forAttributeNamed: "duration")
            else {
                return nil
            }
            return MCClip(
                ref: ref,
                offset: offset,
                duration: duration,
                name: element.stringValue(forAttributeNamed: "name"),
                start: element.stringValue(forAttributeNamed: "start"),
                srcEnable: element.stringValue(forAttributeNamed: "srcEnable"),
                audioStart: element.stringValue(forAttributeNamed: "audioStart"),
                audioDuration: element.stringValue(forAttributeNamed: "audioDuration"),
                sources: element.childElements.compactMap { MCSource.decode(from: $0) }
            )
        }
    }

    /// Candidate story element inside an `<audition>`.
    public indirect enum AuditionCandidate: Element, Hashable {
        case assetClip(AssetClip)
        case video(Video)
        case audio(Audio)
        case title(Title)
        case refClip(RefClip)
        case syncClip(SyncClip)

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            switch self {
            case .assetClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .video(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .audio(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .title(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .refClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            case .syncClip(let value): try value.encodeIfAvailable(into: parent, context: context)
            }
        }

        static func decode(from element: any OFKXMLElement) -> AuditionCandidate? {
            if let clip = AssetClip.decode(from: element) { return .assetClip(clip) }
            if let video = Video.decode(from: element) { return .video(video) }
            if let audio = Audio.decode(from: element) { return .audio(audio) }
            if let title = Title.decode(from: element) { return .title(title) }
            if let refClip = RefClip.decode(from: element) { return .refClip(refClip) }
            if let syncClip = SyncClip.decode(from: element) { return .syncClip(syncClip) }
            return nil
        }
    }

    /// Detached `<audition>` (first child is the active candidate).
    public struct Audition: Element, Hashable {
        public var offset: String?
        public var lane: Int?
        public var candidates: [AuditionCandidate]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            offset: String? = nil,
            lane: Int? = nil,
            candidates: [AuditionCandidate] = []
        ) {
            self.offset = offset
            self.lane = lane
            self.candidates = candidates
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "audition")
            if let offset { element.addAttribute(name: "offset", value: offset) }
            if let lane { element.addAttribute(name: "lane", value: String(lane)) }
            for candidate in candidates {
                try candidate.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Audition? {
            guard element.name == "audition" else { return nil }
            let lane = element.stringValue(forAttributeNamed: "lane").flatMap(Int.init)
            return Audition(
                offset: element.stringValue(forAttributeNamed: "offset"),
                lane: lane,
                candidates: element.childElements.compactMap { AuditionCandidate.decode(from: $0) }
            )
        }
    }

    /// Detached `<mc-angle>` inside multicam media.
    public struct MCAngle: Element, Hashable {
        public var angleID: String
        public var name: String?
        public var items: [SpineItem]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(angleID: String, name: String? = nil, items: [SpineItem] = []) {
            self.angleID = angleID
            self.name = name
            self.items = items
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "mc-angle")
            element.addAttribute(name: "angleID", value: angleID)
            if let name { element.addAttribute(name: "name", value: name) }
            for item in items {
                try item.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> MCAngle? {
            guard element.name == "mc-angle",
                  let angleID = element.stringValue(forAttributeNamed: "angleID")
            else {
                return nil
            }
            return MCAngle(
                angleID: angleID,
                name: element.stringValue(forAttributeNamed: "name"),
                items: element.childElements.compactMap { SpineItem.decode(from: $0) }
            )
        }
    }

    /// Detached `<multicam>` content inside `<media>`.
    public struct Multicam: Element, Hashable {
        public var formatID: String
        public var duration: String?
        public var tcStart: String?
        public var tcFormat: String?
        public var angles: [MCAngle]

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            formatID: String,
            duration: String? = nil,
            tcStart: String? = nil,
            tcFormat: String? = nil,
            angles: [MCAngle] = []
        ) {
            self.formatID = formatID
            self.duration = duration
            self.tcStart = tcStart
            self.tcFormat = tcFormat
            self.angles = angles
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "multicam")
            element.addAttribute(name: "format", value: formatID)
            if let duration { element.addAttribute(name: "duration", value: duration) }
            if let tcStart { element.addAttribute(name: "tcStart", value: tcStart) }
            if let tcFormat { element.addAttribute(name: "tcFormat", value: tcFormat) }
            for angle in angles {
                try angle.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Multicam? {
            guard element.name == "multicam",
                  let formatID = element.stringValue(forAttributeNamed: "format")
            else {
                return nil
            }
            return Multicam(
                formatID: formatID,
                duration: element.stringValue(forAttributeNamed: "duration"),
                tcStart: element.stringValue(forAttributeNamed: "tcStart"),
                tcFormat: element.stringValue(forAttributeNamed: "tcFormat"),
                angles: element.childElements.compactMap { MCAngle.decode(from: $0) }
            )
        }
    }

    /// Detached compound-clip `<sequence>` inside `<media>` (not a project sequence).
    public struct MediaSequence: Element, Hashable {
        public var formatID: String
        public var duration: String?
        public var tcStart: String?
        public var tcFormat: String?
        public var spine: Spine

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            formatID: String,
            duration: String? = nil,
            tcStart: String? = nil,
            tcFormat: String? = nil,
            spine: Spine = Spine()
        ) {
            self.formatID = formatID
            self.duration = duration
            self.tcStart = tcStart
            self.tcFormat = tcFormat
            self.spine = spine
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "sequence")
            element.addAttribute(name: "format", value: formatID)
            if let duration { element.addAttribute(name: "duration", value: duration) }
            if let tcStart { element.addAttribute(name: "tcStart", value: tcStart) }
            if let tcFormat { element.addAttribute(name: "tcFormat", value: tcFormat) }
            try spine.encodeIfAvailable(into: element, context: context)
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> MediaSequence? {
            guard element.name == "sequence",
                  let formatID = element.stringValue(forAttributeNamed: "format")
            else {
                return nil
            }
            let spine = element.firstChildElement(named: "spine").flatMap { try? Spine.decode(from: $0) } ?? Spine()
            return MediaSequence(
                formatID: formatID,
                duration: element.stringValue(forAttributeNamed: "duration"),
                tcStart: element.stringValue(forAttributeNamed: "tcStart"),
                tcFormat: element.stringValue(forAttributeNamed: "tcFormat"),
                spine: spine
            )
        }
    }

    /// Content of a `<media>` resource.
    public enum MediaContent: Element, Hashable {
        case sequence(MediaSequence)
        case multicam(Multicam)

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            switch self {
            case .sequence(let sequence):
                try sequence.encodeIfAvailable(into: parent, context: context)
            case .multicam(let multicam):
                try multicam.encodeIfAvailable(into: parent, context: context)
            }
        }

        static func decode(from element: any OFKXMLElement) -> MediaContent? {
            if let sequence = MediaSequence.decode(from: element) { return .sequence(sequence) }
            if let multicam = Multicam.decode(from: element) { return .multicam(multicam) }
            return nil
        }
    }

    /// Detached `<media>` resource (compound clip or multicam).
    public struct Media: Element, Hashable {
        public var id: String
        public var name: String?
        public var uid: String?
        public var content: MediaContent?

        public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

        public init(
            id: String,
            name: String? = nil,
            uid: String? = nil,
            content: MediaContent? = nil
        ) {
            self.id = id
            self.name = name
            self.uid = uid
            self.content = content
        }

        public func encode(into parent: any OFKXMLElement, context: Context) throws {
            let element = context.makeElement(name: "media")
            element.addAttribute(name: "id", value: id)
            if let name { element.addAttribute(name: "name", value: name) }
            if let uid { element.addAttribute(name: "uid", value: uid) }
            if let content {
                try content.encodeIfAvailable(into: element, context: context)
            }
            parent.addChild(element)
        }

        static func decode(from element: any OFKXMLElement) -> Media? {
            guard element.name == "media",
                  let id = element.stringValue(forAttributeNamed: "id")
            else {
                return nil
            }
            let content = element.childElements.compactMap { MediaContent.decode(from: $0) }.first
            return Media(
                id: id,
                name: element.stringValue(forAttributeNamed: "name"),
                uid: element.stringValue(forAttributeNamed: "uid"),
                content: content
            )
        }
    }
}
