//
//  FCPXMLExporter.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Exports Timeline and assets to an FCPXML document string.
//

import Foundation
import CoreMedia

/// Helper for creating XML attributes safely via PNXMLElement protocol.
@available(macOS 12.0, *)
private extension PNXMLElement {
    func addStringAttribute(name attrName: String, value: String) {
        addAttribute(name: attrName, value: value)
    }
}

/// Errors that can occur during FCPXML export.
@available(macOS 12.0, *)
public enum FCPXMLExportError: Error, LocalizedError, Sendable {
    case missingFormat
    case missingAsset(assetId: String)
    case invalidTimeline(reason: String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .missingFormat: return "Missing format resource"
        case .missingAsset(let id): return "Missing asset resource: \(id)"
        case .invalidTimeline(let reason): return "Invalid timeline: \(reason)"
        case .cancelled: return "Export was cancelled"
        }
    }
}

/// Exports a Timeline and assets to FCPXML document string.
@available(macOS 12.0, *)
public struct FCPXMLExporter: Sendable {

    public var version: FCPXMLVersion
    private nonisolated(unsafe) let factory: any PNXMLFactory

    /// Format resource ID used in exported FCPXML. Must not collide with asset IDs.
    public static let formatResourceID = "r1"

    /// Creates a new exporter.
    /// - Parameters:
    ///   - version: FCPXML version (default: `.default`).
    ///   - factory: XML factory for creating documents and elements (default: `PNXMLDefaultFactory()`).
    public init(version: FCPXMLVersion = .default, factory: any PNXMLFactory = PNXMLDefaultFactory()) {
        self.version = version
        self.factory = factory
    }

    /// Exports the timeline to FCPXML string.
    ///
    /// Supports timelines with zero clips (empty spine). When clips are present, every `assetRef` must match an asset `id`.
    /// Event and project UIDs are generated when not provided so the document matches FCP-style identifiers.
    ///
    /// - Parameters:
    ///   - timeline: The timeline (clips reference `assetRef` matching `assets[].id`; may be empty).
    ///   - assets: Assets referenced by timeline clips. Required only when timeline has clips; each `id` must match a `TimelineClip.assetRef`.
    ///   - libraryName: Library element name.
    ///   - eventName: Event element name.
    ///   - projectName: Project name (default: timeline name).
    ///   - eventUid: Event `uid` attribute; if nil, a new FCPXML-style UID is generated.
    ///   - projectUid: Project `uid` attribute; if nil, a new FCPXML-style UID is generated.
    ///   - libraryLocation: Optional library `location` attribute (e.g. file URL of the library bundle).
    ///   - includeDefaultSmartCollections: If true, adds FCP-style default smart collections (Projects, All Video, Audio Only, Stills, Favorites) under the library.
    /// - Returns: FCPXML XML string.
    /// - Note: Asset IDs must not equal `FCPXMLExporter.formatResourceID` (`r1`).
    public func export(
        timeline: Timeline,
        assets: [FCPXMLExportAsset],
        libraryName: String = "Exported Library",
        eventName: String = "Exported Event",
        projectName: String? = nil,
        eventUid: String? = nil,
        projectUid: String? = nil,
        libraryLocation: String? = nil,
        includeDefaultSmartCollections: Bool = false
    ) throws -> String {
        let utility = FCPXMLUtility.defaultForExtensions
        let assetIds = Set(assets.map(\.id))

        if !timeline.clips.isEmpty {
            for clip in timeline.clips {
                if !assetIds.contains(clip.assetRef) {
                    throw FCPXMLExportError.missingAsset(assetId: clip.assetRef)
                }
            }
        }

        let format = timeline.format ?? .hd1080p(
            frameDuration: CMTime(value: 1001, timescale: 24000),
            colorSpace: .rec709
        )
        let formatID = Self.formatResourceID
        var resourceElements: [any PNXMLElement] = []

        // Format resource
        let formatEl = factory.makeElement(name: "format")
        formatEl.addStringAttribute(name: "id", value: formatID)
        let fps = 1.0 / CMTimeGetSeconds(format.frameDuration)
        let roundedFPS = Float(round(fps * 100) / 100)
        let formatName = utility.ffVideoFormat(
            fromWidth: format.width,
            height: format.height,
            frameRate: roundedFPS,
            isInterlaced: format.interlaced,
            isSD16x9: false
        )
        // Always set name: use the preset identifier when known, or FFVideoFormatRateUndefined for custom dimensions so FCP recognizes the format.
        formatEl.addStringAttribute(name: "name", value: formatName)
        formatEl.addStringAttribute(name: "frameDuration", value: utility.fcpxmlTime(fromCMTime: format.frameDuration))
        formatEl.addStringAttribute(name: "width", value: "\(format.width)")
        formatEl.addStringAttribute(name: "height", value: "\(format.height)")
        formatEl.addStringAttribute(name: "colorSpace", value: format.colorSpace.fcpxmlValue)
        resourceElements.append(formatEl)

        // Asset resources
        for asset in assets {
            let el = factory.makeElement(name: "asset")
            el.addStringAttribute(name: "id", value: asset.id)
            if let name = asset.name, !name.isEmpty {
                el.addStringAttribute(name: "name", value: name)
            }
            if let dur = asset.duration {
                el.addStringAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: dur))
            }
            el.addStringAttribute(name: "hasVideo", value: asset.hasVideo ? "1" : "0")
            el.addStringAttribute(name: "hasAudio", value: asset.hasAudio ? "1" : "0")
            let mediaRep = factory.makeElement(name: "media-rep")
            mediaRep.addStringAttribute(name: "kind", value: "original-media")
            let srcString = asset.relativePath ?? asset.src.absoluteString
            mediaRep.addStringAttribute(name: "src", value: srcString)
            el.addChild(mediaRep)
            resourceElements.append(el)
        }

        // Event > project > sequence > spine
        let event = factory.makeElement(name: "event")
        event.addStringAttribute(name: "name", value: eventName)
        event.addStringAttribute(name: "uid", value: eventUid ?? FCPXMLUID.random())
        let project = factory.makeElement(name: "project")
        project.addStringAttribute(name: "name", value: projectName ?? timeline.name)
        project.addStringAttribute(name: "uid", value: projectUid ?? FCPXMLUID.random())
        project.addStringAttribute(name: "modDate", value: Self._fcpxmlModDateString(from: Date()))
        let sequence = factory.makeElement(name: "sequence")
        sequence.addStringAttribute(name: "format", value: formatID)
        sequence.addStringAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: timeline.duration))
        sequence.addStringAttribute(name: "tcStart", value: "0s")
        sequence.addStringAttribute(name: "tcFormat", value: "NDF")
        sequence.addStringAttribute(name: "audioLayout", value: "stereo")
        sequence.addStringAttribute(name: "audioRate", value: "48k")

        let spine = factory.makeElement(name: "spine")
        for clip in timeline.sortedClips {
            let clipEl = factory.makeElement(name: "asset-clip")
            clipEl.addStringAttribute(name: "ref", value: clip.assetRef)
            if let name = clip.name, !name.isEmpty {
                clipEl.addStringAttribute(name: "name", value: name)
            }
            clipEl.addStringAttribute(name: "offset", value: utility.fcpxmlTime(fromCMTime: clip.offset))
            clipEl.addStringAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: clip.duration))
            if clip.start != .zero {
                clipEl.addStringAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: clip.start))
            }
            if clip.lane != 0 {
                clipEl.addStringAttribute(name: "lane", value: "\(clip.lane)")
            }
            if clip.isVideoDisabled {
                clipEl.addStringAttribute(name: "enabled", value: "0")
            }

            // Add clip-level metadata as children of asset-clip
            for marker in clip.markers {
                clipEl.addChild(_markerElement(marker, utility: utility))
            }
            for chapterMarker in clip.chapterMarkers {
                clipEl.addChild(_chapterMarkerElement(chapterMarker, utility: utility))
            }
            for keyword in clip.keywords {
                clipEl.addChild(_keywordElement(keyword, utility: utility))
            }
            for rating in clip.ratings {
                clipEl.addChild(_ratingElement(rating, utility: utility))
            }
            if let metadata = clip.metadata {
                clipEl.addChild(_metadataElement(metadata))
            }

            spine.addChild(clipEl)
        }
        sequence.addChild(spine)
        project.addChild(sequence)
        event.addChild(project)

        // Build document tree: fcpxml > resources + library > event
        let root = factory.makeElement(name: "fcpxml")
        root.addStringAttribute(name: "version", value: version.stringValue)
        let resourcesEl = factory.makeElement(name: "resources")
        for el in resourceElements {
            resourcesEl.addChild(el)
        }
        root.addChild(resourcesEl)
        let library = factory.makeElement(name: "library")
        // DTD allows only location and colorProcessing on library; no "name" attribute.
        if let location = libraryLocation, !location.isEmpty {
            library.addStringAttribute(name: "location", value: location)
        }
        library.addChild(event)
        if includeDefaultSmartCollections {
            for smartCollection in _defaultSmartCollectionElements() {
                library.addChild(smartCollection)
            }
        }
        root.addChild(library)
        let doc = factory.makeDocument()
        doc.documentContentKind = .xml
        doc.characterEncoding = "UTF-8"
        doc.version = "1.0"
        doc.isStandalone = false  // Required for DTD validation with whitespace nodes
        doc.setRootElement(root)
        doc.rootElement()?.addAttribute(name: "version", value: version.stringValue)
        #if canImport(FoundationXML) || os(macOS)
        let dtd = factory.makeDTD()
        dtd.name = "fcpxml"
        doc.dtd = dtd
        #endif
        // Serialize as formatted FCPXML string with standalone="no" for DTD compatibility
        let formattedData = doc.xmlData(options: .fcpxmlDefaults)
        var formattedString = String(data: formattedData, encoding: .utf8) ?? ""
        if formattedString.hasPrefix("<?xml") {
            formattedString = formattedString.replacingOccurrences(
                of: #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#,
                with: #"<?xml version="1.0" encoding="UTF-8" standalone="no"?>"#
            )
        }
        return formattedString
    }

    /// FCP-style default smart collections (Projects, All Video, Audio Only, Stills, Favorites).
    private func _defaultSmartCollectionElements() -> [any PNXMLElement] {
        let projects = factory.makeElement(name: "smart-collection")
        projects.addStringAttribute(name: "name", value: "Projects")
        projects.addStringAttribute(name: "match", value: "all")
        let matchClip = factory.makeElement(name: "match-clip")
        matchClip.addStringAttribute(name: "rule", value: "is")
        matchClip.addStringAttribute(name: "type", value: "project")
        projects.addChild(matchClip)

        let allVideo = factory.makeElement(name: "smart-collection")
        allVideo.addStringAttribute(name: "name", value: "All Video")
        allVideo.addStringAttribute(name: "match", value: "any")
        for type in ["videoOnly", "videoWithAudio"] {
            let m = factory.makeElement(name: "match-media")
            m.addStringAttribute(name: "rule", value: "is")
            m.addStringAttribute(name: "type", value: type)
            allVideo.addChild(m)
        }

        let audioOnly = factory.makeElement(name: "smart-collection")
        audioOnly.addStringAttribute(name: "name", value: "Audio Only")
        audioOnly.addStringAttribute(name: "match", value: "all")
        let ma = factory.makeElement(name: "match-media")
        ma.addStringAttribute(name: "rule", value: "is")
        ma.addStringAttribute(name: "type", value: "audioOnly")
        audioOnly.addChild(ma)

        let stills = factory.makeElement(name: "smart-collection")
        stills.addStringAttribute(name: "name", value: "Stills")
        stills.addStringAttribute(name: "match", value: "all")
        let ms = factory.makeElement(name: "match-media")
        ms.addStringAttribute(name: "rule", value: "is")
        ms.addStringAttribute(name: "type", value: "stills")
        stills.addChild(ms)

        let favorites = factory.makeElement(name: "smart-collection")
        favorites.addStringAttribute(name: "name", value: "Favorites")
        favorites.addStringAttribute(name: "match", value: "all")
        let mr = factory.makeElement(name: "match-ratings")
        mr.addStringAttribute(name: "value", value: "favorites")
        favorites.addChild(mr)

        return [projects, allVideo, audioOnly, stills, favorites]
    }

    /// FCP-style modDate string (e.g. "2026-02-23 08:18:53 +0800").
    private static func _fcpxmlModDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - Metadata Element Generators

    /// Generates a `<marker>` XML element from a Marker.
    private func _markerElement(_ marker: Marker, utility: FCPXMLUtility) -> any PNXMLElement {
        let el = factory.makeElement(name: "marker")
        el.addStringAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: marker.start))
        el.addStringAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: marker.duration))
        el.addStringAttribute(name: "value", value: marker.value)
        if let note = marker.note, !note.isEmpty {
            el.addStringAttribute(name: "note", value: note)
        }
        if marker.completed {
            el.addStringAttribute(name: "completed", value: "1")
        }
        return el
    }

    /// Generates a `<chapter-marker>` XML element from a ChapterMarker.
    private func _chapterMarkerElement(_ chapterMarker: ChapterMarker, utility: FCPXMLUtility) -> any PNXMLElement {
        let el = factory.makeElement(name: "chapter-marker")
        el.addStringAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: chapterMarker.start))
        el.addStringAttribute(name: "value", value: chapterMarker.value)
        if let posterOffset = chapterMarker.posterOffset {
            el.addStringAttribute(name: "posterOffset", value: utility.fcpxmlTime(fromCMTime: posterOffset))
        }
        if let note = chapterMarker.note, !note.isEmpty {
            el.addStringAttribute(name: "note", value: note)
        }
        return el
    }

    /// Generates a `<keyword>` XML element from a Keyword.
    private func _keywordElement(_ keyword: Keyword, utility: FCPXMLUtility) -> any PNXMLElement {
        let el = factory.makeElement(name: "keyword")
        el.addStringAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: keyword.start))
        el.addStringAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: keyword.duration))
        el.addStringAttribute(name: "value", value: keyword.value)
        if let note = keyword.note, !note.isEmpty {
            el.addStringAttribute(name: "note", value: note)
        }
        return el
    }

    /// Generates a `<rating>` XML element from a Rating.
    private func _ratingElement(_ rating: Rating, utility: FCPXMLUtility) -> any PNXMLElement {
        let el = factory.makeElement(name: "rating")
        el.addStringAttribute(name: "start", value: utility.fcpxmlTime(fromCMTime: rating.start))
        el.addStringAttribute(name: "duration", value: utility.fcpxmlTime(fromCMTime: rating.duration))
        el.addStringAttribute(name: "value", value: rating.value.rawValue)
        if let note = rating.note, !note.isEmpty {
            el.addStringAttribute(name: "note", value: note)
        }
        return el
    }

    /// Generates a `<metadata>` XML element from a Metadata struct.
    private func _metadataElement(_ metadata: Metadata) -> any PNXMLElement {
        let el = factory.makeElement(name: "metadata")
        for (key, value) in metadata.entries.sorted(by: { $0.key < $1.key }) {
            let mdEl = factory.makeElement(name: "md")
            mdEl.addStringAttribute(name: "key", value: key)
            mdEl.addStringAttribute(name: "value", value: value)
            el.addChild(mdEl)
        }
        return el
    }
}
