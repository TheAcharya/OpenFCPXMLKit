//
//  FCPXMLRoleInventorySheetTotal.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Per-role inventory sheet clip-duration footer (optimistic sum of row values).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Presentation helper for per-role inventory sheet ``Total:`` footers.
    ///
    /// Sums already-formatted ``RoleClipReportRow/clipDuration`` cell strings (optimistic,
    /// non-overlap-aware). Does not walk FCPXML or Projection.
    enum RoleInventorySheetTotal {
        /// Footer label placed under the Timeline Out column (PBF-style layout).
        static let label = "Total:"
        
        /// Optimistic sum of ``RoleClipReportRow/clipDuration`` values, formatted for export.
        static func optimisticClipDurationTotal(
            from rows: [RoleClipReportRow],
            timecodeFormat: ReportTimecodeFormat,
            projectFrameRateHint: String? = nil
        ) -> String? {
            guard !rows.isEmpty else { return nil }
            guard let frameRate = inferTimelineFrameRate(
                from: rows,
                projectFrameRateHint: projectFrameRateHint
            ) else { return nil }
            
            switch timecodeFormat {
            case .frames:
                let totalFrames = rows.reduce(into: 0) { partial, row in
                    let trimmed = row.clipDuration.trimmingCharacters(in: .whitespacesAndNewlines)
                    partial += Int(trimmed) ?? 0
                }
                return String(totalFrames)
                
            case .feetAndFrames, .smpteFrames, .smpteNoFrames:
                var totalFrames = 0
                for row in rows {
                    guard let frames = wholeFrames(
                        fromFormattedDuration: row.clipDuration,
                        format: timecodeFormat,
                        frameRate: frameRate
                    ) else { continue }
                    totalFrames += frames
                }
                guard let totalTimecode = try? Timecode(.frames(totalFrames), at: frameRate) else {
                    return nil
                }
                return ReportFormatting.timecodeString(totalTimecode, format: timecodeFormat)
            }
        }
        
        /// Column indices for the footer row in an inventory header row (0-based).
        static func footerColumnIndices(
            in headers: [String],
            excludedColumns: Set<ReportColumn>,
            timecodeFormat: ReportTimecodeFormat
        ) -> (label: Int, value: Int)? {
            guard !excludedColumns.contains(.timelineOut),
                  !excludedColumns.contains(.clipDuration),
                  let timelineOutHeader = ReportColumn.timelineOut.workbookHeader(timecodeFormat: timecodeFormat),
                  let clipDurationHeader = ReportColumn.clipDuration.workbookHeader(timecodeFormat: timecodeFormat),
                  let labelIndex = headers.firstIndex(of: timelineOutHeader),
                  let valueIndex = headers.firstIndex(of: clipDurationHeader)
            else { return nil }
            return (labelIndex, valueIndex)
        }
        
        private static func inferTimelineFrameRate(
            from rows: [RoleClipReportRow],
            projectFrameRateHint: String?
        ) -> TimecodeFrameRate? {
            var baseRate: TimecodeFrameRate?
            for row in rows {
                if let rate = frameRate(fromDisplay: row.frameRateSampleRate) {
                    baseRate = rate
                    break
                }
            }
            if baseRate == nil,
               let hint = projectFrameRateHint
            {
                baseRate = frameRate(fromDisplay: hint)
            }
            guard var rate = baseRate else { return nil }
            
            let usesDropFrameNotation = rows.contains { $0.clipDuration.contains(";") }
            if usesDropFrameNotation {
                switch rate {
                case .fps29_97: rate = .fps29_97d
                case .fps59_94: rate = .fps59_94d
                default: break
                }
            }
            return rate
        }
        
        private static func frameRate(fromDisplay display: String) -> TimecodeFrameRate? {
            let trimmed = display.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            
            let normalized = trimmed
                .lowercased()
                .replacingOccurrences(of: "fps", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let fps = Double(normalized) else { return nil }
            
            let candidates: [(Double, TimecodeFrameRate)] = [
                (23.976, .fps23_976),
                (24, .fps24),
                (25, .fps25),
                (29.97, .fps29_97),
                (30, .fps30),
                (50, .fps50),
                (59.94, .fps59_94),
                (60, .fps60)
            ]
            return candidates.min(by: { abs($0.0 - fps) < abs($1.0 - fps) })?.1
        }
        
        private static func wholeFrames(
            fromFormattedDuration value: String,
            format: ReportTimecodeFormat,
            frameRate: TimecodeFrameRate
        ) -> Int? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            
            switch format {
            case .frames:
                return Int(trimmed)
            case .feetAndFrames:
                let parsed = parseFeetAndFrames(trimmed)
                guard parsed.feet != Int.min else { return nil }
                guard let timecode = try? Timecode(
                    .feetAndFrames(feet: parsed.feet, frames: parsed.frames),
                    at: frameRate
                ) else { return nil }
                return timecode.frameCount.wholeFrames
            case .smpteNoFrames:
                return wholeFrames(fromSMPTEDuration: trimmed, includeFrames: false, frameRate: frameRate)
            case .smpteFrames:
                return wholeFrames(fromSMPTEDuration: trimmed, includeFrames: true, frameRate: frameRate)
            }
        }
        
        private static func parseFeetAndFrames(_ value: String) -> (feet: Int, frames: Int) {
            let parts = value.split(separator: "+", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let feet = Int(parts[0]),
                  let frames = Int(parts[1])
            else {
                return (Int.min, Int.min)
            }
            return (feet, frames)
        }
        
        private static func wholeFrames(
            fromSMPTEDuration value: String,
            includeFrames: Bool,
            frameRate: TimecodeFrameRate
        ) -> Int? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            
            let parseString = includeFrames ? trimmed : "\(trimmed):00"
            guard let timecode = try? Timecode(.string(parseString), at: frameRate) else {
                return nil
            }
            return timecode.frameCount.wholeFrames
        }
    }
}

