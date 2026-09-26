//
//  FCPXMLRoleInventoryScreenshotFileName.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	File names for full-size Role Inventory screenshot PNGs.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Names full-frame screenshot PNGs written beside an Excel report.
    ///
    /// The stamp is the file-relative Source In (`clip start` − asset `start`)
    /// as `HH-MM-SS-FF`. The same source file and time share one name. A
    /// different file that would use that name gains `_1`, `_2`, and so on.
    enum RoleInventoryScreenshotFileName {
        /// `HH-MM-SS-FF` for ``fileTimeSeconds`` at ``frameRate``.
        ///
        /// Separators are hyphens so the name is safe on disk. Drop-frame
        /// media still uses the drop-frame frame number; only the separator
        /// changes.
        static func timecodeStamp(
            fileTimeSeconds: Double,
            frameRate: TimecodeFrameRate
        ) -> String {
            let seconds = max(0, fileTimeSeconds)
            guard let timecode = try? Timecode(.realTime(seconds: seconds), at: frameRate) else {
                return "00-00-00-00"
            }
            return String(
                format: "%02d-%02d-%02d-%02d",
                timecode.hours,
                timecode.minutes,
                timecode.seconds,
                timecode.frames
            )
        }
        
        /// `SourceStem-HH-MM-SS-FF.png`, with the media extension removed.
        static func preferredFileName(
            sourceFileName: String,
            timecodeStamp: String
        ) -> String {
            let stamp = timecodeStamp.isEmpty ? "00-00-00-00" : timecodeStamp
            return "\(sanitizedSourceStem(sourceFileName))-\(stamp).png"
        }
        
        /// First occurrence keeps ``preferred``. Later collisions use `_1`, `_2`, …
        static func uniqueFileName(
            preferred: String,
            existing: Set<String>
        ) -> String {
            if !existing.contains(preferred) {
                return preferred
            }
            let ext = (preferred as NSString).pathExtension
            let stem = (preferred as NSString).deletingPathExtension
            var suffix = 1
            while true {
                let candidate = ext.isEmpty ? "\(stem)_\(suffix)" : "\(stem)_\(suffix).\(ext)"
                if !existing.contains(candidate) {
                    return candidate
                }
                suffix += 1
            }
        }
        
        /// Identity of one grab: resolved media paths plus the file time.
        static func grabIdentity(
            fileURLs: [URL],
            fileTimeSeconds: Double
        ) -> String {
            let paths = fileURLs.map(\.standardizedFileURL.path).joined(separator: ">")
            return paths + "|\(String(format: "%.6f", fileTimeSeconds))"
        }
        
        /// Source file stem safe for a single path component.
        static func sanitizedSourceStem(_ sourceFileName: String) -> String {
            let base = URL(fileURLWithPath: sourceFileName)
                .deletingPathExtension()
                .lastPathComponent
            let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
                .union(.controlCharacters)
                .union(.newlines)
            var stem = ""
            for scalar in base.unicodeScalars {
                if invalid.contains(scalar) {
                    stem.append("_")
                } else {
                    stem.unicodeScalars.append(scalar)
                }
            }
            let trimmed = stem.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
            return trimmed.isEmpty ? "Screenshot" : trimmed
        }
    }
}
