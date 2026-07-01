//
//  AssetValidator.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of asset validation.
//

import Foundation
import CoreMedia

/// Default implementation of asset validation.
@available(macOS 26.0, *)
public struct AssetValidator: AssetValidation, AssetValidationSync, Sendable {
    
    public init() {}
    
    // MARK: - Sync Implementation
    
    public func validateAssetSync(
        at url: URL,
        forLane lane: Int,
        mimeTypeDetector: (any MIMETypeDetectionSync)? = nil
    ) -> AssetValidationResult {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return AssetValidationResult(
                exists: false,
                mimeType: nil,
                isCompatible: false,
                reason: "File does not exist at \(url.path)"
            )
        }
        
        // Detect MIME type
        let detector = mimeTypeDetector ?? MIMETypeDetector()
        guard let mimeType = detector.detectMIMETypeSync(at: url) else {
            return AssetValidationResult(
                exists: true,
                mimeType: nil,
                isCompatible: false,
                reason: "Could not detect MIME type"
            )
        }
        
        // Validate MIME type compatibility with lane
        let isCompatible = isMIMETypeCompatible(mimeType: mimeType, lane: lane)
        let reason: String?
        
        if !isCompatible {
            if lane < 0 {
                reason = "Clip on lane \(lane) expects audio/* but asset has MIME type '\(mimeType)'"
            } else {
                reason = "Clip on lane \(lane) expects video/*, image/*, or audio/* but asset has MIME type '\(mimeType)'"
            }
        } else {
            reason = nil
        }
        
        return AssetValidationResult(
            exists: true,
            mimeType: mimeType,
            isCompatible: isCompatible,
            reason: reason
        )
    }
    
    // MARK: - Async Implementation
    
    public func validateAsset(
        at url: URL,
        forLane lane: Int,
        mimeTypeDetector: (any MIMETypeDetection)? = nil
    ) async -> AssetValidationResult {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return AssetValidationResult(
                exists: false,
                mimeType: nil,
                isCompatible: false,
                reason: "File does not exist at \(url.path)"
            )
        }
        
        // Detect MIME type
        let detector = mimeTypeDetector ?? MIMETypeDetector()
        guard let mimeType = await detector.detectMIMEType(at: url) else {
            return AssetValidationResult(
                exists: true,
                mimeType: nil,
                isCompatible: false,
                reason: "Could not detect MIME type"
            )
        }
        
        // Validate MIME type compatibility with lane
        let isCompatible = isMIMETypeCompatible(mimeType: mimeType, lane: lane)
        let reason: String?
        
        if !isCompatible {
            if lane < 0 {
                reason = "Clip on lane \(lane) expects audio/* but asset has MIME type '\(mimeType)'"
            } else {
                reason = "Clip on lane \(lane) expects video/*, image/*, or audio/* but asset has MIME type '\(mimeType)'"
            }
        } else {
            reason = nil
        }
        
        return AssetValidationResult(
            exists: true,
            mimeType: mimeType,
            isCompatible: isCompatible,
            reason: reason
        )
    }
    
    // MARK: - Private Helpers
    
    /// Checks if a MIME type is compatible with a lane.
    ///
    /// - Parameters:
    ///   - mimeType: The MIME type to check.
    ///   - lane: The lane number (negative = audio only, non-negative = video/image/audio).
    /// - Returns: True if compatible, false otherwise.
    private func isMIMETypeCompatible(mimeType: String, lane: Int) -> Bool {
        if lane < 0 {
            // Negative lanes should be audio only
            return mimeType.hasPrefix("audio/")
        } else {
            // Non-negative lanes can be video, image, or audio
            return mimeType.hasPrefix("video/") ||
                   mimeType.hasPrefix("image/") ||
                   mimeType.hasPrefix("audio/")
        }
    }
}
