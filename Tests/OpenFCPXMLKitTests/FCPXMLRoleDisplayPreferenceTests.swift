//
//  FCPXMLRoleDisplayPreferenceTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for role priority selection in workbook reports.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Role display preference")
struct FCPXMLRoleDisplayPreferenceTests {
    private typealias RoleDisplayPreference = FinalCutPro.FCPXML.RoleDisplayPreference

    @Test("Markers context prefers dialogue over video")
    func preferredRoleMarkersContextPicksDialogueOverVideo() {
        let roles = [interpolatedRole("video"), interpolatedRole("dialogue")]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .markers
        )

        #expect(preferred?.wrapped.role.lowercased() == "dialogue")
    }

    @Test("Video effects context prefers video over dialogue")
    func preferredRoleVideoEffectsContextPicksVideoOverDialogue() {
        let roles = [interpolatedRole("dialogue"), interpolatedRole("video")]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .videoEffects
        )

        #expect(preferred?.wrapped.role.lowercased() == "video")
    }

    @Test("Audio effects context prefers dialogue over music")
    func preferredRoleAudioEffectsContextPicksDialogueOverMusic() {
        let roles = [interpolatedRole("music"), interpolatedRole("dialogue")]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )

        #expect(preferred?.wrapped.role.lowercased() == "dialogue")
    }

    @Test("Falls back to first role by type and name")
    func preferredRoleFallsBackToFirstRoleByTypeAndName() {
        let roles = [
            interpolatedRole("score composer"),
            interpolatedRole("custom library role")
        ]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )

        #expect(preferred?.wrapped.role.lowercased() == "custom library role")
    }

    @Test("Returns nil for empty role list")
    func preferredRoleReturnsNilForEmptyRoleList() {
        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: [],
            context: .markers
        )

        #expect(preferred == nil)
    }

    @Test("Keyword sort rank orders built-in roles before custom")
    func keywordSortRankOrdersBuiltInRolesBeforeCustom() {
        let videoRank = RoleDisplayPreference.keywordSortRank(for: "Video")
        let dialogueRank = RoleDisplayPreference.keywordSortRank(for: "Dialogue")
        let customRank = RoleDisplayPreference.keywordSortRank(for: "Custom Library Role")

        #expect(videoRank < dialogueRank)
        #expect(dialogueRank < customRank)
    }

    @Test("Built-in preference contains only standard role names")
    func builtInContainsOnlyStandardRoleNames() {
        let builtIn = RoleDisplayPreference.builtIn

        #expect(
            builtIn.markerRolePriority
                == ["dialogue", "video", "titles", "srt", "effects", "music"]
        )
        #expect(!builtIn.markerRolePriority.contains("vfx"))
        #expect(!builtIn.markerRolePriority.contains("score composer"))
    }
}
