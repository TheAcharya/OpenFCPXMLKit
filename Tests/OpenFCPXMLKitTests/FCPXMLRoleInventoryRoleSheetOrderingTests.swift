//
//  FCPXMLRoleInventoryRoleSheetOrderingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for dynamic per-role inventory sheet ordering.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory role sheet ordering")
struct FCPXMLRoleInventoryRoleSheetOrderingTests {
    private typealias Ordering = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering

    @Test("Sorted role names orders built-in roles before custom roles")
    func sortedRoleNamesOrdersBuiltInRolesBeforeCustomRoles() {
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

        #expect(sorted == [
            "Gap",
            "Titles",
            "Video",
            "Custom Video Role",
            "Dialogue ▸ Track A"
        ])
    }

    @Test("Sorted role names places parent tab before subroles")
    func sortedRoleNamesPlacesParentTabBeforeSubroles() {
        let sorted = Ordering.sortedRoleNames([
            "SRT ▸ de-DE",
            "SRT",
            "SRT ▸ En"
        ])

        #expect(sorted.first == "SRT")
        let allSubroles = sorted.dropFirst().allSatisfy { $0.hasPrefix("SRT ▸ ") }
        #expect(allSubroles)
    }

    @Test("Role sheets adds empty parent tabs for subrole sheets")
    func roleSheetsAddsEmptyParentTabsForSubroleSheets() {
        let row = sampleRow(
            roleSubrole: "Custom Video ▸ Plate A",
            category: "Connected video"
        )

        let sheets = Ordering.roleSheets(from: [row])
        let names = sheets.map(\.sheetName)

        #expect(names.contains("Custom Video"))
        #expect(names.contains("Custom Video ▸ Plate A"))
        #expect(sheets.first { $0.sheetName == "Custom Video" }?.rows.count == 0)
    }

    @Test("Role sheets omits empty parent tab for audio subrole sheets")
    func roleSheetsOmitsEmptyParentTabForAudioSubroleSheets() {
        let row = sampleRow(
            roleSubrole: "Dialogue ▸ Dialogue-1",
            category: "Primary audio"
        )

        let sheets = Ordering.roleSheets(from: [row])
        let names = sheets.map(\.sheetName)

        #expect(names.contains("Dialogue ▸ Dialogue-1"))
        let hasBareDialogue = names.contains("Dialogue")
        #expect(!hasBareDialogue)
    }

    @Test("Role sheets keeps parent tab when bare role rows exist")
    func roleSheetsKeepsParentTabWhenBareRoleRowsExist() {
        let bareVideo = sampleRow(roleSubrole: "Video", category: "Primary video")
        let customAudioSub = sampleRow(
            roleSubrole: "Atmosphere ▸ Mix L",
            category: "Connected audio"
        )

        let sheets = Ordering.roleSheets(from: [bareVideo, customAudioSub])
        let names = sheets.map(\.sheetName)

        #expect(names.contains("Video"))
        #expect(names.contains("Atmosphere ▸ Mix L"))
        let hasBareAtmosphere = names.contains("Atmosphere")
        #expect(!hasBareAtmosphere)
    }

    @Test("Role names parses combined role field")
    func roleNamesParsesCombinedRoleField() {
        let names = Ordering.roleNames(in: "Video, Dialogue ▸ Track A, Dialogue ▸ Track B")

        #expect(names == [
            "Video",
            "Dialogue ▸ Track A",
            "Dialogue ▸ Track B"
        ])
    }

    @Test("Sheet tab name truncates long names")
    func sheetTabNameTruncatesLongNames() {
        let longName = String(repeating: "A", count: 40)
        #expect(Ordering.sheetTabName(for: longName).count == 31)
    }

    @Test("Role sheets fans out rows to shared subrole sheets for any main role")
    func roleSheetsFansOutRowsToSharedSubroleSheetsForAnyMainRole() {
        let sharedDialogueRow = sampleRow(
            roleSubrole: "Video, Primary Dialog ▸ Boom 1, Mix L",
            category: "Connected video",
            clipName: "Scene A"
        )
        let ambientRow = sampleRow(
            roleSubrole: "Ambient Beds ▸ Boom 1, Room Tone",
            category: "Connected audio",
            clipName: "Atmosphere Clip"
        )

        let sheets = Ordering.roleSheets(from: [sharedDialogueRow, ambientRow])
        let boomSheets = sheets.filter { $0.sheetName.hasSuffix("▸ Boom 1") }
        let boomSheetNames = Set(boomSheets.map(\.sheetName))

        #expect(boomSheetNames == ["Primary Dialog ▸ Boom 1", "Ambient Beds ▸ Boom 1"])

        let dialogueBoomSheet = boomSheets.first { $0.sheetName == "Primary Dialog ▸ Boom 1" }
        #expect(dialogueBoomSheet?.rows.count == 2)
        let hasSceneA = dialogueBoomSheet?.rows.contains { $0.clipName == "Scene A" } ?? false
        #expect(hasSceneA)
        let hasAtmosphereClip = dialogueBoomSheet?.rows.contains { $0.clipName == "Atmosphere Clip" } ?? false
        #expect(hasAtmosphereClip)
    }

    @Test("Sheet role targets does not fan out main-only roles")
    func sheetRoleTargetsDoesNotFanOutMainOnlyRoles() {
        let row = sampleRow(
            roleSubrole: "Video, Primary Dialog ▸ Boom 1",
            category: "Connected video"
        )
        let index = Ordering.subroleRoleIndex(from: [row])
        let targets = Ordering.sheetRoleTargets(for: row, subroleIndex: index)

        #expect(targets == ["Video", "Primary Dialog ▸ Boom 1"])
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

