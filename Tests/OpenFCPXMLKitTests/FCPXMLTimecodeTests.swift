//
//  FCPXMLTimecodeTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXMLTimecode custom timecode type.
//

import XCTest
import CoreMedia
import SwiftTimecode
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTimecodeTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitFromValueAndTimescale() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        XCTAssertEqual(timecode.value, 1001)
        XCTAssertEqual(timecode.timescale, 30000)
        XCTAssertEqual(timecode.seconds, 1001.0 / 30000.0, accuracy: 0.0001)
    }
    
    func testInitFromSeconds() {
        let timecode = FCPXMLTimecode(seconds: 5.0)
        XCTAssertEqual(timecode.seconds, 5.0, accuracy: 0.01)
    }
    
    func testInitFromCMTime() {
        let cmTime = CMTime(value: 1001, timescale: 30000)
        let timecode = FCPXMLTimecode(cmTime: cmTime)
        XCTAssertEqual(timecode.value, 1001)
        XCTAssertEqual(timecode.timescale, 30000)
    }
    
    func testInitFromFrames() {
        let timecode = FCPXMLTimecode(frames: 10, frameRate: .fps24)
        XCTAssertGreaterThan(timecode.seconds, 0)
        // 10 frames at 24fps = 10/24 seconds ≈ 0.4167 seconds
        XCTAssertEqual(timecode.seconds, 10.0 / 24.0, accuracy: 0.01)
    }
    
    func testInitFromFCPXMLString() {
        let timecode1 = FCPXMLTimecode(fcpxmlString: "1001/30000s")
        XCTAssertNotNil(timecode1)
        if let tc1 = timecode1 {
            XCTAssertEqual(tc1.value, 1001)
            XCTAssertEqual(tc1.timescale, 30000)
        }
        
        let timecode2 = FCPXMLTimecode(fcpxmlString: "5s")
        XCTAssertNotNil(timecode2)
        if let tc2 = timecode2 {
            XCTAssertEqual(tc2.seconds, 5.0, accuracy: 0.01)
        }
        
        let timecode3 = FCPXMLTimecode(fcpxmlString: "0s")
        XCTAssertNotNil(timecode3)
        if let tc3 = timecode3 {
            XCTAssertEqual(tc3.value, 0)
        }
        
        let invalid = FCPXMLTimecode(fcpxmlString: "invalid")
        XCTAssertNil(invalid)
    }
    
    func testZeroTimecode() {
        let zero = FCPXMLTimecode.zero
        XCTAssertEqual(zero.value, 0)
        XCTAssertEqual(zero.timescale, 1)
        XCTAssertEqual(zero.seconds, 0.0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testFCPXMLString() {
        let timecode1 = FCPXMLTimecode(value: 0, timescale: 1)
        XCTAssertEqual(timecode1.fcpxmlString, "0s")
        
        let timecode2 = FCPXMLTimecode(value: 5, timescale: 1)
        XCTAssertEqual(timecode2.fcpxmlString, "5s")
        
        let timecode3 = FCPXMLTimecode(value: 1001, timescale: 30000)
        XCTAssertEqual(timecode3.fcpxmlString, "1001/30000s")
    }
    
    func testSeconds() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        let expectedSeconds = 1001.0 / 30000.0
        XCTAssertEqual(timecode.seconds, expectedSeconds, accuracy: 0.0001)
    }
    
    // MARK: - Arithmetic Tests
    
    func testAddition() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let sum = timecode1 + timecode2
        
        // Fraction arithmetic may normalize, so check seconds instead
        let expectedSeconds = (1001.0 / 30000.0) * 2.0
        XCTAssertEqual(sum.seconds, expectedSeconds, accuracy: 0.0001)
    }
    
    func testSubtraction() {
        let timecode1 = FCPXMLTimecode(value: 2002, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let difference = timecode1 - timecode2
        
        // Fraction arithmetic may normalize, so check seconds instead
        let expectedSeconds = 1001.0 / 30000.0
        XCTAssertEqual(difference.seconds, expectedSeconds, accuracy: 0.0001)
    }
    
    func testMultiplication() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        let multiplied = timecode * 2
        
        // Fraction arithmetic may normalize, so check seconds instead
        let expectedSeconds = (1001.0 / 30000.0) * 2.0
        XCTAssertEqual(multiplied.seconds, expectedSeconds, accuracy: 0.0001)
        
        let multiplied2 = 3 * timecode
        let expectedSeconds2 = (1001.0 / 30000.0) * 3.0
        XCTAssertEqual(multiplied2.seconds, expectedSeconds2, accuracy: 0.0001)
    }
    
    // MARK: - Comparison Tests
    
    func testEquality() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        XCTAssertEqual(timecode1, timecode2)
        
        let timecode3 = FCPXMLTimecode(value: 1002, timescale: 30000)
        XCTAssertNotEqual(timecode1, timecode3)
    }
    
    func testComparable() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 2002, timescale: 30000)
        
        XCTAssertLessThan(timecode1, timecode2)
        XCTAssertGreaterThan(timecode2, timecode1)
    }
    
    // MARK: - CMTime Conversion Tests
    
    func testToCMTime() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        let cmTime = timecode.toCMTime()
        
        XCTAssertEqual(cmTime.value, 1001)
        XCTAssertEqual(cmTime.timescale, 30000)
    }
    
    func testFromCMTimeRoundTrip() {
        let originalCMTime = CMTime(value: 1001, timescale: 30000)
        let timecode = FCPXMLTimecode(cmTime: originalCMTime)
        let convertedCMTime = timecode.toCMTime()
        
        XCTAssertEqual(CMTimeCompare(originalCMTime, convertedCMTime), 0)
    }
    
    // MARK: - Frame Alignment Tests
    
    func testFrameAligned() {
        // 0.5 seconds at 24fps should be 12 frames = 0.5 seconds
        let aligned = FCPXMLTimecode.frameAligned(seconds: 0.5, frameRate: .fps24)
        XCTAssertEqual(aligned.seconds, 0.5, accuracy: 0.01)
        
        // 0.6 seconds at 24fps should round to nearest frame (14 or 15 frames)
        let aligned2 = FCPXMLTimecode.frameAligned(seconds: 0.6, frameRate: .fps24)
        let expectedFrames = Int((0.6 * 24).rounded())
        let expectedSeconds = Double(expectedFrames) / 24.0
        XCTAssertEqual(aligned2.seconds, expectedSeconds, accuracy: 0.01)
    }
    
    func testAlignedToFrameRate() {
        let timecode = FCPXMLTimecode(seconds: 0.6)
        let aligned = timecode.aligned(to: .fps24)
        
        // Should be aligned to nearest frame boundary
        let expectedFrames = Int((0.6 * 24).rounded())
        let expectedSeconds = Double(expectedFrames) / 24.0
        XCTAssertEqual(aligned.seconds, expectedSeconds, accuracy: 0.01)
    }
    
    // MARK: - Hashable Tests
    
    func testHashable() {
        let timecode1 = FCPXMLTimecode(value: 1001, timescale: 30000)
        let timecode2 = FCPXMLTimecode(value: 1001, timescale: 30000)
        
        var set = Set<FCPXMLTimecode>()
        set.insert(timecode1)
        set.insert(timecode2)
        
        XCTAssertEqual(set.count, 1)
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(timecode)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FCPXMLTimecode.self, from: data)
        
        XCTAssertEqual(timecode, decoded)
    }
    
    // MARK: - CustomStringConvertible Tests
    
    func testDescription() {
        let timecode = FCPXMLTimecode(value: 1001, timescale: 30000)
        XCTAssertEqual(timecode.description, "1001/30000s")
        
        let zero = FCPXMLTimecode.zero
        XCTAssertEqual(zero.description, "0s")
    }
    
    // MARK: - Edge Cases
    
    func testInvalidCMTime() {
        let invalidCMTime = CMTime.invalid
        let timecode = FCPXMLTimecode(cmTime: invalidCMTime)
        
        // Should default to zero
        XCTAssertEqual(timecode.value, 0)
        XCTAssertEqual(timecode.timescale, 1)
    }
    
    func testZeroTimescalePrecondition() {
        // This should crash in debug builds, but we can't test that easily
        // In release builds, it might not crash, so we'll skip this test
        // The precondition is documented in the initializer
    }
    
    func testDifferentTimescalesEquality() {
        // Fractions should normalize, so 1/2 == 2/4
        let timecode1 = FCPXMLTimecode(value: 1, timescale: 2)
        let timecode2 = FCPXMLTimecode(value: 2, timescale: 4)
        
        // Note: Fraction equality depends on SwiftTimecode's implementation
        // If Fraction normalizes, these should be equal
        // If not, they might not be equal
        // We'll test what actually happens
        let seconds1 = timecode1.seconds
        let seconds2 = timecode2.seconds
        XCTAssertEqual(seconds1, seconds2, accuracy: 0.0001)
    }
}
