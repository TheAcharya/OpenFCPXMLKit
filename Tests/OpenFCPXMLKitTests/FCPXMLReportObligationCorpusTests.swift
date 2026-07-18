//
// FCPXMLReportObligationCorpusTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Reporting contracts: media resolution policy, Media Summary proxy/original,
//	and near-zero-miss obligation corpus on in-repo samples.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Report obligation corpus")
struct FCPXMLReportObligationCorpusTests {

    // MARK: - Fail-soft vs fail-loud

    @Test("Media resolution policy defaults to failSoft")
    func mediaResolutionPolicyDefaultsToFailSoft() {
        let options = FinalCutPro.FCPXML.ReportOptions()
        #expect(options.mediaResolutionPolicy == .failSoft)
        #expect(!options.mediaSummaryDistinguishProxyAndOriginal)
    }

    @Test("Fail-soft continues when projection throws")
    func failSoftContinuesWhenProjectionThrows() async throws {
        let fcpxml = try parseInlineFCPXML(Self.simpleAssetClipXML)
        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.mediaResolutionPolicy = .failSoft
        options.mediaBaseURL = URL(fileURLWithPath: "/tmp")

        let report = try await FinalCutPro.FCPXML.ReportBuilder(
            options: options,
            timelineProjector: FailingTimelineProjector()
        ).build(from: fcpxml)

        #expect(report.mediaSummary != nil)
        // Document fallback still lists missing original-media when projection is empty.
        let hasMissingPaths = !(report.mediaSummary?.missingMediaPaths.isEmpty ?? true)
        #expect(hasMissingPaths)
    }

    @Test("Fail-loud throws projectionFailed when projection throws")
    func failLoudThrowsProjectionFailedWhenProjectionThrows() async throws {
        let fcpxml = try parseInlineFCPXML(Self.simpleAssetClipXML)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.mediaResolutionPolicy = .failLoud

        do {
            _ = try await FinalCutPro.FCPXML.ReportBuilder(
                options: options,
                timelineProjector: FailingTimelineProjector()
            ).build(from: fcpxml)
            Issue.record("Expected ReportError.projectionFailed")
        } catch let error as FinalCutPro.FCPXML.ReportError {
            let isProjectionFailed: Bool
            if case .projectionFailed = error {
                isProjectionFailed = true
            } else {
                isProjectionFailed = false
            }
            #expect(isProjectionFailed, "Unexpected ReportError: \(error)")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Media Summary proxy vs original

    @Test("Media Summary combined paths by default")
    func mediaSummaryCombinedPathsByDefault() async throws {
        let fcpxml = try parseInlineFCPXML(Self.proxyAndOriginalXML)
        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.mediaSummaryDistinguishProxyAndOriginal = false
        options.mediaBaseURL = URL(fileURLWithPath: "/")

        let report = try await fcpxml.buildReport(options: options)
        let summary = try #require(report.mediaSummary)

        #expect(!summary.distinguishProxyAndOriginal)
        let hasOriginal = summary.missingMediaPaths.contains { $0.contains("original-missing.mov") }
        let hasProxy = summary.missingMediaPaths.contains { $0.contains("proxy-missing.mov") }
        #expect(hasOriginal)
        #expect(hasProxy)
        let hasOriginalColumn = !summary.missingOriginalMediaPaths.isEmpty
        let hasProxyColumn = !summary.missingProxyMediaPaths.isEmpty
        #expect(hasOriginalColumn)
        #expect(hasProxyColumn)
    }

    @Test("Media Summary distinguish proxy and original columns")
    func mediaSummaryDistinguishProxyAndOriginalColumns() async throws {
        let fcpxml = try parseInlineFCPXML(Self.proxyAndOriginalXML)
        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.mediaSummaryDistinguishProxyAndOriginal = true
        options.mediaBaseURL = URL(fileURLWithPath: "/")

        let report = try await fcpxml.buildReport(options: options)
        let summary = try #require(report.mediaSummary)

        #expect(summary.distinguishProxyAndOriginal)
        let hasOriginal = summary.missingOriginalMediaPaths.contains { $0.contains("original-missing.mov") }
        let hasProxy = summary.missingProxyMediaPaths.contains { $0.contains("proxy-missing.mov") }
        #expect(hasOriginal)
        #expect(hasProxy)

        let planned = FCPXMLReportPDFSheetPlan.plannedSheets(from: report)
        let hasMediaSummarySheet = planned.contains {
            $0.title == FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        }
        #expect(hasMediaSummarySheet)
    }

    @Test("Source file path exclusion aliases include proxy/original headers")
    func sourceFilePathExclusionAliasesIncludeProxyOriginalHeaders() {
        let excluded = FinalCutPro.FCPXML.ReportColumnExclusion.resolve([
            "Missing Original",
            "Missing Proxy"
        ])
        #expect(excluded.contains(.sourceFilePath))
    }

    // MARK: - Near-zero-miss corpus

    @Test("Obligation corpus BasicMarkers has marker rows")
    func obligationCorpusBasicMarkersHasMarkerRows() async throws {
        // BasicMarkers title markers sit outside the title media range (FCP-hidden).
        let defaultReport = try await buildFullReport(sample: .basicMarkers)
        let defaultEmpty = defaultReport.markers?.rows.isEmpty == true
        #expect(defaultEmpty, "Default Markers report must omit out-of-bounds BasicMarkers")

        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.mediaBaseURL = urlForFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
            .deletingLastPathComponent()
        options.includeMarkersOutsideClipBoundaries = true
        let report = try await fcpxml.buildReport(options: options)
        let markers = try #require(report.markers)
        let hasRows = !markers.rows.isEmpty
        #expect(hasRows, "Opt-in must yield Markers sheet rows for BasicMarkers")
        #expect(markers.showsHiddenColumn)
        for row in markers.rows {
            let nameNonEmpty = !row.markerName.isEmpty
            let positionNonEmpty = !row.position.isEmpty
            #expect(nameNonEmpty)
            #expect(positionNonEmpty)
            #expect(row.isHidden)
        }
    }

    @Test("Obligation corpus Keywords has keyword rows")
    func obligationCorpusKeywordsHasKeywordRows() async throws {
        let report = try await buildFullReport(sample: .keywords)
        let keywords = try #require(report.keywords)
        let hasRows = !keywords.rows.isEmpty
        #expect(hasRows, "Keywords sample must yield Keywords sheet rows")
        for row in keywords.rows {
            let keywordNonEmpty = !row.keyword.isEmpty
            #expect(keywordNonEmpty)
        }
    }

    @Test("Obligation corpus TitlesRoles has title rows")
    func obligationCorpusTitlesRolesHasTitleRows() async throws {
        let report = try await buildFullReport(sample: .titlesRoles)
        let titles = try #require(report.titlesAndGenerators)
        let hasRows = !titles.rows.isEmpty
        #expect(hasRows, "TitlesRoles must yield Titles & Generators rows")
        for row in titles.rows {
            let clipNameNonEmpty = !row.clipName.isEmpty
            #expect(clipNameNonEmpty)
        }
    }

    @Test("Obligation corpus RolesList has inventory rows")
    func obligationCorpusRolesListHasInventoryRows() async throws {
        let report = try await buildFullReport(sample: .rolesList)
        let inventory = try #require(report.roleInventory)
        let hasRoles = !inventory.selectedRoles.isEmpty
        #expect(hasRoles, "RolesList must yield Selected Roles Inventory rows")
        for row in inventory.selectedRoles {
            let clipNameNonEmpty = !row.clipName.isEmpty
            let roleNonEmpty = !row.roleSubrole.isEmpty
            #expect(clipNameNonEmpty)
            #expect(roleNonEmpty)
        }
        let summary = try #require(report.summary)
        #expect(summary.projectSummary != nil)
        let titleNonEmpty = !(summary.projectSummary?.title.isEmpty ?? true)
        #expect(titleNonEmpty)
    }

    @Test("Obligation corpus TransitionMarkers has transition or marker content")
    func obligationCorpusTransitionMarkersHasTransitionOrMarkerContent() async throws {
        let report = try await buildFullReport(sample: .transitionMarkers1)
        let hasTransitions = !(report.transitions?.rows.isEmpty ?? true)
        let hasMarkers = !(report.markers?.rows.isEmpty ?? true)
        let hasContent = hasTransitions || hasMarkers
        #expect(
            hasContent,
            "TransitionMarkers1 must contribute Transitions and/or Markers content"
        )
    }

    @Test("Obligation corpus Complex builds all requested sections")
    func obligationCorpusComplexBuildsAllRequestedSections() async throws {
        let report = try await buildFullReport(sample: .complex)
        #expect(report.roleInventory != nil)
        #expect(report.markers != nil)
        #expect(report.summary != nil)
        #expect(report.mediaSummary != nil)
        // Complex references media that is typically missing on CI → Media Summary may list paths.
        #expect(report.mediaSummary?.missingMediaPaths != nil)
    }

    // MARK: - Helpers

    private func buildFullReport(sample: FCPXMLSampleName) async throws -> FinalCutPro.FCPXML.Report {
        let fcpxml = try requireFCPXMLSample(named: sample.rawValue)
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.mediaBaseURL = urlForFCPXMLSample(named: sample.rawValue).deletingLastPathComponent()
        return try await fcpxml.buildReport(options: options)
    }

    private struct FailingTimelineProjector: FinalCutPro.FCPXML.TimelineProjecting {
        enum ProbeError: Error {
            case intentional
        }

        func project(
            from source: FinalCutPro.FCPXML.ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: FinalCutPro.FCPXML.TimelineProjectionOptions,
            onWindow: (FinalCutPro.FCPXML.MediaUsageWindow) throws -> Void
        ) async throws {
            throw ProbeError.intentional
        }
    }

    private static let simpleAssetClipXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/p4-obligation-missing.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine>
                        <asset-clip ref="r2" offset="0s" name="Clip" duration="5s"/>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """

    private static let proxyAndOriginalXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/p4-original-missing.mov"/>
                    <media-rep kind="proxy-media" src="file:///tmp/p4-proxy-missing.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine>
                        <asset-clip ref="r2" offset="0s" name="Clip" duration="5s"/>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
}

