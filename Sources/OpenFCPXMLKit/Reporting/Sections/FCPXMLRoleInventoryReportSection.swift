//
//  FCPXMLRoleInventoryReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Role-based clip inventory report models.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One row in the Selected Roles sheet or a per-role breakdown sheet.
    public struct RoleClipReportRow: Sendable, Equatable {
        public var roleSubrole: String
        public var clipName: String
        public var category: String
        public var enabled: String
        public var timelineIn: String
        public var timelineOut: String
        public var clipDuration: String
        public var sourceIn: String
        public var sourceOut: String
        public var sourceDuration: String
        public var markers: String
        public var keywords: String
        public var effects: String
        public var notes: String
        public var reel: String
        public var scene: String
        
        public static let selectedRolesColumnHeaders: [String] = [
            "Role ▸ Subrole",
            "Clip Name",
            "Category",
            "Enabled",
            "Timeline In",
            "Timeline Out",
            "Clip Duration",
            "Source In",
            "Source Out",
            "Source Duration",
            "Markers",
            "Keywords",
            "Effects",
            "Notes",
            "Reel",
            "Scene"
        ]
        
        public init(
            roleSubrole: String,
            clipName: String,
            category: String,
            enabled: String,
            timelineIn: String,
            timelineOut: String,
            clipDuration: String,
            sourceIn: String,
            sourceOut: String,
            sourceDuration: String,
            markers: String = "",
            keywords: String = "",
            effects: String = "",
            notes: String = "",
            reel: String = "",
            scene: String = ""
        ) {
            self.roleSubrole = roleSubrole
            self.clipName = clipName
            self.category = category
            self.enabled = enabled
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
            self.clipDuration = clipDuration
            self.sourceIn = sourceIn
            self.sourceOut = sourceOut
            self.sourceDuration = sourceDuration
            self.markers = markers
            self.keywords = keywords
            self.effects = effects
            self.notes = notes
            self.reel = reel
            self.scene = scene
        }
        
        /// Values in ``selectedRolesColumnHeaders`` order.
        public var columnValues: [String] {
            [
                roleSubrole,
                clipName,
                category,
                enabled,
                timelineIn,
                timelineOut,
                clipDuration,
                sourceIn,
                sourceOut,
                sourceDuration,
                markers,
                keywords,
                effects,
                notes,
                reel,
                scene
            ]
        }
    }
    public struct RoleSheet: Sendable, Equatable {
        public var sheetName: String
        public var rows: [RoleClipReportRow]
        
        public init(sheetName: String, rows: [RoleClipReportRow]) {
            self.sheetName = sheetName
            self.rows = rows
        }
    }
    
    /// Role-based clip inventory (Selected Roles + per-role sheets).
    public struct RoleInventoryReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Selected Roles"
        
        public var selectedRoles: [RoleClipReportRow]
        public var roleSheets: [RoleSheet]
        
        public init(
            selectedRoles: [RoleClipReportRow] = [],
            roleSheets: [RoleSheet] = []
        ) {
            self.selectedRoles = selectedRoles
            self.roleSheets = roleSheets
        }
    }
}
