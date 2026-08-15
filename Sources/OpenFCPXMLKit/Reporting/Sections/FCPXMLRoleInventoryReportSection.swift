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
    /// One row in the Selected Roles Inventory sheet or a per-role breakdown sheet.
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
        /// Reused source-range duration vs other projected windows (blank when none).
        public var duplicateFrames: String
        public var markers: String
        public var keywords: String
        public var effects: String
        /// Retime percent (`50.0%`) when the clip has a non-identity speed change; blank otherwise.
        /// Exported only when ``RoleInventoryReportSection/showsSpeedChangeSettingsColumn`` is `true`.
        public var speedChangeSettings: String
        /// Preferred media file for Excel Screenshot embeds when
        /// ``RoleInventoryReportSection/showsScreenshotsColumn`` is `true`.
        /// Always `original-media` when that file exists on disk.
        public var screenshotMediaFileURL: URL?
        /// `proxy-media` file to try when the original is missing or unreadable
        /// (for example MXF or camera RAW).
        public var screenshotFallbackMediaFileURL: URL?
        /// Seconds into the media file for the Source In frame (asset-relative).
        public var screenshotFileTimeSeconds: Double?
        public var notes: String
        public var reel: String
        public var scene: String
        public var take: String
        public var cameraAngle: String
        public var cameraName: String
        public var frameRateSampleRate: String
        /// Video frame size or audio layout/channel config for the inventory column.
        public var frameSize: String
        public var sourceFileName: String
        public var sourceFilePath: String
        /// Spotlight codecs metadata (friendly ``Codecs`` column).
        public var codecs: String
        /// Ingest date metadata (friendly ``Ingest Date`` column).
        public var ingestDate: String
        /// Remaining metadata key/value pairs keyed by raw FCPXML metadata key.
        public var metadataValues: [String: String]
        
        /// Fixed inventory column headers (excluding ``RoleInventoryColumnLayout/rowColumnHeader``
        /// and dynamic metadata key columns).
        public static let fixedColumnHeaders = RoleInventoryColumnLayout.fixedColumnHeaders
        
        /// Legacy alias for fixed inventory headers used by existing call sites.
        public static let selectedRolesColumnHeaders = fixedColumnHeaders
        
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
            duplicateFrames: String = "",
            markers: String = "",
            keywords: String = "",
            effects: String = "",
            speedChangeSettings: String = "",
            screenshotMediaFileURL: URL? = nil,
            screenshotFallbackMediaFileURL: URL? = nil,
            screenshotFileTimeSeconds: Double? = nil,
            notes: String = "",
            reel: String = "",
            scene: String = "",
            take: String = "",
            cameraAngle: String = "",
            cameraName: String = "",
            frameRateSampleRate: String = "",
            frameSize: String = "",
            sourceFileName: String = "",
            sourceFilePath: String = "",
            codecs: String = "",
            ingestDate: String = "",
            metadataValues: [String: String] = [:]
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
            self.duplicateFrames = duplicateFrames
            self.markers = markers
            self.keywords = keywords
            self.effects = effects
            self.speedChangeSettings = speedChangeSettings
            self.screenshotMediaFileURL = screenshotMediaFileURL
            self.screenshotFallbackMediaFileURL = screenshotFallbackMediaFileURL
            self.screenshotFileTimeSeconds = screenshotFileTimeSeconds
            self.notes = notes
            self.reel = reel
            self.scene = scene
            self.take = take
            self.cameraAngle = cameraAngle
            self.cameraName = cameraName
            self.frameRateSampleRate = frameRateSampleRate
            self.frameSize = frameSize
            self.sourceFileName = sourceFileName
            self.sourceFilePath = sourceFilePath
            self.codecs = codecs
            self.ingestDate = ingestDate
            self.metadataValues = metadataValues
        }
        
        /// Values for ``fixedColumnHeaders`` in column order (always-on 26 columns; excludes
        /// optional ``speedChangeSettings``).
        public var fixedColumnValues: [String] {
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
                duplicateFrames,
                markers,
                keywords,
                effects,
                notes,
                reel,
                scene,
                take,
                cameraAngle,
                cameraName,
                frameRateSampleRate,
                frameSize,
                sourceFileName,
                sourceFilePath,
                codecs,
                ingestDate
            ]
        }
        
        /// Values in ``fixedColumnHeaders`` order.
        @available(*, deprecated, message: "Use fixedColumnValues or RoleInventoryColumnLayout.columnValues(for:metadataColumnKeys:)")
        public var columnValues: [String] {
            fixedColumnValues
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
    
    /// Role-based clip inventory (Selected Roles Inventory + per-role sheets).
    public struct RoleInventoryReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Selected Roles Inventory"
        /// Status text when Role Inventory is enabled but Selected Roles Inventory has no rows.
        public static let emptyStatusMessage = "No Roles Found"
        
        public var selectedRoles: [RoleClipReportRow]
        public var roleSheets: [RoleSheet]
        /// Dynamic metadata key columns appended after the fixed inventory columns.
        public var metadataColumnKeys: [String]
        /// When `true` (opt-in via ``ReportOptions/includeSpeedChangeSettingsInRoleInventory``),
        /// inventory sheets include a **Speed Change Settings** column after **Effects**.
        public var showsSpeedChangeSettingsColumn: Bool
        /// When `true` (opt-in via ``ReportOptions/includeScreenshotsInRoleInventory``), Excel
        /// inventory sheets include a **Screenshot** column after **Row** and embed Source In
        /// frames. PDF export ignores this flag.
        public var showsScreenshotsColumn: Bool
        
        public init(
            selectedRoles: [RoleClipReportRow] = [],
            roleSheets: [RoleSheet] = [],
            metadataColumnKeys: [String] = [],
            showsSpeedChangeSettingsColumn: Bool = false,
            showsScreenshotsColumn: Bool = false
        ) {
            self.selectedRoles = selectedRoles
            self.roleSheets = roleSheets
            self.metadataColumnKeys = metadataColumnKeys
            self.showsSpeedChangeSettingsColumn = showsSpeedChangeSettingsColumn
            self.showsScreenshotsColumn = showsScreenshotsColumn
        }
    }
}

