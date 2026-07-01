//
//  FCPXMLTitlesReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Titles & Generators report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One row in the Titles & Generators report sheet.
    public struct TitleReportRow: Sendable, Equatable {
        public var clipName: String
        public var enabled: String
        public var isApple: String
        public var roleSubrole: String
        public var timelineIn: String
        public var timelineOut: String
        public var duration: String
        public var font: String
        public var titleText: String
        
        public static let columnHeaders: [String] = [
            "Clip Name",
            "Enabled",
            "Apple",
            "Role ▸ Subrole",
            "Timeline In",
            "Timeline Out",
            "Duration",
            "Font",
            "Title Text"
        ]
        
        public init(
            clipName: String,
            enabled: String,
            isApple: String,
            roleSubrole: String,
            timelineIn: String,
            timelineOut: String,
            duration: String,
            font: String,
            titleText: String
        ) {
            self.clipName = clipName
            self.enabled = enabled
            self.isApple = isApple
            self.roleSubrole = roleSubrole
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.duration = duration
            self.font = font
            self.titleText = titleText
        }
        
        public var columnValues: [String] {
            [
                clipName,
                enabled,
                isApple,
                roleSubrole,
                timelineIn,
                timelineOut,
                duration,
                font,
                titleText
            ]
        }
    }
    
    /// Titles & Generators report section.
    public struct TitlesReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Titles & Generators"
        public var rows: [TitleReportRow]
        
        public init(rows: [TitleReportRow] = []) {
            self.rows = rows
        }
    }
}
