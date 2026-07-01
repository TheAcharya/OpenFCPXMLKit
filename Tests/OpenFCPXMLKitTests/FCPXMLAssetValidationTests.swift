//
//  FCPXMLAssetValidationTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for asset validation functionality.
//

import XCTest
import CoreMedia
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLAssetValidationTests: XCTestCase {
    
    var validator: AssetValidator!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        validator = AssetValidator()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    // MARK: - Existence Tests
    
    func testValidateAssetNotFound() async {
        let url = tempDirectory.appendingPathComponent("nonexistent.mp4")
        let result = await validator.validateAsset(at: url, forLane: 0)
        
        XCTAssertFalse(result.exists)
        XCTAssertNil(result.mimeType)
        XCTAssertFalse(result.isCompatible)
        XCTAssertNotNil(result.reason)
    }
    
    // MARK: - Lane Compatibility Tests
    
    func testValidateAudioOnNegativeLane() async throws {
        // Create a dummy audio file (we'll use a text file with .mp3 extension for testing)
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)
        
        let result = await validator.validateAsset(at: audioURL, forLane: -1)
        
        XCTAssertTrue(result.exists)
        XCTAssertNotNil(result.mimeType)
        XCTAssertTrue(result.mimeType?.hasPrefix("audio/") ?? false)
        XCTAssertTrue(result.isCompatible)
        XCTAssertNil(result.reason)
    }
    
    func testValidateVideoOnNegativeLaneFails() async throws {
        // Create a dummy video file
        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)
        
        let result = await validator.validateAsset(at: videoURL, forLane: -1)
        
        XCTAssertTrue(result.exists)
        XCTAssertNotNil(result.mimeType)
        XCTAssertTrue(result.mimeType?.hasPrefix("video/") ?? false)
        XCTAssertFalse(result.isCompatible)
        XCTAssertNotNil(result.reason)
        XCTAssertTrue(result.reason?.contains("audio") ?? false)
    }
    
    func testValidateVideoOnPositiveLane() async throws {
        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)
        
        let result = await validator.validateAsset(at: videoURL, forLane: 0)
        
        XCTAssertTrue(result.exists)
        XCTAssertNotNil(result.mimeType)
        XCTAssertTrue(result.mimeType?.hasPrefix("video/") ?? false)
        XCTAssertTrue(result.isCompatible)
        XCTAssertNil(result.reason)
    }
    
    func testValidateImageOnPositiveLane() async throws {
        let imageURL = tempDirectory.appendingPathComponent("image.jpg")
        try "dummy image".write(to: imageURL, atomically: true, encoding: .utf8)
        
        let result = await validator.validateAsset(at: imageURL, forLane: 1)
        
        XCTAssertTrue(result.exists)
        XCTAssertNotNil(result.mimeType)
        XCTAssertTrue(result.mimeType?.hasPrefix("image/") ?? false)
        XCTAssertTrue(result.isCompatible)
        XCTAssertNil(result.reason)
    }
    
    func testValidateAudioOnPositiveLane() async throws {
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)
        
        let result = await validator.validateAsset(at: audioURL, forLane: 0)
        
        XCTAssertTrue(result.exists)
        XCTAssertNotNil(result.mimeType)
        XCTAssertTrue(result.mimeType?.hasPrefix("audio/") ?? false)
        XCTAssertTrue(result.isCompatible)
        XCTAssertNil(result.reason)
    }
    
    // MARK: - Sync Validation Tests
    
    func testValidateAssetSync() throws {
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)
        
        let result = validator.validateAssetSync(at: audioURL, forLane: -1)
        
        XCTAssertTrue(result.exists)
        XCTAssertNotNil(result.mimeType)
        XCTAssertTrue(result.isCompatible)
    }
    
    // MARK: - TimelineClip Integration Tests
    
    func testTimelineClipValidateAsset() async throws {
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: -1
        )
        
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)
        
        let result = await clip.validateAsset(at: audioURL)
        
        XCTAssertTrue(result.exists)
        XCTAssertTrue(result.isCompatible)
    }
    
    func testTimelineClipIsAudioAsset() async throws {
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )
        
        let audioURL = tempDirectory.appendingPathComponent("audio.wav")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)
        
        let isAudio = await clip.isAudioAsset(at: audioURL)
        XCTAssertTrue(isAudio)
        
        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)
        
        let isAudioVideo = await clip.isAudioAsset(at: videoURL)
        XCTAssertFalse(isAudioVideo)
    }
    
    func testTimelineClipIsVideoAsset() async throws {
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )
        
        let videoURL = tempDirectory.appendingPathComponent("video.mov")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)
        
        let isVideo = await clip.isVideoAsset(at: videoURL)
        XCTAssertTrue(isVideo)
        
        let audioURL = tempDirectory.appendingPathComponent("audio.mp3")
        try "dummy audio".write(to: audioURL, atomically: true, encoding: .utf8)
        
        let isVideoAudio = await clip.isVideoAsset(at: audioURL)
        XCTAssertFalse(isVideoAudio)
    }
    
    func testTimelineClipIsImageAsset() async throws {
        let clip = TimelineClip(
            assetRef: "r1",
            offset: .zero,
            duration: CMTime(value: 10, timescale: 1),
            lane: 0
        )
        
        let imageURL = tempDirectory.appendingPathComponent("image.png")
        try "dummy image".write(to: imageURL, atomically: true, encoding: .utf8)
        
        let isImage = await clip.isImageAsset(at: imageURL)
        XCTAssertTrue(isImage)
        
        let videoURL = tempDirectory.appendingPathComponent("video.mp4")
        try "dummy video".write(to: videoURL, atomically: true, encoding: .utf8)
        
        let isImageVideo = await clip.isImageAsset(at: videoURL)
        XCTAssertFalse(isImageVideo)
    }
}
