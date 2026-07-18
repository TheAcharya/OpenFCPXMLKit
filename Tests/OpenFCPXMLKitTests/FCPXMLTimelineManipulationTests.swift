//
//  FCPXMLTimelineManipulationTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for timeline manipulation features: ripple insert, auto lane assignment, etc.
//

import Foundation
import Testing
import CoreMedia
@testable import OpenFCPXMLKit

/// Thread-safe mutable box for injectable "now" in timestamp tests.
///
/// Implemented as a class with explicit synchronization to avoid blocking on
/// async actor operations from synchronous test code (and to avoid DispatchSemaphore deadlock risk).
/// This helper is used by synchronous test code to provide a controllable `Date`
/// source to timeline logic that may run on different threads or executors.
/// Internally it stores a single `Date` value and protects all access to that
/// value using an `NSLock`, ensuring that reads and writes are mutually exclusive.
///
/// The class is marked `@unchecked Sendable` because the Swift compiler cannot
/// automatically verify that it is safe to share between concurrency domains,
/// but manual synchronization via the `NSLock` guarantees that all mutations and
/// reads of `_value` are serialized and free of data races. No other shared
/// mutable state escapes the instance, so the type behaves as a Sendable type
/// in practice despite requiring this override.
private final class NowBox: @unchecked Sendable {
    private var _value: Date
    private let lock = NSLock()
    init(_ value: Date) {
        _value = value
    }
    func getValue() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
    func setValue(_ value: Date) {
        lock.lock()
        _value = value
        lock.unlock()
    }
}

/// Returns a synchronous closure that fetches the current time from the box (used when Timeline's nowProvider is invoked).
///
/// The returned `@Sendable` closure captures the provided `NowBox` and reads its value whenever
/// it is called, allowing tests to inject and advance a thread-safe "now" for `Timeline.nowProvider`.
private func makeSyncNowProvider(nowBox: NowBox) -> @Sendable () -> Date {
    return {
        nowBox.getValue()
    }
}

/// Synchronously sets the box's value from synchronous test code.
///
/// Helper used by synchronous test code to update the injectable "now" value
/// by setting the underlying `NowBox`'s stored `Date` synchronously.
private func syncSetNow(_ value: Date, on nowBox: NowBox) {
    nowBox.setValue(value)
}

/// Calls `insertClipAutoLane` and returns the placement, or rethrows on failure.
private func insertClipAutoLaneOrFail(
    _ clip: TimelineClip,
    into timeline: inout Timeline,
    at offset: CMTime,
    preferredLane: Int = 0
) throws -> ClipPlacement {
    try timeline.insertClipAutoLane(clip, at: offset, preferredLane: preferredLane)
}

/// Calls `insertingClipAutoLane` and returns the (timeline, placement) tuple, or rethrows on failure.
private func insertingClipAutoLaneOrFail(
    _ clip: TimelineClip,
    into timeline: Timeline,
    at offset: CMTime,
    preferredLane: Int = 0
) throws -> (Timeline, ClipPlacement) {
    try timeline.insertingClipAutoLane(clip, at: offset, preferredLane: preferredLane)
}

@Suite("Timeline manipulation")
struct FCPXMLTimelineManipulationTests {

    // MARK: - Ripple Insert Basic Tests
    
    @Test("Ripple insert shifts subsequent clips")
    func rippleInsertShiftsSubsequentClips() throws {
        var timeline = Timeline(name: "Test")
        
        // Add clips at 0s, 10s, 20s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 20, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        timeline.clips = [clip1, clip2, clip3]
        
        // Insert 5s clip at 5s with ripple
        let newClip = TimelineClip(assetRef: "r4", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        // Verify inserted clip placement
        #expect(abs((CMTimeGetSeconds(result.insertedClip.offset)) - (5.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(result.insertedClip.duration)) - (5.0)) < 0.001)
        
        // Verify shifts: clip2 and clip3 should be shifted by 5s
        #expect(result.shiftedClips.count == 2)
        
        // Find clip2's shift (was at index 1)
        let _clip2ShiftOptional = result.shiftedClips.first { $0.clipIndex == 1 }
        let clip2Shift = try #require(_clip2ShiftOptional)
        #expect(abs((CMTimeGetSeconds(clip2Shift.originalOffset)) - (10.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(clip2Shift.newOffset)) - (15.0)) < 0.001)
        
        // Find clip3's shift (was at index 2)
        let _clip3ShiftOptional = result.shiftedClips.first { $0.clipIndex == 2 }
        let clip3Shift = try #require(_clip3ShiftOptional)
        #expect(abs((CMTimeGetSeconds(clip3Shift.originalOffset)) - (20.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(clip3Shift.newOffset)) - (25.0)) < 0.001)
        
        // clip1 should NOT be shifted (starts before insert point)
        let clip1Shift = result.shiftedClips.first { $0.clipIndex == 0 }
        #expect(clip1Shift == nil)
        
        // Verify timeline state
        #expect(timeline.clips.count == 4)
        let sorted = timeline.sortedClips
        #expect(abs((CMTimeGetSeconds(sorted[0].offset)) - (0.0)) < 0.001) // clip1
        #expect(abs((CMTimeGetSeconds(sorted[1].offset)) - (5.0)) < 0.001) // newClip
        #expect(abs((CMTimeGetSeconds(sorted[2].offset)) - (15.0)) < 0.001) // clip2 shifted
        #expect(abs((CMTimeGetSeconds(sorted[3].offset)) - (25.0)) < 0.001) // clip3 shifted
    }
    
    @Test("Ripple insert does not shift clips before insert point")
    func rippleInsertDoesNotShiftClipsBeforeInsertPoint() {
        var timeline = Timeline(name: "Test")
        
        // Add clips
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        timeline.clips = [clip1, clip2]
        
        // Insert at position 15 (after clip1 end, but clip2 starts at 10, so it will be shifted)
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 15, timescale: 1))
        
        // IMPORTANT: By design, Timeline.insertClipWithRipple defines "affected clips" exclusively
        // in terms of their *start time*. clip2 starts at 10, which is before 15, so even though it
        // overlaps the insert position, it is NOT shifted; only clips whose start time is at or after
        // the insert point are moved forward to make room for the inserted clip.
        #expect(result.shiftedClips.count == 0)
        
        // Verify new clip was inserted
        #expect(abs((CMTimeGetSeconds(result.insertedClip.offset)) - (15.0)) < 0.001)
    }
    
    @Test("Ripple insert at timeline start")
    func rippleInsertAtTimelineStart() throws {
        var timeline = Timeline(name: "Test")
        
        // Add clips
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        timeline.clips = [clip1, clip2]
        
        // Insert at position 0
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: .zero)
        
        // Both clips should be shifted
        #expect(result.shiftedClips.count == 2)
        
        // Verify clip1 was shifted
        let _clip1ShiftOptional = result.shiftedClips.first { $0.clipIndex == 0 }
        let clip1Shift = try #require(_clip1ShiftOptional)
        #expect(abs((CMTimeGetSeconds(clip1Shift.originalOffset)) - (0.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(clip1Shift.newOffset)) - (5.0)) < 0.001)
        
        // Verify clip2 was shifted
        let _clip2ShiftOptional = result.shiftedClips.first { $0.clipIndex == 1 }
        let clip2Shift = try #require(_clip2ShiftOptional)
        #expect(abs((CMTimeGetSeconds(clip2Shift.originalOffset)) - (10.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(clip2Shift.newOffset)) - (15.0)) < 0.001)
    }
    
    @Test("Ripple insert at empty timeline")
    func rippleInsertAtEmptyTimeline() {
        var timeline = Timeline(name: "Test")
        
        let newClip = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        #expect(abs((CMTimeGetSeconds(result.insertedClip.offset)) - (5.0)) < 0.001)
        #expect(result.shiftedClips.count == 0)
        #expect(timeline.clips.count == 1)
    }
    
    // MARK: - Ripple Lane Option Tests
    
    @Test("Ripple primary only does not shift other lanes")
    func ripplePrimaryOnlyDoesNotShiftOtherLanes() {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at position 10
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        // Add clip on lane 1 at position 10
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 1)
        
        // Add clip on lane -1 at position 10
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: -1)
        
        timeline.clips = [clip1, clip2, clip3]
        
        // Insert with ripple on primary only
        let newClip = TimelineClip(assetRef: "r4", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(
            newClip,
            at: CMTime(value: 5, timescale: 1),
            rippleLanes: .primaryOnly
        )
        
        // Only clip1 (lane 0) should be shifted
        #expect(result.shiftedClips.count == 1)
        #expect(result.shiftedClips[0].clipIndex == 0) // clip1 is at index 0
    }
    
    @Test("Ripple single lane only affects that lane")
    func rippleSingleLaneOnlyAffectsThatLane() {
        var timeline = Timeline(name: "Test")
        
        // Add clips on lanes 0, 1, 2 at position 10
        let clip0 = TimelineClip(assetRef: "r0", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 1)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 2)
        
        timeline.clips = [clip0, clip1, clip2]
        
        // Insert with ripple on lane 1 only
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 1)
        let result = timeline.insertClipWithRipple(
            newClip,
            at: CMTime(value: 5, timescale: 1),
            lane: 1,
            rippleLanes: .single(1)
        )
        
        // Only clip1 (lane 1) should be shifted
        #expect(result.shiftedClips.count == 1)
        #expect(result.shiftedClips[0].clipIndex == 1) // clip1 is at index 1
    }
    
    @Test("Ripple range affects lanes in range")
    func rippleRangeAffectsLanesInRange() {
        var timeline = Timeline(name: "Test")
        
        // Add clips on lanes -1, 0, 1, 2 at position 10
        let clipNeg1 = TimelineClip(assetRef: "r-1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: -1)
        let clip0 = TimelineClip(assetRef: "r0", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 1)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 2)
        
        timeline.clips = [clipNeg1, clip0, clip1, clip2]
        
        // Insert with ripple on lanes 0...1
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(
            newClip,
            at: CMTime(value: 5, timescale: 1),
            rippleLanes: .range(0...1)
        )
        
        // Only clip0 and clip1 should be shifted
        #expect(result.shiftedClips.count == 2)
        let shiftedIndices = Set(result.shiftedClips.map { $0.clipIndex })
        #expect(shiftedIndices.contains(1)) // clip0 is at index 1
        #expect(shiftedIndices.contains(2)) // clip1 is at index 2
        let _isFalse1 = !(shiftedIndices.contains(0))
        #expect(_isFalse1) // clipNeg1 is at index 0
        let _isFalse2 = !(shiftedIndices.contains(3))
        #expect(_isFalse2) // clip2 is at index 3
    }
    
    @Test("Ripple all affects all lanes")
    func rippleAllAffectsAllLanes() {
        var timeline = Timeline(name: "Test")
        
        // Add clips on lanes -1, 0, 1, 2 at position 10
        let clipNeg1 = TimelineClip(assetRef: "r-1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: -1)
        let clip0 = TimelineClip(assetRef: "r0", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 1)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 2)
        
        timeline.clips = [clipNeg1, clip0, clip1, clip2]
        
        // Insert with ripple on all lanes
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(
            newClip,
            at: CMTime(value: 5, timescale: 1),
            rippleLanes: .all
        )
        
        // All 4 clips should be shifted
        #expect(result.shiftedClips.count == 4)
    }
    
    // MARK: - Clip Shift Amount Tests
    
    @Test("Clip shift amount matches insert duration")
    func clipShiftAmountMatchesInsertDuration() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        // Insert 7.5 second clip
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 15, timescale: 2), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        #expect(result.shiftedClips.count == 1)
        #expect(abs((CMTimeGetSeconds(result.shiftedClips[0].shiftAmount)) - (7.5)) < 0.001)
    }
    
    // MARK: - Timeline State After Ripple Tests
    
    @Test("Timeline duration updates after ripple")
    func timelineDurationUpdatesAfterRipple() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        #expect(abs((CMTimeGetSeconds(timeline.duration)) - (10.0)) < 0.001)
        
        // Insert 5s clip at beginning with ripple
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        _ = timeline.insertClipWithRipple(newClip, at: .zero)
        
        // Duration should now be 15s (5s new clip + shifted 10s clip)
        #expect(abs((CMTimeGetSeconds(timeline.duration)) - (15.0)) < 0.001)
    }
    
    @Test("Clip count updates after ripple")
    func clipCountUpdatesAfterRipple() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        #expect(timeline.clipCount == 1)
        
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        _ = timeline.insertClipWithRipple(newClip, at: .zero)
        
        #expect(timeline.clipCount == 2)
    }
    
    // MARK: - Immutable Ripple Insert Tests
    
    @Test("Inserting clip with ripple returns new timeline")
    func insertingClipWithRippleReturnsNewTimeline() {
        let timeline = Timeline(name: "Test")
        
        // Add clip at 0-10s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Insert clip at 15s (after clip1 ends, so clip1 won't be shifted)
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let (newTimeline, result) = timelineWithClip.insertingClipWithRipple(newClip, at: CMTime(value: 15, timescale: 1))
        
        // Original timeline should be unchanged
        #expect(timelineWithClip.clips.count == 1)
        
        // New timeline should have both clips
        #expect(newTimeline.clips.count == 2)
        
        // Result should contain no shifts (clip1 starts at 0, which is < 15)
        #expect(result.shiftedClips.count == 0)
        
        // Now test with a clip that will be shifted
        let clip2 = TimelineClip(assetRef: "r3", offset: CMTime(value: 20, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let timelineWithTwoClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2])
        
        // Insert at 5s - clip2 (at 20s) should be shifted
        let (newTimeline2, result2) = timelineWithTwoClips.insertingClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        #expect(newTimeline2.clips.count == 3)
        #expect(result2.shiftedClips.count == 1) // clip2 should be shifted
    }
    
    // MARK: - Edge Cases
    
    @Test("Ripple insert at exact clip start")
    func rippleInsertAtExactClipStart() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        // Insert at exact start of existing clip
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 10, timescale: 1))
        
        // Clip should be shifted
        #expect(result.shiftedClips.count == 1)
        #expect(abs((CMTimeGetSeconds(result.shiftedClips[0].originalOffset)) - (10.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(result.shiftedClips[0].newOffset)) - (15.0)) < 0.001)
    }
    
    @Test("Ripple insert with zero duration")
    func rippleInsertWithZeroDuration() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        // Insert zero-duration clip
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: .zero, lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        // Clip should not be shifted (zero duration)
        #expect(result.shiftedClips.count == 0)
        #expect(timeline.clips.count == 2)
    }
    
    @Test("Ripple insert multiple clips on same lane")
    func rippleInsertMultipleClipsOnSameLane() {
        var timeline = Timeline(name: "Test")
        
        // Add multiple clips on lane 0
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 0, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        timeline.clips = [clip1, clip2, clip3]
        
        // Insert at position 7 (between clip2 and clip3)
        let newClip = TimelineClip(assetRef: "r4", offset: .zero, duration: CMTime(value: 3, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 7, timescale: 1))
        
        // clip3 should be shifted (starts at 10, which is >= 7)
        #expect(result.shiftedClips.count == 1)
        #expect(result.shiftedClips[0].clipIndex == 2) // clip3 is at index 2
    }
    
    // MARK: - Auto Lane Assignment Tests
    
    @Test("Auto lane assignment finds available lane")
    func autoLaneAssignmentFindsAvailableLane() throws {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at 0-10s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip1]
        
        // Insert overlapping clip with auto lane
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let placement = try insertClipAutoLaneOrFail(clip2, into: &timeline, at: CMTime(value: 5, timescale: 1), preferredLane: 0)

        // Should be placed on lane 1 (first available)
        #expect(placement.lane == 1)
        #expect(abs((CMTimeGetSeconds(placement.offset)) - (5.0)) < 0.001)
    }
    
    @Test("Auto lane assignment uses preferred when available")
    func autoLaneAssignmentUsesPreferredWhenAvailable() throws {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at 0-10s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip1]
        
        // Insert non-overlapping clip on lane 0
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let placement = try insertClipAutoLaneOrFail(clip2, into: &timeline, at: CMTime(value: 15, timescale: 1), preferredLane: 0)

        // Should use preferred lane 0
        #expect(placement.lane == 0)
    }
    
    @Test("Auto lane assignment throws when disabled and conflict")
    func autoLaneAssignmentThrowsWhenDisabledAndConflict() {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip1]
        
        // Try to insert overlapping clip with auto-assign disabled
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        do {
            _ = try timeline.insertClipAutoLane(clip2, at: CMTime(value: 5, timescale: 1), preferredLane: 0, autoAssignLane: false)
            Issue.record("Expected TimelineError.noAvailableLane")
        } catch TimelineError.noAvailableLane(let offset, let duration) {
            #expect(abs(CMTimeGetSeconds(offset) - 5.0) < 0.001)
            #expect(abs(CMTimeGetSeconds(duration) - 10.0) < 0.001)
        } catch {
            Issue.record("Expected TimelineError.noAvailableLane, got \(error)")
        }
    }
    
    @Test("Find available lane searches outward")
    func findAvailableLaneSearchesOutward() {
        let timeline = Timeline(name: "Test")
        
        // Fill lanes 0 and 1
        let clip0 = TimelineClip(assetRef: "r0", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip0, clip1])
        
        // Find available lane starting from 0
        let availableLane = timelineWithClips.findAvailableLane(at: .zero, duration: CMTime(value: 10, timescale: 1), startingFrom: 0)
        
        // With lanes 0 and 1 occupied and deterministic outward search (+distance then -distance),
        // lane +1 is blocked, so the next check is lane -1, which is selected.
        #expect(availableLane == -1)
    }
    
    @Test("Find available lane returns preferred when available")
    func findAvailableLaneReturnsPreferredWhenAvailable() {
        let timeline = Timeline(name: "Test")
        
        // Add clip on lane 1 only
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 1)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Find available lane starting from 0
        let availableLane = timelineWithClip.findAvailableLane(at: .zero, duration: CMTime(value: 10, timescale: 1), startingFrom: 0)
        
        // Should return preferred lane 0 (available)
        #expect(availableLane == 0)
    }
    
    @Test("Find available lane handles partial overlap")
    func findAvailableLaneHandlesPartialOverlap() {
        let timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at 5-15s
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Try to insert at 0-10s (overlaps with clip1)
        let availableLane = timelineWithClip.findAvailableLane(at: .zero, duration: CMTime(value: 10, timescale: 1), startingFrom: 0)
        
        // Should find a different lane (not 0)
        #expect(availableLane != 0)
    }
    
    @Test("Insert clip auto lane immutable version")
    func insertClipAutoLaneImmutableVersion() throws {
        let timeline = Timeline(name: "Test")
        
        // Add clip on lane 0
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Insert overlapping clip
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let (newTimeline, placement) = try insertingClipAutoLaneOrFail(clip2, into: timelineWithClip, at: CMTime(value: 5, timescale: 1))

        // Original timeline should be unchanged
        #expect(timelineWithClip.clips.count == 1)
        
        // New timeline should have both clips
        #expect(newTimeline.clips.count == 2)
        
        // Placement should be on a different lane
        #expect(placement.lane != 0)
    }
    
    @Test("Auto lane assignment with multiple conflicts")
    func autoLaneAssignmentWithMultipleConflicts() throws {
        var timeline = Timeline(name: "Test")
        
        // Fill lanes 0, 1, 2
        let clip0 = TimelineClip(assetRef: "r0", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 1)
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 2)
        
        timeline.clips = [clip0, clip1, clip2]
        
        // Insert overlapping clip
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let placement = try insertClipAutoLaneOrFail(newClip, into: &timeline, at: .zero, preferredLane: 0)

        // With lanes 0–2 filled and deterministic outward search (+distance then -distance),
        // lane +1 is occupied first, then lane -1 is the first free result.
        #expect(placement.lane == -1)
    }
    
    // MARK: - Advanced Clip Queries Tests
    
    @Test("Clips on lane filters correctly")
    func clipsOnLaneFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        let clip0a = TimelineClip(assetRef: "r0a", offset: CMTime(value: 0, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip0b = TimelineClip(assetRef: "r0b", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip0a, clip0b, clip1])
        
        let lane0Clips = timelineWithClips.clips(onLane: 0)
        let lane1Clips = timelineWithClips.clips(onLane: 1)
        
        #expect(lane0Clips.count == 2)
        #expect(lane1Clips.count == 1)
        
        // Verify sorted order
        #expect(lane0Clips[0].assetRef == "r0a")
        #expect(lane0Clips[1].assetRef == "r0b")
    }
    
    @Test("Clips in range filters correctly")
    func clipsInRangeFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        // Clips at 0-5, 5-10, 10-15
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        // Query range 3-12 should find all three clips (all overlap)
        let clipsInRange = timelineWithClips.clips(inRange: CMTime(value: 3, timescale: 1), end: CMTime(value: 12, timescale: 1))
        
        #expect(clipsInRange.count == 3)
        
        // Query range 6-8 should find only clip2
        let clipsInRange2 = timelineWithClips.clips(inRange: CMTime(value: 6, timescale: 1), end: CMTime(value: 8, timescale: 1))
        
        #expect(clipsInRange2.count == 1)
        #expect(clipsInRange2[0].assetRef == "r2")
    }
    
    @Test("Clips with asset ref filters correctly")
    func clipsWithAssetRefFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        let clipsWithR1 = timelineWithClips.clips(withAssetRef: "r1")
        
        #expect(clipsWithR1.count == 2)
        #expect(clipsWithR1[0].assetRef == "r1")
        #expect(clipsWithR1[1].assetRef == "r1")
        
        // Verify sorted order
        #expect(abs((CMTimeGetSeconds(clipsWithR1[0].offset)) - (0.0)) < 0.001)
        #expect(abs((CMTimeGetSeconds(clipsWithR1[1].offset)) - (10.0)) < 0.001)
    }
    
    @Test("All placements returns all clips")
    func allPlacementsReturnsAllClips() {
        let timeline = Timeline(name: "Test")
        
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        let placements = timelineWithClips.allPlacements()
        
        #expect(placements.count == 3)
    }
    
    @Test("Placements on lane filters correctly")
    func placementsOnLaneFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        let clip0a = TimelineClip(assetRef: "r0a", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip0b = TimelineClip(assetRef: "r0b", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip0a, clip0b, clip1])
        
        let lane0Placements = timelineWithClips.placements(onLane: 0)
        let lane1Placements = timelineWithClips.placements(onLane: 1)
        
        #expect(lane0Placements.count == 2)
        #expect(lane1Placements.count == 1)
    }
    
    @Test("Placements in range filters correctly")
    func placementsInRangeFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        // Clips at 0-5, 5-10, 10-15
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        // Query range 3-12 should find all three clips
        let placements = timelineWithClips.placements(inRange: CMTime(value: 3, timescale: 1), end: CMTime(value: 12, timescale: 1))
        
        #expect(placements.count == 3)
    }
    
    @Test("Lane range with multiple lanes")
    func laneRangeWithMultipleLanes() throws {
        let timeline = Timeline(name: "Test")
        
        let clipNeg2 = TimelineClip(assetRef: "r-2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: -2)
        let clip0 = TimelineClip(assetRef: "r0", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 3)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clipNeg2, clip0, clip3])
        
        let range = try #require(timelineWithClips.laneRange)
        #expect(range.lowerBound == -2)
        #expect(range.upperBound == 3)
    }
    
    @Test("Lane range empty timeline")
    func laneRangeEmptyTimeline() {
        let timeline = Timeline(name: "Test")
        
        #expect(timeline.laneRange == nil)
    }
    
    // MARK: - Timeline Metadata Tests
    
    @Test("Timeline markers management")
    func timelineMarkersManagement() {
        var timeline = Timeline(name: "Test")
        
        let marker1 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker 1")
        let marker2 = Marker(start: CMTime(value: 10, timescale: 1), value: "Marker 2")
        
        timeline.addMarker(marker1)
        timeline.addMarker(marker2)
        
        #expect(timeline.markers.count == 2)
        
        let sorted = timeline.sortedMarkers
        #expect(sorted[0].value == "Marker 1")
        #expect(sorted[1].value == "Marker 2")
        
        let removedMarker = timeline.removeMarker(marker1)
        #expect(removedMarker)
        #expect(timeline.markers.count == 1)
        let removedAgain = timeline.removeMarker(marker1)
        #expect(!removedAgain) // Already removed
    }
    
    @Test("Timeline chapter markers management")
    func timelineChapterMarkersManagement() {
        var timeline = Timeline(name: "Test")
        
        let chapter1 = ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Chapter 1")
        let chapter2 = ChapterMarker(start: CMTime(value: 30, timescale: 1), value: "Chapter 2")
        
        timeline.addChapterMarker(chapter1)
        timeline.addChapterMarker(chapter2)
        
        #expect(timeline.chapterMarkers.count == 2)
        
        let sorted = timeline.sortedChapterMarkers
        #expect(sorted[0].value == "Chapter 1")
        #expect(sorted[1].value == "Chapter 2")
        
        let removedChapter = timeline.removeChapterMarker(chapter1)
        #expect(removedChapter)
        #expect(timeline.chapterMarkers.count == 1)
    }
    
    @Test("Timeline keywords management")
    func timelineKeywordsManagement() {
        var timeline = Timeline(name: "Test")
        
        let keyword1 = Keyword(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: "Action"
        )
        let keyword2 = Keyword(
            start: CMTime(value: 10, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: "Drama"
        )
        
        timeline.addKeyword(keyword1)
        timeline.addKeyword(keyword2)
        
        #expect(timeline.keywords.count == 2)
        
        let sorted = timeline.sortedKeywords
        #expect(sorted[0].value == "Action")
        #expect(sorted[1].value == "Drama")
        
        let removedKeyword = timeline.removeKeyword(keyword1)
        #expect(removedKeyword)
        #expect(timeline.keywords.count == 1)
    }
    
    @Test("Timeline ratings management")
    func timelineRatingsManagement() {
        var timeline = Timeline(name: "Test")
        
        let rating1 = Rating(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 5, timescale: 1),
            value: .favorite
        )
        let rating2 = Rating(
            start: CMTime(value: 5, timescale: 1),
            duration: CMTime(value: 5, timescale: 1),
            value: .rejected
        )
        
        timeline.addRating(rating1)
        timeline.addRating(rating2)
        
        #expect(timeline.ratings.count == 2)
        
        let sorted = timeline.sortedRatings
        #expect(sorted[0].value == .favorite)
        #expect(sorted[1].value == .rejected)
        
        let removedRating = timeline.removeRating(rating1)
        #expect(removedRating)
        #expect(timeline.ratings.count == 1)
    }
    
    @Test("Timeline custom metadata")
    func timelineCustomMetadata() {
        var timeline = Timeline(name: "Test")
        
        var metadata = Metadata()
        metadata.setScene("Scene 1")
        metadata.setTake("Take 3")
        metadata.setReel("Reel A")
        
        timeline.metadata = metadata
        
        #expect(timeline.metadata != nil)
        #expect(timeline.metadata?[Metadata.Key.scene] == "Scene 1")
        #expect(timeline.metadata?[Metadata.Key.take] == "Take 3")
        #expect(timeline.metadata?[Metadata.Key.reel] == "Reel A")
    }
    
    @Test("Timeline initialization with metadata")
    func timelineInitializationWithMetadata() {
        let marker = Marker(start: CMTime(value: 5, timescale: 1), value: "Test Marker")
        let chapter = ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Chapter 1")
        let keyword = Keyword(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: "Action"
        )
        let rating = Rating(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 5, timescale: 1),
            value: .favorite
        )
        var metadata = Metadata()
        metadata.setScene("Scene 1")
        
        let timeline = Timeline(
            name: "Test",
            markers: [marker],
            chapterMarkers: [chapter],
            keywords: [keyword],
            ratings: [rating],
            metadata: metadata
        )
        
        #expect(timeline.markers.count == 1)
        #expect(timeline.chapterMarkers.count == 1)
        #expect(timeline.keywords.count == 1)
        #expect(timeline.ratings.count == 1)
        #expect(timeline.metadata != nil)
    }
    
    // MARK: - Clip Metadata Tests
    
    @Test("Clip markers management")
    func clipMarkersManagement() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        let marker1 = Marker(start: CMTime(value: 2, timescale: 1), value: "Clip Marker 1")
        let marker2 = Marker(start: CMTime(value: 5, timescale: 1), value: "Clip Marker 2")
        
        clip.addMarker(marker1)
        clip.addMarker(marker2)
        
        #expect(clip.markers.count == 2)
        
        let removedMarker = clip.removeMarker(marker1)
        #expect(removedMarker)
        #expect(clip.markers.count == 1)
    }
    
    @Test("Clip chapter markers management")
    func clipChapterMarkersManagement() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        let chapter = ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Clip Chapter")
        
        clip.addChapterMarker(chapter)
        
        #expect(clip.chapterMarkers.count == 1)
        
        let removedChapter = clip.removeChapterMarker(chapter)
        #expect(removedChapter)
        #expect(clip.chapterMarkers.count == 0)
    }
    
    @Test("Clip keywords management")
    func clipKeywordsManagement() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        let keyword = Keyword(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: "Action"
        )
        
        clip.addKeyword(keyword)
        
        #expect(clip.keywords.count == 1)
        
        let removedKeyword = clip.removeKeyword(keyword)
        #expect(removedKeyword)
        #expect(clip.keywords.count == 0)
    }
    
    @Test("Clip ratings management")
    func clipRatingsManagement() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        let rating = Rating(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: .favorite
        )
        
        clip.addRating(rating)
        
        #expect(clip.ratings.count == 1)
        
        let removedRating = clip.removeRating(rating)
        #expect(removedRating)
        #expect(clip.ratings.count == 0)
    }
    
    @Test("Clip custom metadata")
    func clipCustomMetadata() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        var metadata = Metadata()
        metadata.setCameraName("Camera A")
        metadata.setCameraAngle("Wide")
        
        clip.metadata = metadata
        
        #expect(clip.metadata != nil)
        #expect(clip.metadata?[Metadata.Key.cameraName] == "Camera A")
        #expect(clip.metadata?[Metadata.Key.cameraAngle] == "Wide")
    }
    
    @Test("Clip initialization with metadata")
    func clipInitializationWithMetadata() {
        let marker = Marker(start: CMTime(value: 5, timescale: 1), value: "Clip Marker")
        let keyword = Keyword(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: "Action"
        )
        var metadata = Metadata()
        metadata.setCameraName("Camera A")
        
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            markers: [marker],
            keywords: [keyword],
            metadata: metadata
        )
        
        #expect(clip.markers.count == 1)
        #expect(clip.keywords.count == 1)
        #expect(clip.metadata != nil)
    }
    
    @Test("Timeline metadata equality")
    func timelineMetadataEquality() {
        let marker1 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker")
        let marker2 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker")
        
        let timestamp = Date(timeIntervalSince1970: 1000)
        let timeline1 = Timeline(name: "Test", markers: [marker1], createdAt: timestamp, modifiedAt: timestamp)
        let timeline2 = Timeline(name: "Test", markers: [marker2], createdAt: timestamp, modifiedAt: timestamp)
        
        #expect(timeline1 == timeline2)
    }
    
    @Test("Clip metadata equality")
    func clipMetadataEquality() {
        let marker1 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker")
        let marker2 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker")
        
        let clip1 = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            markers: [marker1]
        )
        let clip2 = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            markers: [marker2]
        )
        
        #expect(clip1 == clip2)
    }
    
    // MARK: - Timestamps Tests
    
    @Test("Timeline timestamps initialization")
    func timelineTimestampsInitialization() {
        // Use a fixed baseline time to keep this test deterministic and avoid clock races.
        let baseline = Date(timeIntervalSince1970: 1000)
        let timeline = Timeline(
            name: "Test",
            createdAt: baseline,
            modifiedAt: baseline
        )
        
        // Timestamps should match injected baseline.
        #expect(timeline.createdAt == baseline)
        #expect(timeline.modifiedAt == baseline)
    }
    
    @Test("Timeline timestamps custom initialization")
    func timelineTimestampsCustomInitialization() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let modifiedAt = Date(timeIntervalSince1970: 2000)
        
        let timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt == modifiedAt)
    }
    
    @Test("Timeline modified at updates on ripple insert")
    func timelineModifiedAtUpdatesOnRippleInsert() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        var timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        _ = timeline.insertClipWithRipple(clip, at: .zero)
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline modified at updates on auto lane insert")
    func timelineModifiedAtUpdatesOnAutoLaneInsert() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        var timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        _ = try insertClipAutoLaneOrFail(clip, into: &timeline, at: .zero)

        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline modified at updates on add marker")
    func timelineModifiedAtUpdatesOnAddMarker() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        var timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        let marker = Marker(start: CMTime(value: 5, timescale: 1), value: "Test")
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        timeline.addMarker(marker)
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline modified at updates on remove marker")
    func timelineModifiedAtUpdatesOnRemoveMarker() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        let marker = Marker(start: CMTime(value: 5, timescale: 1), value: "Test")
        var timeline = Timeline(
            name: "Test",
            markers: [marker],
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        _ = timeline.removeMarker(marker)
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline modified at updates on add chapter marker")
    func timelineModifiedAtUpdatesOnAddChapterMarker() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        var timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        let chapterMarker = ChapterMarker(start: CMTime(value: 5, timescale: 1), value: "Chapter 1")
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        timeline.addChapterMarker(chapterMarker)
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline modified at updates on add keyword")
    func timelineModifiedAtUpdatesOnAddKeyword() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        var timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        let keyword = Keyword(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: "Action"
        )
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        timeline.addKeyword(keyword)
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline modified at updates on add rating")
    func timelineModifiedAtUpdatesOnAddRating() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let nowBox = NowBox(createdAt)
        var timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: makeSyncNowProvider(nowBox: nowBox)
        )
        
        let rating = Rating(
            start: CMTime(value: 0, timescale: 1),
            duration: CMTime(value: 10, timescale: 1),
            value: .favorite
        )
        
        syncSetNow(createdAt.addingTimeInterval(1), on: nowBox)
        timeline.addRating(rating)
        
        #expect(timeline.createdAt == createdAt)
        #expect(timeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline created at preserved on immutable operations")
    func timelineCreatedAtPreservedOnImmutableOperations() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let modifiedNow = createdAt.addingTimeInterval(1)
        let timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: createdAt,
            nowProvider: { modifiedNow }
        )
        
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )
        
        let (newTimeline, _) = timeline.insertingClipWithRipple(clip, at: .zero)
        
        #expect(newTimeline.createdAt == createdAt)
        #expect(newTimeline.modifiedAt > createdAt)
    }
    
    @Test("Timeline timestamps equality")
    func timelineTimestampsEquality() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let modifiedAt = Date(timeIntervalSince1970: 2000)
        
        let timeline1 = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
        
        let timeline2 = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
        
        #expect(timeline1 == timeline2)
        #expect(timeline1.createdAt == timeline2.createdAt)
        #expect(timeline1.modifiedAt == timeline2.modifiedAt)
    }
    
    // MARK: - File Tests
    
    @Test("Timeline sample")
    func timelineSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "TimelineSample")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let projects = fcpxml.allProjects()
        let _notMatch1 = !(projects.isEmpty)
        #expect(_notMatch1, "Expected at least one project")
        
        let project = try #require(projects.first)
        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        let _notMatch2 = !(storyElements.isEmpty)
        #expect(_notMatch2, "Expected story elements in timeline")

        // Validate that the loaded timeline contains at least one primary clip-like element
        let clipLikeElements = storyElements.filter { element in
            element.name == "clip" || element.name == "asset-clip"
        }
        let _notMatch3 = !(clipLikeElements.isEmpty)
        #expect(_notMatch3, "Expected at least one clip or asset-clip in primary storyline")

        // Ensure each clip-like element has a duration attribute, which is required for timeline manipulation
        for element in clipLikeElements {
            #expect(element.attribute(forName: "duration") != nil, "Clip \(element.name ?? "?") should have a duration attribute")
        }
    }

    @Test("Timeline with secondary storyline")
    func timelineWithSecondaryStoryline() throws {
        let fcpxml = try requireFCPXMLSample(named: "TimelineWithSecondaryStoryline")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let projects = fcpxml.allProjects()
        let _notMatch4 = !(projects.isEmpty)
        #expect(_notMatch4, "Expected at least one project")
        
        let project = try #require(projects.first)
        let sequence = project.sequence
        let spine = sequence.spine
        
        // Check for secondary storylines (spine elements within clips)
        var foundSecondaryStoryline = false
        for element in Array(spine.storyElements) {
            if element.name == "clip" || element.name == "asset-clip" {
                let nestedSpines = element.childElements.filter { $0.name == "spine" }
                if !nestedSpines.isEmpty {
                    foundSecondaryStoryline = true
                    break
                }
            }
        }
        #expect(foundSecondaryStoryline, "Should find secondary storyline")
    }

    @Test("Timeline with secondary storyline with audio keyframes")
    func timelineWithSecondaryStorylineWithAudioKeyframes() throws {
        let fcpxml = try requireFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let projects = fcpxml.allProjects()
        let _notMatch5 = !(projects.isEmpty)
        #expect(_notMatch5, "Expected at least one project")
        
        let project = try #require(projects.first)
        let sequence = project.sequence
        let spine = sequence.spine
        
        // Check for audio keyframes (adjust-volume with keyframeAnimation) in clips
        var foundAudioKeyframes = false
        func checkForAudioKeyframes(in element: any OFKXMLElement) {
            // Check if this element has adjust-volume with keyframeAnimation
            if let adjustVolume = element.firstChildElement(named: "adjust-volume") {
                let param = adjustVolume.firstChildElement(named: "param")
                if param?.firstChildElement(named: "keyframeAnimation") != nil {
                    foundAudioKeyframes = true
                    return
                }
            }
            // Recursively check children (including nested clips and spines)
            for child in element.childElements {
                checkForAudioKeyframes(in: child)
                if foundAudioKeyframes { return }
            }
        }
        
        for element in Array(spine.storyElements) {
            checkForAudioKeyframes(in: element)
            if foundAudioKeyframes { break }
        }
        #expect(foundAudioKeyframes, "Should find audio keyframes with keyframeAnimation")
    }
}
