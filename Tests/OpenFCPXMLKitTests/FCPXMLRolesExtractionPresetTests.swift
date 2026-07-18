//
//  FCPXMLRolesExtractionPresetTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for role extraction preset filtering and sorting.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Roles extraction preset")
struct FCPXMLRolesExtractionPresetTests {
    @Test("Roles extraction preset returns empty when no types specified")
    func rolesExtractionPresetReturnsEmptyWhenNoTypesSpecified() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: []))

        #expect(roles.isEmpty)
    }

    @Test("Roles extraction preset filters by audio role type")
    func rolesExtractionPresetFiltersByAudioRoleType() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.audio]))

        #expect(!roles.isEmpty)
        #expect(roles.allSatisfy { $0.roleType == .audio })
        let hasDialogue = roles.contains { $0.role.lowercased() == "dialogue" }
        #expect(hasDialogue)
    }

    @Test("Roles extraction preset filters by video role type")
    func rolesExtractionPresetFiltersByVideoRoleType() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.video]))

        #expect(!roles.isEmpty)
        #expect(roles.allSatisfy { $0.roleType == .video })
        let hasVFX = roles.contains { $0.role.lowercased() == "vfx" }
        #expect(hasVFX)
    }

    @Test("Roles extraction preset includes caption roles")
    func rolesExtractionPresetIncludesCaptionRoles() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.caption]))

        #expect(!roles.isEmpty)
        #expect(roles.allSatisfy { $0.roleType == .caption })
        let hasSRT = roles.contains { $0.role.lowercased() == "srt" }
        #expect(hasSRT)
    }

    @Test("Roles extraction preset deduplicates and sorts by type then name")
    func rolesExtractionPresetDeduplicatesAndSortsByTypeThenName() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles())

        #expect(!roles.isEmpty)

        let uniqueRoles = Set(roles.map(\.rawValue))
        #expect(uniqueRoles.count == roles.count)

        let sorted = roles.sortedByRoleTypeThenByName()
        #expect(roles == sorted)
    }

    @Test("Roles extraction preset from Keywords sample finds dialogue")
    func rolesExtractionPresetFromKeywordsSampleFindsDialogue() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.audio]))

        let hasDialogue = roles.contains { $0.role.lowercased() == "dialogue" }
        #expect(hasDialogue)
    }
}

