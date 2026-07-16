//
//  FCPXMLReportExcludeDisabledClipsTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for omitting disabled clips from report extraction.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportExcludeDisabledClipsTests: XCTestCase, @unchecked Sendable {
    
    func testExcludeDisabledClipsOmitsDisabledTitlesFromReport() async throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")
        
        var includingDisabled = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        includingDisabled.excludeDisabledClips = false
        
        var excludingDisabled = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        excludingDisabled.excludeDisabledClips = true
        
        let reportWithDisabled = try await fcpxml.buildReport(options: includingDisabled)
        let reportWithoutDisabled = try await fcpxml.buildReport(options: excludingDisabled)
        
        let withDisabledCount = reportWithDisabled.titlesAndGenerators?.rows.count ?? 0
        let withoutDisabledCount = reportWithoutDisabled.titlesAndGenerators?.rows.count ?? 0
        
        XCTAssertGreaterThan(withDisabledCount, withoutDisabledCount)
        XCTAssertFalse(
            reportWithoutDisabled.titlesAndGenerators?.rows.contains { $0.enabled == "✗" } ?? false
        )
    }
    
    func testExcludeDisabledClipsOmitsDisabledClipsFromRoleInventory() async throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")
        
        var includingDisabled = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        includingDisabled.excludeDisabledClips = false
        
        var excludingDisabled = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        excludingDisabled.excludeDisabledClips = true
        
        let reportWithDisabled = try await fcpxml.buildReport(options: includingDisabled)
        let reportWithoutDisabled = try await fcpxml.buildReport(options: excludingDisabled)
        
        let withDisabledCount = reportWithDisabled.roleInventory?.selectedRoles.count ?? 0
        let withoutDisabledCount = reportWithoutDisabled.roleInventory?.selectedRoles.count ?? 0
        
        XCTAssertGreaterThan(withDisabledCount, withoutDisabledCount)
        XCTAssertFalse(
            reportWithoutDisabled.roleInventory?.selectedRoles.contains { $0.enabled == "✗" } ?? false
        )
    }

    func testExcludeDisabledClipsOmitsDisabledMarkersFromReport() async throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")

        var includingDisabled = FinalCutPro.FCPXML.ReportOptions()
        includingDisabled.includeMarkers = true
        includingDisabled.includeRoleInventory = false
        includingDisabled.excludeDisabledClips = false

        var excludingDisabled = includingDisabled
        excludingDisabled.excludeDisabledClips = true

        let reportWithDisabled = try await fcpxml.buildReport(options: includingDisabled)
        let reportWithoutDisabled = try await fcpxml.buildReport(options: excludingDisabled)

        let withCount = reportWithDisabled.markers?.rows.count ?? 0
        let withoutCount = reportWithoutDisabled.markers?.rows.count ?? 0
        XCTAssertGreaterThanOrEqual(withCount, withoutCount)
    }
}

