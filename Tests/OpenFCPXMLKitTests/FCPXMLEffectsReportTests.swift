//
//  FCPXMLEffectsReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Video & Audio Effects report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLEffectsReportTests: XCTestCase, @unchecked Sendable {
    
    private func buildEffectsReport(
        from fcpxml: FinalCutPro.FCPXML
    ) async throws -> FinalCutPro.FCPXML.Report {
        try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeEffects = true
            }
        )
    }
    
    func testBuildEffectsReportFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildEffectsReport(from: fcpxml)
        
        XCTAssertNotNil(report.effects)
        
        let rows = report.effects?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(FinalCutPro.FCPXML.EffectReportRow.columnHeaders.count, 8)
    }
    
    func testEffectsReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildEffectsReport(from: fcpxml)
        
        let rows = report.effects?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows.prefix(20) {
            XCTAssertFalse(row.clipName.isEmpty)
            XCTAssertFalse(row.effect.isEmpty)
            FCPXMLReportingReportTestSupport.assertCheckmarkOrCross(row.enabled)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineIn)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.timelineOut)
        }
    }
    
    func testEffectsReportSortedByTimelinePosition() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await buildEffectsReport(from: fcpxml)
        
        let rows = report.effects?.rows ?? []
        let sorted = rows.sorted {
            if $0.timelineIn != $1.timelineIn {
                return $0.timelineIn.localizedStandardCompare($1.timelineIn) == .orderedAscending
            }
            if $0.timelineOut != $1.timelineOut {
                return $0.timelineOut.localizedStandardCompare($1.timelineOut) == .orderedDescending
            }
            let clipCompare = $0.clipName.localizedStandardCompare($1.clipName)
            if clipCompare != .orderedSame {
                return clipCompare == .orderedAscending
            }
            let effectCompare = $0.effect.localizedStandardCompare($1.effect)
            if effectCompare != .orderedSame {
                return effectCompare == .orderedAscending
            }
            return $0.settings.localizedStandardCompare($1.settings) == .orderedAscending
        }
        XCTAssertEqual(rows, sorted)
    }
}
