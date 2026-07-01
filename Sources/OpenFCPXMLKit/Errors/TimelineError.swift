//
//  TimelineError.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Error types for timeline manipulation operations.
//

import Foundation
import CoreMedia

/// Errors that can occur during timeline operations
@available(macOS 26.0, *)
public enum TimelineError: Error, LocalizedError, Sendable {
    
    /// No available lane found for clip insertion at the specified position
    case noAvailableLane(at: CMTime, duration: CMTime)
    
    /// Asset not found at the specified URL
    case assetNotFound(url: URL)
    
    /// Invalid asset format - MIME type doesn't match lane requirements
    case invalidFormat(reason: String)
    
    /// Invalid asset reference - asset doesn't exist or can't be accessed
    case invalidAssetReference(assetRef: String, reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .noAvailableLane(let offset, let duration):
            let offsetSeconds = CMTimeGetSeconds(offset)
            let durationSeconds = CMTimeGetSeconds(duration)
            return "No available lane found for clip insertion at \(offsetSeconds)s (duration: \(durationSeconds)s)"
        case .assetNotFound(let url):
            return "Asset not found at URL: \(url.path)"
        case .invalidFormat(let reason):
            return "Invalid asset format: \(reason)"
        case .invalidAssetReference(let assetRef, let reason):
            return "Invalid asset reference '\(assetRef)': \(reason)"
        }
    }
}
