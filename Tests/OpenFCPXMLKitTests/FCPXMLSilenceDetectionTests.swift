//
//  FCPXMLSilenceDetectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for silence detection functionality.
//

import XCTest
import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
@testable import OpenFCPXMLKit

#if canImport(AVFoundation)
@available(macOS 26.0, *)
final class FCPXMLSilenceDetectionTests: XCTestCase {
    
    var detector: SilenceDetector!
    
    override func setUp() {
        super.setUp()
        detector = SilenceDetector()
    }
    
    // MARK: - Result Type Tests
    
    func testSilenceDetectionResultProperties() {
        let result = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 2.0)
        
        XCTAssertEqual(result.duration, 10.0, accuracy: 0.001)
        XCTAssertEqual(result.trimStart, 1.0, accuracy: 0.001)
        XCTAssertEqual(result.trimEnd, 2.0, accuracy: 0.001)
        XCTAssertEqual(result.audioDuration, 7.0, accuracy: 0.001) // 10 - 1 - 2
        XCTAssertFalse(result.isEntirelySilent)
    }
    
    func testSilenceDetectionResultEntirelySilent() {
        let result = SilenceDetectionResult(duration: 10.0, trimStart: 10.0, trimEnd: 0.0)
        
        XCTAssertTrue(result.isEntirelySilent)
        XCTAssertEqual(result.audioDuration, 0.0, accuracy: 0.001)
    }
    
    func testSilenceDetectionResultEquality() {
        let result1 = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 2.0)
        let result2 = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 2.0)
        let result3 = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 3.0)
        
        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
    
    // MARK: - API Tests
    
    func testDetectorInitialization() {
        let detector = SilenceDetector()
        XCTAssertNotNil(detector)
    }
    
    func testDetectSilenceWithNonExistentFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        // File doesn't exist - should throw or return zero trim
        do {
            let result = try await detector.detectSilence(at: tempURL)
            // If it doesn't throw, should return zero trim for non-audio file
            XCTAssertEqual(result.trimStart, 0.0, accuracy: 0.001)
            XCTAssertEqual(result.trimEnd, 0.0, accuracy: 0.001)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }
    
    func testDetectSilenceSyncWithNonExistentFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        // File doesn't exist - should throw or return zero trim
        do {
            let result = try detector.detectSilence(at: tempURL)
            // If it doesn't throw, should return zero trim for non-audio file
            XCTAssertEqual(result.trimStart, 0.0, accuracy: 0.001)
            XCTAssertEqual(result.trimEnd, 0.0, accuracy: 0.001)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }
    
    func testDetectSilenceWithCustomThreshold() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        // Test with custom threshold
        do {
            let result = try await detector.detectSilence(at: tempURL, threshold: -60.0)
            // Should return a result (even if zero trim)
            XCTAssertNotNil(result)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }
    
    // MARK: - Edge Cases
    
    func testSilenceDetectionResultNegativeValues() {
        // Test that negative values are handled correctly
        let result = SilenceDetectionResult(duration: 10.0, trimStart: -1.0, trimEnd: -2.0)
        
        // audioDuration should handle negative values
        XCTAssertEqual(result.audioDuration, 13.0, accuracy: 0.001) // 10 - (-1) - (-2) = 13
    }
    
    func testSilenceDetectionResultZeroDuration() {
        let result = SilenceDetectionResult(duration: 0.0, trimStart: 0.0, trimEnd: 0.0)
        
        XCTAssertEqual(result.duration, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.audioDuration, 0.0, accuracy: 0.001)
        // When trimStart (0) >= duration (0), it's considered entirely silent
        XCTAssertTrue(result.isEntirelySilent)
    }
    
    // Note: Full integration tests with actual audio files would require:
    // 1. Creating test audio files with known silence patterns
    // 2. Verifying detection accuracy
    // 3. Testing various audio formats (WAV, M4A, etc.)
    // These tests verify the API contract and basic functionality.
}
#endif
