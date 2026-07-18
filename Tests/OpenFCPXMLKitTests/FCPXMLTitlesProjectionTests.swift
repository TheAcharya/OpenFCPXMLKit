//
// FCPXMLTitlesProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Titles & Generators report builder prefers Projection title annotations.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Titles projection")
struct FCPXMLTitlesProjectionTests {

    @Test("TitlesRoles report uses projection title annotations")
    func titlesRolesReportUsesProjectionTitleAnnotations() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.titlesRoles.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.titlesAndGenerators?.rows)
        #expect(rows.count == 2, "TitlesRoles has spine + anchored titles")
        let allBasicTitle = rows.allSatisfy { $0.clipName == "Basic Title" }
        let allTitlesRole = rows.allSatisfy { $0.roleSubrole == "Titles" }
        let allTitleText = rows.allSatisfy { $0.titleText == "Title" }
        let hasHelvetica = rows.contains { $0.font.contains("Helvetica") }
        let allHaveIn = rows.allSatisfy { !$0.timelineIn.isEmpty }
        let allHaveOut = rows.allSatisfy { !$0.timelineOut.isEmpty }
        let allHaveDuration = rows.allSatisfy { !$0.duration.isEmpty }
        #expect(allBasicTitle)
        #expect(allTitlesRole)
        #expect(allTitleText)
        #expect(hasHelvetica)
        #expect(allHaveIn)
        #expect(allHaveOut)
        #expect(allHaveDuration)
    }

    @Test("BasicMarkers titles report uses projection")
    func basicMarkersTitlesReportUsesProjection() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        let options = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.titlesAndGenerators?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows, "BasicMarkers titles must appear via Projection")
        let allTitlesRole = rows.allSatisfy { $0.roleSubrole == "Titles" }
        #expect(allTitlesRole)
        let hasTitleText = rows.contains { !$0.titleText.isEmpty }
        #expect(hasTitleText)
    }

    @Test("Projection detailed collects title annotations without media windows")
    func projectionDetailedCollectsTitleAnnotationsWithoutMediaWindows() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        let source = try #require(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        let hasTitle = detailed.clipAnnotations.contains { $0.title != nil }
        #expect(hasTitle, "Title hosts must emit WindowTitleAnnotation")
        let hasTitleHost = detailed.clipAnnotations.contains {
            $0.hostElementType == "title" && $0.title != nil
        }
        #expect(hasTitleHost)
    }

    @Test("Titles-only consumes timeline projection")
    func titlesOnlyConsumesTimelineProjection() {
        let options = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        #expect(options.consumesTimelineProjection)
        #expect(options.includeTitlesAndGenerators)
    }

    @Test("Disabled titles respect excludeDisabledClips")
    func disabledTitlesRespectExcludeDisabledClips() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.disabledClips.rawValue)

        var including = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        including.excludeDisabledClips = false
        let included = try await fcpxml.buildReport(options: including)
        let includedRows = try #require(included.titlesAndGenerators?.rows)

        var excluding = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        excluding.excludeDisabledClips = true
        let excluded = try await fcpxml.buildReport(options: excluding)
        let excludedRows = try #require(excluded.titlesAndGenerators?.rows)

        #expect(
            includedRows.count > excludedRows.count,
            "Excluding disabled clips should drop disabled titles"
        )
        let hasDisabledMark = includedRows.contains { $0.enabled == "✗" }
        let allEnabled = excludedRows.allSatisfy { $0.enabled == "✓" }
        #expect(hasDisabledMark)
        #expect(allEnabled)
    }
}

