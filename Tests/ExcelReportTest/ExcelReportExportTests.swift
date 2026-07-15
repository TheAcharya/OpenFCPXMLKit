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
#if canImport(PDFKit)
import PDFKit
#endif

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
        XCTAssertNotNil(fullReport.mediaSummary)
    }
    
    /// Writes `Output/OFK-Default.pdf` from the role-inventory report for manual PDF review.
    func testExportDefaultRoleInventoryPDF() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let report = try await loadReport(options: .roleInventoryOnly, fixtureURL: fixtureURL)
        let outputURL = outputDir.appendingPathComponent("OFK-Default.pdf")
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        let data = try Data(contentsOf: outputURL)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
        XCTAssertGreaterThan(data.count, 5_000, "Role inventory PDF should contain readable multi-page output")
    }
    
    /// Writes `Output/OFK-ExcludedColumns.pdf` — many columns excluded so remaining widths must expand.
    func testExportRoleInventoryPDFWithManyExcludedColumns() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.excludedColumns = [
            "Reel",
            "Scene",
            "Take",
            "Camera Angle",
            "Camera Name",
            "Notes",
            "Source File Name",
            "Source File Path",
            "Library Name",
            "Event Name",
            "Project Name",
            "Keywords",
            "Markers",
            "Metadata",
        ]
        
        let report = try await loadReport(options: options, fixtureURL: fixtureURL)
        XCTAssertFalse(report.excludedColumns.isEmpty)
        
        let outputURL = outputDir.appendingPathComponent("OFK-ExcludedColumns.pdf")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        let data = try Data(contentsOf: outputURL)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
        XCTAssertGreaterThan(
            data.count,
            5_000,
            "Excluded-column PDF should still contain a readable multi-page role inventory"
        )
    }
    
    /// Writes `Output/OFK-Copyright.xlsx` and `Output/OFK-Copyright.pdf` with `--label-copyright` parity.
    @MainActor
    func testExportRoleInventoryWithCopyrightLabel() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let copyright = "© 2026 Example Studios"
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.copyrightLabel = copyright
        
        let report = try await loadReport(options: options, fixtureURL: fixtureURL)
        XCTAssertEqual(report.copyrightLabel, copyright)
        
        let xlsxURL = try await writeWorkbook(
            report,
            named: ExcelReportFixture.copyrightOutputXLSXFileName,
            to: outputDir
        )
        try assertWorkbookExists(at: xlsxURL)
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let coverName = FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.title
        let coverSheet = workbook.getSheet(name: coverName)
        XCTAssertEqual(
            coverSheet?.getCellWithFormat("A1")?.value.stringValue,
            FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.headerText
        )
        XCTAssertEqual(coverSheet?.getCellWithFormat("A2")?.value.stringValue, copyright)
        
        let pdfURL = outputDir.appendingPathComponent(ExcelReportFixture.copyrightOutputPDFFileName)
        if FileManager.default.fileExists(atPath: pdfURL.path) {
            try FileManager.default.removeItem(at: pdfURL)
        }
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)
        
        let pdfData = try Data(contentsOf: pdfURL)
        XCTAssertEqual(String(data: pdfData.prefix(4), encoding: .ascii), "%PDF")
        XCTAssertGreaterThan(pdfData.count, 5_000)
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: pdfData) else {
            XCTFail("Expected valid copyright-labelled PDF")
            return
        }
        let coverText = document.page(at: 0)?.string ?? ""
        XCTAssertTrue(coverText.contains(copyright), "Cover should include copyright label")
        let footerPageIndex = min(2, max(0, document.pageCount - 1))
        let footerPageText = document.page(at: footerPageIndex)?.string ?? ""
        XCTAssertTrue(
            footerPageText.contains(copyright),
            "Content/footer page should include copyright label"
        )
        #endif
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
                ?? fcpxml.allReportTimelineSources().first?.displayName
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
