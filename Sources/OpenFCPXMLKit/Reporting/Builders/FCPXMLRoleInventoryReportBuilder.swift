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
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) async -> RoleInventoryReportSection {
            let entries = await RoleInventoryClipCollector.collectEntries(
                from: timeline,
                scope: scope,
                roleDisplayPreference: roleDisplayPreference
            )
            
            let selectedRoles = entries
                .sortedByTimelinePosition()
                .compactMap { RoleInventoryRowBuilder.row(from: $0, timecodeFormat: timecodeFormat) }
            
            let roleSheets = RoleInventoryRoleSheetOrdering.roleSheets(from: selectedRoles)
            let metadataColumnKeys = RoleInventoryColumnLayout.metadataColumnKeys(
                from: selectedRoles
            )
            
            return RoleInventoryReportSection(
                selectedRoles: selectedRoles,
                roleSheets: roleSheets,
                metadataColumnKeys: metadataColumnKeys
            )
        }
    }
}
