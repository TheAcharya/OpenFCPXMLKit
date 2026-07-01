//
//  ExcelReportExportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Exports Default and Full Excel workbooks from the local Sample.fcpxmld fixture.
//

import Foundation
import OpenFCPXMLKit
import XCTest

@available(macOS 26.0, *)
final class ExcelReportExportTests: XCTestCase, @unchecked Sendable {
    
    /// Writes `Output/OFK-Default.xlsx` (role inventory only) and `Output/OFK-Full.xlsx` (all sheets).
    func testExportDefaultAndFullWorkbooks() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let defaultReport = try await loadReport(options: .roleInventoryOnly, fixtureURL: fixtureURL)
        let fullReport = try await loadReport(options: .full, fixtureURL: fixtureURL)
        
        let defaultURL = try await writeWorkbook(
            defaultReport,
            named: ExcelReportFixture.defaultOutputFileName,
            to: outputDir
        )
        let fullURL = try await writeWorkbook(
            fullReport,
            named: ExcelReportFixture.fullOutputFileName,
            to: outputDir
        )
        
        try assertWorkbookExists(at: defaultURL)
        try assertWorkbookExists(at: fullURL)
        
        XCTAssertNotNil(defaultReport.roleInventory)
        XCTAssertNil(defaultReport.keywords)
        XCTAssertNil(defaultReport.markers)
        
        XCTAssertNotNil(fullReport.roleInventory)
        XCTAssertNotNil(fullReport.markers)
        XCTAssertNotNil(fullReport.keywords)
        XCTAssertNotNil(fullReport.titlesAndGenerators)
        XCTAssertNotNil(fullReport.transitions)
        XCTAssertNotNil(fullReport.effects)
        XCTAssertNotNil(fullReport.speedChangeEffects)
        XCTAssertNotNil(fullReport.summary)
    }
    
    @MainActor
    private func writeWorkbook(
        _ report: FinalCutPro.FCPXML.Report,
        named fileName: String,
        to outputDir: URL
    ) async throws -> URL {
        let outputURL = outputDir.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: outputURL)
        return outputURL
    }
    
    private func loadReport(
        options: FinalCutPro.FCPXML.ReportOptions,
        fixtureURL: URL
    ) async throws -> FinalCutPro.FCPXML.Report {
        let loader = FCPXMLFileLoader()
        let document = try loader.loadFCPXMLDocument(from: fixtureURL)
        let fcpxml = FinalCutPro.FCPXML(fileContent: document)
        
        var reportOptions = options
        reportOptions.mediaBaseURL = ExcelReportFixture.mediaBaseURL(for: fixtureURL)
        if reportOptions.projectName == nil {
            reportOptions.projectName = fcpxml.allProjects().first?.name
        }
        
        return try await fcpxml.buildReport(options: reportOptions)
    }
    
    private func assertWorkbookExists(at url: URL) throws {
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: url.path),
            "Expected workbook at \(url.path)"
        )
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? NSNumber
        XCTAssertGreaterThan(fileSize?.intValue ?? 0, 0, "Workbook at \(url.lastPathComponent) is empty")
    }
}
