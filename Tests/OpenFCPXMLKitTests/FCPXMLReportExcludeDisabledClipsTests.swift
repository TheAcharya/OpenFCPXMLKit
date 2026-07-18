//
//  FCPXMLReportExcludeDisabledClipsTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for omitting disabled clips from report extraction.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Report exclude disabled clips")
struct FCPXMLReportExcludeDisabledClipsTests {

    @Test("Omits disabled titles from report")
    func excludeDisabledClipsOmitsDisabledTitlesFromReport() async throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")

        var includingDisabled = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        includingDisabled.excludeDisabledClips = false

        var excludingDisabled = FinalCutPro.FCPXML.ReportOptions.titlesAndGeneratorsOnly
        excludingDisabled.excludeDisabledClips = true

        let reportWithDisabled = try await fcpxml.buildReport(options: includingDisabled)
        let reportWithoutDisabled = try await fcpxml.buildReport(options: excludingDisabled)

        let withDisabledCount = reportWithDisabled.titlesAndGenerators?.rows.count ?? 0
        let withoutDisabledCount = reportWithoutDisabled.titlesAndGenerators?.rows.count ?? 0

        #expect(withDisabledCount > withoutDisabledCount)
        let stillHasDisabledMark =
            reportWithoutDisabled.titlesAndGenerators?.rows.contains { $0.enabled == "✗" } ?? false
        #expect(!stillHasDisabledMark)
    }

    @Test("Omits disabled clips from role inventory")
    func excludeDisabledClipsOmitsDisabledClipsFromRoleInventory() async throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")

        var includingDisabled = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        includingDisabled.excludeDisabledClips = false

        var excludingDisabled = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        excludingDisabled.excludeDisabledClips = true

        let reportWithDisabled = try await fcpxml.buildReport(options: includingDisabled)
        let reportWithoutDisabled = try await fcpxml.buildReport(options: excludingDisabled)

        let withDisabledCount = reportWithDisabled.roleInventory?.selectedRoles.count ?? 0
        let withoutDisabledCount = reportWithoutDisabled.roleInventory?.selectedRoles.count ?? 0

        #expect(withDisabledCount > withoutDisabledCount)
        let stillHasDisabledMark =
            reportWithoutDisabled.roleInventory?.selectedRoles.contains { $0.enabled == "✗" } ?? false
        #expect(!stillHasDisabledMark)
    }

    @Test("Omits disabled markers from report")
    func excludeDisabledClipsOmitsDisabledMarkersFromReport() async throws {
        let fcpxml = try requireFCPXMLSample(named: "DisabledClips")

        var includingDisabled = FinalCutPro.FCPXML.ReportOptions()
        includingDisabled.includeMarkers = true
        includingDisabled.includeRoleInventory = false
        includingDisabled.excludeDisabledClips = false

        var excludingDisabled = includingDisabled
        excludingDisabled.excludeDisabledClips = true

        let reportWithDisabled = try await fcpxml.buildReport(options: includingDisabled)
        let reportWithoutDisabled = try await fcpxml.buildReport(options: excludingDisabled)

        let withCount = reportWithDisabled.markers?.rows.count ?? 0
        let withoutCount = reportWithoutDisabled.markers?.rows.count ?? 0
        #expect(withCount >= withoutCount)
    }
}
