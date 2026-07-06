//
//  FCPXMLRoleInventoryReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Role inventory report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLRoleInventoryReportTests: XCTestCase, @unchecked Sendable {
    
    private func roleInventoryOptions() throws -> FinalCutPro.FCPXML.ReportOptions {
        try FCPXMLReportingReportFixture.reportOptions {
            $0.includeRoleInventory = true
        }
    }
    
    func testBuildRoleInventoryReportSheetLayoutFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: roleInventoryOptions())
        
        guard let roleInventory = report.roleInventory else {
            XCTFail("Expected role inventory section")
            return
        }
        
        XCTAssertFalse(roleInventory.selectedRoles.isEmpty)
        XCTAssertFalse(roleInventory.roleSheets.isEmpty)
        
        let sheetNames = roleInventory.roleSheets.map(\.sheetName)
        XCTAssertEqual(Set(sheetNames).count, sheetNames.count)
        
        for sheet in roleInventory.roleSheets where sheet.sheetName.contains(" ▸ ") {
            let parentName = String(sheet.sheetName.split(separator: "▸", maxSplits: 1)[0])
                .trimmingCharacters(in: .whitespaces)
            XCTAssertTrue(
                sheetNames.contains(parentName),
                "Expected parent sheet for \(sheet.sheetName)"
            )
        }
    }
    
    func testBuildRoleInventorySelectedRolesRowShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: roleInventoryOptions())
        
        let rows = report.roleInventory?.selectedRoles ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows.prefix(10) {
            XCTAssertFalse(row.roleSubrole.isEmpty)
            XCTAssertFalse(row.clipName.isEmpty)
            XCTAssertFalse(row.category.isEmpty)
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.enabled)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }
    
    func testBuildRoleInventoryPerRoleSheetsContainRowsFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: roleInventoryOptions())
        
        let sheetsWithRows = report.roleInventory?.roleSheets.filter { !$0.rows.isEmpty } ?? []
        XCTAssertFalse(sheetsWithRows.isEmpty)
        
        for sheet in sheetsWithRows.prefix(5) {
            XCTAssertFalse(sheet.sheetName.isEmpty)
            XCTAssertFalse(sheet.rows.isEmpty)
        }
    }
    
    func testRoleInventoryOnlyPresetEnablesRoleInventorySectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        
        XCTAssertTrue(options.includeRoleInventory)
        XCTAssertFalse(options.includeMarkers)
        XCTAssertFalse(options.includeKeywords)
        XCTAssertFalse(options.includeTitlesAndGenerators)
        XCTAssertFalse(options.includeTransitions)
        XCTAssertFalse(options.includeEffects)
        XCTAssertFalse(options.includeSummary)
        XCTAssertFalse(options.includeMediaSummary)
    }
    
    func testExcludeDisabledClipsOptionDefaultsToIncludingDisabledClips() {
        let options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        
        XCTAssertFalse(options.excludeDisabledClips)
    }
}
