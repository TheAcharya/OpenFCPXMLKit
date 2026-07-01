//
//  FCPXMLParallelFileIOTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for parallel file I/O operations.
//

import XCTest
import Foundation
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLParallelFileIOTests: XCTestCase {
    
    var executor: ParallelFileIOExecutor!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        executor = ParallelFileIOExecutor()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenFCPXMLKitTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    // MARK: - Result Type Tests
    
    func testParallelFileIOResultProperties() {
        let url = URL(fileURLWithPath: "/test/file.txt")
        let data = Data("test".utf8)
        let result = ParallelFileIOResult(index: 0, url: url, data: data, error: nil)
        
        XCTAssertEqual(result.index, 0)
        XCTAssertEqual(result.url, url)
        XCTAssertEqual(result.data, data)
        XCTAssertNil(result.error)
        XCTAssertTrue(result.succeeded)
    }
    
    func testParallelFileIOResultWithError() {
        let url = URL(fileURLWithPath: "/test/file.txt")
        let error = NSError(domain: "Test", code: 1)
        let result = ParallelFileIOResult(index: 0, url: url, data: nil, error: error)
        
        XCTAssertFalse(result.succeeded)
        XCTAssertNotNil(result.error)
    }
    
    // MARK: - Parallel Write Tests
    
    func testWriteFilesInParallel() async throws {
        let testData = [
            (data: Data("File 1".utf8), url: tempDirectory.appendingPathComponent("file1.txt")),
            (data: Data("File 2".utf8), url: tempDirectory.appendingPathComponent("file2.txt")),
            (data: Data("File 3".utf8), url: tempDirectory.appendingPathComponent("file3.txt"))
        ]
        
        let results = try await executor.writeFiles(dataAndURLs: testData)
        
        XCTAssertEqual(results.count, 3)
        
        // Verify all writes succeeded
        for result in results {
            XCTAssertTrue(result.succeeded, "Write failed for \(result.url.lastPathComponent)")
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.url.path))
        }
        
        // Verify file contents
        for (expectedData, url) in testData {
            let writtenData = try Data(contentsOf: url)
            XCTAssertEqual(writtenData, expectedData)
        }
    }
    
    func testWriteFilesMaintainsOrder() async throws {
        let testData = (0..<5).map { index in
            (data: Data("File \(index)".utf8), url: tempDirectory.appendingPathComponent("file\(index).txt"))
        }
        
        let results = try await executor.writeFiles(dataAndURLs: testData)
        
        XCTAssertEqual(results.count, 5)
        
        // Verify order is maintained
        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.index, index)
            XCTAssertEqual(result.url, testData[index].url)
        }
    }
    
    func testWriteFilesWithLargeData() async throws {
        let largeData = Data(count: 10_000_000) // 10 MB
        let testData = [
            (data: largeData, url: tempDirectory.appendingPathComponent("large.bin"))
        ]
        
        let results = try await executor.writeFiles(dataAndURLs: testData)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].succeeded)
        
        // Verify file size
        let attributes = try FileManager.default.attributesOfItem(atPath: results[0].url.path)
        let fileSize = attributes[.size] as! Int64
        XCTAssertEqual(fileSize, Int64(largeData.count))
    }
    
    func testWriteFilesWithProgressReporting() async throws {
        let testData = (0..<10).map { index in
            (data: Data("File \(index)".utf8), url: tempDirectory.appendingPathComponent("file\(index).txt"))
        }
        
        var progressCount = 0
        let progressReporter = MockProgressReporter {
            progressCount += 1
        }
        
        let results = try await executor.writeFiles(dataAndURLs: testData, progress: progressReporter)
        
        XCTAssertEqual(results.count, 10)
        // Progress should be called at least once per file
        XCTAssertGreaterThanOrEqual(progressCount, 10)
    }
    
    // MARK: - Parallel Read Tests
    
    func testReadFilesInParallel() async throws {
        // Create test files first
        let testFiles = [
            (data: Data("Content 1".utf8), url: tempDirectory.appendingPathComponent("read1.txt")),
            (data: Data("Content 2".utf8), url: tempDirectory.appendingPathComponent("read2.txt")),
            (data: Data("Content 3".utf8), url: tempDirectory.appendingPathComponent("read3.txt"))
        ]
        
        // Write files first
        for (data, url) in testFiles {
            try data.write(to: url, options: .atomic)
        }
        
        // Read files in parallel
        let urls = testFiles.map { $0.url }
        let results = try await executor.readFiles(from: urls)
        
        XCTAssertEqual(results.count, 3)
        
        // Verify all reads succeeded
        for (index, result) in results.enumerated() {
            XCTAssertTrue(result.succeeded, "Read failed for \(result.url.lastPathComponent)")
            XCTAssertEqual(result.data, testFiles[index].data)
        }
    }
    
    func testReadFilesMaintainsOrder() async throws {
        // Create test files
        let testFiles = (0..<5).map { index in
            (data: Data("File \(index)".utf8), url: tempDirectory.appendingPathComponent("read\(index).txt"))
        }
        
        for (data, url) in testFiles {
            try data.write(to: url, options: .atomic)
        }
        
        // Read files in parallel
        let urls = testFiles.map { $0.url }
        let results = try await executor.readFiles(from: urls)
        
        XCTAssertEqual(results.count, 5)
        
        // Verify order is maintained
        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.index, index)
            XCTAssertEqual(result.url, testFiles[index].url)
            XCTAssertEqual(result.data, testFiles[index].data)
        }
    }
    
    func testReadFilesWithNonExistentFiles() async throws {
        let nonExistentURLs = [
            tempDirectory.appendingPathComponent("nonexistent1.txt"),
            tempDirectory.appendingPathComponent("nonexistent2.txt")
        ]
        
        // Should throw or return errors in results
        do {
            let results = try await executor.readFiles(from: nonExistentURLs)
            // If it doesn't throw, check that results contain errors
            for result in results {
                XCTAssertFalse(result.succeeded)
                XCTAssertNotNil(result.error)
            }
        } catch {
            // Throwing is also acceptable - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }
    
    func testReadFilesWithProgressReporting() async throws {
        // Create test files
        let testFiles = (0..<10).map { index in
            (data: Data("File \(index)".utf8), url: tempDirectory.appendingPathComponent("read\(index).txt"))
        }
        
        for (data, url) in testFiles {
            try data.write(to: url, options: .atomic)
        }
        
        var progressCount = 0
        let progressReporter = MockProgressReporter {
            progressCount += 1
        }
        
        let urls = testFiles.map { $0.url }
        let results = try await executor.readFiles(from: urls, progress: progressReporter)
        
        XCTAssertEqual(results.count, 10)
        // Progress should be called at least once per file
        XCTAssertGreaterThanOrEqual(progressCount, 10)
    }
    
    // MARK: - Configuration Tests
    
    func testExecutorWithCustomPriority() {
        let executor = ParallelFileIOExecutor(taskPriority: .userInitiated)
        XCTAssertNotNil(executor)
    }
    
    func testExecutorWithFileHandleDisabled() {
        let executor = ParallelFileIOExecutor(useFileHandleOptimization: false)
        XCTAssertNotNil(executor)
    }
    
    func testExecutorWithPreallocationDisabled() {
        let executor = ParallelFileIOExecutor(preallocateFileSpace: false)
        XCTAssertNotNil(executor)
    }
    
    // MARK: - Edge Cases
    
    func testWriteFilesWithEmptyArray() async throws {
        let results = try await executor.writeFiles(dataAndURLs: [])
        XCTAssertEqual(results.count, 0)
    }
    
    func testReadFilesWithEmptyArray() async throws {
        let results = try await executor.readFiles(from: [])
        XCTAssertEqual(results.count, 0)
    }
    
    func testWriteFilesWithEmptyData() async throws {
        let testData = [
            (data: Data(), url: tempDirectory.appendingPathComponent("empty.txt"))
        ]
        
        let results = try await executor.writeFiles(dataAndURLs: testData)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].succeeded)
        
        // Verify file exists but is empty
        let attributes = try FileManager.default.attributesOfItem(atPath: results[0].url.path)
        let fileSize = attributes[.size] as! Int64
        XCTAssertEqual(fileSize, 0)
    }
}

// MARK: - Mock Progress Reporter

@available(macOS 26.0, *)
private final class MockProgressReporter: ProgressReporter, @unchecked Sendable {
    private let onAdvance: () -> Void
    
    init(onAdvance: @escaping () -> Void) {
        self.onAdvance = onAdvance
    }
    
    func advance(by n: Int) {
        for _ in 0..<n {
            onAdvance()
        }
    }
    
    func finish() {
        // No-op for tests
    }
}
