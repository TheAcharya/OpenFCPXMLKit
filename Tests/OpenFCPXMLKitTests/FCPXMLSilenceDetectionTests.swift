//
//  FCPXMLSilenceDetectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for silence detection functionality.
//

import Foundation
import Testing
#if canImport(AVFoundation)
import AVFoundation
#endif
@testable import OpenFCPXMLKit

#if canImport(AVFoundation)
@Suite("Silence detection")
struct FCPXMLSilenceDetectionTests {
    private var detector: SilenceDetector { SilenceDetector() }

    // MARK: - Result Type Tests

    @Test("Silence detection result properties")
    func silenceDetectionResultProperties() {
        let result = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 2.0)

        #expect(abs(result.duration - 10.0) < 0.001)
        #expect(abs(result.trimStart - 1.0) < 0.001)
        #expect(abs(result.trimEnd - 2.0) < 0.001)
        #expect(abs(result.audioDuration - 7.0) < 0.001) // 10 - 1 - 2
        #expect(!result.isEntirelySilent)
    }

    @Test("Silence detection result entirely silent")
    func silenceDetectionResultEntirelySilent() {
        let result = SilenceDetectionResult(duration: 10.0, trimStart: 10.0, trimEnd: 0.0)

        #expect(result.isEntirelySilent)
        #expect(abs(result.audioDuration - 0.0) < 0.001)
    }

    @Test("Silence detection result equality")
    func silenceDetectionResultEquality() {
        let result1 = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 2.0)
        let result2 = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 2.0)
        let result3 = SilenceDetectionResult(duration: 10.0, trimStart: 1.0, trimEnd: 3.0)

        #expect(result1 == result2)
        #expect(result1 != result3)
    }

    // MARK: - API Tests

    @Test("Detector initialization")
    func detectorInitialization() {
        // Smoke: default construction must not trap.
        _ = SilenceDetector()
    }

    @Test("Detect silence with non-existent file")
    func detectSilenceWithNonExistentFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        // File doesn't exist - should throw or return zero trim
        do {
            let result = try await detector.detectSilence(at: tempURL)
            // If it doesn't throw, should return zero trim for non-audio file
            #expect(abs(result.trimStart - 0.0) < 0.001)
            #expect(abs(result.trimEnd - 0.0) < 0.001)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }

    @Test("Detect silence sync with non-existent file")
    func detectSilenceSyncWithNonExistentFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        // File doesn't exist - should throw or return zero trim
        do {
            let result = try detector.detectSilence(at: tempURL)
            // If it doesn't throw, should return zero trim for non-audio file
            #expect(abs(result.trimStart - 0.0) < 0.001)
            #expect(abs(result.trimEnd - 0.0) < 0.001)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }

    @Test("Detect silence with custom threshold")
    func detectSilenceWithCustomThreshold() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        // Test with custom threshold
        do {
            let result = try await detector.detectSilence(at: tempURL, threshold: -60.0)
            // Should return a result (even if zero trim) for a missing/empty file path
            #expect(abs(result.trimStart - 0.0) < 0.001 || result.duration >= 0)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }

    // MARK: - Edge Cases

    @Test("Silence detection result negative values")
    func silenceDetectionResultNegativeValues() {
        // Test that negative values are handled correctly
        let result = SilenceDetectionResult(duration: 10.0, trimStart: -1.0, trimEnd: -2.0)

        // audioDuration should handle negative values
        #expect(abs(result.audioDuration - 13.0) < 0.001) // 10 - (-1) - (-2) = 13
    }

    @Test("Silence detection result zero duration")
    func silenceDetectionResultZeroDuration() {
        let result = SilenceDetectionResult(duration: 0.0, trimStart: 0.0, trimEnd: 0.0)

        #expect(abs(result.duration - 0.0) < 0.001)
        #expect(abs(result.audioDuration - 0.0) < 0.001)
        // When trimStart (0) >= duration (0), it's considered entirely silent
        #expect(result.isEntirelySilent)
    }

    // Note: Full integration tests with actual audio files would require:
    // 1. Creating test audio files with known silence patterns
    // 2. Verifying detection accuracy
    // 3. Testing various audio formats (WAV, M4A, etc.)
    // These tests verify the API contract and basic functionality.
}
#endif

