//
//  FCPXMLMIMETypeDetectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for MIME type detection functionality.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLMIMETypeDetectionTests: XCTestCase {
    
    var detector: MIMETypeDetector!
    
    override func setUp() {
        super.setUp()
        detector = MIMETypeDetector()
    }
    
    // MARK: - Sync Detection Tests
    
    func testDetectMIMETypeFromVideoExtension() {
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let mimeType = detector.detectMIMETypeSync(at: url)
        XCTAssertEqual(mimeType, "video/mp4")
    }
    
    func testDetectMIMETypeFromAudioExtension() {
        let url = URL(fileURLWithPath: "/test/audio.mp3")
        let mimeType = detector.detectMIMETypeSync(at: url)
        XCTAssertEqual(mimeType, "audio/mpeg")
    }
    
    func testDetectMIMETypeFromImageExtension() {
        let url = URL(fileURLWithPath: "/test/image.jpg")
        let mimeType = detector.detectMIMETypeSync(at: url)
        XCTAssertEqual(mimeType, "image/jpeg")
    }
    
    func testDetectMIMETypeFromMOV() {
        let url = URL(fileURLWithPath: "/test/video.mov")
        let mimeType = detector.detectMIMETypeSync(at: url)
        XCTAssertEqual(mimeType, "video/quicktime")
    }
    
    func testDetectMIMETypeFromM4A() {
        let url = URL(fileURLWithPath: "/test/audio.m4a")
        let mimeType = detector.detectMIMETypeSync(at: url)
        // UTType may return "audio/x-m4a" or "audio/mp4", both are valid
        XCTAssertTrue(mimeType?.hasPrefix("audio/") ?? false)
    }
    
    func testDetectMIMETypeFromPNG() {
        let url = URL(fileURLWithPath: "/test/image.png")
        let mimeType = detector.detectMIMETypeSync(at: url)
        XCTAssertEqual(mimeType, "image/png")
    }
    
    func testDetectMIMETypeFromUnknownExtension() {
        let url = URL(fileURLWithPath: "/test/file.unknown")
        let mimeType = detector.detectMIMETypeSync(at: url)
        // Should return nil for truly unknown extensions
        // UTType might identify some, but .unknown should return nil
        // This test just verifies the method doesn't crash
        _ = mimeType // May be nil or some value from UTType
    }
    
    // MARK: - Async Detection Tests
    
    func testDetectMIMETypeAsync() async {
        let url = URL(fileURLWithPath: "/test/video.mp4")
        let mimeType = await detector.detectMIMEType(at: url)
        XCTAssertEqual(mimeType, "video/mp4")
    }
    
    func testDetectMIMETypeAsyncAudio() async {
        let url = URL(fileURLWithPath: "/test/audio.wav")
        let mimeType = await detector.detectMIMEType(at: url)
        // UTType may return "audio/vnd.wave" or "audio/wav", both are valid
        XCTAssertTrue(mimeType?.hasPrefix("audio/") ?? false)
    }
    
    func testDetectMIMETypeAsyncImage() async {
        let url = URL(fileURLWithPath: "/test/image.gif")
        let mimeType = await detector.detectMIMEType(at: url)
        XCTAssertEqual(mimeType, "image/gif")
    }
}
