//
//  ProgressReporter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for reporting progress of long-running operations (e.g. file copy).
//

import Foundation

/// Reports progress for long-running operations.
///
/// **Thread Safety:** Implementations (e.g. ``ProgressBar``) are typically **not thread-safe** and should be used
/// from a single thread (e.g. CLI context or main thread). Concurrent access may cause incorrect progress reporting.
/// If multi-threaded use is required, implementors should provide their own synchronization mechanisms.
public protocol ProgressReporter: AnyObject {
    /// Advance progress by the given number of steps.
    func advance(by n: Int)
    /// Mark progress as finished and finalize output.
    func finish()
}
