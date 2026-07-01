//
//  ServiceLogger.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Pluggable logging protocol with no-op, print, and file-backed implementations.
//

import Foundation

/// Log level for OpenFCPXMLKit operations.
/// Ordered by severity: trace (most verbose) through critical (most severe).
@available(macOS 26.0, *)
public enum ServiceLogLevel: Int, Sendable, Comparable, CaseIterable {
    case trace = 0
    case debug = 1
    case info = 2
    case notice = 3
    case warning = 4
    case error = 5
    case critical = 6

    public static func < (lhs: ServiceLogLevel, rhs: ServiceLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Short label for log output (e.g. "TRACE", "INFO").
    public var label: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }

    /// Parses a log level from a string (e.g. "info", "debug"). Case-insensitive. Returns nil if invalid.
    public static func from(string: String) -> ServiceLogLevel? {
        switch string.lowercased() {
        case "trace": return .trace
        case "debug": return .debug
        case "info": return .info
        case "notice": return .notice
        case "warning": return .warning
        case "error": return .error
        case "critical": return .critical
        default: return nil
        }
    }
}

/// Protocol for optional logging in OpenFCPXMLKit. Consumers can supply a custom implementation
/// (e.g. bridging to swift-log or OSLog); the default is no-op.
@available(macOS 26.0, *)
public protocol ServiceLogger: Sendable {
    /// Log a message with optional metadata.
    /// - Parameters:
    ///   - level: Severity level.
    ///   - message: Log message.
    ///   - metadata: Optional key-value metadata (e.g. "url", "duration").
    func log(level: ServiceLogLevel, message: String, metadata: [String: String]?)
}

/// Default no-op logger. Used when no logger is injected.
@available(macOS 26.0, *)
public struct NoOpServiceLogger: ServiceLogger, Sendable {
    public init() {}
    public func log(level: ServiceLogLevel, message: String, metadata: [String: String]?) {}
}

/// Simple print-based logger for debugging. Logs to stdout with level prefix.
@available(macOS 26.0, *)
public struct PrintServiceLogger: ServiceLogger, Sendable {
    public var minimumLevel: ServiceLogLevel

    public init(minimumLevel: ServiceLogLevel = .info) {
        self.minimumLevel = minimumLevel
    }

    public func log(level: ServiceLogLevel, message: String, metadata: [String: String]?) {
        guard level >= minimumLevel else { return }
        let prefix = "[OpenFCPXMLKit \(level.label)]"
        var line = "\(prefix) \(message)"
        if let metadata = metadata, !metadata.isEmpty {
            line += " " + metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        }
        // Write to stderr to avoid interfering with progress bars on stdout
        fputs("\(line)\n", stderr)
    }
}

/// Logger that writes to a file and optionally to the console. Thread-safe; uses a serial queue for file writes.
@available(macOS 26.0, *)
public final class FileServiceLogger: ServiceLogger, Sendable {

    private let minimumLevel: ServiceLogLevel
    private let quiet: Bool
    private let writeToFile: Bool
    private let fileURL: URL?
    private let writeToConsole: Bool
    private let fileHandle: FileHandle?
    private let queue: DispatchQueue

    /// - Parameters:
    ///   - minimumLevel: Minimum level to emit (default: .info).
    ///   - fileURL: If non-nil and writable, log lines are appended to this file.
    ///   - alsoPrint: If true, also print to stdout (ignored when quiet).
    ///   - quiet: If true, no output is produced (file and console both disabled).
    public init(
        minimumLevel: ServiceLogLevel = .info,
        fileURL: URL? = nil,
        alsoPrint: Bool = true,
        quiet: Bool = false
    ) {
        self.minimumLevel = minimumLevel
        self.quiet = quiet
        self.writeToFile = !quiet && fileURL != nil
        self.fileURL = fileURL
        self.writeToConsole = !quiet && alsoPrint
        self.queue = DispatchQueue(label: "OpenFCPXMLKit.FileServiceLogger", qos: .utility)

        var handle: FileHandle?
        if let url = fileURL, writeToFile {
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            handle = try? FileHandle(forWritingTo: url)
            if let h = handle {
                h.seekToEndOfFile()
            }
        }
        self.fileHandle = handle
    }

    deinit {
        try? fileHandle?.close()
    }

    private static func formatTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    public func log(level: ServiceLogLevel, message: String, metadata: [String: String]?) {
        guard !quiet, level >= minimumLevel else { return }
        let levelLabel = level.label
        let meta = metadata
        queue.async { [weak self] in
            guard let self = self else { return }
            let ts = Self.formatTimestamp()
            var line = "\(ts) [\(levelLabel)] \(message)"
            if let metadata = meta, !metadata.isEmpty {
                line += " " + metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            }
            line += "\n"
            if self.writeToConsole {
                // Write to stderr to avoid interfering with progress bars on stdout
                fputs(line, stderr)
            }
            if let handle = self.fileHandle, self.writeToFile {
                if let data = line.data(using: .utf8) {
                    handle.write(data)
                    try? handle.synchronize()
                }
            }
        }
    }
}
