//
//  AssetValidation.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for validating assets (existence and MIME type compatibility).
//

import Foundation
import CoreMedia

/// Result of asset validation.
@available(macOS 26.0, *)
public struct AssetValidationResult: Sendable, Equatable {
    /// Whether the asset exists and is accessible.
    public let exists: Bool
    
    /// The detected MIME type (nil if detection failed or asset doesn't exist).
    public let mimeType: String?
    
    /// Whether the MIME type is compatible with the lane.
    public let isCompatible: Bool
    
    /// Human-readable reason if validation failed.
    public let reason: String?
    
    public init(exists: Bool, mimeType: String?, isCompatible: Bool, reason: String? = nil) {
        self.exists = exists
        self.mimeType = mimeType
        self.isCompatible = isCompatible
        self.reason = reason
    }
    
    /// Whether validation passed (asset exists and MIME type is compatible).
    public var isValid: Bool {
        exists && isCompatible
    }
}

/// Protocol for validating assets.
@available(macOS 26.0, *)
public protocol AssetValidation: Sendable {
    /// Validates an asset at the given URL for compatibility with a specific lane.
    ///
    /// - Parameters:
    ///   - url: The asset URL to validate.
    ///   - lane: The lane number (negative = audio only, non-negative = video/image/audio).
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: Validation result indicating existence, MIME type, and compatibility.
    func validateAsset(
        at url: URL,
        forLane lane: Int,
        mimeTypeDetector: (any MIMETypeDetection)?
    ) async -> AssetValidationResult
}

/// Synchronous version of asset validation protocol.
@available(macOS 26.0, *)
public protocol AssetValidationSync: Sendable {
    /// Validates an asset at the given URL synchronously.
    ///
    /// - Parameters:
    ///   - url: The asset URL to validate.
    ///   - lane: The lane number.
    ///   - mimeTypeDetector: Optional MIME type detector (uses default if nil).
    /// - Returns: Validation result.
    func validateAssetSync(
        at url: URL,
        forLane lane: Int,
        mimeTypeDetector: (any MIMETypeDetectionSync)?
    ) -> AssetValidationResult
}
