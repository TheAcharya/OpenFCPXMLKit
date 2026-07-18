//
//  FCPXMLReportBuildPhaseTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Canonical report build-phase order and progress callback tests.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Report build phase")
struct FCPXMLReportBuildPhaseTests {

    @Test("Content cases match product section order")
    func contentCasesMatchProductSectionOrder() {
        #expect(
            FinalCutPro.FCPXML.ReportBuildPhase.contentCases.map(\.rawValue)
                == [
                    "Selected Roles Inventory",
                    "Markers",
                    "Keywords",
                    "Titles & Generators",
                    "Transitions",
                    "Video & Audio Effects",
                    "Speed Change Effects",
                    "Summary",
                    "Media Summary"
                ]
        )
    }

    @Test("Enabled phases for full options use product order")
    func enabledPhasesForFullOptionsUsesProductOrder() {
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(
            for: .full
        )

        #expect(phases == FinalCutPro.FCPXML.ReportBuildPhase.contentCases)
    }

    @Test("Enabled phases omit disabled sections")
    func enabledPhasesOmitsDisabledSections() {
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.includeKeywords = false
        options.includeTransitions = false
        options.includeMediaSummary = false

        let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)

        #expect(phases == [
            .roleInventory,
            .markers,
            .titlesAndGenerators,
            .effects,
            .speedChangeEffects,
            .summary
        ])
    }

    @Test("Enabled phases for role inventory only")
    func enabledPhasesForRoleInventoryOnly() {
        #expect(
            FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: .roleInventoryOnly)
                == [.roleInventory]
        )
    }

    @Test("Export pipeline phases include projecting and saves")
    func exportPipelinePhasesIncludesProjectingAndSaves() {
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.exportPipelinePhases(
            for: .roleInventoryOnly,
            includeWorkbookSave: true,
            includePDFSave: true
        )
        #expect(phases.first == .projecting)
        #expect(phases == [
            .projecting,
            .roleInventory,
            .savingWorkbook,
            .savingPDF
        ])
    }

    @Test("buildReport onPhaseStarted includes projecting then content")
    func buildReportOnPhaseStartedIncludesProjectingThenContent() async throws {
        let fcpxml = try requireFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"

        let expectedContent = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
        let observed = PhaseCollector()

        _ = try await fcpxml.buildReport(options: options) { phase in
            observed.append(phase)
        }

        let phases = observed.phases
        #expect(phases.first == .projecting)
        #expect(Array(phases.dropFirst()) == expectedContent)
        #expect(phases.last == .mediaSummary)
    }
}

private final class PhaseCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [FinalCutPro.FCPXML.ReportBuildPhase] = []

    func append(_ phase: FinalCutPro.FCPXML.ReportBuildPhase) {
        lock.lock()
        values.append(phase)
        lock.unlock()
    }

    var phases: [FinalCutPro.FCPXML.ReportBuildPhase] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}
