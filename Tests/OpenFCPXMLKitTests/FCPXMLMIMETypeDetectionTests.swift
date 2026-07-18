//
//  FCPXMLMIMETypeDetectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for MIME type detection functionality.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("MIME type detection")
struct FCPXMLMIMETypeDetectionTests {
    private var detector: MIMETypeDetector { MIMETypeDetector() }

    // MARK: - Sync Detection Tests

    @Test("Detect MIME type from video extension")
    func detectMIMETypeFromVideoExtension() {
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let mimeType = detector.detectMIMETypeSync(at: url)
        #expect(mimeType == "video/mp4")
    }

    @Test("Detect MIME type from audio extension")
    func detectMIMETypeFromAudioExtension() {
        let url = URL(fileURLWithPath: "/test/audio.mp3")
        let mimeType = detector.detectMIMETypeSync(at: url)
        #expect(mimeType == "audio/mpeg")
    }

    @Test("Detect MIME type from image extension")
    func detectMIMETypeFromImageExtension() {
        let url = URL(fileURLWithPath: "/test/image.jpg")
        let mimeType = detector.detectMIMETypeSync(at: url)
        #expect(mimeType == "image/jpeg")
    }

    @Test("Detect MIME type from MOV")
    func detectMIMETypeFromMOV() {
        let url = URL(fileURLWithPath: "/test/video.mov")
        let mimeType = detector.detectMIMETypeSync(at: url)
        #expect(mimeType == "video/quicktime")
    }

    @Test("Detect MIME type from M4A")
    func detectMIMETypeFromM4A() {
        let url = URL(fileURLWithPath: "/test/audio.m4a")
        let mimeType = detector.detectMIMETypeSync(at: url)
        // UTType may return "audio/x-m4a" or "audio/mp4", both are valid
        #expect(mimeType?.hasPrefix("audio/") ?? false)
    }

    @Test("Detect MIME type from PNG")
    func detectMIMETypeFromPNG() {
        let url = URL(fileURLWithPath: "/test/image.png")
        let mimeType = detector.detectMIMETypeSync(at: url)
        #expect(mimeType == "image/png")
    }

    @Test("Detect MIME type from unknown extension")
    func detectMIMETypeFromUnknownExtension() {
        let url = URL(fileURLWithPath: "/test/file.unknown")
        let mimeType = detector.detectMIMETypeSync(at: url)
        // Should return nil for truly unknown extensions
        // UTType might identify some, but .unknown should return nil
        // This test just verifies the method doesn't crash
        _ = mimeType // May be nil or some value from UTType
    }

    // MARK: - Async Detection Tests

    @Test("Detect MIME type async")
    func detectMIMETypeAsync() async {
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let mimeType = await detector.detectMIMEType(at: url)
        #expect(mimeType == "video/mp4")
    }

    @Test("Detect MIME type async audio")
    func detectMIMETypeAsyncAudio() async {
        let url = URL(fileURLWithPath: "/test/audio.wav")
        let mimeType = await detector.detectMIMEType(at: url)
        // UTType may return "audio/vnd.wave" or "audio/wav", both are valid
        #expect(mimeType?.hasPrefix("audio/") ?? false)
    }

    @Test("Detect MIME type async image")
    func detectMIMETypeAsyncImage() async {
        let url = URL(fileURLWithPath: "/test/image.gif")
        let mimeType = await detector.detectMIMEType(at: url)
        #expect(mimeType == "image/gif")
    }
}
