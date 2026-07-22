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

    // MARK: - mc-clip host annotations + missing sequence tcFormat

    @Test("Projection collects markers and keywords hosted on mc-clip")
    func projectionCollectsMarkersAndKeywordsHostedOnMCClip() async throws {
        let fcpxml = try parseInlineFCPXML(mcClipHostedAnnotationsXML(includeSequenceTCFormat: true))
        let source = try #require(fcpxml.allReportTimelineSources().first)
        var options = FinalCutPro.FCPXML.TimelineProjectionOptions()
        options.includeAnnotations = true
        options.excludeFullyOccluded = true

        let detailed = try await FinalCutPro.FCPXML.TimelineProjector()
            .projectDetailed(from: source, fcpxml: fcpxml, options: options)

        let mcHosts = detailed.clipAnnotations.filter { $0.hostElementType == "mc-clip" }
        #expect(!mcHosts.isEmpty, "mc-clip must emit clip annotations")
        let markerNames = Set(mcHosts.flatMap(\.markers).map(\.name))
        #expect(markerNames.contains("MC Marker"))
        let keywordValues = Set(mcHosts.flatMap(\.keywords).map(\.keyword))
        #expect(keywordValues.contains("mc-keyword"))
    }

    @Test("Full markers+keywords report includes mc-clip hosts without sequence tcFormat")
    func fullMarkersKeywordsReportIncludesMCClipHostsWithoutSequenceTCFormat() async throws {
        // Sample-02-style: sequence omits tcFormat; markers/keywords live on mc-clip.
        let fcpxml = try parseInlineFCPXML(mcClipHostedAnnotationsXML(includeSequenceTCFormat: false))
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.includeRoleInventory = false
        options.includeSummary = false
        options.includeMediaSummary = false
        options.includeEffects = false
        options.includeSpeedChangeEffects = false
        options.includeTitlesAndGenerators = false
        options.includeTransitions = false
        options.includeNonStandardEffectsTemplates = false
        options.includeMarkers = true
        options.includeKeywords = true

        let report = try await fcpxml.buildReport(options: options)
        let markerRows = try #require(report.markers?.rows)
        let keywordRows = try #require(report.keywords?.rows)

        let markerNames = Set(markerRows.map(\.markerName))
        #expect(markerNames.contains("MC Marker"))
        let allMarkersHavePosition = markerRows.allSatisfy { !$0.position.isEmpty }
        #expect(allMarkersHavePosition, "Missing sequence tcFormat must still format positions")

        let keywordValues = Set(keywordRows.map(\.keyword))
        #expect(keywordValues.contains("mc-keyword"))
        let allKeywordsHaveIn = keywordRows.allSatisfy { !$0.timelineIn.isEmpty }
        #expect(allKeywordsHaveIn)

        // Keyword start=0s with host start=10s must clamp to the clip's timeline appearance.
        let mcKeyword = try #require(keywordRows.first { $0.keyword == "mc-keyword" })
        #expect(mcKeyword.clipName == "Performance")
    }

    @Test("MulticamSample keywords report includes mc-clip hosted keyword")
    func multicamSampleKeywordsReportIncludesMCClipHostedKeyword() async throws {
        let fcpxml = try requireFCPXMLSample(named: "MulticamSample")
        var options = FinalCutPro.FCPXML.ReportOptions.keywordsOnly
        options.includeMarkers = false

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.keywords?.rows)
        let hasMCClipKeyword = rows.contains {
            $0.keyword.localizedCaseInsensitiveContains("multicam")
                && $0.clipName == "Chocolate Interview"
        }
        #expect(hasMCClipKeyword, "Keyword on mc-clip Chocolate Interview must appear")
    }

    @Test("Connected-clip markers appear even when host is fully occluded")
    func connectedClipMarkersAppearEvenWhenHostIsFullyOccluded() async throws {
        // Parent is short; lane-1 connected clip starts inside parent but extends past it
        // (fully occluded for occupancy) while still carrying a timeline marker.
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="Primary" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/primary.mov"/>
                    </asset>
                    <asset id="r3" name="Connected" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/connected.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="20s" tcStart="0s" tcFormat="NDF">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="Primary" start="0s" duration="2s">
                                        <asset-clip ref="r3" lane="1" offset="0s" name="Connected" start="0s" duration="10s">
                                            <marker start="1s" duration="1/24s" value="Connected Marker"/>
                                        </asset-clip>
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)

        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.includeMarkersOutsideClipBoundaries = false

        let report = try await fcpxml.buildReport(options: options)
        let rows = try #require(report.markers?.rows)
        let names = Set(rows.map(\.markerName))
        #expect(names.contains("Connected Marker"))
        let connectedRows = rows.filter { $0.markerName == "Connected Marker" }
        let allHavePosition = connectedRows.allSatisfy { !$0.position.isEmpty }
        #expect(allHavePosition)
        // Not "Hidden" — start is inside host media range; default omit-outside does not apply.
        let anyHidden = connectedRows.contains { $0.isHidden }
        #expect(!anyHidden)
    }

    // MARK: - Inline fixtures

    private func parseInlineFCPXML(_ xml: String) throws -> FinalCutPro.FCPXML {
        let data = try #require(xml.data(using: .utf8))
        return try FinalCutPro.FCPXML(fileContent: data)
    }

    /// Minimal timeline: one mc-clip with a host marker + keyword.
    /// Keyword uses `start="0s"` while the host media in-point is `10s` (Sample-02 pattern).
    private func mcClipHostedAnnotationsXML(includeSequenceTCFormat: Bool) -> String {
        let tcFormatAttr = includeSequenceTCFormat ? #" tcFormat="NDF""# : ""
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="CamA" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" duration="60s">
                        <media-rep kind="original-media" src="file:///tmp/cam-a.mov"/>
                    </asset>
                    <media id="r3" name="Performance">
                        <multicam format="r1" renderFormat="r1" tcStart="0s" tcFormat="NDF">
                            <mc-angle name="A" angleID="angle-a">
                                <asset-clip ref="r2" offset="0s" name="CamA" start="0s" duration="60s"/>
                            </mc-angle>
                        </multicam>
                    </media>
                </resources>
                <library>
                    <event name="E">
                        <project name="P">
                            <sequence format="r1" duration="20s" tcStart="0s"\(tcFormatAttr)>
                                <spine>
                                    <mc-clip ref="r3" offset="2s" name="Performance" start="10s" duration="8s">
                                        <mc-source angleID="angle-a" srcEnable="all"/>
                                        <marker start="12s" duration="1/24s" value="MC Marker"/>
                                        <keyword start="0s" duration="60s" value="mc-keyword"/>
                                    </mc-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """
    }
}

