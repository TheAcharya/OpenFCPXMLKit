//
//  FCPXMLAssetDurationMeasurementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for asset duration measurement functionality.
//

import Foundation
import Testing
#if canImport(AVFoundation)
import AVFoundation
#endif
@testable import OpenFCPXMLKit

#if canImport(AVFoundation)
@Suite("Asset duration measurement")
struct FCPXMLAssetDurationMeasurementTests {
    private var measurer: AssetDurationMeasurer { AssetDurationMeasurer() }

    // MARK: - Result Type Tests

    @Test("Duration measurement result properties")
    func durationMeasurementResultProperties() throws {
        let result = DurationMeasurementResult(mediaType: .audio, duration: 10.5)

        #expect(result.mediaType == .audio)
        let duration = try #require(result.duration)
        #expect(abs(duration - 10.5) < 0.001)
        #expect(result.hasDuration)
        #expect(!result.isImage)
    }

    @Test("Duration measurement result image")
    func durationMeasurementResultImage() {
        let result = DurationMeasurementResult(mediaType: .image, duration: nil)

        #expect(result.mediaType == .image)
        #expect(result.duration == nil)
        #expect(!result.hasDuration)
        #expect(result.isImage)
    }

    @Test("Duration measurement result video")
    func durationMeasurementResultVideo() throws {
        let result = DurationMeasurementResult(mediaType: .video, duration: 30.0)

        #expect(result.mediaType == .video)
        let duration = try #require(result.duration)
        #expect(abs(duration - 30.0) < 0.001)
        #expect(result.hasDuration)
        #expect(!result.isImage)
    }

    @Test("Duration measurement result equality")
    func durationMeasurementResultEquality() {
        let result1 = DurationMeasurementResult(mediaType: .audio, duration: 10.0)
        let result2 = DurationMeasurementResult(mediaType: .audio, duration: 10.0)
        let result3 = DurationMeasurementResult(mediaType: .audio, duration: 20.0)
        let result4 = DurationMeasurementResult(mediaType: .video, duration: 10.0)

        #expect(result1 == result2)
        #expect(result1 != result3)
        #expect(result1 != result4)
    }

    @Test("Duration measurement result nil duration equality")
    func durationMeasurementResultNilDurationEquality() {
        let result1 = DurationMeasurementResult(mediaType: .image, duration: nil)
        let result2 = DurationMeasurementResult(mediaType: .image, duration: nil)
        let result3 = DurationMeasurementResult(mediaType: .unknown, duration: nil)

        #expect(result1 == result2)
        #expect(result1 != result3)
    }

    // MARK: - Media Type Tests

    @Test("Media type equality")
    func mediaTypeEquality() {
        #expect(MediaType.audio == MediaType.audio)
        #expect(MediaType.video == MediaType.video)
        #expect(MediaType.image == MediaType.image)
        #expect(MediaType.unknown == MediaType.unknown)

        #expect(MediaType.audio != MediaType.video)
        #expect(MediaType.image != MediaType.unknown)
    }

    // MARK: - API Tests

    @Test("Measurer initialization")
    func measurerInitialization() {
        // Smoke: default construction must not trap.
        _ = AssetDurationMeasurer()
    }

    @Test("Measure duration with non-existent file")
    func measureDurationWithNonExistentFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        // File doesn't exist - should throw or return unknown
        do {
            let result = try await measurer.measureDuration(at: tempURL)
            // If it doesn't throw, should return unknown or nil duration
            #expect(result.mediaType == .unknown || result.duration == nil)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }

    @Test("Measure duration sync with non-existent file")
    func measureDurationSyncWithNonExistentFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        // File doesn't exist - should throw or return unknown
        do {
            let result = try measurer.measureDuration(at: tempURL)
            // If it doesn't throw, should return unknown or nil duration
            #expect(result.mediaType == .unknown || result.duration == nil)
        } catch {
            // Error is acceptable for non-existent file - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }

    // MARK: - Edge Cases

    @Test("Duration measurement result zero duration")
    func durationMeasurementResultZeroDuration() throws {
        let result = DurationMeasurementResult(mediaType: .audio, duration: 0.0)

        let duration = try #require(result.duration)
        #expect(abs(duration - 0.0) < 0.001)
        #expect(result.hasDuration) // Zero is still a valid duration
    }

    @Test("Duration measurement result very long duration")
    func durationMeasurementResultVeryLongDuration() throws {
        let result = DurationMeasurementResult(mediaType: .video, duration: 3600.0) // 1 hour

        let duration = try #require(result.duration)
        #expect(abs(duration - 3600.0) < 0.001)
        #expect(result.hasDuration)
    }

    // Note: Full integration tests with actual media files would require:
    // 1. Creating test audio files (WAV, M4A, etc.) with known durations
    // 2. Creating test video files (MOV, MP4) with known durations
    // 3. Creating test image files (JPG, PNG) to verify nil duration
    // 4. Verifying media type detection accuracy
    // These tests verify the API contract and basic functionality.
}
#endif

