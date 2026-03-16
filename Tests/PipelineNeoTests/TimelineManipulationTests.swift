//
//  TimelineManipulationTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for timeline manipulation features: ripple insert, auto lane assignment, etc.
//

import XCTest
import CoreMedia
@testable import PipelineNeo

/// Thread-safe mutable box for injectable "now" in timestamp tests, implemented as a class with explicit synchronization
/// to avoid blocking on async actor operations from synchronous test code (and to avoid DispatchSemaphore deadlock risk).
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
private func makeSyncNowProvider(nowBox: NowBox) -> @Sendable () -> Date {
    return {
        nowBox.getValue()
    }
}

/// Synchronously sets the box's value from synchronous test code.
private func syncSetNow(_ value: Date, on nowBox: NowBox) {
    nowBox.setValue(value)
}

@available(macOS 12.0, *)
final class TimelineManipulationTests: XCTestCase {

    // MARK: - Ripple Insert Basic Tests
    
    func testRippleInsertShiftsSubsequentClips() {
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
        XCTAssertEqual(CMTimeGetSeconds(result.insertedClip.offset), 5.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(result.insertedClip.duration), 5.0, accuracy: 0.001)
        
        // Verify shifts: clip2 and clip3 should be shifted by 5s
        XCTAssertEqual(result.shiftedClips.count, 2)
        
        // Find clip2's shift (was at index 1)
        let clip2Shift = result.shiftedClips.first { $0.clipIndex == 1 }
        XCTAssertNotNil(clip2Shift)
        XCTAssertEqual(CMTimeGetSeconds(clip2Shift!.originalOffset), 10.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(clip2Shift!.newOffset), 15.0, accuracy: 0.001)
        
        // Find clip3's shift (was at index 2)
        let clip3Shift = result.shiftedClips.first { $0.clipIndex == 2 }
        XCTAssertNotNil(clip3Shift)
        XCTAssertEqual(CMTimeGetSeconds(clip3Shift!.originalOffset), 20.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(clip3Shift!.newOffset), 25.0, accuracy: 0.001)
        
        // clip1 should NOT be shifted (starts before insert point)
        let clip1Shift = result.shiftedClips.first { $0.clipIndex == 0 }
        XCTAssertNil(clip1Shift)
        
        // Verify timeline state
        XCTAssertEqual(timeline.clips.count, 4)
        let sorted = timeline.sortedClips
        XCTAssertEqual(CMTimeGetSeconds(sorted[0].offset), 0.0, accuracy: 0.001) // clip1
        XCTAssertEqual(CMTimeGetSeconds(sorted[1].offset), 5.0, accuracy: 0.001) // newClip
        XCTAssertEqual(CMTimeGetSeconds(sorted[2].offset), 15.0, accuracy: 0.001) // clip2 shifted
        XCTAssertEqual(CMTimeGetSeconds(sorted[3].offset), 25.0, accuracy: 0.001) // clip3 shifted
    }
    
    func testRippleInsertDoesNotShiftClipsBeforeInsertPoint() {
        var timeline = Timeline(name: "Test")
        
        // Add clips
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        timeline.clips = [clip1, clip2]
        
        // Insert at position 15 (after clip1 end, but clip2 starts at 10, so it will be shifted)
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 15, timescale: 1))
        
        // clip2 starts at 10, which is before 15, so under this behavior only clips whose *start time*
        // is at or after the insert point are shifted; overlapping clips that start before 15 are not.
        XCTAssertEqual(result.shiftedClips.count, 0)
        
        // Verify new clip was inserted
        XCTAssertEqual(CMTimeGetSeconds(result.insertedClip.offset), 15.0, accuracy: 0.001)
    }
    
    func testRippleInsertAtTimelineStart() {
        var timeline = Timeline(name: "Test")
        
        // Add clips
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        timeline.clips = [clip1, clip2]
        
        // Insert at position 0
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: .zero)
        
        // Both clips should be shifted
        XCTAssertEqual(result.shiftedClips.count, 2)
        
        // Verify clip1 was shifted
        let clip1Shift = result.shiftedClips.first { $0.clipIndex == 0 }
        XCTAssertNotNil(clip1Shift)
        XCTAssertEqual(CMTimeGetSeconds(clip1Shift!.originalOffset), 0.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(clip1Shift!.newOffset), 5.0, accuracy: 0.001)
        
        // Verify clip2 was shifted
        let clip2Shift = result.shiftedClips.first { $0.clipIndex == 1 }
        XCTAssertNotNil(clip2Shift)
        XCTAssertEqual(CMTimeGetSeconds(clip2Shift!.originalOffset), 10.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(clip2Shift!.newOffset), 15.0, accuracy: 0.001)
    }
    
    func testRippleInsertAtEmptyTimeline() {
        var timeline = Timeline(name: "Test")
        
        let newClip = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        XCTAssertEqual(CMTimeGetSeconds(result.insertedClip.offset), 5.0, accuracy: 0.001)
        XCTAssertEqual(result.shiftedClips.count, 0)
        XCTAssertEqual(timeline.clips.count, 1)
    }
    
    // MARK: - Ripple Lane Option Tests
    
    func testRipplePrimaryOnlyDoesNotShiftOtherLanes() {
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
        XCTAssertEqual(result.shiftedClips.count, 1)
        XCTAssertEqual(result.shiftedClips[0].clipIndex, 0) // clip1 is at index 0
    }
    
    func testRippleSingleLaneOnlyAffectsThatLane() {
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
        XCTAssertEqual(result.shiftedClips.count, 1)
        XCTAssertEqual(result.shiftedClips[0].clipIndex, 1) // clip1 is at index 1
    }
    
    func testRippleRangeAffectsLanesInRange() {
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
        XCTAssertEqual(result.shiftedClips.count, 2)
        let shiftedIndices = Set(result.shiftedClips.map { $0.clipIndex })
        XCTAssertTrue(shiftedIndices.contains(1)) // clip0 is at index 1
        XCTAssertTrue(shiftedIndices.contains(2)) // clip1 is at index 2
        XCTAssertFalse(shiftedIndices.contains(0)) // clipNeg1 is at index 0
        XCTAssertFalse(shiftedIndices.contains(3)) // clip2 is at index 3
    }
    
    func testRippleAllAffectsAllLanes() {
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
        XCTAssertEqual(result.shiftedClips.count, 4)
    }
    
    // MARK: - Clip Shift Amount Tests
    
    func testClipShiftAmountMatchesInsertDuration() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        // Insert 7.5 second clip
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 15, timescale: 2), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        XCTAssertEqual(result.shiftedClips.count, 1)
        XCTAssertEqual(CMTimeGetSeconds(result.shiftedClips[0].shiftAmount), 7.5, accuracy: 0.001)
    }
    
    // MARK: - Timeline State After Ripple Tests
    
    func testTimelineDurationUpdatesAfterRipple() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        XCTAssertEqual(CMTimeGetSeconds(timeline.duration), 10.0, accuracy: 0.001)
        
        // Insert 5s clip at beginning with ripple
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        _ = timeline.insertClipWithRipple(newClip, at: .zero)
        
        // Duration should now be 15s (5s new clip + shifted 10s clip)
        XCTAssertEqual(CMTimeGetSeconds(timeline.duration), 15.0, accuracy: 0.001)
    }
    
    func testClipCountUpdatesAfterRipple() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        XCTAssertEqual(timeline.clipCount, 1)
        
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        _ = timeline.insertClipWithRipple(newClip, at: .zero)
        
        XCTAssertEqual(timeline.clipCount, 2)
    }
    
    // MARK: - Immutable Ripple Insert Tests
    
    func testInsertingClipWithRippleReturnsNewTimeline() {
        let timeline = Timeline(name: "Test")
        
        // Add clip at 0-10s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Insert clip at 15s (after clip1 ends, so clip1 won't be shifted)
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let (newTimeline, result) = timelineWithClip.insertingClipWithRipple(newClip, at: CMTime(value: 15, timescale: 1))
        
        // Original timeline should be unchanged
        XCTAssertEqual(timelineWithClip.clips.count, 1)
        
        // New timeline should have both clips
        XCTAssertEqual(newTimeline.clips.count, 2)
        
        // Result should contain no shifts (clip1 starts at 0, which is < 15)
        XCTAssertEqual(result.shiftedClips.count, 0)
        
        // Now test with a clip that will be shifted
        let clip2 = TimelineClip(assetRef: "r3", offset: CMTime(value: 20, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let timelineWithTwoClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2])
        
        // Insert at 5s - clip2 (at 20s) should be shifted
        let (newTimeline2, result2) = timelineWithTwoClips.insertingClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        XCTAssertEqual(newTimeline2.clips.count, 3)
        XCTAssertEqual(result2.shiftedClips.count, 1) // clip2 should be shifted
    }
    
    // MARK: - Edge Cases
    
    func testRippleInsertAtExactClipStart() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        // Insert at exact start of existing clip
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 10, timescale: 1))
        
        // Clip should be shifted
        XCTAssertEqual(result.shiftedClips.count, 1)
        XCTAssertEqual(CMTimeGetSeconds(result.shiftedClips[0].originalOffset), 10.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(result.shiftedClips[0].newOffset), 15.0, accuracy: 0.001)
    }
    
    func testRippleInsertWithZeroDuration() {
        var timeline = Timeline(name: "Test")
        
        let clip = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip]
        
        // Insert zero-duration clip
        let newClip = TimelineClip(assetRef: "r2", offset: .zero, duration: .zero, lane: 0)
        let result = timeline.insertClipWithRipple(newClip, at: CMTime(value: 5, timescale: 1))
        
        // Clip should not be shifted (zero duration)
        XCTAssertEqual(result.shiftedClips.count, 0)
        XCTAssertEqual(timeline.clips.count, 2)
    }
    
    func testRippleInsertMultipleClipsOnSameLane() {
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
        XCTAssertEqual(result.shiftedClips.count, 1)
        XCTAssertEqual(result.shiftedClips[0].clipIndex, 2) // clip3 is at index 2
    }
    
    // MARK: - Auto Lane Assignment Tests
    
    func testAutoLaneAssignmentFindsAvailableLane() {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at 0-10s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip1]
        
        // Insert overlapping clip with auto lane
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let placement: ClipPlacement
        do {
            placement = try timeline.insertClipAutoLane(clip2, at: CMTime(value: 5, timescale: 1), preferredLane: 0)
        } catch {
            XCTFail("insertClipAutoLane threw unexpectedly: \(error)")
            return
        }

        // Should be placed on lane 1 (first available)
        XCTAssertEqual(placement.lane, 1)
        XCTAssertEqual(CMTimeGetSeconds(placement.offset), 5.0, accuracy: 0.001)
    }
    
    func testAutoLaneAssignmentUsesPreferredWhenAvailable() {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at 0-10s
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip1]
        
        // Insert non-overlapping clip on lane 0
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let placement: ClipPlacement
        do {
            placement = try timeline.insertClipAutoLane(clip2, at: CMTime(value: 15, timescale: 1), preferredLane: 0)
        } catch {
            XCTFail("insertClipAutoLane threw unexpectedly: \(error)")
            return
        }
        
        // Should use preferred lane 0
        XCTAssertEqual(placement.lane, 0)
    }
    
    func testAutoLaneAssignmentThrowsWhenDisabledAndConflict() {
        var timeline = Timeline(name: "Test")
        
        // Add clip on lane 0
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        timeline.clips = [clip1]
        
        // Try to insert overlapping clip with auto-assign disabled
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        
        XCTAssertThrowsError(try timeline.insertClipAutoLane(clip2, at: CMTime(value: 5, timescale: 1), preferredLane: 0, autoAssignLane: false)) { error in
            guard case TimelineError.noAvailableLane(let offset, let duration) = error else {
                XCTFail("Expected TimelineError.noAvailableLane, got \(error)"); return
            }
            XCTAssertEqual(CMTimeGetSeconds(offset), 5.0, accuracy: 0.001)
            XCTAssertEqual(CMTimeGetSeconds(duration), 10.0, accuracy: 0.001)
        }
    }
    
    func testFindAvailableLaneSearchesOutward() {
        let timeline = Timeline(name: "Test")
        
        // Fill lanes 0 and 1
        let clip0 = TimelineClip(assetRef: "r0", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip0, clip1])
        
        // Find available lane starting from 0
        let availableLane = timelineWithClips.findAvailableLane(at: .zero, duration: CMTime(value: 10, timescale: 1), startingFrom: 0)
        
        // Should find an available lane: 2 (positive) or -1 (negative); implementation alternates by distance.
        XCTAssertTrue(availableLane == 2 || availableLane == -1)
    }
    
    func testFindAvailableLaneReturnsPreferredWhenAvailable() {
        let timeline = Timeline(name: "Test")
        
        // Add clip on lane 1 only
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 1)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Find available lane starting from 0
        let availableLane = timelineWithClip.findAvailableLane(at: .zero, duration: CMTime(value: 10, timescale: 1), startingFrom: 0)
        
        // Should return preferred lane 0 (available)
        XCTAssertEqual(availableLane, 0)
    }
    
    func testFindAvailableLaneHandlesPartialOverlap() {
        let timeline = Timeline(name: "Test")
        
        // Add clip on lane 0 at 5-15s
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 10, timescale: 1), lane: 0)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Try to insert at 0-10s (overlaps with clip1)
        let availableLane = timelineWithClip.findAvailableLane(at: .zero, duration: CMTime(value: 10, timescale: 1), startingFrom: 0)
        
        // Should find a different lane (not 0)
        XCTAssertNotEqual(availableLane, 0)
    }
    
    func testInsertClipAutoLaneImmutableVersion() {
        let timeline = Timeline(name: "Test")
        
        // Add clip on lane 0
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let timelineWithClip = Timeline(name: timeline.name, format: timeline.format, clips: [clip1])
        
        // Insert overlapping clip
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let newTimeline: Timeline
        let placement: ClipPlacement
        do {
            let result = try timelineWithClip.insertingClipAutoLane(clip2, at: CMTime(value: 5, timescale: 1))
            newTimeline = result.0
            placement = result.1
        } catch {
            XCTFail("insertingClipAutoLane threw unexpectedly: \(error)")
            return
        }

        // Original timeline should be unchanged
        XCTAssertEqual(timelineWithClip.clips.count, 1)
        
        // New timeline should have both clips
        XCTAssertEqual(newTimeline.clips.count, 2)
        
        // Placement should be on a different lane
        XCTAssertNotEqual(placement.lane, 0)
    }
    
    func testAutoLaneAssignmentWithMultipleConflicts() {
        var timeline = Timeline(name: "Test")
        
        // Fill lanes 0, 1, 2
        let clip0 = TimelineClip(assetRef: "r0", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 1)
        let clip2 = TimelineClip(assetRef: "r2", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 2)
        
        timeline.clips = [clip0, clip1, clip2]
        
        // Insert overlapping clip
        let newClip = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 10, timescale: 1), lane: 0)
        let placement: ClipPlacement
        do {
            placement = try timeline.insertClipAutoLane(newClip, at: .zero, preferredLane: 0)
        } catch {
            XCTFail("insertClipAutoLane threw unexpectedly: \(error)")
            return
        }

        // With lanes 0–2 filled, auto-lane assignment returns the next free lane (3 or -1 depending on search order).
        XCTAssertTrue(placement.lane == 3 || placement.lane == -1)
    }
    
    // MARK: - Advanced Clip Queries Tests
    
    func testClipsOnLaneFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        let clip0a = TimelineClip(assetRef: "r0a", offset: CMTime(value: 0, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip0b = TimelineClip(assetRef: "r0b", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip0a, clip0b, clip1])
        
        let lane0Clips = timelineWithClips.clips(onLane: 0)
        let lane1Clips = timelineWithClips.clips(onLane: 1)
        
        XCTAssertEqual(lane0Clips.count, 2)
        XCTAssertEqual(lane1Clips.count, 1)
        
        // Verify sorted order
        XCTAssertEqual(lane0Clips[0].assetRef, "r0a")
        XCTAssertEqual(lane0Clips[1].assetRef, "r0b")
    }
    
    func testClipsInRangeFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        // Clips at 0-5, 5-10, 10-15
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        // Query range 3-12 should find all three clips (all overlap)
        let clipsInRange = timelineWithClips.clips(inRange: CMTime(value: 3, timescale: 1), end: CMTime(value: 12, timescale: 1))
        
        XCTAssertEqual(clipsInRange.count, 3)
        
        // Query range 6-8 should find only clip2
        let clipsInRange2 = timelineWithClips.clips(inRange: CMTime(value: 6, timescale: 1), end: CMTime(value: 8, timescale: 1))
        
        XCTAssertEqual(clipsInRange2.count, 1)
        XCTAssertEqual(clipsInRange2[0].assetRef, "r2")
    }
    
    func testClipsWithAssetRefFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r1", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        let clipsWithR1 = timelineWithClips.clips(withAssetRef: "r1")
        
        XCTAssertEqual(clipsWithR1.count, 2)
        XCTAssertEqual(clipsWithR1[0].assetRef, "r1")
        XCTAssertEqual(clipsWithR1[1].assetRef, "r1")
        
        // Verify sorted order
        XCTAssertEqual(CMTimeGetSeconds(clipsWithR1[0].offset), 0.0, accuracy: 0.001)
        XCTAssertEqual(CMTimeGetSeconds(clipsWithR1[1].offset), 10.0, accuracy: 0.001)
    }
    
    func testAllPlacementsReturnsAllClips() {
        let timeline = Timeline(name: "Test")
        
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        let placements = timelineWithClips.allPlacements()
        
        XCTAssertEqual(placements.count, 3)
    }
    
    func testPlacementsOnLaneFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        let clip0a = TimelineClip(assetRef: "r0a", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip0b = TimelineClip(assetRef: "r0b", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 1)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip0a, clip0b, clip1])
        
        let lane0Placements = timelineWithClips.placements(onLane: 0)
        let lane1Placements = timelineWithClips.placements(onLane: 1)
        
        XCTAssertEqual(lane0Placements.count, 2)
        XCTAssertEqual(lane1Placements.count, 1)
    }
    
    func testPlacementsInRangeFiltersCorrectly() {
        let timeline = Timeline(name: "Test")
        
        // Clips at 0-5, 5-10, 10-15
        let clip1 = TimelineClip(assetRef: "r1", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip2 = TimelineClip(assetRef: "r2", offset: CMTime(value: 5, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: CMTime(value: 10, timescale: 1), duration: CMTime(value: 5, timescale: 1), lane: 0)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clip1, clip2, clip3])
        
        // Query range 3-12 should find all three clips
        let placements = timelineWithClips.placements(inRange: CMTime(value: 3, timescale: 1), end: CMTime(value: 12, timescale: 1))
        
        XCTAssertEqual(placements.count, 3)
    }
    
    func testLaneRangeWithMultipleLanes() {
        let timeline = Timeline(name: "Test")
        
        let clipNeg2 = TimelineClip(assetRef: "r-2", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: -2)
        let clip0 = TimelineClip(assetRef: "r0", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 0)
        let clip3 = TimelineClip(assetRef: "r3", offset: .zero, duration: CMTime(value: 5, timescale: 1), lane: 3)
        
        let timelineWithClips = Timeline(name: timeline.name, format: timeline.format, clips: [clipNeg2, clip0, clip3])
        
        let range = timelineWithClips.laneRange
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.lowerBound, -2)
        XCTAssertEqual(range?.upperBound, 3)
    }
    
    func testLaneRangeEmptyTimeline() {
        let timeline = Timeline(name: "Test")
        
        XCTAssertNil(timeline.laneRange)
    }
    
    // MARK: - Timeline Metadata Tests
    
    func testTimelineMarkersManagement() {
        var timeline = Timeline(name: "Test")
        
        let marker1 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker 1")
        let marker2 = Marker(start: CMTime(value: 10, timescale: 1), value: "Marker 2")
        
        timeline.addMarker(marker1)
        timeline.addMarker(marker2)
        
        XCTAssertEqual(timeline.markers.count, 2)
        
        let sorted = timeline.sortedMarkers
        XCTAssertEqual(sorted[0].value, "Marker 1")
        XCTAssertEqual(sorted[1].value, "Marker 2")
        
        XCTAssertTrue(timeline.removeMarker(marker1))
        XCTAssertEqual(timeline.markers.count, 1)
        XCTAssertFalse(timeline.removeMarker(marker1)) // Already removed
    }
    
    func testTimelineChapterMarkersManagement() {
        var timeline = Timeline(name: "Test")
        
        let chapter1 = ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Chapter 1")
        let chapter2 = ChapterMarker(start: CMTime(value: 30, timescale: 1), value: "Chapter 2")
        
        timeline.addChapterMarker(chapter1)
        timeline.addChapterMarker(chapter2)
        
        XCTAssertEqual(timeline.chapterMarkers.count, 2)
        
        let sorted = timeline.sortedChapterMarkers
        XCTAssertEqual(sorted[0].value, "Chapter 1")
        XCTAssertEqual(sorted[1].value, "Chapter 2")
        
        XCTAssertTrue(timeline.removeChapterMarker(chapter1))
        XCTAssertEqual(timeline.chapterMarkers.count, 1)
    }
    
    func testTimelineKeywordsManagement() {
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
        
        XCTAssertEqual(timeline.keywords.count, 2)
        
        let sorted = timeline.sortedKeywords
        XCTAssertEqual(sorted[0].value, "Action")
        XCTAssertEqual(sorted[1].value, "Drama")
        
        XCTAssertTrue(timeline.removeKeyword(keyword1))
        XCTAssertEqual(timeline.keywords.count, 1)
    }
    
    func testTimelineRatingsManagement() {
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
        
        XCTAssertEqual(timeline.ratings.count, 2)
        
        let sorted = timeline.sortedRatings
        XCTAssertEqual(sorted[0].value, .favorite)
        XCTAssertEqual(sorted[1].value, .rejected)
        
        XCTAssertTrue(timeline.removeRating(rating1))
        XCTAssertEqual(timeline.ratings.count, 1)
    }
    
    func testTimelineCustomMetadata() {
        var timeline = Timeline(name: "Test")
        
        var metadata = Metadata()
        metadata.setScene("Scene 1")
        metadata.setTake("Take 3")
        metadata.setReel("Reel A")
        
        timeline.metadata = metadata
        
        XCTAssertNotNil(timeline.metadata)
        XCTAssertEqual(timeline.metadata?[Metadata.Key.scene], "Scene 1")
        XCTAssertEqual(timeline.metadata?[Metadata.Key.take], "Take 3")
        XCTAssertEqual(timeline.metadata?[Metadata.Key.reel], "Reel A")
    }
    
    func testTimelineInitializationWithMetadata() {
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
        
        XCTAssertEqual(timeline.markers.count, 1)
        XCTAssertEqual(timeline.chapterMarkers.count, 1)
        XCTAssertEqual(timeline.keywords.count, 1)
        XCTAssertEqual(timeline.ratings.count, 1)
        XCTAssertNotNil(timeline.metadata)
    }
    
    // MARK: - Clip Metadata Tests
    
    func testClipMarkersManagement() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        let marker1 = Marker(start: CMTime(value: 2, timescale: 1), value: "Clip Marker 1")
        let marker2 = Marker(start: CMTime(value: 5, timescale: 1), value: "Clip Marker 2")
        
        clip.addMarker(marker1)
        clip.addMarker(marker2)
        
        XCTAssertEqual(clip.markers.count, 2)
        
        XCTAssertTrue(clip.removeMarker(marker1))
        XCTAssertEqual(clip.markers.count, 1)
    }
    
    func testClipChapterMarkersManagement() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        let chapter = ChapterMarker(start: CMTime(value: 0, timescale: 1), value: "Clip Chapter")
        
        clip.addChapterMarker(chapter)
        
        XCTAssertEqual(clip.chapterMarkers.count, 1)
        
        XCTAssertTrue(clip.removeChapterMarker(chapter))
        XCTAssertEqual(clip.chapterMarkers.count, 0)
    }
    
    func testClipKeywordsManagement() {
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
        
        XCTAssertEqual(clip.keywords.count, 1)
        
        XCTAssertTrue(clip.removeKeyword(keyword))
        XCTAssertEqual(clip.keywords.count, 0)
    }
    
    func testClipRatingsManagement() {
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
        
        XCTAssertEqual(clip.ratings.count, 1)
        
        XCTAssertTrue(clip.removeRating(rating))
        XCTAssertEqual(clip.ratings.count, 0)
    }
    
    func testClipCustomMetadata() {
        var clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1)
        )
        
        var metadata = Metadata()
        metadata.setCameraName("Camera A")
        metadata.setCameraAngle("Wide")
        
        clip.metadata = metadata
        
        XCTAssertNotNil(clip.metadata)
        XCTAssertEqual(clip.metadata?[Metadata.Key.cameraName], "Camera A")
        XCTAssertEqual(clip.metadata?[Metadata.Key.cameraAngle], "Wide")
    }
    
    func testClipInitializationWithMetadata() {
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
        
        XCTAssertEqual(clip.markers.count, 1)
        XCTAssertEqual(clip.keywords.count, 1)
        XCTAssertNotNil(clip.metadata)
    }
    
    func testTimelineMetadataEquality() {
        let marker1 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker")
        let marker2 = Marker(start: CMTime(value: 5, timescale: 1), value: "Marker")
        
        let timestamp = Date(timeIntervalSince1970: 1000)
        let timeline1 = Timeline(name: "Test", markers: [marker1], createdAt: timestamp, modifiedAt: timestamp)
        let timeline2 = Timeline(name: "Test", markers: [marker2], createdAt: timestamp, modifiedAt: timestamp)
        
        XCTAssertEqual(timeline1, timeline2)
    }
    
    func testClipMetadataEquality() {
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
        
        XCTAssertEqual(clip1, clip2)
    }
    
    // MARK: - Timestamps Tests
    
    func testTimelineTimestampsInitialization() {
        let timeline = Timeline(name: "Test")
        
        // Timestamps should be set to current time (within a reasonable range)
        let now = Date()
        XCTAssertLessThan(abs(timeline.createdAt.timeIntervalSince(now)), 1.0)
        XCTAssertLessThan(abs(timeline.modifiedAt.timeIntervalSince(now)), 1.0)
        // createdAt and modifiedAt should be approximately equal (within 0.1 seconds)
        XCTAssertLessThan(abs(timeline.createdAt.timeIntervalSince(timeline.modifiedAt)), 0.1)
    }
    
    func testTimelineTimestampsCustomInitialization() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let modifiedAt = Date(timeIntervalSince1970: 2000)
        
        let timeline = Timeline(
            name: "Test",
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertEqual(timeline.modifiedAt, modifiedAt)
    }
    
    func testTimelineModifiedAtUpdatesOnRippleInsert() {
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
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineModifiedAtUpdatesOnAutoLaneInsert() {
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
        do {
            _ = try timeline.insertClipAutoLane(clip, at: .zero)
        } catch {
            XCTFail("Auto lane insert should not throw, got error: \(error)")
            return
        }
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineModifiedAtUpdatesOnAddMarker() {
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
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineModifiedAtUpdatesOnRemoveMarker() {
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
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineModifiedAtUpdatesOnAddChapterMarker() {
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
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineModifiedAtUpdatesOnAddKeyword() {
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
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineModifiedAtUpdatesOnAddRating() {
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
        
        XCTAssertEqual(timeline.createdAt, createdAt)
        XCTAssertGreaterThan(timeline.modifiedAt, createdAt)
    }
    
    func testTimelineCreatedAtPreservedOnImmutableOperations() {
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
        
        XCTAssertEqual(newTimeline.createdAt, createdAt)
        XCTAssertGreaterThan(newTimeline.modifiedAt, createdAt)
    }
    
    func testTimelineTimestampsEquality() {
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
        
        XCTAssertEqual(timeline1, timeline2)
        XCTAssertEqual(timeline1.createdAt, timeline2.createdAt)
        XCTAssertEqual(timeline1.modifiedAt, timeline2.modifiedAt)
    }
    
    // MARK: - File Tests
    
    func testTimelineSample() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        XCTAssertFalse(storyElements.isEmpty, "Expected story elements in timeline")

        // Validate that the loaded timeline contains at least one primary clip-like element
        let clipLikeElements = storyElements.filter { element in
            element.name == "clip" || element.name == "asset-clip"
        }
        XCTAssertFalse(clipLikeElements.isEmpty, "Expected at least one clip or asset-clip in primary storyline")

        // Ensure each clip-like element has a duration attribute, which is required for timeline manipulation
        for element in clipLikeElements {
            XCTAssertNotNil(element.attribute(forName: "duration"), "Clip \(element.name ?? "?") should have a duration attribute")
        }
    }

    func testTimelineWithSecondaryStoryline() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStoryline")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
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
        XCTAssertTrue(foundSecondaryStoryline, "Should find secondary storyline")
    }

    func testTimelineWithSecondaryStorylineWithAudioKeyframes() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
        
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        // Check for audio keyframes (adjust-volume with keyframeAnimation) in clips
        var foundAudioKeyframes = false
        func checkForAudioKeyframes(in element: any PNXMLElement) {
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
        XCTAssertTrue(foundAudioKeyframes, "Should find audio keyframes with keyframeAnimation")
    }
}
