//
//  FCPXMLMarkersReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Markers report integration tests (optional local FCPXML fixture).
//

import Foundation
import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("Markers report")
struct FCPXMLMarkersReportTests {

    private func markersOptions(
        includeChapterMarkersInMarkersReport: Bool = false
    ) throws -> FinalCutPro.FCPXML.ReportOptions {
        let fcpxml = try requireReportingFixtureFCPXML()
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeMarkers = true
        options.includeChapterMarkersInMarkersReport = includeChapterMarkersInMarkersReport
        return options
    }

    @Test("Build markers report from fixture")
    func buildMarkersReportFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let options = try markersOptions()

        let report = try await fcpxml.buildReport(options: options)

        #expect(report.projectName == FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml))
        #expect(report.markers != nil)

        let rows = report.markers?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)
        #expect(FinalCutPro.FCPXML.MarkerReportRow.columnHeaders.count == 9)
    }

    @Test("Marker report rows have valid shape from fixture")
    func markerReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: try markersOptions())

        let rows = report.markers?.rows ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)

        for row in rows.prefix(20) {
            let markerNameEmpty = row.markerName.isEmpty
            let clipNameEmpty = row.clipName.isEmpty
            #expect(!markerNameEmpty)
            #expect(!clipNameEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.position)
        }
    }

    @Test("Markers report excludes chapter markers by default")
    func markersReportExcludesChapterMarkersByDefault() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(
            options: try markersOptions(includeChapterMarkersInMarkersReport: false)
        )

        let rows = report.markers?.rows ?? []
        let hasChapter = rows.contains { $0.type == FinalCutPro.FCPXML.MarkerReportType.chapter }
        #expect(!hasChapter)
    }

    @Test("Markers report sorted by timeline position")
    func markersReportSortedByTimelinePosition() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()
        let report = try await fcpxml.buildReport(options: try markersOptions())

        let positions = report.markers?.rows.map(\.position) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(positions)
    }

    @Test("Marker on audio-video clip fans out to video and dialogue rows")
    func markerOnAudioVideoClipFansOutToVideoAndDialogueRows() async throws {
        let fcpxml = try parseInlineFCPXML(avAssetClipMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []

        let chapterRows = rows.filter { $0.markerName == "Chapter 1" }
        #expect(chapterRows.count == 2)
        #expect(chapterRows.map(\.roleSubrole) == ["Video", "Dialogue"])
        #expect(Set(chapterRows.map(\.position)).count == 1)
        #expect(Set(chapterRows.map(\.clipName)) == ["Clip"])
    }

    @Test("Full preset includes chapter markers")
    func fullPresetIncludesChapterMarkers() {
        #expect(FinalCutPro.FCPXML.ReportOptions.full.includeChapterMarkersInMarkersReport)
        #expect(
            !FinalCutPro.FCPXML.ReportOptions.markersOnly.includeChapterMarkersInMarkersReport
        )
    }

    @Test("Chapter marker on audio-video clip fans out when included")
    func chapterMarkerOnAudioVideoClipFansOutWhenIncluded() async throws {
        let fcpxml = try parseInlineFCPXML(avAssetClipChapterMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.includeChapterMarkersInMarkersReport = true
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []

        let chapterRows = rows.filter { $0.markerName == "Chapter 4" }
        #expect(chapterRows.count == 2)
        #expect(chapterRows.map(\.roleSubrole) == ["Video", "Dialogue"])
        #expect(chapterRows.allSatisfy { $0.type == .chapter })
    }

    @Test("Chapter marker excluded by default markers preset")
    func chapterMarkerExcludedByDefaultMarkersPreset() async throws {
        let fcpxml = try parseInlineFCPXML(avAssetClipChapterMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []

        let hasChapter4 = rows.contains { $0.markerName == "Chapter 4" }
        #expect(!hasChapter4)
    }

    @Test("Hidden markers sample excludes out-of-bounds by default")
    func hiddenMarkersSampleExcludesOutOfBoundsByDefault() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.hiddenMarkers.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let section = try #require(report.markers)
        let names = Set(section.rows.map(\.markerName))

        #expect(names == ["Marker 1", "Marker 2"])
        #expect(!section.showsHiddenColumn)
        let hasHiddenHeader = section.columnHeaders().contains("Hidden")
        #expect(
            !hasHiddenHeader,
            "Hidden column must be omitted when outside-bounds markers are excluded"
        )
        #expect(section.rows.first?.columnValues.count == 9)
    }

    @Test("Hidden markers sample includes out-of-bounds with Hidden column when opted in")
    func hiddenMarkersSampleIncludesOutOfBoundsWithHiddenColumnWhenOptedIn() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.hiddenMarkers.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.includeMarkersOutsideClipBoundaries = true
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let section = try #require(report.markers)
        let byName = Dictionary(uniqueKeysWithValues: section.rows.map { ($0.markerName, $0) })

        #expect(section.showsHiddenColumn)
        #expect(section.columnHeaders().last == "Hidden")
        #expect(Set(byName.keys) == ["Marker 1", "Marker 2", "Marker 3", "Marker 4"])

        #expect(byName["Marker 1"]?.isHidden == false)
        #expect(byName["Marker 2"]?.isHidden == false)
        #expect(byName["Marker 3"]?.isHidden == true)
        #expect(byName["Marker 4"]?.isHidden == true)

        let values = section.columnValues(for: try #require(byName["Marker 3"]))
        #expect(values.count == 10)
        #expect(values.last == "✓")
        #expect(
            section.columnValues(for: try #require(byName["Marker 1"])).last
                == "✗"
        )
    }

    @Test("Marker clip boundary detects outside host media range")
    func markerClipBoundaryDetectsOutsideHostMediaRange() {
        let hostStart = Fraction(double: 3600)
        let hostDuration = Fraction(double: 35.12)

        #expect(
            !FinalCutPro.FCPXML.MarkerClipBoundary.isOutsideHostMediaRange(
                markerStart: Fraction(double: 3610.68),
                hostStart: hostStart,
                hostDuration: hostDuration
            )
        )
        #expect(
            FinalCutPro.FCPXML.MarkerClipBoundary.isOutsideHostMediaRange(
                markerStart: Fraction(double: 3641.76),
                hostStart: hostStart,
                hostDuration: hostDuration
            )
        )
        #expect(
            FinalCutPro.FCPXML.MarkerClipBoundary.isOutsideHostMediaRange(
                markerStart: Fraction(double: 3599),
                hostStart: hostStart,
                hostDuration: hostDuration
            )
        )
        #expect(
            !FinalCutPro.FCPXML.MarkerClipBoundary.isOutsideHostMediaRange(
                markerStart: Fraction(double: 3641.76),
                hostStart: hostStart,
                hostDuration: nil
            )
        )
    }

    @Test("Marker on audio-only clip yields single dialogue row")
    func markerOnAudioOnlyClipYieldsSingleDialogueRow() async throws {
        let fcpxml = try parseInlineFCPXML(audioOnlyClipMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []

        let markerRows = rows.filter { $0.markerName == "Marker 1" }
        #expect(markerRows.count == 1)
        #expect(markerRows.first?.roleSubrole == "Dialogue")
    }

    private var avAssetClipMarkerFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Media" uid="M1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Clip" duration="5s" tcFormat="NDF" audioRole="dialogue">
                                    <marker start="1s" duration="100/2400s" value="Chapter 1" completed="0"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }

    private var avAssetClipChapterMarkerFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Media" uid="M1" start="0s" duration="10s" hasVideo="1" hasAudio="1" audioSources="1" format="r1" videoSources="1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Clip" duration="5s" tcFormat="NDF" audioRole="dialogue">
                                    <chapter-marker start="1s" duration="100/2400s" value="Chapter 4" posterOffset="11/30s"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }

    private var audioOnlyClipMarkerFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r3" name="Audio" uid="A1" start="0s" duration="10s" hasAudio="1" audioSources="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r3" offset="0s" name="Audio" duration="5s" tcFormat="NDF" audioRole="dialogue">
                                    <marker start="1s" duration="100/2400s" value="Marker 1"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
}

