//
// FCPXMLReportObligationCorpusTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Reporting contracts: media resolution policy, Media Summary proxy/original,
//	and near-zero-miss obligation corpus on in-repo samples.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportObligationCorpusTests: XCTestCase {

    // MARK: - Fail-soft vs fail-loud

    func testMediaResolutionPolicyDefaultsToFailSoft() {
        let options = FinalCutPro.FCPXML.ReportOptions()
        XCTAssertEqual(options.mediaResolutionPolicy, .failSoft)
        XCTAssertFalse(options.mediaSummaryDistinguishProxyAndOriginal)
    }

    func testFailSoftContinuesWhenProjectionThrows() async throws {
        let fcpxml = try parseInlineFCPXML(Self.simpleAssetClipXML)
        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.mediaResolutionPolicy = .failSoft
        options.mediaBaseURL = URL(fileURLWithPath: "/tmp")

        let report = try await FinalCutPro.FCPXML.ReportBuilder(
            options: options,
            timelineProjector: FailingTimelineProjector()
        ).build(from: fcpxml)

        XCTAssertNotNil(report.mediaSummary)
        // Document fallback still lists missing original-media when projection is empty.
        XCTAssertFalse(report.mediaSummary?.missingMediaPaths.isEmpty ?? true)
    }

    func testFailLoudThrowsProjectionFailedWhenProjectionThrows() async throws {
        let fcpxml = try parseInlineFCPXML(Self.simpleAssetClipXML)
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.mediaResolutionPolicy = .failLoud

        do {
            _ = try await FinalCutPro.FCPXML.ReportBuilder(
                options: options,
                timelineProjector: FailingTimelineProjector()
            ).build(from: fcpxml)
            XCTFail("Expected ReportError.projectionFailed")
        } catch let error as FinalCutPro.FCPXML.ReportError {
            guard case .projectionFailed = error else {
                XCTFail("Unexpected ReportError: \(error)")
                return
            }
        }
    }

    // MARK: - Media Summary proxy vs original

    func testMediaSummaryCombinedPathsByDefault() async throws {
        let fcpxml = try parseInlineFCPXML(Self.proxyAndOriginalXML)
        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.mediaSummaryDistinguishProxyAndOriginal = false
        options.mediaBaseURL = URL(fileURLWithPath: "/")

        let report = try await fcpxml.buildReport(options: options)
        let summary = try XCTUnwrap(report.mediaSummary)

        XCTAssertFalse(summary.distinguishProxyAndOriginal)
        XCTAssertTrue(summary.missingMediaPaths.contains { $0.contains("original-missing.mov") })
        XCTAssertTrue(summary.missingMediaPaths.contains { $0.contains("proxy-missing.mov") })
        XCTAssertFalse(summary.missingOriginalMediaPaths.isEmpty)
        XCTAssertFalse(summary.missingProxyMediaPaths.isEmpty)
    }

    func testMediaSummaryDistinguishProxyAndOriginalColumns() async throws {
        let fcpxml = try parseInlineFCPXML(Self.proxyAndOriginalXML)
        var options = FinalCutPro.FCPXML.ReportOptions.mediaSummaryOnly
        options.mediaSummaryDistinguishProxyAndOriginal = true
        options.mediaBaseURL = URL(fileURLWithPath: "/")

        let report = try await fcpxml.buildReport(options: options)
        let summary = try XCTUnwrap(report.mediaSummary)

        XCTAssertTrue(summary.distinguishProxyAndOriginal)
        XCTAssertTrue(summary.missingOriginalMediaPaths.contains { $0.contains("original-missing.mov") })
        XCTAssertTrue(summary.missingProxyMediaPaths.contains { $0.contains("proxy-missing.mov") })

        let planned = FCPXMLReportPDFSheetPlan.plannedSheets(from: report)
        XCTAssertTrue(planned.contains {
            $0.title == FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
        })
    }

    func testSourceFilePathExclusionAliasesIncludeProxyOriginalHeaders() {
        let excluded = FinalCutPro.FCPXML.ReportColumnExclusion.resolve([
            "Missing Original",
            "Missing Proxy"
        ])
        XCTAssertTrue(excluded.contains(.sourceFilePath))
    }

    // MARK: - Near-zero-miss corpus

    func testObligationCorpusBasicMarkersHasMarkerRows() async throws {
        let report = try await buildFullReport(sample: .basicMarkers)
        let markers = try XCTUnwrap(report.markers)
        XCTAssertFalse(markers.rows.isEmpty, "BasicMarkers must yield Markers sheet rows")
        for row in markers.rows {
            XCTAssertFalse(row.markerName.isEmpty)
            XCTAssertFalse(row.position.isEmpty)
        }
    }

    func testObligationCorpusKeywordsHasKeywordRows() async throws {
        let report = try await buildFullReport(sample: .keywords)
        let keywords = try XCTUnwrap(report.keywords)
        XCTAssertFalse(keywords.rows.isEmpty, "Keywords sample must yield Keywords sheet rows")
        for row in keywords.rows {
            XCTAssertFalse(row.keyword.isEmpty)
        }
    }

    func testObligationCorpusTitlesRolesHasTitleRows() async throws {
        let report = try await buildFullReport(sample: .titlesRoles)
        let titles = try XCTUnwrap(report.titlesAndGenerators)
        XCTAssertFalse(titles.rows.isEmpty, "TitlesRoles must yield Titles & Generators rows")
        for row in titles.rows {
            XCTAssertFalse(row.clipName.isEmpty)
        }
    }

    func testObligationCorpusRolesListHasInventoryRows() async throws {
        let report = try await buildFullReport(sample: .rolesList)
        let inventory = try XCTUnwrap(report.roleInventory)
        XCTAssertFalse(
            inventory.selectedRoles.isEmpty,
            "RolesList must yield Selected Roles Inventory rows"
        )
        for row in inventory.selectedRoles {
            XCTAssertFalse(row.clipName.isEmpty)
            XCTAssertFalse(row.roleSubrole.isEmpty)
        }
        let summary = try XCTUnwrap(report.summary)
        XCTAssertNotNil(summary.projectSummary)
        XCTAssertFalse(summary.projectSummary?.title.isEmpty ?? true)
    }

    func testObligationCorpusTransitionMarkersHasTransitionOrMarkerContent() async throws {
        let report = try await buildFullReport(sample: .transitionMarkers1)
        let hasTransitions = !(report.transitions?.rows.isEmpty ?? true)
        let hasMarkers = !(report.markers?.rows.isEmpty ?? true)
        XCTAssertTrue(
            hasTransitions || hasMarkers,
            "TransitionMarkers1 must contribute Transitions and/or Markers content"
        )
    }

    func testObligationCorpusComplexBuildsAllRequestedSections() async throws {
        let report = try await buildFullReport(sample: .complex)
        XCTAssertNotNil(report.roleInventory)
        XCTAssertNotNil(report.markers)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.mediaSummary)
        // Complex references media that is typically missing on CI → Media Summary may list paths.
        XCTAssertNotNil(report.mediaSummary?.missingMediaPaths)
    }

    // MARK: - Helpers

    private func buildFullReport(sample: FCPXMLSampleName) async throws -> FinalCutPro.FCPXML.Report {
        let fcpxml = try loadFCPXMLSample(named: sample.rawValue)
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
