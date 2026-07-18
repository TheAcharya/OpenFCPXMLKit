//
//  FCPXMLParallelFileIOTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for parallel file I/O operations.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Parallel file I/O")
struct FCPXMLParallelFileIOTests {
    private var executor: ParallelFileIOExecutor { ParallelFileIOExecutor() }

    private func makeTempDirectory() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenFCPXMLKitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        return tempDirectory
    }

    // MARK: - Result Type Tests

    @Test("Parallel file I/O result properties")
    func parallelFileIOResultProperties() {
        let url = URL(fileURLWithPath: "/test/file.txt")
        let data = Data("test".utf8)
        let result = ParallelFileIOResult(index: 0, url: url, data: data, error: nil)

        #expect(result.index == 0)
        #expect(result.url == url)
        #expect(result.data == data)
        #expect(result.error == nil)
        #expect(result.succeeded)
    }

    @Test("Parallel file I/O result with error")
    func parallelFileIOResultWithError() {
        let url = URL(fileURLWithPath: "/test/file.txt")
        let error = NSError(domain: "Test", code: 1)
        let result = ParallelFileIOResult(index: 0, url: url, data: nil, error: error)

        #expect(!result.succeeded)
        #expect(result.error != nil)
    }

    // MARK: - Parallel Write Tests

    @Test("Write files in parallel")
    func writeFilesInParallel() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let testData = [
            (data: Data("File 1".utf8), url: tempDirectory.appendingPathComponent("file1.txt")),
            (data: Data("File 2".utf8), url: tempDirectory.appendingPathComponent("file2.txt")),
            (data: Data("File 3".utf8), url: tempDirectory.appendingPathComponent("file3.txt"))
        ]

        let results = try await executor.writeFiles(dataAndURLs: testData)

        #expect(results.count == 3)

        // Verify all writes succeeded
        for result in results {
            #expect(result.succeeded, "Write failed for \(result.url.lastPathComponent)")
            #expect(FileManager.default.fileExists(atPath: result.url.path))
        }

        // Verify file contents
        for (expectedData, url) in testData {
            let writtenData = try Data(contentsOf: url)
            #expect(writtenData == expectedData)
        }
    }

    @Test("Write files maintains order")
    func writeFilesMaintainsOrder() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let testData = (0..<5).map { index in
            (data: Data("File \(index)".utf8), url: tempDirectory.appendingPathComponent("file\(index).txt"))
        }

        let results = try await executor.writeFiles(dataAndURLs: testData)

        #expect(results.count == 5)

        // Verify order is maintained
        for (index, result) in results.enumerated() {
            #expect(result.index == index)
            #expect(result.url == testData[index].url)
        }
    }

    @Test("Write files with large data")
    func writeFilesWithLargeData() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let largeData = Data(count: 10_000_000) // 10 MB
        let testData = [
            (data: largeData, url: tempDirectory.appendingPathComponent("large.bin"))
        ]

        let results = try await executor.writeFiles(dataAndURLs: testData)

        #expect(results.count == 1)
        #expect(results[0].succeeded)

        // Verify file size
        let attributes = try FileManager.default.attributesOfItem(atPath: results[0].url.path)
        let fileSize = attributes[.size] as! Int64
        #expect(fileSize == Int64(largeData.count))
    }

    @Test("Write files with progress reporting")
    func writeFilesWithProgressReporting() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let testData = (0..<10).map { index in
            (data: Data("File \(index)".utf8), url: tempDirectory.appendingPathComponent("file\(index).txt"))
        }

        var progressCount = 0
        let progressReporter = MockProgressReporter {
            progressCount += 1
        }

        let results = try await executor.writeFiles(dataAndURLs: testData, progress: progressReporter)

        #expect(results.count == 10)
        // Progress should be called at least once per file
        #expect(progressCount >= 10)
    }

    // MARK: - Parallel Read Tests

    @Test("Read files in parallel")
    func readFilesInParallel() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
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

        #expect(results.count == 3)

        // Verify all reads succeeded
        for (index, result) in results.enumerated() {
            #expect(result.succeeded, "Read failed for \(result.url.lastPathComponent)")
            #expect(result.data == testFiles[index].data)
        }
    }

    @Test("Read files maintains order")
    func readFilesMaintainsOrder() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
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

        #expect(results.count == 5)

        // Verify order is maintained
        for (index, result) in results.enumerated() {
            #expect(result.index == index)
            #expect(result.url == testFiles[index].url)
            #expect(result.data == testFiles[index].data)
        }
    }

    @Test("Read files with non-existent files")
    func readFilesWithNonExistentFiles() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let nonExistentURLs = [
            tempDirectory.appendingPathComponent("nonexistent1.txt"),
            tempDirectory.appendingPathComponent("nonexistent2.txt")
        ]

        // Should throw or return errors in results
        do {
            let results = try await executor.readFiles(from: nonExistentURLs)
            // If it doesn't throw, check that results contain errors
            for result in results {
                #expect(!result.succeeded)
                #expect(result.error != nil)
            }
        } catch {
            // Throwing is also acceptable - error was thrown (verified by catch block)
            _ = error // Suppress unused variable warning
        }
    }

    @Test("Read files with progress reporting")
    func readFilesWithProgressReporting() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
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

        #expect(results.count == 10)
        // Progress should be called at least once per file
        #expect(progressCount >= 10)
    }

    // MARK: - Configuration Tests

    @Test("Executor with custom priority")
    func executorWithCustomPriority() {
        let executor = ParallelFileIOExecutor(taskPriority: .userInitiated)
        _ = executor
        #expect(true)
    }

    @Test("Executor with file handle disabled")
    func executorWithFileHandleDisabled() {
        let executor = ParallelFileIOExecutor(useFileHandleOptimization: false)
        _ = executor
        #expect(true)
    }

    @Test("Executor with preallocation disabled")
    func executorWithPreallocationDisabled() {
        let executor = ParallelFileIOExecutor(preallocateFileSpace: false)
        _ = executor
        #expect(true)
    }

    // MARK: - Edge Cases

    @Test("Write files with empty array")
    func writeFilesWithEmptyArray() async throws {
        let results = try await executor.writeFiles(dataAndURLs: [])
        #expect(results.count == 0)
    }

    @Test("Read files with empty array")
    func readFilesWithEmptyArray() async throws {
        let results = try await executor.readFiles(from: [])
        #expect(results.count == 0)
    }

    @Test("Write files with empty data")
    func writeFilesWithEmptyData() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let testData = [
            (data: Data(), url: tempDirectory.appendingPathComponent("empty.txt"))
        ]

        let results = try await executor.writeFiles(dataAndURLs: testData)

        #expect(results.count == 1)
        #expect(results[0].succeeded)

        // Verify file exists but is empty
        let attributes = try FileManager.default.attributesOfItem(atPath: results[0].url.path)
        let fileSize = attributes[.size] as! Int64
        #expect(fileSize == 0)
    }
}

// MARK: - Mock Progress Reporter

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
