//
//  FCPXMLMediaExtractionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for media reference extraction and copy.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLMediaExtractionTests: XCTestCase, @unchecked Sendable {

    private var service: FCPXMLService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        service = FCPXMLService()
    }

    override func tearDownWithError() throws {
        service = nil
        try super.tearDownWithError()
    }

    // MARK: - Copy (missing file → skipped)

    func testCopyReferencedMedia_MissingFile_Skips() throws {
        let nonexistent = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)/missing.mov")
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Missing" format="r1">
                    <media-rep kind="original-media" src="\(nonexistent.absoluteString)"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        let data = Data(fcpxml.utf8)
        let document = try service.parseFCPXML(from: data)
        let destDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destDir) }
        let result = service.copyReferencedMedia(from: document, to: destDir, baseURL: nil, progress: nil)
        XCTAssertEqual(result.entries.count, 1)
        let entry = try XCTUnwrap(result.entries.first)
        if case .skipped(_, let reason) = entry {
            XCTAssertEqual(reason, "File does not exist")
        } else {
            XCTFail("Expected skipped when source file does not exist, got \(entry)")
        }
    }

    // MARK: - Copy (real file → copied)

    func testCopyReferencedMedia_RealFile_Copies() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let sourceFile = tempDir.appendingPathComponent("test_media.mp4")
        try Data("fake video bytes".utf8).write(to: sourceFile)
        let fcpxmlURL = tempDir.appendingPathComponent("project.fcpxml")
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Test" format="r1">
                    <media-rep kind="original-media" src="\(sourceFile.absoluteString)"/>
                </asset>
            </resources>
            <library>
                <event name="E1">
                    <project name="P1">
                        <sequence format="r1" duration="100/25s" tcStart="0s"/>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
        try Data(fcpxml.utf8).write(to: fcpxmlURL)
        let data = try Data(contentsOf: fcpxmlURL)
        let document = try service.parseFCPXML(from: data)
        let destDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destDir) }
        let result = service.copyReferencedMedia(from: document, to: destDir, baseURL: nil, progress: nil)
        XCTAssertEqual(result.copied.count, 1, "One file should be copied")
        let (src, dest) = try XCTUnwrap(result.copied.first)
        XCTAssertEqual(src.lastPathComponent, "test_media.mp4")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path), "Copied file should exist at destination")
    }

    func testCopyReferencedMedia_RealFile_Async() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let sourceFile = tempDir.appendingPathComponent("async_test.mp4")
        try Data("async".utf8).write(to: sourceFile)
        let fcpxmlURL = tempDir.appendingPathComponent("project.fcpxml")
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Async" format="r1">
                    <media-rep kind="original-media" src="\(sourceFile.absoluteString)"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        try Data(fcpxml.utf8).write(to: fcpxmlURL)
        let data = try Data(contentsOf: fcpxmlURL)
        let document = try await service.parseFCPXML(from: data)
        let destDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destDir) }
        let result = await service.copyReferencedMedia(from: document, to: destDir, baseURL: nil, progress: nil)
        XCTAssertEqual(result.copied.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.copied[0].destination.path))
    }

    // MARK: - Extract then copy (flow used by CLI --media-copy)

    /// Verifies the extract-then-copy flow used by the CLI: extraction returns file refs (video/audio/image by extension), then copy succeeds.
    func testExtractThenCopy_MultipleTypes_DetectedAndCopied() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let videoFile = tempDir.appendingPathComponent("clip.mov")
        let audioFile = tempDir.appendingPathComponent("sound.wav")
        try Data("video".utf8).write(to: videoFile)
        try Data("audio".utf8).write(to: audioFile)
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="V" format="r1">
                    <media-rep kind="original-media" src="\(videoFile.absoluteString)"/>
                </asset>
                <asset id="r3" name="A" format="r1">
                    <media-rep kind="original-media" src="\(audioFile.absoluteString)"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        let data = Data(fcpxml.utf8)
        let document = try service.parseFCPXML(from: data)
        let extraction = service.extractMediaReferences(from: document, baseURL: tempDir)
        let fileRefs = extraction.fileReferences
        XCTAssertEqual(fileRefs.count, 2, "Two file references (video + audio)")
        let extensions = Set(fileRefs.compactMap { $0.url?.pathExtension.lowercased() })
        XCTAssertTrue(extensions.contains("mov"), "Video reference (.mov) detected")
        XCTAssertTrue(extensions.contains("wav"), "Audio reference (.wav) detected")

        let destDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destDir) }
        let copyResult = service.copyReferencedMedia(from: document, to: destDir, baseURL: tempDir, progress: nil)
        XCTAssertEqual(copyResult.copied.count, 2, "Both files copied")
        XCTAssertEqual(copyResult.failed.count, 0)
    }

    // MARK: - URL Resolution Edge Cases

    func testExtractMediaReferences_InvalidURL_HandledGracefully() throws {
        // Test that URLs without schemes are handled (Foundation's URL(string:) may create URLs even without schemes)
        // The important thing is that the MediaReference is created and can be handled appropriately
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Invalid" format="r1">
                    <media-rep kind="original-media" src="not-a-valid-url-without-scheme"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        let data = Data(fcpxml.utf8)
        let document = try service.parseFCPXML(from: data)
        
        // Extract without baseURL
        let result = service.extractMediaReferences(from: document, baseURL: nil)
        
        XCTAssertEqual(result.references.count, 1, "Should still create MediaReference")
        let ref = try XCTUnwrap(result.references.first)
        // URL may or may not be nil depending on Foundation's URL parsing behavior
        // The important thing is that if it's not a file URL, it will be skipped during copy
        XCTAssertEqual(ref.resourceID, "r2")
        if let url = ref.url {
            // If URL exists, verify it's not a file URL (so it will be skipped)
            XCTAssertFalse(url.isFileURL, "URL without scheme should not be a file URL")
        }
    }

    func testExtractMediaReferences_RelativeURLWithoutBase_HandledGracefully() throws {
        // Test that relative URLs without baseURL are handled appropriately
        // Foundation's URL(string:) may create URLs, but they won't be file URLs
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Relative" format="r1">
                    <media-rep kind="original-media" src="relative/path/to/file.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        let data = Data(fcpxml.utf8)
        let document = try service.parseFCPXML(from: data)
        
        // Extract without baseURL
        let result = service.extractMediaReferences(from: document, baseURL: nil)
        
        XCTAssertEqual(result.references.count, 1)
        let ref = try XCTUnwrap(result.references.first)
        // URL may exist but won't be a file URL, so it will be skipped during copy
        if let url = ref.url {
            XCTAssertFalse(url.isFileURL, "Relative URL without baseURL should not resolve to file URL")
        }
    }

    func testExtractMediaReferences_RelativeURLWithBase_ResolvesCorrectly() throws {
        // Test that relative URLs with baseURL resolve correctly
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let relativePath = "media/clip.mov"
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Relative" format="r1">
                    <media-rep kind="original-media" src="\(relativePath)"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        let data = Data(fcpxml.utf8)
        let document = try service.parseFCPXML(from: data)
        
        // Extract with baseURL - relative URL should resolve
        let result = service.extractMediaReferences(from: document, baseURL: tempDir)
        
        XCTAssertEqual(result.references.count, 1)
        let ref = try XCTUnwrap(result.references.first)
        XCTAssertNotNil(ref.url, "URL should be resolved when baseURL is provided")
        XCTAssertEqual(ref.url?.lastPathComponent, "clip.mov")
    }

    func testCopyReferencedMedia_NilURL_Skips() throws {
        // Test that references with nil URLs are skipped during copy
        let fcpxml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Invalid" format="r1">
                    <media-rep kind="original-media" src="invalid-url-without-scheme"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P"><sequence format="r1" duration="100/25s" tcStart="0s"/></project></event></library>
        </fcpxml>
        """
        let data = Data(fcpxml.utf8)
        let document = try service.parseFCPXML(from: data)
        
        let destDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destDir) }
        
        let result = service.copyReferencedMedia(from: document, to: destDir, baseURL: nil, progress: nil)
        
        // Should have no entries because nil URL references are skipped
        XCTAssertEqual(result.entries.count, 0, "References with nil URLs should be skipped during copy")
        XCTAssertEqual(result.copied.count, 0)
        XCTAssertEqual(result.skipped.count, 0)
    }
}
