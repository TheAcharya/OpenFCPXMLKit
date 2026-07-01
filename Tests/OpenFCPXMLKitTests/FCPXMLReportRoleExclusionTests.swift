//
//  FCPXMLReportRoleExclusionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Report role exclusion")
struct FCPXMLReportRoleExclusionTests {
    private typealias RoleInventory = FinalCutPro.FCPXML.RoleInventoryReportSection
    private typealias RoleRow = FinalCutPro.FCPXML.RoleClipReportRow
    private typealias RoleSheet = FinalCutPro.FCPXML.RoleSheet
    
    private func sampleRow(roleSubrole: String, clipName: String = "Clip A") -> RoleRow {
        RoleRow(
            roleSubrole: roleSubrole,
            clipName: clipName,
            category: "Audio",
            enabled: "Yes",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            clipDuration: "00:00:01:00",
            sourceIn: "00:00:00:00",
            sourceOut: "00:00:01:00",
            sourceDuration: "00:00:01:00"
        )
    }
    
    @Test("Excluding a main role removes parent and subrole sheets")
    func excludingMainRoleRemovesParentAndSubroles() {
        let section = RoleInventory(
            selectedRoles: [
                sampleRow(roleSubrole: "Dialogue ▸ Boom 1"),
                sampleRow(roleSubrole: "Video", clipName: "Clip B"),
            ],
            roleSheets: [
                RoleSheet(sheetName: "Dialogue", rows: []),
                RoleSheet(sheetName: "Dialogue ▸ Boom 1", rows: []),
                RoleSheet(sheetName: "Video", rows: []),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["Dialogue"],
            to: section
        )
        
        #expect(filtered.selectedRoles.count == 1)
        #expect(filtered.selectedRoles[0].clipName == "Clip B")
        #expect(filtered.roleSheets.map(\.sheetName) == ["Video"])
    }
    
    @Test("Excluding a subrole keeps sibling subroles")
    func excludingSubroleKeepsSiblingSubroles() {
        let section = RoleInventory(
            selectedRoles: [
                sampleRow(roleSubrole: "Dialogue ▸ Boom 1"),
                sampleRow(roleSubrole: "Dialogue ▸ Mix", clipName: "Clip B"),
            ],
            roleSheets: [
                RoleSheet(sheetName: "Dialogue ▸ Boom 1", rows: []),
                RoleSheet(sheetName: "Dialogue ▸ Mix", rows: []),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["Dialogue ▸ Boom 1"],
            to: section
        )
        
        #expect(filtered.selectedRoles.count == 1)
        #expect(filtered.selectedRoles[0].clipName == "Clip B")
        #expect(filtered.roleSheets.map(\.sheetName) == ["Dialogue ▸ Mix"])
    }
    
    @Test("Role exclusion is case-insensitive")
    func roleExclusionIsCaseInsensitive() {
        let section = RoleInventory(
            selectedRoles: [sampleRow(roleSubrole: "Video")],
            roleSheets: [RoleSheet(sheetName: "Video", rows: [])]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["video"],
            to: section
        )
        
        #expect(filtered.selectedRoles.isEmpty)
        #expect(filtered.roleSheets.isEmpty)
    }
}
