//
//  FCPXMLTransitionsReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Transitions report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One row in the Transitions report sheet.
    public struct TransitionReportRow: Sendable, Equatable {
        public var transition: String
        public var category: String
        public var isApple: String
        public var timelineIn: String
        public var timelineOut: String
        public var duration: String
        
        public static let columnHeaders: [String] = [
            "Transition",
            "Category",
            "Apple",
            "Timeline In",
            "Timeline Out",
            "Duration"
        ]
        
        public init(
            transition: String,
            category: String,
            isApple: String,
            timelineIn: String,
            timelineOut: String,
            duration: String
        ) {
            self.transition = transition
            self.category = category
            self.isApple = isApple
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.duration = duration
        }
        
        public var columnValues: [String] {
            [transition, category, isApple, timelineIn, timelineOut, duration]
        }
    }
    
    /// Transitions report section.
    public struct TransitionsReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Transitions"
        public var rows: [TransitionReportRow]
        
        public init(rows: [TransitionReportRow] = []) {
            self.rows = rows
        }
    }
}
