//
//  FCPXMLAssetDurationMeasurementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for asset duration measurement functionality.
//

import XCTest
import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
@testable import OpenFCPXMLKit

#if canImport(AVFoundation)
@available(macOS 26.0, *)
final class FCPXMLAssetDurationMeasurementTests: XCTestCase {
    
    var measurer: AssetDurationMeasurer!
    
    override func setUp() {
        super.setUp()
        measurer = AssetDurationMeasurer()
    }
    
    // MARK: - Result Type Tests
    
    func testDurationMeasurementResultProperties() {
        let result = DurationMeasurementResult(mediaType: .audio, duration: 10.5)
        
        XCTAssertEqual(result.mediaType, .audio)
        XCTAssertNotNil(result.duration)
        XCTAssertEqual(result.duration!, 10.5, accuracy: 0.001)
        XCTAssertTrue(result.hasDuration)
        XCTAssertFalse(result.isImage)
    }
    
    func testDurationMeasurementResultImage() {
        let result = DurationMeasurementResult(mediaType: .image, duration: nil)
        
        XCTAssertEqual(result.mediaType, .image)
        XCTAssertNil(result.duration)
        XCTAssertFalse(result.hasDuration)
        XCTAssertTrue(result.isImage)
    }
    
    func testDurationMeasurementResultVideo() {
        let result = DurationMeasurementResult(mediaType: .video, duration: 30.0)
        
        XCTAssertEqual(result.mediaType, .video)
        XCTAssertNotNil(result.duration)
        XCTAssertEqual(result.duration!, 30.0, accuracy: 0.001)
        XCTAssertTrue(result.hasDuration)
        XCTAssertFalse(result.isImage)
    }
    
    func testDurationMeasurementResultEquality() {
        let result1 = DurationMeasurementResult(mediaType: .audio, duration: 10.0)
        let result2 = DurationMeasurementResult(mediaType: .audio, duration: 10.0)
        let result3 = DurationMeasurementResult(mediaType: .audio, duration: 20.0)
        let result4 = DurationMeasurementResult(mediaType: .video, duration: 10.0)
        
        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
        XCTAssertNotEqual(result1, result4)
    }
    
    func testDurationMeasurementResultNilDurationEquality() {
        let result1 = DurationMeasurementResult(mediaType: .image, duration: nil)
        let result2 = DurationMeasurementResult(mediaType: .image, duration: nil)
        let result3 = DurationMeasurementResult(mediaType: .unknown, duration: nil)
        
        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
    
    // MARK: - Media Type Tests
    
    func testMediaTypeEquality() {
        XCTAssertEqual(MediaType.audio, MediaType.audio)
        XCTAssertEqual(MediaType.video, MediaType.video)
        XCTAssertEqual(MediaType.image, MediaType.image)
        XCTAssertEqual(MediaType.unknown, MediaType.unknown)
        
        XCTAssertNotEqual(MediaType.audio, MediaType.video)
        XCTAssertNotEqual(MediaType.image, MediaType.unknown)
    }
    
    // MARK: - API Tests
    
    func testMeasurerInitialization() {
        let measurer = AssetDurationMeasurer()
        XCTAssertNotNil(measurer)
    }
    
    func testMeasureDurationWithNonExistentFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        
        // File doesn't exist - should throw or return unknown
        do {
            let result = try await measurer.measureDuration(at: tempURL)
            // If it doesn't throw, should return unknown or nil duration
            XCTAssertTrue(result.mediaType == .unknown || result.duration == nil)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }
    
    func testMeasureDurationSyncWithNonExistentFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        
        // File doesn't exist - should throw or return unknown
        do {
            let result = try measurer.measureDuration(at: tempURL)
            // If it doesn't throw, should return unknown or nil duration
            XCTAssertTrue(result.mediaType == .unknown || result.duration == nil)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }
    
    // MARK: - Edge Cases
    
    func testDurationMeasurementResultZeroDuration() {
        let result = DurationMeasurementResult(mediaType: .audio, duration: 0.0)
        
        XCTAssertNotNil(result.duration)
        XCTAssertEqual(result.duration!, 0.0, accuracy: 0.001)
        XCTAssertTrue(result.hasDuration) // Zero is still a valid duration
    }
    
    func testDurationMeasurementResultVeryLongDuration() {
        let result = DurationMeasurementResult(mediaType: .video, duration: 3600.0) // 1 hour
        
        XCTAssertNotNil(result.duration)
        XCTAssertEqual(result.duration!, 3600.0, accuracy: 0.001)
        XCTAssertTrue(result.hasDuration)
    }
    
    // Note: Full integration tests with actual media files would require:
    // 1. Creating test audio files (WAV, M4A, etc.) with known durations
    // 2. Creating test video files (MOV, MP4) with known durations
    // 3. Creating test image files (JPG, PNG) to verify nil duration
    // 4. Verifying media type detection accuracy
    // These tests verify the API contract and basic functionality.
}
#endif
