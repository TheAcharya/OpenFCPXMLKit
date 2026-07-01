//
//  FCPXMLSummaryReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Summary / Files report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Project-level summary information for the Summary sheet header.
    public struct ProjectSummary: Sendable, Equatable {
        public var title: String
        public var duration: String
        public var resolution: String
        public var frameRate: String
        public var audioSampleRate: String
        
        public init(
            title: String,
            duration: String,
            resolution: String,
            frameRate: String,
            audioSampleRate: String
        ) {
            self.title = title
            self.duration = duration
            self.resolution = resolution
            self.frameRate = frameRate
            self.audioSampleRate = audioSampleRate
        }
        
        /// Values for the second row of the Summary sheet (duration, resolution, frame rate, audio rate).
        public var headerMetricValues: [String] {
            ["", duration, resolution, frameRate, audioSampleRate]
        }
    }
    
    /// One role-duration row in the Summary sheet role breakdown table.
    public struct SummaryRoleDurationRow: Sendable, Equatable {
        public var roleSubrole: String
        public var estimatedTotal: String
        public var percentOfTotal: Double
        
        public static let columnHeaders: [String] = [
            "Role ▸ Subrole",
            "Estimated Total",
            "% of Total"
        ]
        
        public init(roleSubrole: String, estimatedTotal: String, percentOfTotal: Double) {
            self.roleSubrole = roleSubrole
            self.estimatedTotal = estimatedTotal
            self.percentOfTotal = percentOfTotal
        }
        
        public var columnValues: [String] {
            [
                roleSubrole,
                estimatedTotal,
                String(percentOfTotal)
            ]
        }
    }
    
    /// Summary report section (project header, role-duration breakdown, missing media paths).
    public struct SummaryReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Summary"
        public static let missingMediaSectionTitle = "Missing Media"
        
        public var projectSummary: ProjectSummary?
        public var roleDurations: [SummaryRoleDurationRow]
        public var missingMediaPaths: [String]
        
        public init(
            projectSummary: ProjectSummary? = nil,
            roleDurations: [SummaryRoleDurationRow] = [],
            missingMediaPaths: [String] = []
        ) {
            self.projectSummary = projectSummary
            self.roleDurations = roleDurations
            self.missingMediaPaths = missingMediaPaths
        }
    }
}
