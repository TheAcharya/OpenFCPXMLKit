//
//  FCPXMLReportRoleExclusionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

import Foundation
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
    
    @Test("Excluding a main role omits matching Video & Audio Effects rows")
    func excludingMainRoleOmitsEffectsRows() {
        let section = FinalCutPro.FCPXML.EffectsReportSection(
            rows: [
                effectRow(clipName: "Basic Title", roleSubrole: "Vfx Shot No ▸ Vfx Shot No-1"),
                effectRow(clipName: "A Roll", roleSubrole: "Video"),
                effectRow(
                    clipName: "VFX Card",
                    roleSubrole: "Vfx Shot No ▸ Vfx Shot No-1"
                ),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["VFX Shot No"],
            to: section
        )
        
        #expect(filtered.rows.map(\.clipName) == ["A Roll"])
        #expect(filtered.rows.map(\.roleSubrole) == ["Video"])
    }
    
    @Test("Excluding a full Role Subrole omits main-only Effects rows")
    func excludingFullRoleSubroleOmitsMainOnlyEffectsRows() {
        let section = FinalCutPro.FCPXML.EffectsReportSection(
            rows: [
                effectRow(clipName: "Basic Title", roleSubrole: "Vfx Shot No"),
                effectRow(clipName: "A Roll", roleSubrole: "Video"),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["Vfx Shot No ▸ Vfx Shot No-1"],
            to: section
        )
        
        #expect(filtered.rows.map(\.clipName) == ["A Roll"])
    }
    
    @Test("Excluding a raw FCP role id omits matching Effects rows")
    func excludingRawFCPRoleIdOmitsEffectsRows() {
        let section = FinalCutPro.FCPXML.EffectsReportSection(
            rows: [
                effectRow(clipName: "Basic Title", roleSubrole: "Vfx Shot No ▸ Vfx Shot No-1"),
                effectRow(clipName: "A Roll", roleSubrole: "Video"),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["VFX Shot No.VFX Shot No-1"],
            to: section
        )
        
        #expect(filtered.rows.map(\.clipName) == ["A Roll"])
    }
    
    @Test("Excluding a subrole keeps sibling subroles on Effects")
    func excludingSubroleKeepsSiblingEffectsSubroles() {
        let section = FinalCutPro.FCPXML.EffectsReportSection(
            rows: [
                effectRow(clipName: "Boom FX", roleSubrole: "Dialogue ▸ Boom 1"),
                effectRow(clipName: "Mix FX", roleSubrole: "Dialogue ▸ Mix"),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["Dialogue ▸ Boom 1"],
            to: section
        )
        
        #expect(filtered.rows.map(\.clipName) == ["Mix FX"])
    }
    
    @Test("Excluding an Excel-truncated sheet tab omits the full Role Subrole rows")
    func excludingTruncatedSheetTabOmitsFullRoleSubroleRows() {
        // Long enough that `sheetTabName` truncates to 31 characters (Excel tab limit).
        let fullRole = "Custom Library Role Name Here ▸ Custom Library Role Name Here-1"
        let truncatedTab = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(for: fullRole)
        #expect(truncatedTab.count == 31)
        #expect(truncatedTab != fullRole)
        #expect(fullRole.hasPrefix(truncatedTab))
        
        let inventory = RoleInventory(
            selectedRoles: [
                sampleRow(roleSubrole: fullRole),
                sampleRow(roleSubrole: "Video", clipName: "Clip B"),
            ],
            roleSheets: [
                RoleSheet(sheetName: truncatedTab, rows: []),
                RoleSheet(sheetName: "Video", rows: []),
            ]
        )
        let titles = FinalCutPro.FCPXML.TitlesReportSection(
            rows: [
                titleRow(clipName: "Title Card", roleSubrole: fullRole),
                titleRow(clipName: "Lower Third", roleSubrole: "Titles"),
            ]
        )
        let effects = FinalCutPro.FCPXML.EffectsReportSection(
            rows: [
                effectRow(clipName: "Title Card", roleSubrole: fullRole),
                effectRow(clipName: "A Roll", roleSubrole: "Video"),
            ]
        )
        
        let filteredInventory = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: [truncatedTab],
            to: inventory
        )
        let filteredTitles = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: [truncatedTab],
            to: titles
        )
        let filteredEffects = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: [truncatedTab],
            to: effects
        )
        
        #expect(filteredInventory.selectedRoles.map(\.clipName) == ["Clip B"])
        #expect(filteredInventory.roleSheets.map(\.sheetName) == ["Video"])
        #expect(filteredTitles.rows.map(\.clipName) == ["Lower Third"])
        #expect(filteredEffects.rows.map(\.clipName) == ["A Roll"])
    }
    
    @Test("Excluding a main role omits matching Titles & Generators rows")
    func excludingMainRoleOmitsTitleRows() {
        let section = FinalCutPro.FCPXML.TitlesReportSection(
            rows: [
                titleRow(clipName: "Basic Title", roleSubrole: "Vfx Shot No ▸ Vfx Shot No-1"),
                titleRow(clipName: "Lower Third", roleSubrole: "Titles"),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["VFX Shot No"],
            to: section
        )
        
        #expect(filtered.rows.map(\.clipName) == ["Lower Third"])
    }
    
    @Test("Excluding a role keeps empty Role Subrole rows")
    func excludingRoleKeepsEmptyRoleFields() {
        let section = FinalCutPro.FCPXML.MarkersReportSection(
            rows: [
                markerRow(clipName: "Basic Title", roleSubrole: "Vfx Shot No"),
                markerRow(clipName: "Unrole'd", roleSubrole: ""),
                markerRow(clipName: "A Roll", roleSubrole: "Video"),
            ]
        )
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.applying(
            excludedRoleNames: ["VFX Shot No"],
            to: section
        )
                #expect(filtered.rows.map(\.clipName) == ["Unrole'd", "A Roll"])
    }
    
    @Test("Excluding a main role drops matching Summary inventory components")
    func excludingMainRoleDropsSummaryComponents() {
        let components = [
            FinalCutPro.FCPXML.RoleInventoryClipComponent(
                roleSubroleField: "Vfx Shot No ▸ Vfx Shot No-1",
                category: .connectedTitle,
                durationSeconds: 10
            ),
            FinalCutPro.FCPXML.RoleInventoryClipComponent(
                roleSubroleField: "Video",
                category: .primaryVideo,
                durationSeconds: 10
            ),
        ]
        
        let filtered = FinalCutPro.FCPXML.ReportRoleExclusion.filteringComponents(
            components,
            excludedRoleNames: ["VFX Shot No"]
        )
        
        #expect(filtered.map(\.roleSubroleField) == ["Video"])
    }
    
    @Test("Build report excludes VFX title effects when that role is excluded")
    func buildReportExcludesVFXTitleEffects() async throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r4" name="Clip" hasVideo="1" duration="10s" format="r1">
                    <media-rep kind="original-media" src="file:///tmp/clip.mov"/>
                </asset>
                <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
                <effect id="r3" name="Gaussian" uid=".../Effects.localized/Blur.localized/Gaussian.localized/Gaussian.motn"/>
            </resources>
            <library>
                <event name="Event">
                    <project name="Role Exclusion">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <asset-clip ref="r4" name="A Roll" offset="0s" duration="10s" start="0s" format="r1">
                                    <filter-video ref="r3" name="Gaussian"/>
                                    <title ref="r2" lane="1" offset="0s" name="Basic Title" start="3600s" duration="10s" role="VFX Shot No.VFX Shot No-1">
                                        <text>
                                            <text-style ref="ts1">VFX</text-style>
                                        </text>
                                        <text-style-def id="ts1">
                                            <text-style font="Helvetica" fontSize="63" fontColor="1 1 1 1" alignment="center"/>
                                        </text-style-def>
                                        <adjust-transform position="-91.3978 40.8602"/>
                                    </title>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(xml.utf8))
        
        var unfilteredOptions = FinalCutPro.FCPXML.ReportOptions.full
        unfilteredOptions.workbookCoverSheet = nil
        let unfiltered = try await fcpxml.buildReport(options: unfilteredOptions)
        let unfilteredHasVFXEffect = unfiltered.effects?.rows.contains {
            $0.roleSubrole.localizedCaseInsensitiveContains("vfx")
        } ?? false
        #expect(unfilteredHasVFXEffect)
        
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.workbookCoverSheet = nil
        options.excludedRoles = ["VFX Shot No"]
        let report = try await fcpxml.buildReport(options: options)
        
        let effectRoles = report.effects?.rows.map(\.roleSubrole) ?? []
        #expect(effectRoles.allSatisfy { !$0.localizedCaseInsensitiveContains("vfx") })
        let remainingEffectClips = report.effects?.rows.map(\.clipName) ?? []
        #expect(remainingEffectClips.contains("A Roll"))
        
        let titleRoles = report.titlesAndGenerators?.rows.map(\.roleSubrole) ?? []
        #expect(titleRoles.allSatisfy { !$0.localizedCaseInsensitiveContains("vfx") })
        
        let summaryRoles = report.summary?.roleDurations
            .map(\.roleSubrole)
            .filter { !$0.isEmpty } ?? []
        #expect(summaryRoles.allSatisfy { !$0.localizedCaseInsensitiveContains("vfx") })
    }
    
    private func effectRow(
        clipName: String,
        roleSubrole: String
    ) -> FinalCutPro.FCPXML.EffectReportRow {
        FinalCutPro.FCPXML.EffectReportRow(
            effect: "Transform",
            settings: "",
            enabled: "✓",
            isApple: "✓",
            clipName: clipName,
            roleSubrole: roleSubrole,
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00"
        )
    }
    
    private func titleRow(
        clipName: String,
        roleSubrole: String
    ) -> FinalCutPro.FCPXML.TitleReportRow {
        FinalCutPro.FCPXML.TitleReportRow(
            clipName: clipName,
            enabled: "✓",
            isApple: "✓",
            roleSubrole: roleSubrole,
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            duration: "00:00:01:00",
            font: "Helvetica",
            titleText: "Title"
        )
    }
    
    private func markerRow(
        clipName: String,
        roleSubrole: String
    ) -> FinalCutPro.FCPXML.MarkerReportRow {
        FinalCutPro.FCPXML.MarkerReportRow(
            markerName: "Marker",
            type: .standard,
            position: "00:00:00:00",
            clipName: clipName,
            roleSubrole: roleSubrole,
            sourcePosition: "00:00:00:00"
        )
    }
}

