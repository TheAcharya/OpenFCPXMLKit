//
//  FCPXMLRoleInventoryRoleSheetOrderingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for dynamic per-role inventory sheet ordering.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLRoleInventoryRoleSheetOrderingTests: XCTestCase {
    private typealias Ordering = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering
    
    func testSortedRoleNamesOrdersBuiltInRolesBeforeCustomRoles() {
        let customVideoRow = sampleRow(
            roleSubrole: "Custom Video Role",
            category: "Connected video"
        )
        let sorted = Ordering.sortedRoleNames(
            [
                "Dialogue ▸ Track A",
                "Custom Video Role",
                "Gap",
                "Video",
                "Titles"
            ],
            rowsByName: [
                "Custom Video Role": [customVideoRow],
                "Dialogue ▸ Track A": [
                    sampleRow(roleSubrole: "Dialogue ▸ Track A", category: "Connected audio")
                ]
            ]
        )
        
        XCTAssertEqual(sorted, [
            "Gap",
            "Titles",
            "Video",
            "Custom Video Role",
            "Dialogue ▸ Track A"
        ])
    }
    
    func testSortedRoleNamesPlacesParentTabBeforeSubroles() {
        let sorted = Ordering.sortedRoleNames([
            "SRT ▸ de-DE",
            "SRT",
            "SRT ▸ En"
        ])
        
        XCTAssertEqual(sorted.first, "SRT")
        XCTAssertTrue(sorted.dropFirst().allSatisfy { $0.hasPrefix("SRT ▸ ") })
    }
    
    func testRoleSheetsAddsEmptyParentTabsForSubroleSheets() {
        let row = sampleRow(
            roleSubrole: "Custom Video ▸ Plate A",
            category: "Connected video"
        )
        
        let sheets = Ordering.roleSheets(from: [row])
        let names = sheets.map(\.sheetName)
        
        XCTAssertTrue(names.contains("Custom Video"))
        XCTAssertTrue(names.contains("Custom Video ▸ Plate A"))
        XCTAssertEqual(sheets.first { $0.sheetName == "Custom Video" }?.rows.count, 0)
    }
    
    func testRoleSheetsOmitsEmptyParentTabForAudioSubroleSheets() {
        let row = sampleRow(
            roleSubrole: "Dialogue ▸ Dialogue-1",
            category: "Primary audio"
        )
        
        let sheets = Ordering.roleSheets(from: [row])
        let names = sheets.map(\.sheetName)
        
        XCTAssertTrue(names.contains("Dialogue ▸ Dialogue-1"))
        XCTAssertFalse(names.contains("Dialogue"))
    }
    
    func testRoleSheetsKeepsParentTabWhenBareRoleRowsExist() {
        let bareVideo = sampleRow(roleSubrole: "Video", category: "Primary video")
        let customAudioSub = sampleRow(
            roleSubrole: "Atmos ▸ Mix L",
            category: "Connected audio"
        )
        
        let sheets = Ordering.roleSheets(from: [bareVideo, customAudioSub])
        let names = sheets.map(\.sheetName)
        
        XCTAssertTrue(names.contains("Video"))
        XCTAssertTrue(names.contains("Atmos ▸ Mix L"))
        XCTAssertFalse(names.contains("Atmos"))
    }
    
    func testRoleNamesParsesCombinedRoleField() {
        let names = Ordering.roleNames(in: "Video, Dialogue ▸ Track A, Dialogue ▸ Track B")
        
        XCTAssertEqual(names, [
            "Video",
            "Dialogue ▸ Track A",
            "Dialogue ▸ Track B"
        ])
    }
    
    func testSheetTabNameTruncatesLongNames() {
        let longName = String(repeating: "A", count: 40)
        XCTAssertEqual(Ordering.sheetTabName(for: longName).count, 31)
    }
    
    func testRoleSheetsFansOutRowsToSharedSubroleSheetsForAnyMainRole() {
        let sharedDialogueRow = sampleRow(
            roleSubrole: "Video, Primary Dialog ▸ Boom 1, Mix L",
            category: "Connected video",
            clipName: "Scene A"
        )
        let ambientRow = sampleRow(
            roleSubrole: "Ambient Beds ▸ Boom 1, Room Tone",
            category: "Connected audio",
            clipName: "Atmo Clip"
        )
        
        let sheets = Ordering.roleSheets(from: [sharedDialogueRow, ambientRow])
        let boomSheets = sheets.filter { $0.sheetName.hasSuffix("▸ Boom 1") }
        let boomSheetNames = Set(boomSheets.map(\.sheetName))
        
        XCTAssertEqual(boomSheetNames, ["Primary Dialog ▸ Boom 1", "Ambient Beds ▸ Boom 1"])
        
        let dialogueBoomSheet = boomSheets.first { $0.sheetName == "Primary Dialog ▸ Boom 1" }
        XCTAssertEqual(dialogueBoomSheet?.rows.count, 2)
        XCTAssertTrue(dialogueBoomSheet?.rows.contains { $0.clipName == "Scene A" } ?? false)
        XCTAssertTrue(dialogueBoomSheet?.rows.contains { $0.clipName == "Atmo Clip" } ?? false)
    }
    
    func testSheetRoleTargetsDoesNotFanOutMainOnlyRoles() {
        let row = sampleRow(
            roleSubrole: "Video, Primary Dialog ▸ Boom 1",
            category: "Connected video"
        )
        let index = Ordering.subroleRoleIndex(from: [row])
        let targets = Ordering.sheetRoleTargets(for: row, subroleIndex: index)
        
        XCTAssertEqual(targets, ["Video", "Primary Dialog ▸ Boom 1"])
    }
    
    private func sampleRow(
        roleSubrole: String,
        category: String,
        clipName: String = "Clip"
    ) -> FinalCutPro.FCPXML.RoleClipReportRow {
        FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: roleSubrole,
            clipName: clipName,
            category: category,
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            clipDuration: "00:00:01:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: ""
        )
    }
}
