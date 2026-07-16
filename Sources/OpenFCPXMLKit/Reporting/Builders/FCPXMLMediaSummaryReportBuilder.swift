//
// FCPXMLMediaSummaryReportBuilder.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Builds the Media Summary report section from FCPXML / Projection.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Builds the Media Summary sheet: missing media file paths referenced by the project.
    enum MediaSummaryReportBuilder {
        static func build(
            document: any OFKXMLDocument,
            baseURL: URL?,
            projection: ReportProjectionContext? = nil,
            distinguishProxyAndOriginal: Bool = false
        ) -> MediaSummaryReportSection {
            let classified = classifiedMissingPaths(
                in: document,
                baseURL: baseURL,
                projection: projection
            )
            let combined = classified.original
                .union(classified.proxy)
                .union(classified.locator)
                .sorted()

            return MediaSummaryReportSection(
                missingMediaPaths: combined,
                missingOriginalMediaPaths: classified.original.union(classified.locator).sorted(),
                missingProxyMediaPaths: classified.proxy.sorted(),
                distinguishProxyAndOriginal: distinguishProxyAndOriginal
            )
        }

        private struct ClassifiedMissing {
            var original: Set<String> = []
            var proxy: Set<String> = []
            var locator: Set<String> = []
        }

        private static func classifiedMissingPaths(
            in document: any OFKXMLDocument,
            baseURL: URL?,
            projection: ReportProjectionContext?
        ) -> ClassifiedMissing {
            var result = ClassifiedMissing()

            if let projection, !projection.windows.isEmpty {
                for window in projection.windows {
                    if let path = missingPath(for: window.channel.originalMediaURL, baseURL: baseURL) {
                        result.original.insert(path)
                    }
                    if let path = missingPath(for: window.channel.proxyMediaURL, baseURL: baseURL) {
                        result.proxy.insert(path)
                    }
                }
                result.locator = missingLocatorPaths(from: document, baseURL: baseURL)
                return result
            }

            // Document fallback cannot distinguish proxy vs original (first media-rep only).
            let combined = missingPathsFromDocument(document, baseURL: baseURL)
            result.original = combined
            return result
        }

        private static func missingPath(for url: URL?, baseURL: URL?) -> String? {
            guard let resolved = resolveFileURL(url, baseURL: baseURL) else { return nil }
            let path = resolved.path
            guard !path.isEmpty else { return nil }
            return FileManager.default.fileExists(atPath: path) ? nil : path
        }

        private static func missingLocatorPaths(
            from document: any OFKXMLDocument,
            baseURL: URL?
        ) -> Set<String> {
            let extractor = MediaExtractor()
            let result = extractor.extractMediaReferences(from: document, baseURL: baseURL)
            var missingPaths: Set<String> = []
            for reference in result.references where reference.isLocator {
                guard let url = reference.url, url.isFileURL else { continue }
                let path = url.path
                guard !path.isEmpty else { continue }
                if !FileManager.default.fileExists(atPath: path) {
                    missingPaths.insert(path)
                }
            }
            return missingPaths
        }

        private static func missingPathsFromDocument(
            _ document: any OFKXMLDocument,
            baseURL: URL?
        ) -> Set<String> {
            let extractor = MediaExtractor()
            let result = extractor.extractMediaReferences(from: document, baseURL: baseURL)
            var missingPaths: Set<String> = []
            for reference in result.references {
                guard let url = reference.url, url.isFileURL else { continue }
                let path = url.path
                guard !path.isEmpty else { continue }
                if !FileManager.default.fileExists(atPath: path) {
                    missingPaths.insert(path)
                }
            }
            return missingPaths
        }

        /// Resolves optional media URLs (absolute or relative to `baseURL`) to file URLs.
        private static func resolveFileURL(_ url: URL?, baseURL: URL?) -> URL? {
            guard let url else { return nil }
            if url.isFileURL { return url }
            if url.scheme != nil { return url.isFileURL ? url : nil }

            if let baseURL {
                let resolved = URL(string: url.relativeString, relativeTo: baseURL)?.absoluteURL
                return resolved?.isFileURL == true ? resolved : nil
            }
            return nil
        }
    }
}
