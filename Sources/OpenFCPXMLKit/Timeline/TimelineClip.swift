//
//  TimelineClip.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Single clip within a Timeline, with source reference, offset, and duration.
//

import Foundation
import CoreMedia
#if canImport(AVFoundation)
import AVFoundation
#endif

/// A clip on a timeline for FCPXML export.
///
/// References an asset by string ID (e.g. `"r2"`). Use with `Timeline` and `FCPXMLExporter`;
/// assets are provided separately as `FCPXMLExportAsset`.
@available(macOS 26.0, *)
public struct TimelineClip: Sendable, Equatable {

    /// Optional display name.
    public var name: String?

    /// Resource ID of the asset (e.g. `"r2"`). Must match an `FCPXMLExportAsset.id` when exporting.
    public var assetRef: String

    /// Position on the timeline (CMTime).
    public var offset: CMTime

    /// Duration of the clip on the timeline (CMTime).
    public var duration: CMTime

    /// Start time within the source asset (trim start). Default zero.
    public var start: CMTime

    /// Lane: 0 = primary storyline, positive = above, negative = below.
    public var lane: Int

    /// When true, video is disabled (audio-only clip).
    public var isVideoDisabled: Bool
    
    // MARK: - Metadata
    
    /// Markers attached to this clip.
    public var markers: [Marker]
    
    /// Chapter markers for this clip.
    public var chapterMarkers: [ChapterMarker]
    
    /// Keywords for this clip.
    public var keywords: [Keyword]
    
    /// Ratings for this clip.
    public var ratings: [Rating]
    
    /// Custom metadata key-value pairs.
    public var metadata: Metadata?

    public init(
        name: String? = nil,
        assetRef: String,
        offset: CMTime,
        duration: CMTime,
        start: CMTime = .zero,
        lane: Int = 0,
        isVideoDisabled: Bool = false,
        markers: [Marker] = [],
        chapterMarkers: [ChapterMarker] = [],
        keywords: [Keyword] = [],
        ratings: [Rating] = [],
        metadata: Metadata? = nil
    ) {
        self.name = name
        self.assetRef = assetRef
        self.offset = offset
        self.duration = duration
        self.start = start
        self.lane = lane
        self.isVideoDisabled = isVideoDisabled
        self.markers = markers
        self.chapterMarkers = chapterMarkers
        self.keywords = keywords
        self.ratings = ratings
        self.metadata = metadata
    }

    /// End time on the timeline (offset + duration).
    public var endTime: CMTime {
        CMTimeAdd(offset, duration)
    }
    
    // MARK: - Metadata Management
    
    /// Adds a marker to the clip.
    ///
    /// - Parameter marker: The marker to add.
    public mutating func addMarker(_ marker: Marker) {
        markers.append(marker)
    }
    
    /// Removes a marker from the clip.
    ///
    /// - Parameter marker: The marker to remove.
    /// - Returns: True if the marker was found and removed.
    @discardableResult
    public mutating func removeMarker(_ marker: Marker) -> Bool {
        if let index = markers.firstIndex(of: marker) {
            markers.remove(at: index)
            return true
        }
        return false
    }
    
    /// Adds a chapter marker to the clip.
    ///
    /// - Parameter chapterMarker: The chapter marker to add.
    public mutating func addChapterMarker(_ chapterMarker: ChapterMarker) {
        chapterMarkers.append(chapterMarker)
    }
    
    /// Removes a chapter marker from the clip.
    ///
    /// - Parameter chapterMarker: The chapter marker to remove.
    /// - Returns: True if the chapter marker was found and removed.
    @discardableResult
    public mutating func removeChapterMarker(_ chapterMarker: ChapterMarker) -> Bool {
        if let index = chapterMarkers.firstIndex(of: chapterMarker) {
            chapterMarkers.remove(at: index)
            return true
        }
        return false
    }
    
    /// Adds a keyword to the clip.
    ///
    /// - Parameter keyword: The keyword to add.
    public mutating func addKeyword(_ keyword: Keyword) {
        keywords.append(keyword)
    }
    
    /// Removes a keyword from the clip.
    ///
    /// - Parameter keyword: The keyword to remove.
    /// - Returns: True if the keyword was found and removed.
    @discardableResult
    public mutating func removeKeyword(_ keyword: Keyword) -> Bool {
        if let index = keywords.firstIndex(of: keyword) {
            keywords.remove(at: index)
            return true
        }
        return false
    }
    
    /// Adds a rating to the clip.
    ///
    /// - Parameter rating: The rating to add.
    public mutating func addRating(_ rating: Rating) {
        ratings.append(rating)
    }
    
    /// Removes a rating from the clip.
    ///
    /// - Parameter rating: The rating to remove.
    /// - Returns: True if the rating was found and removed.
    @discardableResult
    public mutating func removeRating(_ rating: Rating) -> Bool {
        if let index = ratings.firstIndex(of: rating) {
            ratings.remove(at: index)
            return true
        }
        return false
    }
}

// MARK: - Asset Validation

extension TimelineClip {
    /// Validates that an asset at the given URL exists and is compatible with this clip's lane.
    ///
    /// - Parameters:
    ///   - url: The asset URL to validate.
    ///   - validator: Optional asset validator (uses default if nil).
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: Validation result indicating existence, MIME type, and compatibility.
    public func validateAsset(
        at url: URL,
        validator: (any AssetValidation)? = nil,
        mimeTypeDetector: (any MIMETypeDetection)? = nil
    ) async -> AssetValidationResult {
        let validator = validator ?? AssetValidator()
        return await validator.validateAsset(
            at: url,
            forLane: lane,
            mimeTypeDetector: mimeTypeDetector
        )
    }
    
    /// Validates an asset synchronously.
    ///
    /// - Parameters:
    ///   - url: The asset URL to validate.
    ///   - validator: Optional asset validator (uses default if nil).
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: Validation result.
    public func validateAssetSync(
        at url: URL,
        validator: (any AssetValidationSync)? = nil,
        mimeTypeDetector: (any MIMETypeDetectionSync)? = nil
    ) -> AssetValidationResult {
        let validator = validator ?? AssetValidator()
        return validator.validateAssetSync(
            at: url,
            forLane: lane,
            mimeTypeDetector: mimeTypeDetector
        )
    }
    
    /// Checks if an asset at the given URL is audio content.
    ///
    /// - Parameters:
    ///   - url: The asset URL to check.
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: True if the asset has an audio/* MIME type.
    public func isAudioAsset(
        at url: URL,
        mimeTypeDetector: (any MIMETypeDetection)? = nil
    ) async -> Bool {
        let detector = mimeTypeDetector ?? MIMETypeDetector()
        guard let mimeType = await detector.detectMIMEType(at: url) else {
            return false
        }
        return mimeType.hasPrefix("audio/")
    }
    
    /// Checks if an asset at the given URL is video content.
    ///
    /// - Parameters:
    ///   - url: The asset URL to check.
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: True if the asset has a video/* MIME type.
    public func isVideoAsset(
        at url: URL,
        mimeTypeDetector: (any MIMETypeDetection)? = nil
    ) async -> Bool {
        let detector = mimeTypeDetector ?? MIMETypeDetector()
        guard let mimeType = await detector.detectMIMEType(at: url) else {
            return false
        }
        return mimeType.hasPrefix("video/")
    }
    
    /// Checks if an asset at the given URL is image content.
    ///
    /// - Parameters:
    ///   - url: The asset URL to check.
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: True if the asset has an image/* MIME type.
    public func isImageAsset(
        at url: URL,
        mimeTypeDetector: (any MIMETypeDetection)? = nil
    ) async -> Bool {
        let detector = mimeTypeDetector ?? MIMETypeDetector()
        guard let mimeType = await detector.detectMIMEType(at: url) else {
            return false
        }
        return mimeType.hasPrefix("image/")
    }
}
