//
//  FCPXMLRoleInventoryReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Selected Roles inventory and per-role sheets from FCPXML.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Builds role-based clip inventory from a timeline element.
    enum RoleInventoryReportBuilder {
        static func build(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            projection: ReportProjectionContext? = nil,
            entries: [RoleInventoryClipEntry]? = nil,
            includeSpeedChangeSettings: Bool = false,
            includeScreenshots: Bool = false,
            mediaBaseURL: URL? = nil
        ) async -> RoleInventoryReportSection {
            let resolvedEntries: [RoleInventoryClipEntry]
            if let entries {
                resolvedEntries = entries
            } else {
                resolvedEntries = await RoleInventoryClipCollector.collectEntries(
                    from: timeline,
                    scope: scope,
                    roleDisplayPreference: roleDisplayPreference
                )
            }

            let windows = projection?.windows
            let windowIndex = windows.map { ProjectionWindowIndex(windows: $0) }

            // Building a row reads the XML tree, and the Foundation backend hands back
            // autoreleased objects. Without a pool boundary per row they accumulate for the
            // whole section.
            let selectedRoles = resolvedEntries
                .sortedByTimelinePosition()
                .compactMap { entry in
                    autoreleasepool {
                        RoleInventoryRowBuilder.row(
                            from: entry,
                            timecodeFormat: timecodeFormat,
                            projectionWindows: windows,
                            windowIndex: windowIndex,
                            includeScreenshots: includeScreenshots,
                            mediaBaseURL: mediaBaseURL
                        )
                    }
                }

            let roleSheets = RoleInventoryRoleSheetOrdering.roleSheets(from: selectedRoles)
            let metadataColumnKeys = RoleInventoryColumnLayout.metadataColumnKeys(
                from: selectedRoles
            )

            return RoleInventoryReportSection(
                selectedRoles: selectedRoles,
                roleSheets: roleSheets,
                metadataColumnKeys: metadataColumnKeys,
                showsSpeedChangeSettingsColumn: includeSpeedChangeSettings,
                showsScreenshotsColumn: includeScreenshots
            )
        }
    }
}