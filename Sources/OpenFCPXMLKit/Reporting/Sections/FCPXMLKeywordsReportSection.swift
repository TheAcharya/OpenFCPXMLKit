//
//  FCPXMLKeywordsReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Keywords report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One row in the Keywords report sheet.
    public struct KeywordReportRow: Sendable, Equatable {
        public var keyword: String
        public var notes: String
        public var timelineIn: String
        public var timelineOut: String
        public var duration: String
        public var clipName: String
        public var roleSubrole: String
        public var reel: String
        public var scene: String
        
        public static let columnHeaders: [String] = [
            "Keyword",
            "Notes",
            "Timeline In",
            "Timeline Out",
            "Duration",
            "Clip Name",
            "Role ▸ Subrole",
            "Reel",
            "Scene"
        ]
        
        public init(
            keyword: String,
            notes: String = "",
            timelineIn: String,
            timelineOut: String,
            duration: String,
            clipName: String,
            roleSubrole: String,
            reel: String = "",
            scene: String = ""
        ) {
            self.keyword = keyword
            self.notes = notes
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.duration = duration
            self.clipName = clipName
            self.roleSubrole = roleSubrole
            self.reel = reel
            self.scene = scene
        }
        
        public var columnValues: [String] {
            [
                keyword,
                notes,
                timelineIn,
                timelineOut,
                duration,
                clipName,
                roleSubrole,
                reel,
                scene
            ]
        }
    }
    
    /// Keywords report section.
    public struct KeywordsReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Keywords"
        public var rows: [KeywordReportRow]
        
        public init(rows: [KeywordReportRow] = []) {
            self.rows = rows
        }
    }
}
