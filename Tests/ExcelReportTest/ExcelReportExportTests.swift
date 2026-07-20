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
import Testing
#if canImport(PDFKit)
import PDFKit
#endif

@Suite("Excel report export")
struct ExcelReportExportTests {
    
    /// Writes `Output/OFK-Default.xlsx` (role inventory only) and `Output/OFK-Full.xlsx` (all sheets).
    @Test("Export default and full workbooks")
    func exportDefaultAndFullWorkbooks() async throws {
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
        
        #expect(defaultReport.roleInventory != nil)
        #expect(defaultReport.keywords == nil)
        #expect(defaultReport.markers == nil)
        
        #expect(fullReport.roleInventory != nil)
        #expect(fullReport.markers != nil)
        #expect(fullReport.keywords != nil)
        #expect(fullReport.titlesAndGenerators != nil)
        #expect(fullReport.transitions != nil)
        #expect(fullReport.nonStandardEffectsTemplates != nil)
        #expect(fullReport.effects != nil)
        #expect(fullReport.speedChangeEffects != nil)
        #expect(fullReport.summary != nil)
        #expect(fullReport.mediaSummary != nil)
    }
    
    /// Writes `Output/OFK-Default.pdf` from the role-inventory report for manual PDF review.
    @Test("Export default role inventory PDF")
    func exportDefaultRoleInventoryPDF() async throws {
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
        #expect(String(data: data.prefix(4), encoding: .ascii) == "%PDF")
        #expect(data.count > 5_000, "Role inventory PDF should contain readable multi-page output")
    }
    
    /// Writes `Output/OFK-ExcludedColumns.pdf` — many columns excluded so remaining widths must expand.
    @Test("Export role inventory PDF with many excluded columns")
    func exportRoleInventoryPDFWithManyExcludedColumns() async throws {
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
        #expect(!report.excludedColumns.isEmpty)
        
        let outputURL = outputDir.appendingPathComponent("OFK-ExcludedColumns.pdf")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        let data = try Data(contentsOf: outputURL)
        #expect(String(data: data.prefix(4), encoding: .ascii) == "%PDF")
        #expect(
            data.count > 5_000,
            "Excluded-column PDF should still contain a readable multi-page role inventory"
        )
    }
    
    /// Writes `Output/OFK-Copyright.xlsx` and `Output/OFK-Copyright.pdf` with `--label-copyright` parity.
    @Test("Export role inventory with copyright label")
    @MainActor
    func exportRoleInventoryWithCopyrightLabel() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let copyright = "© 2026 Example Studios"
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.copyrightLabel = copyright
        
        let report = try await loadReport(options: options, fixtureURL: fixtureURL)
        #expect(report.copyrightLabel == copyright)
        
        let xlsxURL = try await writeWorkbook(
            report,
            named: ExcelReportFixture.copyrightOutputXLSXFileName,
            to: outputDir
        )
        try assertWorkbookExists(at: xlsxURL)
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let coverName = FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.title
        let coverSheet = workbook.getSheet(name: coverName)
        #expect(
            coverSheet?.getCellWithFormat("A1")?.value.stringValue
                == FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.headerText
        )
        #expect(coverSheet?.getCellWithFormat("A2")?.value.stringValue == copyright)
        
        let pdfURL = outputDir.appendingPathComponent(ExcelReportFixture.copyrightOutputPDFFileName)
        if FileManager.default.fileExists(atPath: pdfURL.path) {
            try FileManager.default.removeItem(at: pdfURL)
        }
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: pdfURL)
        
        let pdfData = try Data(contentsOf: pdfURL)
        #expect(String(data: pdfData.prefix(4), encoding: .ascii) == "%PDF")
        #expect(pdfData.count > 5_000)
        
        #if canImport(PDFKit)
        let document = try #require(PDFDocument(data: pdfData))
        let coverText = document.page(at: 0)?.string ?? ""
        #expect(coverText.contains(copyright), "Cover should include copyright label")
        let footerPageIndex = min(2, max(0, document.pageCount - 1))
        let footerPageText = document.page(at: footerPageIndex)?.string ?? ""
        #expect(
            footerPageText.contains(copyright),
            "Content/footer page should include copyright label"
        )
        #endif
    }
    
    /// Writes `Output/OFK-OutsideClipBoundaries.xlsx` / `.pdf` with
    /// `--include-markers-outside-clip-boundaries` parity (Hidden column on Markers).
    @Test("Export markers including outside clip boundaries")
    @MainActor
    func exportMarkersIncludingOutsideClipBoundaries() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        var defaultOptions = FinalCutPro.FCPXML.ReportOptions.markersOnly
        defaultOptions.includeChapterMarkersInMarkersReport = true
        let defaultMarkersReport = try await loadReport(
            options: defaultOptions,
            fixtureURL: fixtureURL
        )
        let defaultMarkers = try #require(defaultMarkersReport.markers)
        #expect(
            !defaultMarkers.showsHiddenColumn,
            "Default Markers sheet must omit the Hidden column"
        )
        #expect(!defaultMarkers.columnHeaders().contains("Hidden"))
        
        var includeOptions = FinalCutPro.FCPXML.ReportOptions.markersOnly
        includeOptions.includeChapterMarkersInMarkersReport = true
        includeOptions.includeMarkersOutsideClipBoundaries = true
        // Keep role inventory off for a focused Markers workbook, but still write a cover sheet.
        let includeReport = try await loadReport(options: includeOptions, fixtureURL: fixtureURL)
        let includeMarkers = try #require(includeReport.markers)
        
        #expect(includeMarkers.showsHiddenColumn)
        #expect(includeMarkers.columnHeaders().last == "Hidden")
        #expect(
            includeMarkers.rows.count >= defaultMarkers.rows.count,
            "Opt-in must not drop in-bounds markers and may add out-of-bounds rows"
        )
        
        let hiddenValues = Set(
            includeMarkers.rows.map { includeMarkers.columnValues(for: $0).last ?? "" }
        )
        #expect(
            hiddenValues.isSubset(of: ["✓", "✗"]),
            "Hidden column cells must be ✓ or ✗"
        )
        if includeMarkers.rows.count > defaultMarkers.rows.count {
            let hasHiddenRow = includeMarkers.rows.contains { $0.isHidden }
            #expect(
                hasHiddenRow,
                "Extra rows from opt-in should be marked Hidden"
            )
        }
        
        let xlsxURL = try await writeWorkbook(
            includeReport,
            named: ExcelReportFixture.outsideClipBoundariesOutputXLSXFileName,
            to: outputDir
        )
        try assertWorkbookExists(at: xlsxURL)
        
        let pdfURL = outputDir.appendingPathComponent(
            ExcelReportFixture.outsideClipBoundariesOutputPDFFileName
        )
        if FileManager.default.fileExists(atPath: pdfURL.path) {
            try FileManager.default.removeItem(at: pdfURL)
        }
        try FinalCutPro.FCPXML.ReportPDFExport.export(includeReport, to: pdfURL)
        
        let pdfData = try Data(contentsOf: pdfURL)
        #expect(String(data: pdfData.prefix(4), encoding: .ascii) == "%PDF")
        #expect(pdfData.count > 5_000)
    }
    
    /// Writes `Output/OFK-ProtectedSheets.xlsx` with worksheet protection on every sheet
    /// (CLI `--protect-sheets` parity). Excel only — PDF is unaffected.
    @Test("Export protected sheets workbook")
    @MainActor
    func exportProtectedSheetsWorkbook() async throws {
        let fixtureURL = try ExcelReportFixture.requireFixtureURL()
        let outputDir = ExcelReportFixture.outputDirectoryURL()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.protectSheets = true
        let report = try await loadReport(options: options, fixtureURL: fixtureURL)
        #expect(report.protectSheets)
        
        let workbook = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
        let sheets = workbook.getSheets()
        #expect(!sheets.isEmpty)
        for sheet in sheets {
            #expect(
                sheet.protection != nil,
                "Sheet '\(sheet.name)' should be protected"
            )
        }
        
        let xlsxURL = try await writeWorkbook(
            report,
            named: ExcelReportFixture.protectedSheetsOutputXLSXFileName,
            to: outputDir
        )
        try assertWorkbookExists(at: xlsxURL)
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
        #expect(
            FileManager.default.fileExists(atPath: url.path),
            "Expected workbook at \(url.path)"
        )
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? NSNumber
        #expect(
            (fileSize?.intValue ?? 0) > 0,
            "Workbook at \(url.lastPathComponent) is empty"
        )
    }
}


