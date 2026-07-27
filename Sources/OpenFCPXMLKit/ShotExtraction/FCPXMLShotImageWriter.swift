//
// FCPXMLShotImageWriter.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Converts still media to PNG without changing pixel dimensions.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

extension FinalCutPro.FCPXML {
    /// Writes a still-image file as PNG at the destination URL (resolution preserved).
    enum ShotImageWriter {
        static func writePNG(from sourceURL: URL, to destinationURL: URL) throws {
            guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
                throw ShotExtractionError.imageWriteFailed(
                    path: destinationURL.path,
                    reason: "Could not open image source at \(sourceURL.path)"
                )
            }
            guard CGImageSourceGetCount(source) > 0,
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw ShotExtractionError.imageWriteFailed(
                    path: destinationURL.path,
                    reason: "Could not decode image at \(sourceURL.path)"
                )
            }

            let pngType = UTType.png.identifier as CFString
            guard let destination = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                pngType,
                1,
                nil
            ) else {
                throw ShotExtractionError.imageWriteFailed(
                    path: destinationURL.path,
                    reason: "Could not create PNG destination"
                )
            }

            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ShotExtractionError.imageWriteFailed(
                    path: destinationURL.path,
                    reason: "CGImageDestinationFinalize failed"
                )
            }
        }
    }
}
