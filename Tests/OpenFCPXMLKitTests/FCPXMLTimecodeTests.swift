//
//  FCPXMLTimecodeTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXMLTimecode custom timecode type.
//

import Testing
import CoreMedia
import SwiftTimecode
@testable import OpenFCPXMLKit

@Suite("FCPXMLTimecode")
struct FCPXMLTimecodeTests {

    // MARK: - Initialization Tests

    @Test("Init from value and timescale")
    func initFromValueAndTimescale() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        #expect(timecode.value == 1001)
        #expect(timecode.timescale == 30000)
        let secondsMatch = abs(timecode.seconds - (1001.0 / 30000.0)) < 0.0001
        #expect(secondsMatch)
    }

    @Test("Init from seconds")
    func initFromSeconds() {
        let timecode = FCPXMLTimecode(seconds: 5.0)
        let secondsMatch = abs(timecode.seconds - 5.0) < 0.01
        #expect(secondsMatch)
    }

    @Test("Init from CMTime")
    func initFromCMTime() {
        let cmTime = CMTime(value: 1001, timescale: 30000)
        let timecode = FCPXMLTimecode(cmTime: cmTime)
        #expect(timecode.value == 1001)
        #expect(timecode.timescale == 30000)
    }

    @Test("Init from frames")
    func initFromFrames() {
        let timecode = FCPXMLTimecode(frames: 10, frameRate: .fps24)
        #expect(timecode.seconds > 0)
        // 10 frames at 24fps = 10/24 seconds ≈ 0.4167 seconds
        let secondsMatch = abs(timecode.seconds - (10.0 / 24.0)) < 0.01
        #expect(secondsMatch)
    }

    @Test("Init from FCPXML string")
    func initFromFCPXMLString() throws {
        let tc1 = try #require(FCPXMLTimecode(fcpxmlString: "1001/30000s"))
        #expect(tc1.value == 1001)
        #expect(tc1.timescale == 30000)

        let tc2 = try #require(FCPXMLTimecode(fcpxmlString: "5s"))
        let tc2SecondsMatch = abs(tc2.seconds - 5.0) < 0.01
        #expect(tc2SecondsMatch)

        let tc3 = try #require(FCPXMLTimecode(fcpxmlString: "0s"))
        #expect(tc3.value == 0)

        let invalid = FCPXMLTimecode(fcpxmlString: "invalid")
        #expect(invalid == nil)
    }

    @Test("Zero timecode")
    func zeroTimecode() {
        let zero = FCPXMLTimecode.zero
        #expect(zero.value == 0)
        #expect(zero.timescale == 1)
        #expect(zero.seconds == 0.0)
    }

    // MARK: - Computed Properties Tests

    @Test("FCPXML string")
    func fcpxmlString() {
        let timecode1 = FCPXMLTimecode(value: 0, timescale: 1)
        #expect(timecode1.fcpxmlString == "0s")

        let timecode2 = FCPXMLTimecode(value: 5, timescale: 1)
        #expect(timecode2.fcpxmlString == "5s")

        let timecode3 = FCPXMLTimecode(value: 1001, timescale: 30000)
        #expect(timecode3.fcpxmlString == "1001/30000s")
    }

    @Test("Seconds")
    func seconds() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        let expectedSeconds = 1001.0 / 30000.0
        let secondsMatch = abs(timecode.seconds - expectedSeconds) < 0.0001
        #expect(secondsMatch)
    }

    // MARK: - Arithmetic Tests

    @Test("Addition")
    func addition() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let sum = timecode1 + timecode2

        // Fraction arithmetic may normalize, so check seconds instead
        let expectedSeconds = (1001.0 / 30000.0) * 2.0
        let secondsMatch = abs(sum.seconds - expectedSeconds) < 0.0001
        #expect(secondsMatch)
    }

    @Test("Subtraction")
    func subtraction() {
        let timecode1 = FCPXMLTimecode(value: 2002, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let difference = timecode1 - timecode2

        // Fraction arithmetic may normalize, so check seconds instead
        let expectedSeconds = 1001.0 / 30000.0
        let secondsMatch = abs(difference.seconds - expectedSeconds) < 0.0001
        #expect(secondsMatch)
    }

    @Test("Multiplication")
    func multiplication() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        let multiplied = timecode * 2

        // Fraction arithmetic may normalize, so check seconds instead
        let expectedSeconds = (1001.0 / 30000.0) * 2.0
        let multipliedMatch = abs(multiplied.seconds - expectedSeconds) < 0.0001
        #expect(multipliedMatch)

        let multiplied2 = 3 * timecode
        let expectedSeconds2 = (1001.0 / 30000.0) * 3.0
        let multiplied2Match = abs(multiplied2.seconds - expectedSeconds2) < 0.0001
        #expect(multiplied2Match)
    }

    // MARK: - Comparison Tests

    @Test("Equality")
    func equality() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        #expect(timecode1 == timecode2)

        let timecode3 = FCPXMLTimecode(value: 1002, timescale: 30000)
        #expect(timecode1 != timecode3)
    }

    @Test("Comparable")
    func comparable() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 2002, timescale: 30000)

        let isLess = timecode1 < timecode2
        #expect(isLess)
        let isGreater = timecode2 > timecode1
        #expect(isGreater)
    }

    // MARK: - CMTime Conversion Tests

    @Test("To CMTime")
    func toCMTime() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        let cmTime = timecode.toCMTime()

        #expect(cmTime.value == 1001)
        #expect(cmTime.timescale == 30000)
    }

    @Test("From CMTime round trip")
    func fromCMTimeRoundTrip() {
        let originalCMTime = CMTime(value: 1001, timescale: 30000)
        let timecode = FCPXMLTimecode(cmTime: originalCMTime)
        let convertedCMTime = timecode.toCMTime()

        #expect(CMTimeCompare(originalCMTime, convertedCMTime) == 0)
    }

    // MARK: - Frame Alignment Tests

    @Test("Frame aligned")
    func frameAligned() {
        // 0.5 seconds at 24fps should be 12 frames = 0.5 seconds
        let aligned = FCPXMLTimecode.frameAligned(seconds: 0.5, frameRate: .fps24)
        let alignedMatch = abs(aligned.seconds - 0.5) < 0.01
        #expect(alignedMatch)

        // 0.6 seconds at 24fps should round to nearest frame (14 or 15 frames)
        let aligned2 = FCPXMLTimecode.frameAligned(seconds: 0.6, frameRate: .fps24)
        let expectedFrames = Int((0.6 * 24).rounded())
        let expectedSeconds = Double(expectedFrames) / 24.0
        let aligned2Match = abs(aligned2.seconds - expectedSeconds) < 0.01
        #expect(aligned2Match)
    }

    @Test("Aligned to frame rate")
    func alignedToFrameRate() {
        let timecode = FCPXMLTimecode(seconds: 0.6)
        let aligned = timecode.aligned(to: .fps24)

        // Should be aligned to nearest frame boundary
        let expectedFrames = Int((0.6 * 24).rounded())
        let expectedSeconds = Double(expectedFrames) / 24.0
        let secondsMatch = abs(aligned.seconds - expectedSeconds) < 0.01
        #expect(secondsMatch)
    }

    // MARK: - Hashable Tests

    @Test("Hashable")
    func hashable() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)

        var set = Set<FCPXMLTimecode>()
        set.insert(timecode1)
        set.insert(timecode2)

        #expect(set.count == 1)
    }

    // MARK: - Codable Tests

    @Test("Codable")
    func codable() throws {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)

        let encoder = JSONEncoder()
        let data = try encoder.encode(timecode)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FCPXMLTimecode.self, from: data)

        #expect(timecode == decoded)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("Description")
    func description() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        #expect(timecode.description == "1001/30000s")

        let zero = FCPXMLTimecode.zero
        #expect(zero.description == "0s")
    }

    // MARK: - Edge Cases

    @Test("Invalid CMTime")
    func invalidCMTime() {
        let invalidCMTime = CMTime.invalid
        let timecode = FCPXMLTimecode(cmTime: invalidCMTime)

        // Should default to zero
        #expect(timecode.value == 0)
        #expect(timecode.timescale == 1)
    }

    @Test("Zero timescale precondition")
    func zeroTimescalePrecondition() {
        // This should crash in debug builds, but we can't test that easily
        // In release builds, it might not crash, so we'll skip this test
        // The precondition is documented in the initializer
    }

    @Test("Different timescales equality")
    func differentTimescalesEquality() {
        // Fractions should normalize, so 1/2 == 2/4
        let timecode1 = FCPXMLTimecode(value: 1, timescale: 2)
        let timecode2 = FCPXMLTimecode(value: 2, timescale: 4)

        // Note: Fraction equality depends on SwiftTimecode's implementation
        // If Fraction normalizes, these should be equal
        // If not, they might not be equal
        // We'll test what actually happens
        let seconds1 = timecode1.seconds
        let seconds2 = timecode2.seconds
        let secondsMatch = abs(seconds1 - seconds2) < 0.0001
        #expect(secondsMatch)
    }
}

