//
//  FCPXMLRoleInventoryScreenshotMedia.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Resolves original / proxy media files for Role Inventory Excel screenshots.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Picks a Source In grab file for Role Inventory screenshots.
    ///
    /// Always prefers ``MediaRep/Kind/originalMedia``. ``MediaRep/Kind/proxyMedia`` is
    /// only a fallback when the original is missing on disk or cannot be decoded
    /// (for example MXF or camera RAW). Source File Path stays original-first.
    enum RoleInventoryScreenshotMedia {
        struct Target: Equatable, Sendable {
            var preferredURL: URL
            var fallbackURL: URL?
            var fileTimeSeconds: Double
            
            /// Unique grab candidates in try order (original first, then proxy).
            var orderedFileURLs: [URL] {
                var urls = [preferredURL]
                if let fallbackURL, !Self.sameFile(fallbackURL, preferredURL) {
                    urls.append(fallbackURL)
                }
                return urls
            }
            
            static func sameFile(_ lhs: URL, _ rhs: URL) -> Bool {
                lhs.standardizedFileURL.path == rhs.standardizedFileURL.path
            }
        }
        
        /// Resolves a screenshot target, or `nil` for categories with no useful video frame.
        static func target(
            for clipContext: ExtractedElement,
            category: ReportClipCategory,
            preferAudioAngle: Bool,
            mediaBaseURL: URL?,
            projectionWindow: MediaUsageWindow? = nil
        ) -> Target? {
            guard category.isVideoCategory
                || category == .primaryClip
                || category == .connectedClip
                || category == .connectedGenerator
            else {
                return nil
            }
            
            let declared = declaredURLs(
                for: clipContext,
                preferAudioAngle: preferAudioAngle,
                projectionWindow: projectionWindow
            )
            guard declared.original != nil || declared.proxy != nil else {
                return nil
            }
            
            let ordered = orderedCandidateURLs(
                original: declared.original,
                proxy: declared.proxy,
                mediaBaseURL: mediaBaseURL
            )
            guard let preferred = ordered.first else { return nil }
            
            let clipStart = clipContext.element.fcpStart?.doubleValue
                ?? clipContext.element._fcpStartAsTimecode(
                    frameRateSource: .localToElement,
                    default: nil
                )?.realTimeValue
                ?? 0
            let assetStart = assetStartSeconds(
                for: clipContext.element,
                resources: clipContext.resources,
                preferAudioAngle: preferAudioAngle
            )
            
            return Target(
                preferredURL: preferred,
                fallbackURL: ordered.dropFirst().first,
                fileTimeSeconds: max(0, clipStart - assetStart)
            )
        }
        
        /// Declared original / proxy URLs from a matching Projection window, else Parsing.
        static func declaredURLs(
            for clipContext: ExtractedElement,
            preferAudioAngle: Bool,
            projectionWindow: MediaUsageWindow?
        ) -> (original: URL?, proxy: URL?) {
            if let channel = projectionWindow?.channel,
               channel.originalMediaURL != nil || channel.proxyMediaURL != nil
            {
                return (channel.originalMediaURL, channel.proxyMediaURL)
            }
            
            return clipContext.element.fcpMediaRepresentationURLs(
                in: clipContext.resources,
                preferAudioAngle: preferAudioAngle
            )
        }
        
        /// On-disk original, then on-disk proxy; if neither exists, declared original then proxy.
        static func orderedCandidateURLs(
            original: URL?,
            proxy: URL?,
            mediaBaseURL: URL?
        ) -> [URL] {
            let resolvedOriginal = original.flatMap { existingFileURL($0, mediaBaseURL: mediaBaseURL) }
            let resolvedProxy = proxy.flatMap { existingFileURL($0, mediaBaseURL: mediaBaseURL) }
            
            var ordered: [URL] = []
            func append(_ url: URL?) {
                guard let url else { return }
                if !ordered.contains(where: { Target.sameFile($0, url) }) {
                    ordered.append(url)
                }
            }
            
            if resolvedOriginal != nil || resolvedProxy != nil {
                append(resolvedOriginal)
                append(resolvedProxy)
                return ordered
            }
            
            append(original)
            append(proxy)
            return ordered
        }
        
        /// Absolute / `mediaBaseURL`-relative file that exists on disk.
        static func existingFileURL(
            _ url: URL,
            mediaBaseURL: URL?
        ) -> URL? {
            let resolved = resolveFileURL(url, mediaBaseURL: mediaBaseURL)
            let path = resolved.standardizedFileURL.path
            guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
                return nil
            }
            return resolved
        }
        
        static func resolveFileURL(
            _ url: URL,
            mediaBaseURL: URL?
        ) -> URL {
            if url.isFileURL {
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
                if let mediaBaseURL {
                    let relative = url.path.hasPrefix("/")
                        ? String(url.path.dropFirst())
                        : url.path
                    let joined = mediaBaseURL.appendingPathComponent(relative)
                    if FileManager.default.fileExists(atPath: joined.path) {
                        return joined
                    }
                    let byName = mediaBaseURL.appendingPathComponent(url.lastPathComponent)
                    if FileManager.default.fileExists(atPath: byName.path) {
                        return byName
                    }
                }
                return url
            }
            if let mediaBaseURL {
                let byName = mediaBaseURL.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: byName.path) {
                    return byName
                }
                return byName
            }
            return url
        }
        
        static func assetStartSeconds(
            for element: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            preferAudioAngle: Bool
        ) -> Double {
            if let ref = element.fcpRef,
               let asset = element.fcpResource(forID: ref, in: resources)?.fcpAsAsset
            {
                return asset.start?.doubleValue ?? 0
            }
            
            switch element.fcpElementType {
            case .clip, .syncClip, .mcClip, .refClip, .audition:
                if let leaf = element._fcpFirstChildTimelineElement(excluding: [.gap, .title]) {
                    return assetStartSeconds(
                        for: leaf,
                        resources: resources,
                        preferAudioAngle: preferAudioAngle
                    )
                }
            default:
                break
            }
            return 0
        }
    }
}
