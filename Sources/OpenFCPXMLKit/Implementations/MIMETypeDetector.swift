//
//  MIMETypeDetector.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of MIME type detection using UTType and AVFoundation.
//

import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Default implementation of MIME type detection.
@available(macOS 26.0, *)
public struct MIMETypeDetector: MIMETypeDetection, MIMETypeDetectionSync, Sendable {
    
    public init() {}
    
    // MARK: - Sync Implementation
    
    /// Detects MIME type synchronously using UTType and file extension fallback.
    public func detectMIMETypeSync(at url: URL) -> String? {
        // Strategy 1: Use UTType from file extension
        #if canImport(UniformTypeIdentifiers)
        if let utType = UTType(filenameExtension: url.pathExtension) {
            if let mimeType = utType.preferredMIMEType {
                return mimeType
            }
        }
        #endif
        
        // Strategy 2: File extension fallback
        return mimeTypeFromExtension(url.pathExtension)
    }
    
    // MARK: - Async Implementation
    
    /// Detects MIME type asynchronously, using AVFoundation for media files when available.
    public func detectMIMEType(at url: URL) async -> String? {
        // First try sync detection (UTType + extension)
        if let mimeType = detectMIMETypeSync(at: url) {
            return mimeType
        }
        
        // Strategy 3: Use AVFoundation for media files
        #if canImport(AVFoundation)
        if let avMimeType = await detectMIMETypeFromAVAsset(at: url) {
            return avMimeType
        }
        #endif
        
        return nil
    }
    
    // MARK: - Private Helpers
    
    #if canImport(AVFoundation)
    /// Detects MIME type by inspecting AVAsset.
    private func detectMIMETypeFromAVAsset(at url: URL) async -> String? {
        let asset = AVURLAsset(url: url)
        
        // Check if asset is readable
        guard let isReadable = try? await asset.load(.isReadable), isReadable else {
            return nil
        }
        
        // Check tracks to determine media type
        do {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            
            if !videoTracks.isEmpty {
                // Has video - determine format from extension or default to video/mp4
                return mimeTypeFromExtension(url.pathExtension) ?? "video/mp4"
            } else if !audioTracks.isEmpty {
                // Audio only - determine format from extension or default to audio/mpeg
                return mimeTypeFromExtension(url.pathExtension) ?? "audio/mpeg"
            }
        } catch {
            // If track loading fails, fall back to extension-based detection
            return nil
        }
        
        return nil
    }
    #endif
    
    /// Maps file extension to MIME type.
    private func mimeTypeFromExtension(_ fileExtension: String) -> String? {
        let ext = fileExtension.lowercased()
        
        // Common MIME type mappings
        switch ext {
        // Video
        case "mp4", "m4v": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        case "mpg", "mpeg": return "video/mpeg"
        case "webm": return "video/webm"
        case "flv": return "video/x-flv"
        
        // Audio
        case "mp3": return "audio/mpeg"
        case "m4a": return "audio/mp4"
        case "aac": return "audio/aac"
        case "wav": return "audio/wav"
        case "aiff", "aif": return "audio/aiff"
        case "caf": return "audio/x-caf"
        case "flac": return "audio/flac"
        case "ogg": return "audio/ogg"
        case "opus": return "audio/opus"
        
        // Image
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "tiff", "tif": return "image/tiff"
        case "heic": return "image/heic"
        case "heif": return "image/heif"
        case "webp": return "image/webp"
        case "bmp": return "image/bmp"
        case "svg": return "image/svg+xml"
        
        default: return nil
        }
    }
}
