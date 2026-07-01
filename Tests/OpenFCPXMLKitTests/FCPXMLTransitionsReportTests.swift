//
//  FCPXMLTransitionsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Transitions report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTransitionsReportTests: XCTestCase, @unchecked Sendable {
    
    func testBuildTransitionsReportFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        
        let report = try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeTransitions = true
            }
        )
        
        XCTAssertEqual(report.projectName, projectName)
        XCTAssertNotNil(report.transitions)
        XCTAssertEqual(
            FinalCutPro.FCPXML.TransitionReportRow.columnHeaders.count,
            6
        )
    }
    
    func testTransitionReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        
        let report = try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeTransitions = true
            }
        )
        
        let rows = report.transitions?.rows ?? []
        
        for row in rows {
            XCTAssertFalse(row.transition.isEmpty)
            XCTAssertFalse(row.category.isEmpty)
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.isApple)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.duration)
        }
    }
    
    func testTransitionsReportSortedByTimelineIn() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        
        var options = try FCPXMLReportingReportFixture.reportOptions {
            $0.includeTransitions = true
        }
        options = FinalCutPro.FCPXML.ReportOptions.transitionsOnly.merging(
            projectName: options.projectName
        )
        
        let report = try await fcpxml.buildReport(options: options)
        
        let timelineIns = report.transitions?.rows.map(\.timelineIn) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(timelineIns)
    }
}

private extension FinalCutPro.FCPXML.ReportOptions {
    func merging(projectName: String?) -> Self {
        var copy = self
        copy.projectName = projectName
        return copy
    }
}
