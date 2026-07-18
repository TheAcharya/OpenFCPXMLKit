//
// FCPXMLEffectsProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Video & Audio Effects report builder prefers Projection effect annotations.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Effects projection")
struct FCPXMLEffectsProjectionTests {

    @Test("Effects-only consumes timeline projection and annotations")
    func effectsOnlyConsumesTimelineProjectionAndAnnotations() {
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly
        #expect(options.consumesTimelineProjection)
        #expect(options.includeEffects)
    }

    @Test("CompoundClipSample effects report uses projection")
    func compoundClipSampleEffectsReportUsesProjection() async throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClipSample")
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.effects?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows, "CompoundClipSample must yield Effects via Projection")
        let hasVolumeOrTransform = rows.contains { $0.effect == "volume" || $0.effect == "Transform" }
        #expect(hasVolumeOrTransform)
        let allHaveIn = rows.allSatisfy { !$0.timelineIn.isEmpty }
        let allHaveOut = rows.allSatisfy { !$0.timelineOut.isEmpty }
        #expect(allHaveIn)
        #expect(allHaveOut)
    }

    @Test("Projection detailed collects report effect annotations")
    func projectionDetailedCollectsReportEffectAnnotations() async throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClipSample")
        let source = try #require(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        let hasEffects = detailed.clipAnnotations.contains { !$0.effects.isEmpty }
        #expect(hasEffects, "Effect hosts must emit WindowReportEffectAnnotation")
    }

    @Test("Occlusion3 filter-video policy parity")
    func occlusion3FilterVideoPolicyParity() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.occlusion3.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly

        let report = try await fcpxml.buildReport(options: options)
        #expect(report.effects != nil)
    }

    @Test("TimelineWithSecondaryStoryline effects present")
    func timelineWithSecondaryStorylineEffectsPresent() async throws {
        let fcpxml = try requireFCPXMLSample(named: "TimelineWithSecondaryStoryline")
        let options = FinalCutPro.FCPXML.ReportOptions.effectsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.effects?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows)
    }
}
