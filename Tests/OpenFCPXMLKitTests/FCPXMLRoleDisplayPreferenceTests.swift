//
//  FCPXMLRoleDisplayPreferenceTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for role priority selection in workbook reports.
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLRoleDisplayPreferenceTests: XCTestCase {
    private typealias RoleDisplayPreference = FinalCutPro.FCPXML.RoleDisplayPreference
    
    func testPreferredRoleMarkersContextPicksDialogueOverVideo() {
        let roles = [interpolatedRole("video"), interpolatedRole("dialogue")]
        
        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .markers
        )
        
        XCTAssertEqual(preferred?.wrapped.role.lowercased(), "dialogue")
    }
    
    func testPreferredRoleVideoEffectsContextPicksVideoOverDialogue() {
        let roles = [interpolatedRole("dialogue"), interpolatedRole("video")]
        
        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .videoEffects
        )
        
        XCTAssertEqual(preferred?.wrapped.role.lowercased(), "video")
    }
    
    func testPreferredRoleAudioEffectsContextPicksDialogueOverMusic() {
        let roles = [interpolatedRole("music"), interpolatedRole("dialogue")]
        
        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )
        
        XCTAssertEqual(preferred?.wrapped.role.lowercased(), "dialogue")
    }
    
    func testPreferredRoleFallsBackToFirstRoleByTypeAndName() {
        let roles = [
            interpolatedRole("score komponist"),
            interpolatedRole("custom library role")
        ]
        
        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: roles,
            context: .audioEffects
        )
        
        XCTAssertEqual(preferred?.wrapped.role.lowercased(), "custom library role")
    }
    
    func testPreferredRoleReturnsNilForEmptyRoleList() {
        let preferred = RoleDisplayPreference.builtIn.preferredRole(
            from: [],
            context: .markers
        )
        
        XCTAssertNil(preferred)
    }
    
    func testKeywordSortRankOrdersBuiltInRolesBeforeCustom() {
        let videoRank = RoleDisplayPreference.keywordSortRank(for: "Video")
        let dialogueRank = RoleDisplayPreference.keywordSortRank(for: "Dialogue")
        let customRank = RoleDisplayPreference.keywordSortRank(for: "Custom Library Role")
        
        XCTAssertLessThan(videoRank, dialogueRank)
        XCTAssertLessThan(dialogueRank, customRank)
    }
    
    func testBuiltInContainsOnlyStandardRoleNames() {
        let builtIn = RoleDisplayPreference.builtIn
        
        XCTAssertEqual(
            builtIn.markerRolePriority,
            ["dialogue", "video", "titles", "srt", "effects", "music"]
        )
        XCTAssertFalse(builtIn.markerRolePriority.contains("vfx"))
        XCTAssertFalse(builtIn.markerRolePriority.contains("score komponist"))
    }
}
