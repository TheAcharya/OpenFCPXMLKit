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
    /// Column order for the Markers sheet:
    /// Marker Name, Type, Notes, Position, Clip Name, Role ▸ Subrole, Reel, Scene, Source Position.
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
        
        public init(
            markerName: String,
            type: MarkerReportType,
            notes: String = "",
            position: String,
            clipName: String,
            roleSubrole: String,
            reel: String = "",
            scene: String = "",
            sourcePosition: String
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
        }
        
        /// Column headers for the Markers sheet.
        public static let columnHeaders: [String] = columnHeaders(timecodeFormat: .smpteFrames)
        
        public static func columnHeaders(
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) -> [String] {
            [
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
        }
        
        /// Values in ``columnHeaders`` order.
        public var columnValues: [String] {
            [
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
