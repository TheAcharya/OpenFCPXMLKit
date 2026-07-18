//
//  FCPXMLReportPDFExportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF export tests for structured FCPXML reports.
//

import Foundation
import OpenFCPXMLKit
import XCTest
#if canImport(PDFKit)
import PDFKit
#endif

@available(macOS 26.0, *)
final class FCPXMLReportPDFExportTests: XCTestCase, @unchecked Sendable {
    
    func testMakePDFDataFromSyntheticMarkersReportStartsWithPDFHeader() throws {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test Project",
            eventName: "Test Event",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Scene 1",
                    type: .standard,
                    notes: "Note",
                    position: "00:00:10:00",
                    clipName: "Clip A",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1",
                    sourcePosition: "00:00:05:00"
                )
            ])
        )
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        XCTAssertGreaterThan(data.count, 0)
        
        let prefix = String(data: data.prefix(4), encoding: .ascii)
        XCTAssertEqual(prefix, "%PDF")
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else {
            XCTFail("Expected valid PDF document")
            return
        }
        
        let markersPageIndex = document.pageCount > 2 ? 2 : 1
        guard let markersPageText = document.page(at: markersPageIndex)?.string else {
            XCTFail("Expected markers content page")
            return
        }
        
        for header in FinalCutPro.FCPXML.MarkerReportRow.columnHeaders {
            XCTAssertTrue(
                markersPageText.contains(header),
                "Expected table header \"\(header)\" to be visible in PDF text extraction"
            )
        }
        #endif
    }
    
    func testExportSyntheticSummaryReportWritesPDFFile() throws {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Summary Project",
            summary: FinalCutPro.FCPXML.SummaryReportSection(
                projectSummary: FinalCutPro.FCPXML.ProjectSummary(
                    title: "Summary Project",
                    duration: "00:05:00:00",
                    resolution: "1920x1080",
                    frameRate: "25 fps",
                    audioSampleRate: "48 kHz"
                ),
                roleDurations: [
                    FinalCutPro.FCPXML.SummaryRoleDurationRow(
                        roleSubrole: "Dialogue",
                        estimatedTotal: "00:02:00:00",
                        percentOfTotal: 40
                    )
                ]
            )
        )
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-Summary-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        let data = try Data(contentsOf: outputURL)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
    }
    
    func testExportSyntheticMediaSummaryReportWritesPDFFile() throws {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Media Project",
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: [
                    "/Volumes/Media/clip001.mov",
                    "/Volumes/Media/clip002.wav"
                ]
            )
        )
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-MediaSummary-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }
    
    func testExportMarkersReportWritesPDFFileFromFixture() async throws {
        let fcpxml = try FCPXMLReportingReportFixture.loadFCPXML()
        
        let report = try await fcpxml.buildReport(
            options: try FCPXMLReportingReportFixture.reportOptions {
                $0.includeMarkers = true
            }
        )
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-Markers-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = attributes[.size] as? NSNumber
        XCTAssertGreaterThan(fileSize?.intValue ?? 0, 0)
    }
    
    func testExportMarkersReportFromBasicMarkersSampleWritesPDFFile() async throws {
        let fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)
        
        var options = FinalCutPro.FCPXML.ReportOptions(
            includeMarkers: true,
            includeRoleInventory: false
        )
        options.projectName = fcpxml.allProjects().first?.name
        options.includeMarkersOutsideClipBoundaries = true
        
        let report = try await fcpxml.buildReport(options: options)
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-BasicMarkers-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        
        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        let data = try Data(contentsOf: outputURL)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
    }
    
    func testWideMarkersTableProducesMultiPagePDF() throws {
        let rows = (1...40).map { index in
            FinalCutPro.FCPXML.MarkerReportRow(
                markerName: "Marker \(index)",
                type: .standard,
                notes: "Note for marker \(index) with additional detail",
                position: "00:00:\(String(format: "%02d", index % 60)):00",
                clipName: "Clip \(index)",
                roleSubrole: "Dialogue ▸ Main",
                reel: "A\(index)",
                scene: "\(index)",
                sourcePosition: "00:00:\(String(format: "%02d", index % 60)):00"
            )
        }
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Wide Table",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: rows)
        )
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        XCTAssertGreaterThan(data.count, 4_000, "Wide tables should produce multi-page PDF output")
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else {
            XCTFail("Expected valid PDF document")
            return
        }
        
        var foundRowOnContinuationPage = false
        for pageIndex in 1..<document.pageCount {
            guard let pageText = document.page(at: pageIndex)?.string else { continue }
            if pageText.contains("Row"), pageText.contains("Marker 25") {
                foundRowOnContinuationPage = true
                break
            }
        }
        
        XCTAssertTrue(
            foundRowOnContinuationPage,
            "Expected Row column with stable row numbers on marker continuation pages"
        )
        #endif
    }
    
    func testWideMarkersTableOmitsRowWhenExcluded() throws {
        let rows = (1...40).map { index in
            FinalCutPro.FCPXML.MarkerReportRow(
                markerName: "Marker \(index)",
                type: .standard,
                notes: "Note for marker \(index) with additional detail",
                position: "00:00:\(String(format: "%02d", index % 60)):00",
                clipName: "Clip \(index)",
                roleSubrole: "Dialogue ▸ Main",
                reel: "A\(index)",
                scene: "\(index)",
                sourcePosition: "00:00:\(String(format: "%02d", index % 60)):00"
            )
        }
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Wide Table",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: rows),
            excludedColumns: [.row]
        )
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else {
            XCTFail("Expected valid PDF document")
            return
        }
        
        // Cover notes may mention "Row"; assert marker continuation pages never include the column.
        var foundMarkerContinuationWithoutRow = false
        for pageIndex in 1..<document.pageCount {
            guard let pageText = document.page(at: pageIndex)?.string else { continue }
            if pageText.contains("Marker 25") {
                XCTAssertFalse(
                    pageText.contains("Row"),
                    "Excluded Row must not appear on marker continuation pages"
                )
                foundMarkerContinuationWithoutRow = true
                break
            }
        }
        
        XCTAssertTrue(
            foundMarkerContinuationWithoutRow,
            "Expected Marker 25 on a continuation page for exclusion assertion"
        )
        #else
        XCTAssertGreaterThan(data.count, 4_000)
        #endif
    }
    
    func testCoverPageOnlyReportProducesMinimalPDF() throws {
        let report = FinalCutPro.FCPXML.Report(projectName: "Cover Only")
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        XCTAssertGreaterThan(data.count, 100)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "%PDF")
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data),
              let coverText = document.page(at: 0)?.string
        else {
            XCTFail("Expected cover page text")
            return
        }
        
        XCTAssertTrue(coverText.contains(FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.brandingText))
        XCTAssertTrue(coverText.contains("About This PDF Export"))
        XCTAssertTrue(coverText.contains("experimental"))
        XCTAssertTrue(coverText.contains("truncate"))
        XCTAssertTrue(coverText.contains("Excel (.xlsx)"))
        #endif
    }
    
    func testCustomWorkbookCoverSheetBrandingAppearsInPDFCoverAndFooter() throws {
        let branding = "Exported by My Studio"
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Branded Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Marker 1",
                    type: .standard,
                    notes: "Note",
                    position: "00:00:10:00",
                    clipName: "Clip A",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1",
                    sourcePosition: "00:00:05:00"
                )
            ]),
            workbookCoverSheet: FinalCutPro.FCPXML.ReportWorkbookCoverSheet(
                title: "My Studio",
                headerText: branding
            )
        )
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else {
            XCTFail("Expected valid PDF document")
            return
        }
        
        XCTAssertEqual(report.exportBrandingText, branding)
        XCTAssertTrue(document.page(at: 0)?.string?.contains(branding) == true)
        
        let contentPageIndex = document.pageCount > 2 ? 2 : 1
        XCTAssertTrue(document.page(at: contentPageIndex)?.string?.contains(branding) == true)
        #endif
    }
    
    func testCopyrightLabelAppearsOnPDFCoverAndCenteredFooter() throws {
        let branding = FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.brandingText
        let copyright = "© 2026 Example Studios"
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Copyright Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Marker 1",
                    type: .standard,
                    notes: "Note",
                    position: "00:00:10:00",
                    clipName: "Clip A",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1",
                    sourcePosition: "00:00:05:00"
                )
            ]),
            workbookCoverSheet: .openFCPXMLKitDefault,
            copyrightLabel: copyright
        )
        
        XCTAssertEqual(report.copyrightLabel, copyright)
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else {
            XCTFail("Expected valid PDF document")
            return
        }
        
        let coverText = document.page(at: 0)?.string ?? ""
        XCTAssertTrue(coverText.contains(branding))
        XCTAssertTrue(coverText.contains(copyright))
        
        let contentPageIndex = document.pageCount > 2 ? 2 : 1
        let contentText = document.page(at: contentPageIndex)?.string ?? ""
        XCTAssertTrue(contentText.contains(branding))
        XCTAssertTrue(contentText.contains(copyright))
        #endif
    }
    
    func testRoleInventoryReportIncludesTableOfContentsWithoutLinks() throws {
        let clipRow = FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: "Dialogue",
            clipName: "Clip A",
            category: "Primary clip",
            enabled: "Yes",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:05:00",
            clipDuration: "00:00:05:00",
            sourceIn: "01:00:00:00",
            sourceOut: "01:00:05:00",
            sourceDuration: "00:00:05:00"
        )
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "TOC Project",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Marker 1",
                    type: .standard,
                    notes: "Note",
                    position: "00:00:10:00",
                    clipName: "Clip A",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1",
                    sourcePosition: "00:00:05:00"
                )
            ]),
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [clipRow],
                roleSheets: [
                    FinalCutPro.FCPXML.RoleSheet(
                        sheetName: "Dialogue",
                        rows: [clipRow]
                    )
                ]
            )
        )
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else {
            XCTFail("Expected valid PDF document")
            return
        }
        
        guard let tocPage = document.page(at: 1), let tocText = tocPage.string else {
            XCTFail("Expected table of contents page")
            return
        }
        
        XCTAssertTrue(tocText.contains("Table of Contents"))
        XCTAssertTrue(tocText.contains("Sheet"))
        XCTAssertTrue(tocText.contains("Page"))
        XCTAssertTrue(tocText.contains("Selected Roles Inventory"))
        XCTAssertTrue(tocText.contains("Dialogue"))
        XCTAssertTrue(tocText.contains("Markers"))
        XCTAssertFalse(tocText.contains("...."))
        #endif
    }
    
    func testFullReportIncludesAllWorkbookSectionsInPDF() throws {
        let effectRow = FinalCutPro.FCPXML.EffectReportRow(
            effect: "Blur",
            settings: "Amount 50",
            enabled: "Yes",
            isApple: "No",
            clipName: "Clip A",
            roleSubrole: "Video",
            timelineIn: "00:00:01:00",
            timelineOut: "00:00:05:00"
        )
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Full Report",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: [
                FinalCutPro.FCPXML.MarkerReportRow(
                    markerName: "Marker 1",
                    type: .standard,
                    notes: "Note",
                    position: "00:00:10:00",
                    clipName: "Clip A",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1",
                    sourcePosition: "00:00:05:00"
                )
            ]),
            keywords: FinalCutPro.FCPXML.KeywordsReportSection(rows: [
                FinalCutPro.FCPXML.KeywordReportRow(
                    keyword: "Hero",
                    notes: "Note",
                    timelineIn: "00:00:01:00",
                    timelineOut: "00:00:05:00",
                    duration: "00:00:04:00",
                    clipName: "Clip A",
                    roleSubrole: "Video",
                    reel: "A001",
                    scene: "1"
                )
            ]),
            titlesAndGenerators: FinalCutPro.FCPXML.TitlesReportSection(rows: [
                FinalCutPro.FCPXML.TitleReportRow(
                    clipName: "Lower Third",
                    enabled: "Yes",
                    isApple: "Yes",
                    roleSubrole: "Titles",
                    timelineIn: "00:00:01:00",
                    timelineOut: "00:00:05:00",
                    duration: "00:00:04:00",
                    font: "Helvetica",
                    titleText: "Hello"
                )
            ]),
            transitions: FinalCutPro.FCPXML.TransitionsReportSection(rows: [
                FinalCutPro.FCPXML.TransitionReportRow(
                    transition: "Cross Dissolve",
                    category: "Video",
                    isApple: "Yes",
                    timelineIn: "00:00:01:00",
                    timelineOut: "00:00:02:00",
                    duration: "00:00:01:00"
                )
            ]),
            effects: FinalCutPro.FCPXML.EffectsReportSection(rows: [effectRow]),
            speedChangeEffects: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection(rows: [effectRow]),
            summary: FinalCutPro.FCPXML.SummaryReportSection(
                projectSummary: FinalCutPro.FCPXML.ProjectSummary(
                    title: "Full Report",
                    duration: "00:05:00:00",
                    resolution: "1920x1080",
                    frameRate: "25 fps",
                    audioSampleRate: "48 kHz"
                )
            ),
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(
                missingMediaPaths: ["/Volumes/Media/missing.mov"]
            ),
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [
                    FinalCutPro.FCPXML.RoleClipReportRow(
                        roleSubrole: "Dialogue",
                        clipName: "Clip A",
                        category: "Primary clip",
                        enabled: "Yes",
                        timelineIn: "00:00:00:00",
                        timelineOut: "00:00:05:00",
                        clipDuration: "00:00:05:00",
                        sourceIn: "01:00:00:00",
                        sourceOut: "01:00:05:00",
                        sourceDuration: "00:00:05:00"
                    )
                ]
            )
        )
        
        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data),
              let tocText = document.page(at: 1)?.string
        else {
            XCTFail("Expected table of contents page")
            return
        }
        
        let expectedSheets = [
            FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName,
            FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName,
            FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName,
            FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName,
            FinalCutPro.FCPXML.SummaryReportSection.defaultSheetName,
            FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName,
        ]
        
        for sheet in expectedSheets {
            XCTAssertTrue(tocText.contains(sheet), "Expected TOC to include \(sheet)")
        }
        
        var combinedContent = ""
        for pageIndex in 2..<document.pageCount {
            combinedContent += document.page(at: pageIndex)?.string ?? ""
        }
        
        XCTAssertTrue(combinedContent.contains("Hero"))
        XCTAssertTrue(combinedContent.contains("Lower Third"))
        XCTAssertTrue(combinedContent.contains("Cross Dissolve"))
        XCTAssertTrue(combinedContent.contains("Blur"))
        XCTAssertTrue(combinedContent.contains("/Volumes/Media/missing.mov"))
        #endif
    }
}
