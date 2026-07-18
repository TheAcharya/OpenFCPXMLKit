//
// FCPXMLMarkersKeywordsProjectionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Markers + Keywords report builders prefer Projection clip annotations.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Markers keywords projection")
struct FCPXMLMarkersKeywordsProjectionTests {

    @Test("BasicMarkers report uses projection clip annotations")
    func basicMarkersReportUsesProjectionClipAnnotations() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.includeChapterMarkersInMarkersReport = true
        // BasicMarkers title markers lie outside the title media range (FCP-hidden);
        // opt in so this sample still exercises Projection marker annotations.
        options.includeMarkersOutsideClipBoundaries = true

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.markers?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows, "BasicMarkers title markers must appear via Projection")

        let names = Set(rows.map(\.markerName))
        #expect(names.contains("Standard Marker"))
        let hasToDo = names.contains("To Do Marker, Incomplete") || names.contains(where: { $0.contains("To Do") })
        #expect(hasToDo)
        let hasChapter = rows.contains { $0.type == .chapter }
        #expect(hasChapter)
        let allHavePosition = rows.allSatisfy { !$0.position.isEmpty }
        #expect(allHavePosition)
        let hasTitlesRole = rows.contains { $0.roleSubrole == "Titles" }
        #expect(hasTitlesRole)
    }

    @Test("Keywords sample report uses projection when present")
    func keywordsSampleReportUsesProjectionWhenPresent() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.keywords.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.keywordsOnly
        options.includeMarkers = false

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.keywords?.rows)
        let hasRows = !rows.isEmpty
        #expect(hasRows)
        let allHaveKeyword = rows.allSatisfy { !$0.keyword.isEmpty }
        #expect(allHaveKeyword)
        // Most keywords have timeline In; some fixtures use value-only keywords without start.
        let hasTimelineIn = rows.contains { !$0.timelineIn.isEmpty }
        #expect(hasTimelineIn)
    }

    @Test("Projection detailed collects title markers without media windows")
    func projectionDetailedCollectsTitleMarkersWithoutMediaWindows() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        let source = try #require(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        let hasMarkers = detailed.clipAnnotations.contains { !$0.markers.isEmpty }
        #expect(hasMarkers, "Title-hosted markers must be collected as clip annotations")
        let hasTitleHost = detailed.clipAnnotations.contains { $0.hostElementType == "title" }
        #expect(hasTitleHost)
    }

    @Test("Markers-only consumes timeline projection")
    func markersOnlyConsumesTimelineProjection() {
        let options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        #expect(options.consumesTimelineProjection)
        #expect(options.includeMarkers)
    }
}
