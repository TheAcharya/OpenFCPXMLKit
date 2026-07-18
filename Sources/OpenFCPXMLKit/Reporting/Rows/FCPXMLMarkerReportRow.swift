//
//  FCPXMLMarkerReportRow.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Row model for the Markers report sheet.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One row in the Markers report sheet.
    ///
    /// Default column order:
    /// Marker Name, Type, Notes, Position, Clip Name, Role ▸ Subrole, Reel, Scene, Source Position.
    ///
    /// When ``MarkersReportSection/showsHiddenColumn`` is `true` (opt-in via
    /// ``ReportOptions/includeMarkersOutsideClipBoundaries``), a trailing **Hidden** column is
    /// appended (✓ = outside host media range; ✗ = inside).
    public struct MarkerReportRow: Sendable, Equatable {
        public var markerName: String
        public var type: MarkerReportType
        public var notes: String
        public var position: String
        public var clipName: String
        public var roleSubrole: String
        public var reel: String
        public var scene: String
        public var sourcePosition: String
        /// Outside host media range (hidden in FCP Tags/timeline). Used when the Hidden column is shown.
        public var isHidden: Bool
        
        public init(
            markerName: String,
            type: MarkerReportType,
            notes: String = "",
            position: String,
            clipName: String,
            roleSubrole: String,
            reel: String = "",
            scene: String = "",
            sourcePosition: String,
            isHidden: Bool = false
        ) {
            self.markerName = markerName
            self.type = type
            self.notes = notes
            self.position = position
            self.clipName = clipName
            self.roleSubrole = roleSubrole
            self.reel = reel
            self.scene = scene
            self.sourcePosition = sourcePosition
            self.isHidden = isHidden
        }
        
        /// Column headers for the Markers sheet (no Hidden column).
        public static let columnHeaders: [String] = columnHeaders(timecodeFormat: .smpteFrames)
        
        public static func columnHeaders(
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            includeHiddenColumn: Bool = false
        ) -> [String] {
            var headers = [
                "Marker Name",
                "Type",
                "Notes",
                timecodeFormat.formattedColumnHeader("Position"),
                "Clip Name",
                "Role ▸ Subrole",
                "Reel",
                "Scene",
                timecodeFormat.formattedColumnHeader("Source Position")
            ]
            if includeHiddenColumn {
                headers.append("Hidden")
            }
            return headers
        }
        
        /// Values matching ``columnHeaders(timecodeFormat:includeHiddenColumn:)`` with Hidden omitted.
        public var columnValues: [String] {
            columnValues(includeHiddenColumn: false)
        }
        
        /// Values in header order, optionally including the Hidden checkmark column.
        public func columnValues(includeHiddenColumn: Bool) -> [String] {
            var values = [
                markerName,
                type.displayName,
                notes,
                position,
                clipName,
                roleSubrole,
                reel,
                scene,
                sourcePosition
            ]
            if includeHiddenColumn {
                values.append(ReportFormatting.enabledCheckmark(forEnabled: isHidden))
            }
            return values
        }
    }
    
    /// Marker type labels used in reference workbook exports.
    public enum MarkerReportType: String, Sendable, Equatable, CaseIterable {
        case standard = "Standard"
        case incompleteToDo = "Incomplete To-Do"
        case completedToDo = "Completed To-Do"
        case chapter = "Chapter"
        case analysis = "Analysis"
        
        public var displayName: String { rawValue }
    }
}
