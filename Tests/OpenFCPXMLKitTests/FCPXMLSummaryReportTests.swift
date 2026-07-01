//
//  FCPXMLSummaryReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Summary report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLSummaryReportTests: XCTestCase, @unchecked Sendable {
    
    private func summaryOptions() throws -> FinalCutPro.FCPXML.ReportOptions {
        var options = try FCPXMLReportingReportFixture.reportOptions {
            $0.includeSummary = true
        }
        options.mediaBaseURL = try FCPXMLReportingReportFixture.mediaBaseURL()
        return options
    }
    
    func testBuildSummaryReportProjectHeaderFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: try summaryOptions())
        
        XCTAssertNotNil(report.summary)
        
        let projectSummary = report.summary?.projectSummary
        XCTAssertEqual(projectSummary?.title, FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml))
        FCPXMLReportingReportTestSupport.assertValidTimecode(projectSummary?.duration ?? "")
        XCTAssertFalse(projectSummary?.resolution.isEmpty ?? true)
        XCTAssertFalse(projectSummary?.frameRate.isEmpty ?? true)
        XCTAssertFalse(projectSummary?.audioSampleRate.isEmpty ?? true)
    }
    
    func testSummaryRoleDurationRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: try summaryOptions())
        
        let rows = report.summary?.roleDurations ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows {
            XCTAssertFalse(row.roleSubrole.isEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.estimatedTotal)
            XCTAssertGreaterThanOrEqual(row.percentOfTotal, 0)
        }
    }
    
    func testSummaryMissingMediaPathsFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: try summaryOptions())
        
        let paths = report.summary?.missingMediaPaths ?? []
        XCTAssertFalse(paths.isEmpty)
        XCTAssertTrue(paths.allSatisfy { $0.hasPrefix("/") })
    }
    
    func testSummaryOnlyPresetEnablesSummarySectionOnly() {
        let options = FinalCutPro.FCPXML.ReportOptions.summaryOnly
        
        XCTAssertFalse(options.includeMarkers)
        XCTAssertFalse(options.includeKeywords)
        XCTAssertFalse(options.includeTitlesAndGenerators)
        XCTAssertFalse(options.includeTransitions)
        XCTAssertFalse(options.includeEffects)
        XCTAssertTrue(options.includeSummary)
        XCTAssertFalse(options.includeRoleInventory)
    }
}
