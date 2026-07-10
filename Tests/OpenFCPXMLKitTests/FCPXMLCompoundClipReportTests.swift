//
//  FCPXMLCompoundClipReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Excel reporting for standalone compound-clip FCPXML (event ref-clip, no project).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLCompoundClipReportTests: XCTestCase {
    
    private static let compoundClipName = "Standalone Compound Clip"
    private static let eventName = "Sample Event"
    private static let projectName = "Normal Project"
    
    // MARK: - Discovery
    
    func testAllReportTimelineSourcesIncludesEventLevelCompoundClip() throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        
        XCTAssertTrue(fcpxml.allProjects().isEmpty)
        
        let sources = fcpxml.allReportTimelineSources()
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources[0].displayName, Self.compoundClipName)
        XCTAssertEqual(sources[0].eventName, Self.eventName)
        XCTAssertNil(sources[0].project)
        XCTAssertNotNil(sources[0].sequence.spine)
    }
    
    func testAllReportTimelineSourcesUsesProjectWhenCompoundIsOnlyOnSpine() throws {
        // Compound clip lives inside the project spine, not as an event-level browser clip.
        // Discovery must report the project timeline only (not double-count the media sequence).
        let fcpxml = try parseInlineFCPXML(projectWithEmbeddedCompoundFixture)
        
        let sources = fcpxml.allReportTimelineSources()
        XCTAssertEqual(sources.count, 1)
        XCTAssertNotNil(sources[0].project)
        XCTAssertEqual(sources[0].displayName, "Project Timeline")
    }
    
    // MARK: - Report build
    
    func testBuildRoleInventoryFromStandaloneCompoundClip() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        
        XCTAssertEqual(report.projectName, Self.compoundClipName)
        XCTAssertEqual(report.eventName, Self.eventName)
        
        let rows = report.roleInventory?.selectedRoles ?? []
        XCTAssertFalse(rows.isEmpty, "Expected role inventory rows from compound clip sequence")
        
        let clipNames = Set(rows.map(\.clipName))
        XCTAssertTrue(clipNames.contains("Video Clip A"))
        
        let roles = Set(rows.map(\.roleSubrole))
        XCTAssertTrue(
            roles.contains(where: { $0.localizedCaseInsensitiveContains("dialogue") }),
            "Expected dialogue role from compound clip timeline; got \(roles)"
        )
    }
    
    func testBuildMarkersFromStandaloneCompoundClip() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []
        
        XCTAssertFalse(rows.isEmpty)
        XCTAssertTrue(rows.contains { $0.markerName == "Marker One" })
    }
    
    func testBuildSummaryFromStandaloneCompoundClip() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.summaryOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        
        XCTAssertEqual(report.summary?.projectSummary?.title, Self.compoundClipName)
        FCPXMLReportingReportTestSupport.assertValidTimecode(
            report.summary?.projectSummary?.duration ?? ""
        )
        XCTAssertFalse(report.summary?.roleDurations.isEmpty ?? true)
    }
    
    func testProjectNameFilterMatchesCompoundClipName() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = Self.compoundClipName
        
        let report = try await fcpxml.buildReport(options: options)
        XCTAssertEqual(report.projectName, Self.compoundClipName)
        XCTAssertFalse(report.roleInventory?.selectedRoles.isEmpty ?? true)
    }
    
    func testProjectNameFilterThrowsWhenCompoundClipNameMissing() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = "Does Not Exist"
        
        do {
            _ = try await fcpxml.buildReport(options: options)
            XCTFail("Expected projectNotFound")
        } catch FinalCutPro.FCPXML.ReportError.projectNotFound(let name) {
            XCTAssertEqual(name, "Does Not Exist")
        }
    }
    
    func testNormalProjectReportStillWorks() async throws {
        let fcpxml = try parseInlineFCPXML(normalProjectFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        
        let report = try await fcpxml.buildReport(options: options)
        XCTAssertEqual(report.projectName, Self.projectName)
        XCTAssertFalse(report.roleInventory?.selectedRoles.isEmpty ?? true)
    }
    
    // MARK: - Fixtures
    
    /// Mirrors FCP “Export XML” of a compound clip: no `<project>`, event holds `ref-clip`,
    /// timeline lives under `resources` → `media` → `sequence`.
    private var standaloneCompoundClipFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                <media id="r1" name="\(Self.compoundClipName)" uid="CCUID1">
                    <sequence format="r2" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <asset-clip ref="r3" offset="0s" name="Video Clip A" duration="5s" tcFormat="NDF" audioRole="dialogue">
                                <marker start="1s" duration="100/2500s" value="Marker One" completed="0"/>
                                <audio-channel-source srcCh="1, 2" role="dialogue.dialogue-1"/>
                            </asset-clip>
                            <asset-clip ref="r4" offset="5s" name="Video Clip B" duration="5s" tcFormat="NDF" audioRole="dialogue">
                                <marker start="1s" duration="100/2500s" value="Marker Two"/>
                            </asset-clip>
                        </spine>
                    </sequence>
                </media>
                <format id="r2" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
                <asset id="r3" name="Video Clip A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" format="r2" audioSources="1" audioChannels="2" audioRate="44100"/>
                <asset id="r4" name="Video Clip B" uid="A2" start="0s" duration="10s" hasVideo="1" hasAudio="1" format="r2" audioSources="1" audioChannels="2" audioRate="44100"/>
            </resources>
            <library>
                <event name="\(Self.eventName)" uid="E1">
                    <ref-clip ref="r1" name="\(Self.compoundClipName)" duration="10s"/>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var normalProjectFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <asset id="r2" name="Video Clip A" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" format="r1" audioSources="1" audioChannels="2"/>
            </resources>
            <library>
                <event name="\(Self.eventName)" uid="E1">
                    <project name="\(Self.projectName)" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Video Clip A" duration="5s" tcFormat="NDF" audioRole="dialogue">
                                    <audio-channel-source srcCh="1, 2" role="dialogue.dialogue-1"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
    
    private var projectWithEmbeddedCompoundFixture: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
                <media id="r2" name="Inner Compound" uid="M1">
                    <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <asset-clip ref="r3" offset="0s" name="Inner Clip" duration="5s" tcFormat="NDF" audioRole="dialogue"/>
                        </spine>
                    </sequence>
                </media>
                <asset id="r3" name="Inner Clip" uid="A1" start="0s" duration="10s" hasVideo="1" hasAudio="1" format="r1"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="Project Timeline" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <ref-clip ref="r2" offset="0s" name="Inner Compound" duration="5s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
}
