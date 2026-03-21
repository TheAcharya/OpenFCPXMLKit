//
//  Timeline.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Timeline model with clips, format settings, and duration calculation.
//

import Foundation
import CoreMedia

/// Video format descriptor for export (resolution, frame duration, color space).
@available(macOS 12.0, *)
public struct TimelineFormat: Sendable, Equatable {

    public var width: Int
    public var height: Int
    public var frameDuration: CMTime
    public var colorSpace: ColorSpace
    public var interlaced: Bool

    public init(
        width: Int,
        height: Int,
        frameDuration: CMTime,
        colorSpace: ColorSpace = .rec709,
        interlaced: Bool = false
    ) {
        precondition(width > 0, "Width must be positive")
        precondition(height > 0, "Height must be positive")
        self.width = width
        self.height = height
        self.frameDuration = frameDuration
        self.colorSpace = colorSpace
        self.interlaced = interlaced
    }

    // MARK: - Computed Properties
    
    /// The aspect ratio as width/height.
    public var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }
    
    /// Whether this is a standard HD resolution (1920×1080 or 1280×720).
    public var isHD: Bool {
        (width == 1920 && height == 1080) ||
        (width == 1280 && height == 720)
    }
    
    /// Whether this is a 4K/UHD resolution (3840×2160 or 4096×2160).
    public var isUHD: Bool {
        (width == 3840 && height == 2160) ||
        (width == 4096 && height == 2160)
    }
    
    /// Whether this is DCI 4K (4096×2160).
    public var isDCI4K: Bool {
        width == 4096 && height == 2160
    }
    
    /// Whether this is standard 4K UHD (3840×2160).
    public var isStandard4K: Bool {
        width == 3840 && height == 2160
    }
    
    /// Whether this is 1080p HD.
    public var is1080p: Bool {
        width == 1920 && height == 1080
    }
    
    /// Whether this is 720p HD.
    public var is720p: Bool {
        width == 1280 && height == 720
    }

    // MARK: - Standard Format Presets

    /// 1920×1080 progressive.
    public static func hd1080p(frameDuration: CMTime, colorSpace: ColorSpace = .rec709) -> TimelineFormat {
        TimelineFormat(width: 1920, height: 1080, frameDuration: frameDuration, colorSpace: colorSpace)
    }

    /// 1280×720 progressive.
    public static func hd720p(frameDuration: CMTime, colorSpace: ColorSpace = .rec709) -> TimelineFormat {
        TimelineFormat(width: 1280, height: 720, frameDuration: frameDuration, colorSpace: colorSpace)
    }

    /// 3840×2160 (4K UHD).
    public static func uhd4K(frameDuration: CMTime, colorSpace: ColorSpace = .rec2020) -> TimelineFormat {
        TimelineFormat(width: 3840, height: 2160, frameDuration: frameDuration, colorSpace: colorSpace)
    }
    
    /// 4096×2160 (DCI 4K).
    public static func dci4K(frameDuration: CMTime, colorSpace: ColorSpace = .rec2020) -> TimelineFormat {
        TimelineFormat(width: 4096, height: 2160, frameDuration: frameDuration, colorSpace: colorSpace)
    }
    
    /// 1920×1080 interlaced.
    public static func hd1080i(frameDuration: CMTime, colorSpace: ColorSpace = .rec709) -> TimelineFormat {
        TimelineFormat(width: 1920, height: 1080, frameDuration: frameDuration, colorSpace: colorSpace, interlaced: true)
    }
    
    /// 1280×720 interlaced.
    public static func hd720i(frameDuration: CMTime, colorSpace: ColorSpace = .rec709) -> TimelineFormat {
        TimelineFormat(width: 1280, height: 720, frameDuration: frameDuration, colorSpace: colorSpace, interlaced: true)
    }
}

/// In-memory timeline used to build or export FCPXML. No persistence; clips reference assets by string ID.
@available(macOS 12.0, *)
public struct Timeline: Sendable, Equatable {

    public var name: String
    public var format: TimelineFormat?
    public var clips: [TimelineClip]
    
    // MARK: - Metadata
    
    /// Markers attached to the timeline (project-level).
    public var markers: [Marker]
    
    /// Chapter markers for the timeline.
    public var chapterMarkers: [ChapterMarker]
    
    /// Keywords for the entire timeline.
    public var keywords: [Keyword]
    
    /// Ratings for the timeline.
    public var ratings: [Rating]
    
    /// Custom metadata key-value pairs.
    public var metadata: Metadata?
    
    // MARK: - Timestamps
    
    /// When this timeline was created.
    public var createdAt: Date
    
    /// When this timeline was last modified.
    public var modifiedAt: Date

    /// Optional provider for "current" time (used when updating modifiedAt). Internal for testing; when nil, `Date()` is used.
    internal var nowProvider: (@Sendable () -> Date)?

    public init(
        name: String,
        format: TimelineFormat? = nil,
        clips: [TimelineClip] = [],
        markers: [Marker] = [],
        chapterMarkers: [ChapterMarker] = [],
        keywords: [Keyword] = [],
        ratings: [Rating] = [],
        metadata: Metadata? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        nowProvider: (@Sendable () -> Date)? = nil
    ) {
        self.name = name
        self.format = format
        self.clips = clips
        self.markers = markers
        self.chapterMarkers = chapterMarkers
        self.keywords = keywords
        self.ratings = ratings
        self.metadata = metadata
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.nowProvider = nowProvider
    }

    /// Current time for modifiedAt updates (injected for tests when nowProvider is set).
    private func modifiedNow() -> Date {
        nowProvider?() ?? Date()
    }

    public static func == (lhs: Timeline, rhs: Timeline) -> Bool {
        lhs.name == rhs.name
            && lhs.format == rhs.format
            && lhs.clips == rhs.clips
            && lhs.markers == rhs.markers
            && lhs.chapterMarkers == rhs.chapterMarkers
            && lhs.keywords == rhs.keywords
            && lhs.ratings == rhs.ratings
            && lhs.metadata == rhs.metadata
            && lhs.createdAt == rhs.createdAt
            && lhs.modifiedAt == rhs.modifiedAt
    }

    // MARK: - Format Helpers
    
    /// Whether the timeline format is HD.
    public var isHD: Bool {
        format?.isHD ?? false
    }
    
    /// Whether the timeline format is 4K/UHD.
    public var isUHD: Bool {
        format?.isUHD ?? false
    }
    
    /// The aspect ratio of the timeline format.
    public var aspectRatio: Double {
        format?.aspectRatio ?? 0
    }

    /// Total duration (max of offset+duration on lane 0). Returns zero if empty.
    public var duration: CMTime {
        let primary = clips.filter { $0.lane == 0 }
        guard !primary.isEmpty else { return .zero }
        var maxEnd = CMTime.zero
        for clip in primary {
            let end = CMTimeAdd(clip.offset, clip.duration)
            if CMTimeCompare(end, maxEnd) > 0 {
                maxEnd = end
            }
        }
        return maxEnd
    }

    /// Clips sorted by offset then lane.
    public var sortedClips: [TimelineClip] {
        clips.sorted { lhs, rhs in
            let c = CMTimeCompare(lhs.offset, rhs.offset)
            if c != 0 { return c < 0 }
            return lhs.lane < rhs.lane
        }
    }

    public var isEmpty: Bool { clips.isEmpty }
    public var clipCount: Int { clips.count }
    
    // MARK: - Clip Management
    
    /// Inserts a clip with ripple effect, shifting subsequent clips forward.
    ///
    /// When a clip is inserted, all clips that start at or after the insertion point
    /// on the affected lanes are shifted forward by the inserted clip's duration.
    /// Clips that overlap the insertion point but start before it are intentionally
    /// not shifted by this operation.
    ///
    /// - Parameters:
    ///   - clip: The clip to insert (will be modified with offset and lane).
    ///   - offset: The timecode position for insertion.
    ///   - lane: The lane for the clip (default: 0).
    ///   - rippleLanes: Which lanes to ripple (default: primary only).
    /// - Returns: A new timeline with the clip inserted and subsequent clips shifted, plus result metadata.
    public func insertingClipWithRipple(
        _ clip: TimelineClip,
        at offset: CMTime,
        lane: Int = 0,
        rippleLanes: RippleLaneOption = .primaryOnly
    ) -> (timeline: Timeline, result: RippleInsertResult) {
        let insertDuration = clip.duration
        var shiftedClips: [ClipShift] = []
        var newClips = clips
        
        // If duration is zero, no shifting needed
        let hasDuration = CMTimeCompare(insertDuration, .zero) > 0
        
        // Find clips that need to be shifted
        let clipsToShift = clips.enumerated().filter { index, existingClip in
            // Must start at or after the insertion point
            guard CMTimeCompare(existingClip.offset, offset) >= 0 else { return false }
            
            // Check lane filtering
            switch rippleLanes {
            case .all:
                return true
            case .single(let targetLane):
                return existingClip.lane == targetLane
            case .range(let laneRange):
                return laneRange.contains(existingClip.lane)
            case .primaryOnly:
                return existingClip.lane == 0
            }
        }
        
        // Shift the clips (only if there's actual duration to shift by)
        if hasDuration {
            for (index, _) in clipsToShift {
                let existingClip = newClips[index]
                let originalOffset = existingClip.offset
                let newOffset = CMTimeAdd(existingClip.offset, insertDuration)
                
                // Create shifted clip
                var shiftedClip = existingClip
                shiftedClip.offset = newOffset
                newClips[index] = shiftedClip
                
                shiftedClips.append(ClipShift(
                    clipIndex: index,
                    originalOffset: originalOffset,
                    newOffset: newOffset
                ))
            }
        }
        
        // Insert the new clip
        var newClip = clip
        newClip.offset = offset
        newClip.lane = lane
        newClips.append(newClip)
        
        let newTimeline = Timeline(
            name: name,
            format: format,
            clips: newClips,
            markers: markers,
            chapterMarkers: chapterMarkers,
            keywords: keywords,
            ratings: ratings,
            metadata: metadata,
            createdAt: createdAt,
            modifiedAt: modifiedNow(),
            nowProvider: nowProvider
        )
        
        let placement = ClipPlacement(
            offset: newClip.offset,
            duration: newClip.duration,
            lane: newClip.lane
        )
        
        let result = RippleInsertResult(
            insertedClip: placement,
            shiftedClips: shiftedClips
        )
        
        return (newTimeline, result)
    }
    
    /// Inserts a clip with ripple effect (mutating version for convenience).
    ///
    /// This is a convenience method that mutates `self`. For immutable operations,
    /// use `insertingClipWithRipple(_:at:lane:rippleLanes:)`.
    ///
    /// - Parameters:
    ///   - clip: The clip to insert (will be modified with offset and lane).
    ///   - offset: The timecode position for insertion.
    ///   - lane: The lane for the clip (default: 0).
    ///   - rippleLanes: Which lanes to ripple (default: primary only).
    /// - Returns: Result containing placement info and shifted clips.
    @discardableResult
    public mutating func insertClipWithRipple(
        _ clip: TimelineClip,
        at offset: CMTime,
        lane: Int = 0,
        rippleLanes: RippleLaneOption = .primaryOnly
    ) -> RippleInsertResult {
        let (newTimeline, result) = insertingClipWithRipple(clip, at: offset, lane: lane, rippleLanes: rippleLanes)
        self = newTimeline
        return result
    }
    
    /// Finds an available lane for a clip at the given position.
    ///
    /// Searches outward from the starting lane (positive lanes first, then negative).
    /// Checks for overlap: a lane is available if no existing clip on that lane overlaps
    /// with the proposed clip's time range.
    ///
    /// - Parameters:
    ///   - offset: The clip's start position.
    ///   - duration: The clip's duration.
    ///   - startingFrom: The lane to start searching from (default: 0).
    /// - Returns: An available lane number.
    public func findAvailableLane(at offset: CMTime, duration: CMTime, startingFrom: Int = 0) -> Int {
        let clipEnd = CMTimeAdd(offset, duration)
        
        // Check if a lane is available
        func isLaneAvailable(_ lane: Int) -> Bool {
            !clips.contains { existingClip in
                guard existingClip.lane == lane else { return false }
                let existingEnd = CMTimeAdd(existingClip.offset, existingClip.duration)
                // Overlap: clip starts before existing ends AND clip ends after existing starts
                return CMTimeCompare(offset, existingEnd) < 0 && CMTimeCompare(clipEnd, existingClip.offset) > 0
            }
        }
        
        // Try the starting lane first
        if isLaneAvailable(startingFrom) {
            return startingFrom
        }
        
        // Search outward from the starting lane
        var distance = 1
        while distance < 1000 { // Reasonable upper limit
            // Try positive lane
            let positiveLane = startingFrom + distance
            if isLaneAvailable(positiveLane) {
                return positiveLane
            }
            
            // Try negative lane
            let negativeLane = startingFrom - distance
            if isLaneAvailable(negativeLane) {
                return negativeLane
            }
            
            distance += 1
        }
        
        // Fallback (should never reach here)
        return startingFrom + 1000
    }
    
    /// Inserts a clip at a specific timecode, automatically assigning a lane if needed.
    ///
    /// If `autoAssignLane` is true and the clip would overlap with existing clips
    /// on the target lane, a new lane will be automatically assigned.
    ///
    /// - Parameters:
    ///   - clip: The clip to insert (will be modified with offset and lane).
    ///   - offset: The timecode position for insertion.
    ///   - preferredLane: The preferred lane (default: 0).
    ///   - autoAssignLane: Whether to auto-assign a lane on conflict (default: true).
    /// - Returns: A new timeline with the clip inserted, plus placement information.
    /// - Throws: `TimelineError.noAvailableLane` if auto-assign is disabled and there's a conflict.
    public func insertingClipAutoLane(
        _ clip: TimelineClip,
        at offset: CMTime,
        preferredLane: Int = 0,
        autoAssignLane: Bool = true
    ) throws -> (timeline: Timeline, placement: ClipPlacement) {
        let clipEnd = CMTimeAdd(offset, clip.duration)
        
        // Check for conflicts on the preferred lane
        let hasConflict = clips.contains { existingClip in
            guard existingClip.lane == preferredLane else { return false }
            let existingEnd = CMTimeAdd(existingClip.offset, existingClip.duration)
            // Check for overlap
            return CMTimeCompare(offset, existingEnd) < 0 && CMTimeCompare(clipEnd, existingClip.offset) > 0
        }
        
        if !hasConflict {
            var newClip = clip
            newClip.offset = offset
            newClip.lane = preferredLane
            var newClips = clips
            newClips.append(newClip)
            let newTimeline = Timeline(name: name, format: format, clips: newClips, markers: markers, chapterMarkers: chapterMarkers, keywords: keywords, ratings: ratings, metadata: metadata, createdAt: createdAt, modifiedAt: modifiedNow(), nowProvider: nowProvider)
            let placement = ClipPlacement(offset: newClip.offset, duration: newClip.duration, lane: newClip.lane)
            return (newTimeline, placement)
        }
        
        guard autoAssignLane else {
            throw TimelineError.noAvailableLane(at: offset, duration: clip.duration)
        }
        
        // Find an available lane
        let assignedLane = findAvailableLane(at: offset, duration: clip.duration, startingFrom: preferredLane)
        var newClip = clip
        newClip.offset = offset
        newClip.lane = assignedLane
        var newClips = clips
        newClips.append(newClip)
        let newTimeline = Timeline(name: name, format: format, clips: newClips, markers: markers, chapterMarkers: chapterMarkers, keywords: keywords, ratings: ratings, metadata: metadata, createdAt: createdAt, modifiedAt: modifiedNow(), nowProvider: nowProvider)
        let placement = ClipPlacement(offset: newClip.offset, duration: newClip.duration, lane: newClip.lane)
        return (newTimeline, placement)
    }

    /// Inserts a clip at a specific timecode, automatically assigning a lane if needed (mutating version).
    ///
    /// This is a convenience method that mutates `self`. For immutable operations,
    /// use `insertingClipAutoLane(_:at:preferredLane:autoAssignLane:)`.
    ///
    /// - Parameters:
    ///   - clip: The clip to insert (will be modified with offset and lane).
    ///   - offset: The timecode position for insertion.
    ///   - preferredLane: The preferred lane (default: 0).
    ///   - autoAssignLane: Whether to auto-assign a lane on conflict (default: true).
    /// - Returns: Placement information for the inserted clip.
    /// - Throws: `TimelineError.noAvailableLane` if auto-assign is disabled and there's a conflict.
    @discardableResult
    public mutating func insertClipAutoLane(
        _ clip: TimelineClip,
        at offset: CMTime,
        preferredLane: Int = 0,
        autoAssignLane: Bool = true
    ) throws -> ClipPlacement {
        let (newTimeline, placement) = try insertingClipAutoLane(clip, at: offset, preferredLane: preferredLane, autoAssignLane: autoAssignLane)
        self = newTimeline
        return placement
    }
    
    // MARK: - Clip Queries
    
    /// Returns all clips on a specific lane.
    ///
    /// - Parameter lane: The lane number to filter by.
    /// - Returns: Array of clips on the specified lane, sorted by offset.
    public func clips(onLane lane: Int) -> [TimelineClip] {
        clips
            .filter { $0.lane == lane }
            .sorted { lhs, rhs in
                CMTimeCompare(lhs.offset, rhs.offset) < 0
            }
    }
    
    /// Returns all clips that overlap with a time range.
    ///
    /// A clip overlaps if it starts before the range ends AND ends after the range starts.
    ///
    /// - Parameters:
    ///   - start: Start of the time range.
    ///   - end: End of the time range.
    /// - Returns: Array of clips that overlap with the range.
    public func clips(inRange start: CMTime, end: CMTime) -> [TimelineClip] {
        clips.filter { clip in
            let clipEnd = CMTimeAdd(clip.offset, clip.duration)
            // Overlap: clip starts before range ends AND clip ends after range starts
            return CMTimeCompare(clip.offset, end) < 0 && CMTimeCompare(clipEnd, start) > 0
        }
    }
    
    /// Returns all clips that reference a specific asset.
    ///
    /// - Parameter assetRef: The asset reference ID to search for.
    /// - Returns: Array of clips referencing the asset, sorted by offset.
    public func clips(withAssetRef assetRef: String) -> [TimelineClip] {
        clips
            .filter { $0.assetRef == assetRef }
            .sorted { lhs, rhs in
                CMTimeCompare(lhs.offset, rhs.offset) < 0
            }
    }
    
    /// Returns placement information for all clips.
    ///
    /// - Returns: Array of clip placements, sorted by offset then lane.
    public func allPlacements() -> [ClipPlacement] {
        sortedClips.map { clip in
            ClipPlacement(
                offset: clip.offset,
                duration: clip.duration,
                lane: clip.lane
            )
        }
    }
    
    /// Returns placements for clips on a specific lane.
    ///
    /// - Parameter lane: The lane to filter by.
    /// - Returns: Array of clip placements on the specified lane, sorted by offset.
    public func placements(onLane lane: Int) -> [ClipPlacement] {
        clips(onLane: lane).map { clip in
            ClipPlacement(
                offset: clip.offset,
                duration: clip.duration,
                lane: clip.lane
            )
        }
    }
    
    /// Returns placements for clips overlapping a time range.
    ///
    /// - Parameters:
    ///   - start: Start of the time range.
    ///   - end: End of the time range.
    /// - Returns: Array of clip placements overlapping the range.
    public func placements(inRange start: CMTime, end: CMTime) -> [ClipPlacement] {
        clips(inRange: start, end: end).map { clip in
            ClipPlacement(
                offset: clip.offset,
                duration: clip.duration,
                lane: clip.lane
            )
        }
    }
    
    /// Returns the range of lanes used in the timeline.
    ///
    /// - Returns: A closed range from minimum to maximum lane, or nil if timeline is empty.
    public var laneRange: ClosedRange<Int>? {
        guard !clips.isEmpty else { return nil }
        let lanes = clips.map { $0.lane }
        let minLane = lanes.min()!
        let maxLane = lanes.max()!
        return minLane...maxLane
    }
    
    // MARK: - Metadata Management
    
    /// Adds a marker to the timeline.
    ///
    /// - Parameter marker: The marker to add.
    public mutating func addMarker(_ marker: Marker) {
        markers.append(marker)
        modifiedAt = modifiedNow()
    }
    
    /// Removes a marker from the timeline.
    ///
    /// - Parameter marker: The marker to remove.
    /// - Returns: True if the marker was found and removed.
    @discardableResult
    public mutating func removeMarker(_ marker: Marker) -> Bool {
        if let index = markers.firstIndex(of: marker) {
            markers.remove(at: index)
            modifiedAt = modifiedNow()
            return true
        }
        return false
    }
    
    /// Adds a chapter marker to the timeline.
    ///
    /// - Parameter chapterMarker: The chapter marker to add.
    public mutating func addChapterMarker(_ chapterMarker: ChapterMarker) {
        chapterMarkers.append(chapterMarker)
        modifiedAt = modifiedNow()
    }
    
    /// Removes a chapter marker from the timeline.
    ///
    /// - Parameter chapterMarker: The chapter marker to remove.
    /// - Returns: True if the chapter marker was found and removed.
    @discardableResult
    public mutating func removeChapterMarker(_ chapterMarker: ChapterMarker) -> Bool {
        if let index = chapterMarkers.firstIndex(of: chapterMarker) {
            chapterMarkers.remove(at: index)
            modifiedAt = modifiedNow()
            return true
        }
        return false
    }
    
    /// Adds a keyword to the timeline.
    ///
    /// - Parameter keyword: The keyword to add.
    public mutating func addKeyword(_ keyword: Keyword) {
        keywords.append(keyword)
        modifiedAt = modifiedNow()
    }
    
    /// Removes a keyword from the timeline.
    ///
    /// - Parameter keyword: The keyword to remove.
    /// - Returns: True if the keyword was found and removed.
    @discardableResult
    public mutating func removeKeyword(_ keyword: Keyword) -> Bool {
        if let index = keywords.firstIndex(of: keyword) {
            keywords.remove(at: index)
            modifiedAt = modifiedNow()
            return true
        }
        return false
    }
    
    /// Adds a rating to the timeline.
    ///
    /// - Parameter rating: The rating to add.
    public mutating func addRating(_ rating: Rating) {
        ratings.append(rating)
        modifiedAt = modifiedNow()
    }
    
    /// Removes a rating from the timeline.
    ///
    /// - Parameter rating: The rating to remove.
    /// - Returns: True if the rating was found and removed.
    @discardableResult
    public mutating func removeRating(_ rating: Rating) -> Bool {
        if let index = ratings.firstIndex(of: rating) {
            ratings.remove(at: index)
            modifiedAt = modifiedNow()
            return true
        }
        return false
    }
    
    /// Returns all markers sorted by start time.
    public var sortedMarkers: [Marker] {
        markers.sorted { lhs, rhs in
            CMTimeCompare(lhs.start, rhs.start) < 0
        }
    }
    
    /// Returns all chapter markers sorted by start time.
    public var sortedChapterMarkers: [ChapterMarker] {
        chapterMarkers.sorted { lhs, rhs in
            CMTimeCompare(lhs.start, rhs.start) < 0
        }
    }
    
    /// Returns all keywords sorted by start time.
    public var sortedKeywords: [Keyword] {
        keywords.sorted { lhs, rhs in
            CMTimeCompare(lhs.start, rhs.start) < 0
        }
    }
    
    /// Returns all ratings sorted by start time.
    public var sortedRatings: [Rating] {
        ratings.sorted { lhs, rhs in
            CMTimeCompare(lhs.start, rhs.start) < 0
        }
    }
}

// MARK: - Ripple Insert Supporting Types

/// Options for which lanes to affect during a ripple insert.
@available(macOS 12.0, *)
public enum RippleLaneOption: Sendable, Equatable {
    /// Ripple all lanes.
    case all
    
    /// Ripple only a single lane.
    case single(Int)
    
    /// Ripple a range of lanes.
    case range(ClosedRange<Int>)
    
    /// Ripple only the primary storyline (lane 0).
    case primaryOnly
}

/// Result of a ripple insert operation.
@available(macOS 12.0, *)
public struct RippleInsertResult: Sendable, Equatable {
    /// The placement of the newly inserted clip.
    public let insertedClip: ClipPlacement
    
    /// Information about clips that were shifted.
    public let shiftedClips: [ClipShift]
    
    public init(insertedClip: ClipPlacement, shiftedClips: [ClipShift]) {
        self.insertedClip = insertedClip
        self.shiftedClips = shiftedClips
    }
}

/// Information about a clip that was shifted during ripple.
@available(macOS 12.0, *)
public struct ClipShift: Sendable, Equatable {
    /// The shifted clip's index in the clips array.
    public let clipIndex: Int
    
    /// The clip's original offset before ripple.
    public let originalOffset: CMTime
    
    /// The clip's new offset after ripple.
    public let newOffset: CMTime
    
    /// The amount the clip was shifted.
    public var shiftAmount: CMTime {
        CMTimeSubtract(newOffset, originalOffset)
    }
    
    public init(clipIndex: Int, originalOffset: CMTime, newOffset: CMTime) {
        self.clipIndex = clipIndex
        self.originalOffset = originalOffset
        self.newOffset = newOffset
    }
}

/// Information about a clip's placement on the timeline.
@available(macOS 12.0, *)
public struct ClipPlacement: Sendable, Equatable {
    /// The clip's start position on the timeline.
    public let offset: CMTime
    
    /// The clip's duration.
    public let duration: CMTime
    
    /// The lane the clip is on (0 = primary storyline).
    public let lane: Int
    
    /// The clip's end position on the timeline.
    public var endTime: CMTime {
        CMTimeAdd(offset, duration)
    }
    
    public init(offset: CMTime, duration: CMTime, lane: Int) {
        self.offset = offset
        self.duration = duration
        self.lane = lane
    }
}
