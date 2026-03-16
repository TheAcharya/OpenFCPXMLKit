//
//  MediaExtractor.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of MediaExtraction: extracts asset media-rep and locator URLs, copies files.
//

import Foundation

/// Default implementation of `MediaExtraction`.
@available(macOS 12.0, *)
public final class MediaExtractor: MediaExtraction, Sendable {

    public init() {}

    // MARK: - MediaExtraction (Sync)

    public func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL?) -> MediaExtractionResult {
        _extract(from: document, baseURL: baseURL)
    }

    public func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL?, progress: (any ProgressReporter)? = nil) -> MediaCopyResult {
        _copy(from: document, to: destinationURL, baseURL: baseURL, progress: progress)
    }

    // MARK: - MediaExtraction (Async)

    public func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL?) async -> MediaExtractionResult {
        _extract(from: document, baseURL: baseURL)
    }

    public func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL?, progress: (any ProgressReporter)? = nil) async -> MediaCopyResult {
        _copy(from: document, to: destinationURL, baseURL: baseURL, progress: progress)
    }

    // MARK: - Private

    private func _extract(from document: any PNXMLDocument, baseURL: URL?) -> MediaExtractionResult {
        var refs: [MediaReference] = []
        // Traverse: root > fcpxml > resources > child elements
        let resources: [any PNXMLElement] = {
            guard let root = document.rootElement(),
                  let resourcesEl = root.firstChildElement(named: "resources") else { return [] }
            return Array(resourcesEl.childElements)
        }()

        for resource in resources {
            let elementType = resource.fcpxType
            if elementType == .assetResource {
                if let ref = _assetMediaReference(resource, baseURL: baseURL) {
                    refs.append(ref)
                }
            } else if elementType == .locator {
                if let ref = _locatorMediaReference(resource, baseURL: baseURL) {
                    refs.append(ref)
                }
            }
        }
        return MediaExtractionResult(references: refs, baseURL: baseURL)
    }

    private func _assetMediaReference(_ assetElement: any PNXMLElement, baseURL: URL?) -> MediaReference? {
        guard let mediaRep = assetElement.firstChildElement(named: "media-rep") else { return nil }
        let srcString = mediaRep.getElementAttribute("src")
        guard let srcString = srcString, !srcString.isEmpty else { return nil }
        let url = _resolveURL(srcString, baseURL: baseURL)
        let resourceID = assetElement.fcpxID ?? assetElement.getElementAttribute("id") ?? ""
        let name = assetElement.fcpxName ?? assetElement.getElementAttribute("name")
        let suggestedFilename = mediaRep.getElementAttribute("suggestedFilename") ?? url?.lastPathComponent
        return MediaReference(
            resourceID: resourceID,
            url: url,
            name: name,
            suggestedFilename: suggestedFilename,
            isLocator: false
        )
    }

    private func _locatorMediaReference(_ locatorElement: any PNXMLElement, baseURL: URL?) -> MediaReference? {
        let urlString = locatorElement.getElementAttribute("url")
        guard let urlString = urlString, !urlString.isEmpty else { return nil }
        let url = _resolveURL(urlString, baseURL: baseURL)
        let resourceID = locatorElement.fcpxID ?? locatorElement.getElementAttribute("id") ?? ""
        return MediaReference(
            resourceID: resourceID,
            url: url,
            name: nil,
            suggestedFilename: url?.lastPathComponent,
            isLocator: true
        )
    }

    /// Resolves a URL string to a URL object.
    ///
    /// Resolution strategy:
    /// 1. If `srcString` is an absolute URL with a scheme (e.g., "file:///path" or "http://example.com"), returns it directly.
    /// 2. If `baseURL` is provided, attempts to resolve `srcString` relative to `baseURL`.
    /// 3. Otherwise, attempts to create a URL from `srcString` directly using Foundation's `URL(string:)`.
    ///
    /// - Parameters:
    ///   - srcString: The URL string to resolve (may be absolute or relative).
    ///   - baseURL: Optional base URL for resolving relative paths.
    /// - Returns: Resolved URL, or `nil` if Foundation's URL creation fails.
    ///
    /// - Note: When this method returns `nil`, the `MediaReference` will still be created but with `url: nil`.
    ///   Such references are automatically skipped during media copy operations. Additionally, URLs that are
    ///   not file URLs (e.g., http:// URLs) are also skipped during copy operations.
    private func _resolveURL(_ srcString: String, baseURL: URL?) -> URL? {
        // Try absolute URL with scheme first (file://, http://, etc.)
        if let u = URL(string: srcString), u.scheme != nil {
            return u
        }
        // Try relative to baseURL if provided
        if let base = baseURL {
            return URL(string: srcString, relativeTo: base)?.absoluteURL
        }
        // Last resort: try direct creation (may return nil for invalid strings)
        return URL(string: srcString)
    }

    private func _copy(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL?, progress: (any ProgressReporter)?) -> MediaCopyResult {
        let result = _extract(from: document, baseURL: baseURL)
        let fileRefs = result.fileReferences
        var seenSourceURLs: Set<URL> = []
        var usedFilenames: Set<String> = []
        var entries: [MediaCopyEntry] = []
        var processed = 0

        let fm = FileManager.default
        for ref in fileRefs {
            guard let sourceURL = ref.url else {
                // Advance progress even for skipped items (nil URL)
                progress?.advance(by: 1)
                continue
            }
            guard sourceURL.isFileURL else {
                entries.append(.skipped(source: sourceURL, reason: "Not a file URL"))
                progress?.advance(by: 1)
                continue
            }
            if seenSourceURLs.contains(sourceURL) {
                entries.append(.skipped(source: sourceURL, reason: "Duplicate"))
                progress?.advance(by: 1)
                continue
            }
            seenSourceURLs.insert(sourceURL)
            let filename = _uniqueFilename(
                preferred: ref.suggestedFilename ?? sourceURL.lastPathComponent,
                existing: &usedFilenames
            )
            usedFilenames.insert(filename)
            let destURL = destinationURL.appendingPathComponent(filename)
            if !fm.fileExists(atPath: sourceURL.path) {
                entries.append(.skipped(source: sourceURL, reason: "File does not exist"))
                progress?.advance(by: 1)
                continue
            }
            do {
                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                try fm.copyItem(at: sourceURL, to: destURL)
                entries.append(.copied(source: sourceURL, destination: destURL))
            } catch {
                entries.append(.failed(source: sourceURL, error: error.localizedDescription))
            }
            processed += 1
            progress?.advance(by: 1)
        }
        progress?.finish()
        return MediaCopyResult(entries: entries)
    }

    private func _uniqueFilename(preferred: String, existing: inout Set<String>) -> String {
        let base = preferred.isEmpty ? "media" : preferred
        if !existing.contains(base) {
            return base
        }
        let ext = (base as NSString).pathExtension
        let stem = (base as NSString).deletingPathExtension
        var n = 1
        while true {
            let candidate = ext.isEmpty ? "\(stem)_\(n)" : "\(stem)_\(n).\(ext)"
            if !existing.contains(candidate) {
                return candidate
            }
            n += 1
        }
    }
}
