//
//  FCPXMLMarkersReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Markers report integration tests (optional local FCPXML fixture).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLMarkersReportTests: XCTestCase, @unchecked Sendable {
    
    private func markersOptions(
        includeChapterMarkersInMarkersReport: Bool = false
    ) throws -> FinalCutPro.FCPXML.ReportOptions {
        try FCPXMLReportingReportFixture.reportOptions {
            $0.includeMarkers = true
            $0.includeChapterMarkersInMarkersReport = includeChapterMarkersInMarkersReport
        }
    }
    
    func testBuildMarkersReportFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let options = try markersOptions()
        
        let report = try await fcpxml.buildReport(options: options)
        
        XCTAssertEqual(report.projectName, FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml))
        XCTAssertNotNil(report.markers)
        
        let rows = report.markers?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(FinalCutPro.FCPXML.MarkerReportRow.columnHeaders.count, 9)
    }
    
    func testMarkerReportRowsHaveValidShapeFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: try markersOptions())
        
        let rows = report.markers?.rows ?? []
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows.prefix(20) {
            XCTAssertFalse(row.markerName.isEmpty)
            XCTAssertFalse(row.clipName.isEmpty)
            FCPXMLReportingReportTestSupport.assertValidTimecode(row.position)
        }
    }
    
    func testMarkersReportExcludesChapterMarkersByDefault() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(
            options: try markersOptions(includeChapterMarkersInMarkersReport: false)
        )
        
        let rows = report.markers?.rows ?? []
        XCTAssertFalse(rows.contains { $0.type == FinalCutPro.FCPXML.MarkerReportType.chapter })
    }
    
    func testMarkersReportSortedByTimelinePosition() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        let report = try await fcpxml.buildReport(options: try markersOptions())
        
        let positions = report.markers?.rows.map(\.position) ?? []
        FCPXMLReportingReportTestSupport.assertSortedTimelinePositions(positions)
    }
    
    func testMarkerOnAudioVideoClipFansOutToVideoAndDialogueRows() async throws {
        let fcpxml = try parseInlineFCPXML(avAssetClipMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []
        
        let chapterRows = rows.filter { $0.markerName == "Chapter 1" }
        XCTAssertEqual(chapterRows.count, 2)
        XCTAssertEqual(chapterRows.map(\.roleSubrole), ["Video", "Dialogue"])
        XCTAssertEqual(Set(chapterRows.map(\.position)).count, 1)
        XCTAssertEqual(Set(chapterRows.map(\.clipName)), ["Clip"])
    }
    
    func testFullPresetIncludesChapterMarkers() {
        XCTAssertTrue(FinalCutPro.FCPXML.ReportOptions.full.includeChapterMarkersInMarkersReport)
        XCTAssertFalse(
            FinalCutPro.FCPXML.ReportOptions.markersOnly.includeChapterMarkersInMarkersReport
        )
    }
    
    func testChapterMarkerOnAudioVideoClipFansOutWhenIncluded() async throws {
        let fcpxml = try parseInlineFCPXML(avAssetClipChapterMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.includeChapterMarkersInMarkersReport = true
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []
        
        let chapterRows = rows.filter { $0.markerName == "Chapter 4" }
        XCTAssertEqual(chapterRows.count, 2)
        XCTAssertEqual(chapterRows.map(\.roleSubrole), ["Video", "Dialogue"])
        XCTAssertTrue(chapterRows.allSatisfy { $0.type == .chapter })
    }
    
    func testChapterMarkerExcludedByDefaultMarkersPreset() async throws {
        let fcpxml = try parseInlineFCPXML(avAssetClipChapterMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []
        
        XCTAssertFalse(rows.contains { $0.markerName == "Chapter 4" })
    }
    
    func testMarkerOnAudioOnlyClipYieldsSingleDialogueRow() async throws {
        let fcpxml = try parseInlineFCPXML(audioOnlyClipMarkerFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []
        
        let markerRows = rows.filter { $0.markerName == "Marker 1" }
        XCTAssertEqual(markerRows.count, 1)
        XCTAssertEqual(markerRows.first?.roleSubrole, "Dialogue")
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
