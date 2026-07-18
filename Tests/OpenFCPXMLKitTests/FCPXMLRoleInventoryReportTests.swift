//
//  FCPXMLRoleInventoryReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Role inventory report integration tests (optional local FCPXML fixture).
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory report")
struct FCPXMLRoleInventoryReportTests {

    private func roleInventoryOptions(
        for fcpxml: FinalCutPro.FCPXML
    ) -> FinalCutPro.FCPXML.ReportOptions {
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeRoleInventory = true
        return options
    }

    @Test("Build role inventory report sheet layout from fixture")
    func buildRoleInventoryReportSheetLayoutFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: roleInventoryOptions(for: fcpxml))

        let roleInventory = try #require(report.roleInventory)

        let selectedRolesEmpty = roleInventory.selectedRoles.isEmpty
        let roleSheetsEmpty = roleInventory.roleSheets.isEmpty
        #expect(!selectedRolesEmpty)
        #expect(!roleSheetsEmpty)

        let sheetNames = roleInventory.roleSheets.map(\.sheetName)
        #expect(Set(sheetNames).count == sheetNames.count)

        for sheet in roleInventory.roleSheets where sheet.sheetName.contains(" ▸ ") {
            let parentName = String(sheet.sheetName.split(separator: "▸", maxSplits: 1)[0])
                .trimmingCharacters(in: .whitespaces)
            #expect(
                sheetNames.contains(parentName),
                "Expected parent sheet for \(sheet.sheetName)"
            )
        }
    }

    @Test("Build role inventory selected roles row shape from fixture")
    func buildRoleInventorySelectedRolesRowShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: roleInventoryOptions(for: fcpxml))

        let rows = report.roleInventory?.selectedRoles ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows.prefix(10) {
            let roleEmpty = row.roleSubrole.isEmpty
            let clipNameEmpty = row.clipName.isEmpty
            let categoryEmpty = row.category.isEmpty
            #expect(!roleEmpty)
            #expect(!clipNameEmpty)
            #expect(!categoryEmpty)
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.enabled)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }

    @Test("Build role inventory per-role sheets contain rows from fixture")
    func buildRoleInventoryPerRoleSheetsContainRowsFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: roleInventoryOptions(for: fcpxml))

        let sheetsWithRows = report.roleInventory?.roleSheets.filter { !$0.rows.isEmpty } ?? []
        let sheetsEmpty = sheetsWithRows.isEmpty
        #expect(!sheetsEmpty)

        for sheet in sheetsWithRows.prefix(5) {
            let sheetNameEmpty = sheet.sheetName.isEmpty
            let rowsEmpty = sheet.rows.isEmpty
            #expect(!sheetNameEmpty)
            #expect(!rowsEmpty)
        }
    }

    @Test("Role inventory only preset enables role inventory section only")
    func roleInventoryOnlyPresetEnablesRoleInventorySectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly

        #expect(options.includeRoleInventory)
        #expect(!options.includeMarkers)
        #expect(!options.includeKeywords)
        #expect(!options.includeTitlesAndGenerators)
        #expect(!options.includeTransitions)
        #expect(!options.includeEffects)
        #expect(!options.includeSummary)
        #expect(!options.includeMediaSummary)
    }

    @Test("Exclude disabled clips option defaults to including disabled clips")
    func excludeDisabledClipsOptionDefaultsToIncludingDisabledClips() {
        let options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly

        #expect(!options.excludeDisabledClips)
    }
}

