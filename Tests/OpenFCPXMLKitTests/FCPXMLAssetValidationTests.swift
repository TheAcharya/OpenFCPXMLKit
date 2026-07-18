//
//  FCPXMLAssetValidationTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for asset validation functionality.
//

import Foundation
import CoreMedia
import Testing
@testable import OpenFCPXMLKit

@Suite("Asset validation")
struct FCPXMLAssetValidationTests {
    private var validator: AssetValidator { AssetValidator() }

    private func makeTempDirectory() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        return tempDirectory
    }

    // MARK: - Existence Tests

    @Test("Validate asset not found")
    func validateAssetNotFound() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let url = tempDirectory.appendingPathComponent("nonexistent.mp4")
        let result = await validator.validateAsset(at: url, forLane: 0)

        #expect(!result.exists)
        #expect(result.mimeType == nil)
        #expect(!result.isCompatible)
        #expect(result.reason != nil)
    }

    // MARK: - Lane Compatibility Tests

    @Test("Validate audio on negative lane")
    func validateAudioOnNegativeLane() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        // Create a dummy audio file (we'll use a text file with .mp3 extension for testing)
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)

        let result = await validator.validateAsset(at: audioURL, forLane: -1)

        #expect(result.exists)
        #expect(result.mimeType != nil)
        #expect(result.mimeType?.hasPrefix("audio/") ?? false)
        #expect(result.isCompatible)
        #expect(result.reason == nil)
    }

    @Test("Validate video on negative lane fails")
    func validateVideoOnNegativeLaneFails() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        // Create a dummy video file
        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)

        let result = await validator.validateAsset(at: videoURL, forLane: -1)

        #expect(result.exists)
        #expect(result.mimeType != nil)
        #expect(result.mimeType?.hasPrefix("video/") ?? false)
        #expect(!result.isCompatible)
        #expect(result.reason != nil)
        #expect(result.reason?.contains("audio") ?? false)
    }

    @Test("Validate video on positive lane")
    func validateVideoOnPositiveLane() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)

        let result = await validator.validateAsset(at: videoURL, forLane: 0)

        #expect(result.exists)
        #expect(result.mimeType != nil)
        #expect(result.mimeType?.hasPrefix("video/") ?? false)
        #expect(result.isCompatible)
        #expect(result.reason == nil)
    }

    @Test("Validate image on positive lane")
    func validateImageOnPositiveLane() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let imageURL = tempDirectory.appendingPathComponent("image.jpg")
        try "dummy image".write(to: imageURL, atomically: true, encoding: .utf8)

        let result = await validator.validateAsset(at: imageURL, forLane: 1)

        #expect(result.exists)
        #expect(result.mimeType != nil)
        #expect(result.mimeType?.hasPrefix("image/") ?? false)
        #expect(result.isCompatible)
        #expect(result.reason == nil)
    }

    @Test("Validate audio on positive lane")
    func validateAudioOnPositiveLane() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)

        let result = await validator.validateAsset(at: audioURL, forLane: 0)

        #expect(result.exists)
        #expect(result.mimeType != nil)
        #expect(result.mimeType?.hasPrefix("audio/") ?? false)
        #expect(result.isCompatible)
        #expect(result.reason == nil)
    }

    // MARK: - Sync Validation Tests

    @Test("Validate asset sync")
    func validateAssetSync() throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)

        let result = validator.validateAssetSync(at: audioURL, forLane: -1)

        #expect(result.exists)
        #expect(result.mimeType != nil)
        #expect(result.isCompatible)
    }

    // MARK: - TimelineClip Integration Tests

    @Test("Timeline clip validate asset")
    func timelineClipValidateAsset() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: -1
        )

        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)

        let result = await clip.validateAsset(at: audioURL)

        #expect(result.exists)
        #expect(result.isCompatible)
    }

    @Test("Timeline clip is audio asset")
    func timelineClipIsAudioAsset() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )

        let audioURL = tempDirectory.appendingPathComponent("audio.wav")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)

        let isAudio = await clip.isAudioAsset(at: audioURL)
        #expect(isAudio)

        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)

        let isAudioVideo = await clip.isAudioAsset(at: videoURL)
        #expect(!isAudioVideo)
    }

    @Test("Timeline clip is video asset")
    func timelineClipIsVideoAsset() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )

        let videoURL = tempDirectory.appendingPathComponent("video.mov")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)

        let isVideo = await clip.isVideoAsset(at: videoURL)
        #expect(isVideo)

        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)

        let isVideoAudio = await clip.isVideoAsset(at: audioURL)
        #expect(!isVideoAudio)
    }

    @Test("Timeline clip is image asset")
    func timelineClipIsImageAsset() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )

        let imageURL = tempDirectory.appendingPathComponent("image.png")
        try "dummy image".write(to: imageURL, atomically: true, encoding: .utf8)

        let isImage = await clip.isImageAsset(at: imageURL)
        #expect(isImage)

        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)

        let isImageVideo = await clip.isImageAsset(at: videoURL)
        #expect(!isImageVideo)
    }
}
