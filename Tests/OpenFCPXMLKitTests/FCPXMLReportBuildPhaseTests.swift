//
//  FCPXMLReportBuildPhaseTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Canonical report build-phase order and progress callback tests.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportBuildPhaseTests: XCTestCase, @unchecked Sendable {
    
    func testContentCasesMatchProductSectionOrder() {
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportBuildPhase.contentCases.map(\.rawValue),
            [
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
    
    func testEnabledPhasesForFullOptionsUsesProductOrder() {
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(
            for: .full
        )
        
        XCTAssertEqual(
            phases,
            FinalCutPro.FCPXML.ReportBuildPhase.contentCases
        )
    }
    
    func testEnabledPhasesOmitsDisabledSections() {
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.includeKeywords = false
        options.includeTransitions = false
        options.includeMediaSummary = false
        
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
        
        XCTAssertEqual(phases, [
            .roleInventory,
            .markers,
            .titlesAndGenerators,
            .effects,
            .speedChangeEffects,
            .summary
        ])
    }
    
    func testEnabledPhasesForRoleInventoryOnly() {
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: .roleInventoryOnly),
            [.roleInventory]
        )
    }

    func testExportPipelinePhasesIncludesProjectingAndSaves() {
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.exportPipelinePhases(
            for: .roleInventoryOnly,
            includeWorkbookSave: true,
            includePDFSave: true
        )
        XCTAssertEqual(phases.first, .projecting)
        XCTAssertEqual(phases, [
            .projecting,
            .roleInventory,
            .savingWorkbook,
            .savingPDF
        ])
    }
    
    func testBuildReportOnPhaseStartedIncludesProjectingThenContent() async throws {
        let fcpxml = try loadFCPXMLSample(named: "24")
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.workbookCoverSheet = nil
        options.projectName = "24_V1"
        
        let expectedContent = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: options)
        let observed = PhaseCollector()
        
        _ = try await fcpxml.buildReport(options: options) { phase in
            observed.append(phase)
        }
        
        let phases = observed.phases
        XCTAssertEqual(phases.first, .projecting)
        XCTAssertEqual(Array(phases.dropFirst()), expectedContent)
        XCTAssertEqual(phases.last, .mediaSummary)
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
