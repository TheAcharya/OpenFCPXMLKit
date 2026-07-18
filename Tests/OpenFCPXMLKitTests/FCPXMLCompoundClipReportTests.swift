//
//  FCPXMLCompoundClipReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Excel reporting for standalone compound-clip FCPXML (event ref-clip, no project).
//	Inline fixtures only (no bundled samples or DTD validation), so these tests run on
//	iOS 26+ as well as macOS and cover compound-clip discovery via the AEXML backend.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Compound clip report")
struct FCPXMLCompoundClipReportTests {

    private static let compoundClipName = "Standalone Compound Clip"
    private static let eventName = "Sample Event"
    private static let projectName = "Normal Project"

    // MARK: - Discovery

    @Test("All report timeline sources includes event-level compound clip")
    func allReportTimelineSourcesIncludesEventLevelCompoundClip() throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)

        #expect(fcpxml.allProjects().isEmpty)

        let sources = fcpxml.allReportTimelineSources()
        #expect(sources.count == 1)
        #expect(sources[0].displayName == Self.compoundClipName)
        #expect(sources[0].eventName == Self.eventName)
        #expect(sources[0].project == nil)
        #expect(sources[0].sequence.spine != nil)
    }

    @Test("All report timeline sources uses project when compound is only on spine")
    func allReportTimelineSourcesUsesProjectWhenCompoundIsOnlyOnSpine() throws {
        // Compound clip lives inside the project spine, not as an event-level browser clip.
        // Discovery must report the project timeline only (not double-count the media sequence).
        let fcpxml = try parseInlineFCPXML(projectWithEmbeddedCompoundFixture)

        let sources = fcpxml.allReportTimelineSources()
        #expect(sources.count == 1)
        #expect(sources[0].project != nil)
        #expect(sources[0].displayName == "Project Timeline")
    }

    // MARK: - Report build

    @Test("Build role inventory from standalone compound clip")
    func buildRoleInventoryFromStandaloneCompoundClip() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)

        #expect(report.projectName == Self.compoundClipName)
        #expect(report.eventName == Self.eventName)

        let rows = report.roleInventory?.selectedRoles ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty, "Expected role inventory rows from compound clip sequence")

        let clipNames = Set(rows.map(\.clipName))
        #expect(clipNames.contains("Video Clip A"))

        let roles = Set(rows.map(\.roleSubrole))
        let hasDialogue = roles.contains(where: { $0.localizedCaseInsensitiveContains("dialogue") })
        #expect(
            hasDialogue,
            "Expected dialogue role from compound clip timeline; got \(roles)"
        )
    }

    @Test("Build markers from standalone compound clip")
    func buildMarkersFromStandaloneCompoundClip() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.markersOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        let rows = report.markers?.rows ?? []

        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)
        #expect(rows.contains { $0.markerName == "Marker One" })
    }

    @Test("Build summary from standalone compound clip")
    func buildSummaryFromStandaloneCompoundClip() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.summaryOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)

        #expect(report.summary?.projectSummary?.title == Self.compoundClipName)
        FCPXMLReportingReportTestSupport.assertValidTimecode(
            report.summary?.projectSummary?.duration ?? ""
        )

        let roleDurations = report.summary?.roleDurations ?? []
        let roleDurationsEmpty = roleDurations.isEmpty
        #expect(!roleDurationsEmpty)
        let hasDialogue = roleDurations.contains(where: {
            $0.roleSubrole.localizedCaseInsensitiveContains("dialogue")
        })
        #expect(
            hasDialogue,
            "Expected dialogue role in summary role durations; got \(Set(roleDurations.map(\.roleSubrole)))"
        )
    }

    @Test("Project name filter matches compound clip name")
    func projectNameFilterMatchesCompoundClipName() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = Self.compoundClipName

        let report = try await fcpxml.buildReport(options: options)
        #expect(report.projectName == Self.compoundClipName)
        let selectedRolesEmpty = report.roleInventory?.selectedRoles.isEmpty ?? true
        #expect(!selectedRolesEmpty)
    }

    @Test("Project name filter throws when compound clip name missing")
    func projectNameFilterThrowsWhenCompoundClipNameMissing() async throws {
        let fcpxml = try parseInlineFCPXML(standaloneCompoundClipFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil
        options.projectName = "Does Not Exist"

        do {
            _ = try await fcpxml.buildReport(options: options)
            Issue.record("Expected projectNotFound")
        } catch FinalCutPro.FCPXML.ReportError.projectNotFound(let name) {
            #expect(name == "Does Not Exist")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Normal project report still works")
    func normalProjectReportStillWorks() async throws {
        let fcpxml = try parseInlineFCPXML(normalProjectFixture)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.workbookCoverSheet = nil

        let report = try await fcpxml.buildReport(options: options)
        #expect(report.projectName == Self.projectName)
        let selectedRolesEmpty = report.roleInventory?.selectedRoles.isEmpty ?? true
        #expect(!selectedRolesEmpty)
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
