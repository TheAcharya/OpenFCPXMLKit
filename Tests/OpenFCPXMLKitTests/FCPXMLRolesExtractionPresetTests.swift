//
//  FCPXMLRolesExtractionPresetTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for role extraction preset filtering and sorting.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLRolesExtractionPresetTests: XCTestCase {
    func testRolesExtractionPresetReturnsEmptyWhenNoTypesSpecified() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: []))
        
        XCTAssertTrue(roles.isEmpty)
    }
    
    func testRolesExtractionPresetFiltersByAudioRoleType() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.audio]))
        
        XCTAssertFalse(roles.isEmpty)
        XCTAssertTrue(roles.allSatisfy { $0.roleType == .audio })
        XCTAssertTrue(roles.contains { $0.role.lowercased() == "dialogue" })
    }
    
    func testRolesExtractionPresetFiltersByVideoRoleType() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.video]))
        
        XCTAssertFalse(roles.isEmpty)
        XCTAssertTrue(roles.allSatisfy { $0.roleType == .video })
        XCTAssertTrue(roles.contains { $0.role.lowercased() == "vfx" })
    }
    
    func testRolesExtractionPresetIncludesCaptionRoles() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.caption]))
        
        XCTAssertFalse(roles.isEmpty)
        XCTAssertTrue(roles.allSatisfy { $0.roleType == .caption })
        XCTAssertTrue(roles.contains { $0.role.lowercased() == "srt" })
    }
    
    func testRolesExtractionPresetDeduplicatesAndSortsByTypeThenName() async throws {
        let timeline = try timelineElement(fromSampleNamed: "SyncClipRoles")
        let roles = await timeline.fcpExtract(preset: .roles())
        
        XCTAssertFalse(roles.isEmpty)
        
        let uniqueRoles = Set(roles.map(\.rawValue))
        XCTAssertEqual(uniqueRoles.count, roles.count)
        
        let sorted = roles.sortedByRoleTypeThenByName()
        XCTAssertEqual(roles, sorted)
    }
    
    func testRolesExtractionPresetFromKeywordsSampleFindsDialogue() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Keywords")
        let roles = await timeline.fcpExtract(preset: .roles(roleTypes: [.audio]))
        
        XCTAssertTrue(roles.contains { $0.role.lowercased() == "dialogue" })
    }
}
