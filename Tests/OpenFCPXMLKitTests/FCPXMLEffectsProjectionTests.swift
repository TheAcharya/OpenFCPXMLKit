//
// FCPXMLEffectsProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Video & Audio Effects report builder prefers Projection effect annotations.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLEffectsProjectionTests: XCTestCase {

    func testEffectsOnlyConsumesTimelineProjectionAndAnnotations() {
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly
        XCTAssertTrue(options.consumesTimelineProjection)
        XCTAssertTrue(options.includeEffects)
    }

    func testCompoundClipSampleEffectsReportUsesProjection() async throws {
        let fcpxml = try loadFCPXMLSample(named: "CompoundClipSample")
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.effects?.rows)
        XCTAssertFalse(rows.isEmpty, "CompoundClipSample must yield Effects via Projection")
        XCTAssertTrue(rows.contains { $0.effect == "volume" || $0.effect == "Transform" })
        XCTAssertTrue(rows.allSatisfy { !$0.timelineIn.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.timelineOut.isEmpty })
    }

    func testProjectionDetailedCollectsReportEffectAnnotations() async throws {
        let fcpxml = try loadFCPXMLSample(named: "CompoundClipSample")
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        XCTAssertTrue(
            detailed.clipAnnotations.contains { !$0.effects.isEmpty },
            "Effect hosts must emit WindowReportEffectAnnotation"
        )
    }

    func testOcclusion3FilterVideoPolicyParity() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.occlusion3.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly

        let report = try await fcpxml.buildReport(options: options)
        XCTAssertNotNil(report.effects)
    }

    func testTimelineWithSecondaryStorylineEffectsPresent() async throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStoryline")
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try XCTUnwrap(report.effects?.rows)
        XCTAssertFalse(rows.isEmpty)
    }
}
