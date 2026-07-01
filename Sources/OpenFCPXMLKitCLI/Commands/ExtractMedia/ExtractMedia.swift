//
//  ExtractMedia.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License

//
//
//  Scan FCPXML/FCPXMLD and copy all referenced media to output-dir (used by --media-copy).
//

import Foundation
import OpenFCPXMLKit

enum ExtractMedia {

    private static let videoExtensions: Set<String> = ["mov", "mp4", "m4v", "avi", "mxf", "mkv", "webm", "mpg", "mpeg", "3gp"]
    private static let audioExtensions: Set<String> = ["wav", "aif", "aiff", "mp3", "m4a", "caf", "aac", "wma", "flac"]
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "tiff", "tif", "heic", "heif", "gif", "bmp", "psd"]

    /// Categorizes a file URL by extension into video, audio, or image; otherwise "other".
    private static func mediaKind(for url: URL) -> (video: Int, audio: Int, image: Int) {
        let ext = url.pathExtension.lowercased()
        if videoExtensions.contains(ext) { return (1, 0, 0) }
        if audioExtensions.contains(ext) { return (0, 1, 0) }
        if imageExtensions.contains(ext) { return (0, 0, 1) }
        return (0, 0, 0)
    }

    /// Loads the FCPXML at the given URL and copies all referenced media files to outputDir.
    /// - Parameter showProgress: When true and there are files to copy, shows a progress bar (unless stdout is not a TTY).
    static func run(fcpxmlPath: URL, outputDir: URL, logger: ServiceLogger = NoOpServiceLogger(), showProgress: Bool = true) throws {
        let service = FCPXMLService(logger: logger)
        let document = try service.parseFCPXML(from: fcpxmlPath)

        let baseURL: URL? = fcpxmlPath.hasDirectoryPath
            ? fcpxmlPath
            : fcpxmlPath.deletingLastPathComponent()

        let extraction = service.extractMediaReferences(from: document, baseURL: baseURL)
        let fileRefs = extraction.fileReferences

        var videoCount = 0, audioCount = 0, imageCount = 0
        for ref in fileRefs {
            guard let url = ref.url else { continue }
            let k = mediaKind(for: url)
            videoCount += k.video
            audioCount += k.audio
            imageCount += k.image
        }
        let totalDetected = fileRefs.count
        let detectedMessage = "Media detected: \(videoCount) video, \(audioCount) audio, \(imageCount) images (\(totalDetected) total)."
        fputs("\(detectedMessage)\n", stderr)
        logger.log(level: .info, message: detectedMessage, metadata: nil)

        let progress: (any ProgressReporter)? = (showProgress && totalDetected > 0)
            ? ProgressBar(total: totalDetected, desc: "Copying media")
            : nil
        let result = service.copyReferencedMedia(from: document, to: outputDir, baseURL: baseURL, progress: progress)

        let copiedCount = result.copied.count
        let skippedCount = result.skipped.count
        let failedCount = result.failed.count

        for (_, destination) in result.copied {
            print(destination.path)
            logger.log(level: .info, message: "Copied to \(destination.path)", metadata: nil)
        }

        if failedCount > 0 {
            for entry in result.failed {
                if case .failed(_, let error) = entry {
                    let errMsg = "\(entry.sourceURL.path): \(error)"
                    fputs("Error: \(errMsg)\n", stderr)
                    logger.log(level: .error, message: errMsg, metadata: nil)
                }
            }
            let summaryMsg = "Copied: \(copiedCount), skipped: \(skippedCount), failed: \(failedCount)."
            fputs("\(summaryMsg)\n", stderr)
            logger.log(level: .error, message: summaryMsg, metadata: nil)
            throw ExtractMediaError.copyFailed(count: failedCount)
        }

        let successMessage = "Successfully copied \(copiedCount) media file\(copiedCount == 1 ? "" : "s") to \(outputDir.path)."
        fputs("\(successMessage)\n", stderr)
        logger.log(level: .info, message: successMessage, metadata: nil)
    }
}

enum ExtractMediaError: Error, LocalizedError {
    case copyFailed(count: Int)

    var errorDescription: String? {
        switch self {
        case .copyFailed(let count):
            return "Failed to copy \(count) file(s). See stderr for details."
        }
    }
}
