//
//  FCPXMLProgressReporter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for reporting progress of long-running operations (e.g. file copy).
//

import Foundation

/// Reports progress for long-running operations.
///
/// Named `FCPXMLProgressReporter` so it does not collide with Foundation’s
/// `ProgressReporter` type (macOS 27 / iOS 27, Xcode 27 / Swift 6.4).
///
/// **Thread Safety:** Implementations (e.g. ``ProgressBar``) are typically **not thread-safe** and should be used
/// from a single thread (e.g. CLI context or main thread). Concurrent access may cause incorrect progress reporting.
/// If multi-threaded use is required, implementors should provide their own synchronization mechanisms.
@available(macOS 26.0, *)
public protocol FCPXMLProgressReporter: AnyObject {
    /// Advance progress by the given number of steps.
    func advance(by n: Int)
    /// Mark progress as finished and finalize output.
    func finish()
}
