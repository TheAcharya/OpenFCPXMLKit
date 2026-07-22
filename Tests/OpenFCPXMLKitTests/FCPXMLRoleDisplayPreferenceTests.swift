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
        let roles = [assignedAudioRole("music"), assignedAudioRole("dialogue")]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )

        #expect(preferred?.wrapped.role.lowercased() == "dialogue")
    }

    @Test("Falls back to first role by type and name")
    func preferredRoleFallsBackToFirstRoleByTypeAndName() {
        let roles = [
            assignedAudioRole("zebra fx"),
            assignedAudioRole("alpha room")
        ]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )

        #expect(preferred?.wrapped.role.lowercased() == "alpha room")
    }

    @Test("Video effects ignore audio-only roles")
    func preferredRoleVideoEffectsIgnoresAudioOnlyRoles() {
        let roles = [assignedAudioRole("dialogue"), assignedAudioRole("effects")]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .videoEffects
        )

        #expect(preferred == nil)
    }

    @Test("Audio effects ignore video-only roles")
    func preferredRoleAudioEffectsIgnoresVideoOnlyRoles() {
        let roles = [interpolatedRole("video"), interpolatedRole("titles")]

        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )

        #expect(preferred == nil)
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
        #expect(builtIn.videoEffectRolePriority == ["video", "titles", "srt"])
        #expect(builtIn.audioEffectRolePriority == ["dialogue", "effects", "music"])
        #expect(!builtIn.markerRolePriority.contains("vfx"))
        #expect(!builtIn.markerRolePriority.contains("score composer"))
        #expect(!builtIn.videoEffectRolePriority.contains("dialogue"))
        #expect(!builtIn.videoEffectRolePriority.contains("vfx"))
        #expect(!builtIn.audioEffectRolePriority.contains("video"))
        #expect(!builtIn.audioEffectRolePriority.contains("atmosphere"))
        #expect(!builtIn.audioEffectRolePriority.contains("score composer"))
        #expect(!builtIn.audioEffectRolePriority.contains("sound mix"))
    }
}

private func assignedAudioRole(_ rawValue: String) -> FinalCutPro.FCPXML.AnyInterpolatedRole {
    guard let audio = FinalCutPro.FCPXML.AudioRole(rawValue: rawValue) else {
        preconditionFailure("Could not create audio role from raw value: \(rawValue)")
    }
    return .assigned(.audio(audio))
}

