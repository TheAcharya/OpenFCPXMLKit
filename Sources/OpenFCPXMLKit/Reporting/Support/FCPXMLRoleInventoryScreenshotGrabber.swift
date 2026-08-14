//
//  FCPXMLRoleInventoryScreenshotGrabber.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Frame / still grabs for Role Inventory Excel Screenshot column (Source In).
//

import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension FinalCutPro.FCPXML {
    /// Builds JPEG thumbnails for Role Inventory screenshots (Excel export only).
    enum RoleInventoryScreenshotGrabber {
        /// Maximum long-edge length in pixels. Source aspect ratio is preserved;
        /// frames are scaled down only when either edge exceeds this limit.
        static let maxLongEdgePixels: CGFloat = 480
        private static let jpegQuality: CGFloat = 0.72
        
        /// Returns JPEG bytes for the media file at ``fileTimeSeconds``, or `nil` when
        /// the file is missing / unreadable. Still images ignore the time and use the file
        /// itself. Failures are silent (blank Excel cell).
        static func jpegData(
            fileURL: URL,
            fileTimeSeconds: Double
        ) async -> Data? {
            let resolved = fileURL.standardizedFileURL
            guard FileManager.default.fileExists(atPath: resolved.path) else {
                return nil
            }
            
            if isStillImageFile(resolved) {
                return stillImageJPEG(from: resolved)
            }
            
            return await videoFrameJPEG(from: resolved, fileTimeSeconds: max(0, fileTimeSeconds))
        }
        
        private static func isStillImageFile(_ url: URL) -> Bool {
            let ext = url.pathExtension.lowercased()
            return [
                "png", "jpg", "jpeg", "tif", "tiff", "gif", "bmp",
                "heic", "heif", "webp", "psd"
            ].contains(ext)
        }
        
        private static func stillImageJPEG(from url: URL) -> Data? {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  CGImageSourceGetCount(source) > 0,
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                return nil
            }
            return jpegData(from: scaledImage(image))
        }
        
        private static func videoFrameJPEG(
            from url: URL,
            fileTimeSeconds: Double
        ) async -> Data? {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            // Decode a bit above the final long-edge cap, then scale precisely.
            generator.maximumSize = CGSize(
                width: maxLongEdgePixels * 2,
                height: maxLongEdgePixels * 2
            )
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            let timescale: CMTimeScale = 600
            let time = CMTime(
                seconds: fileTimeSeconds,
                preferredTimescale: timescale
            )
            
            if let image = await cgImage(from: generator, at: time) {
                return jpegData(from: scaledImage(image))
            }
            
            // Retry with a looser tolerance near the requested time (GOP boundaries).
            generator.requestedTimeToleranceBefore = CMTime(seconds: 0.25, preferredTimescale: timescale)
            generator.requestedTimeToleranceAfter = CMTime(seconds: 0.25, preferredTimescale: timescale)
            if let image = await cgImage(from: generator, at: time) {
                return jpegData(from: scaledImage(image))
            }
            
            // Last resort: first frame.
            if fileTimeSeconds > 0.001 {
                return await videoFrameJPEG(from: url, fileTimeSeconds: 0)
            }
            return nil
        }
        
        private static func cgImage(
            from generator: AVAssetImageGenerator,
            at time: CMTime
        ) async -> CGImage? {
            do {
                let result = try await generator.image(at: time)
                return result.image
            } catch {
                return nil
            }
        }
        
        private static func scaledImage(_ image: CGImage) -> CGImage {
            let width = CGFloat(image.width)
            let height = CGFloat(image.height)
            guard width > 0, height > 0 else { return image }
            
            let longEdge = max(width, height)
            let scale = min(maxLongEdgePixels / longEdge, 1.0)
            let targetW = max(1, Int((width * scale).rounded()))
            let targetH = max(1, Int((height * scale).rounded()))
            if targetW == image.width, targetH == image.height {
                return image
            }
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            guard let context = CGContext(
                data: nil,
                width: targetW,
                height: targetH,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return image
            }
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))
            return context.makeImage() ?? image
        }
        
        private static func jpegData(from image: CGImage) -> Data? {
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                return nil
            }
            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: jpegQuality
            ]
            CGImageDestinationAddImage(destination, image, options as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return data as Data
        }
    }
}
