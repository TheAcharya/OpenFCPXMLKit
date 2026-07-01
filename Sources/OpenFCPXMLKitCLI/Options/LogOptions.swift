//
//  LogOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	CLI options for logging: log file, level, and quiet.
//

import ArgumentParser
import Foundation
import OpenFCPXMLKit

struct LogOptions: ParsableArguments {
    @Option(
        name: .long,
        help: "Log file path.",
        transform: URL.init(fileURLWithPath:)
    )
    var log: URL?

    @Option(
        name: .long,
        help: "Log level. (values: trace, debug, info, notice, warning, error, critical; default: info)"
    )
    var logLevel: String = "info"

    @Flag(name: .long, help: "Disable log.")
    var quiet: Bool = false

    /// Builds a logger from the current options. When quiet, returns `NoOpServiceLogger`.
    /// When log level is invalid, defaults to .info.
    func makeLogger() -> ServiceLogger {
        if quiet {
            return NoOpServiceLogger()
        }
        let level = ServiceLogLevel.from(string: logLevel) ?? .info
        if let fileURL = log {
            return FileServiceLogger(
                minimumLevel: level,
                fileURL: fileURL,
                alsoPrint: true,
                quiet: false
            )
        }
        return PrintServiceLogger(minimumLevel: level)
    }
}
