//
//  FCPXMLReportPDFExportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF export tests for structured FCPXML reports.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit
#if canImport(PDFKit)
import PDFKit
#endif

@Suite("Report PDF export")
struct FCPXMLReportPDFExportTests {

    @Test("Make PDF data from synthetic markers report starts with PDF header")
    func makePDFDataFromSyntheticMarkersReportStartsWithPDFHeader() throws {
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
        #expect(data.count > 0)

        let prefix = String(data: data.prefix(4), encoding: .ascii)
        #expect(prefix == "%PDF")

        #if canImport(PDFKit)
        let document = try #require(PDFDocument(data: data))

        let markersPageIndex = document.pageCount > 2 ? 2 : 1
        let markersPageText = try #require(document.page(at: markersPageIndex)?.string)

        for header in FinalCutPro.FCPXML.MarkerReportRow.columnHeaders {
            let containsHeader = markersPageText.contains(header)
            #expect(
                containsHeader,
                "Expected table header \"\(header)\" to be visible in PDF text extraction"
            )
        }
        #endif
    }

    @Test("Export synthetic Summary report writes PDF file")
    func exportSyntheticSummaryReportWritesPDFFile() throws {
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

        #expect(FileManager.default.fileExists(atPath: outputURL.path))

        let data = try Data(contentsOf: outputURL)
        #expect(String(data: data.prefix(4), encoding: .ascii) == "%PDF")
    }

    @Test("Export synthetic Media Summary report writes PDF file")
    func exportSyntheticMediaSummaryReportWritesPDFFile() throws {
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

        #expect(FileManager.default.fileExists(atPath: outputURL.path))
    }

    @Test("Export markers report writes PDF file from fixture")
    func exportMarkersReportWritesPDFFileFromFixture() async throws {
        let fcpxml = try requireReportingFixtureFCPXML()

        var options = FinalCutPro.FCPXML.ReportOptions()
        options.projectName = FCPXMLReportingReportFixture.primaryProjectName(in: fcpxml)
        options.includeMarkers = true

        let report = try await fcpxml.buildReport(options: options)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-Markers-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        try FinalCutPro.FCPXML.ReportPDFExport.export(report, to: outputURL)

        #expect(FileManager.default.fileExists(atPath: outputURL.path))

        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = attributes[.size] as? NSNumber
        #expect((fileSize?.intValue ?? 0) > 0)
    }

    @Test("Export markers report from BasicMarkers sample writes PDF file")
    func exportMarkersReportFromBasicMarkersSampleWritesPDFFile() async throws {
        let fcpxml = try requireFCPXMLSample(named: FCPXMLSampleName.basicMarkers.rawValue)

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

        #expect(FileManager.default.fileExists(atPath: outputURL.path))
        let data = try Data(contentsOf: outputURL)
        #expect(String(data: data.prefix(4), encoding: .ascii) == "%PDF")
    }

    @Test("Wide markers table produces multi-page PDF")
    func wideMarkersTableProducesMultiPagePDF() throws {
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
        #expect(data.count > 4_000, "Wide tables should produce multi-page PDF output")

        #if canImport(PDFKit)
        let document = try #require(PDFDocument(data: data))

        var foundRowOnContinuationPage = false
        for pageIndex in 1..<document.pageCount {
            guard let pageText = document.page(at: pageIndex)?.string else { continue }
            if pageText.contains("Row"), pageText.contains("Marker 25") {
                foundRowOnContinuationPage = true
                break
            }
        }

        #expect(
            foundRowOnContinuationPage,
            "Expected Row column with stable row numbers on marker continuation pages"
        )
        #endif
    }

    @Test("Wide markers table omits Row when excluded")
    func wideMarkersTableOmitsRowWhenExcluded() throws {
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
        let document = try #require(PDFDocument(data: data))

        // Cover notes may mention "Row"; assert marker continuation pages never include the column.
        var foundMarkerContinuationWithoutRow = false
        for pageIndex in 1..<document.pageCount {
            guard let pageText = document.page(at: pageIndex)?.string else { continue }
            if pageText.contains("Marker 25") {
                let containsRow = pageText.contains("Row")
                #expect(
                    !containsRow,
                    "Excluded Row must not appear on marker continuation pages"
                )
                foundMarkerContinuationWithoutRow = true
                break
            }
        }

        #expect(
            foundMarkerContinuationWithoutRow,
            "Expected Marker 25 on a continuation page for exclusion assertion"
        )
        #else
        #expect(data.count > 4_000)
        #endif
    }

    @Test("Cover-page-only report produces minimal PDF")
    func coverPageOnlyReportProducesMinimalPDF() throws {
        let report = FinalCutPro.FCPXML.Report(projectName: "Cover Only")

        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)
        #expect(data.count > 100)
        #expect(String(data: data.prefix(4), encoding: .ascii) == "%PDF")

        #if canImport(PDFKit)
        let document = try #require(PDFDocument(data: data))
        let coverText = try #require(document.page(at: 0)?.string)

        let containsBranding = coverText.contains(
            FinalCutPro.FCPXML.ReportWorkbookCoverSheet.openFCPXMLKitDefault.brandingText
        )
        let containsAbout = coverText.contains("About This PDF Export")
        let containsExperimental = coverText.contains("experimental")
        let containsTruncate = coverText.contains("truncate")
        let containsExcel = coverText.contains("Excel (.xlsx)")
        #expect(containsBranding)
        #expect(containsAbout)
        #expect(containsExperimental)
        #expect(containsTruncate)
        #expect(containsExcel)
        #endif
    }

    @Test("Custom workbook cover sheet branding appears in PDF cover and footer")
    func customWorkbookCoverSheetBrandingAppearsInPDFCoverAndFooter() throws {
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
        let document = try #require(PDFDocument(data: data))

        #expect(report.exportBrandingText == branding)
        let coverContainsBranding = document.page(at: 0)?.string?.contains(branding) == true
        #expect(coverContainsBranding)

        let contentPageIndex = document.pageCount > 2 ? 2 : 1
        let contentContainsBranding =
            document.page(at: contentPageIndex)?.string?.contains(branding) == true
        #expect(contentContainsBranding)
        #endif
    }

    @Test("Copyright label appears on PDF cover and centered footer")
    func copyrightLabelAppearsOnPDFCoverAndCenteredFooter() throws {
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

        #expect(report.copyrightLabel == copyright)

        let data = try FinalCutPro.FCPXML.ReportPDFExport.makePDFData(from: report)

        #if canImport(PDFKit)
        let document = try #require(PDFDocument(data: data))

        let coverText = document.page(at: 0)?.string ?? ""
        let coverHasBranding = coverText.contains(branding)
        let coverHasCopyright = coverText.contains(copyright)
        #expect(coverHasBranding)
        #expect(coverHasCopyright)

        let contentPageIndex = document.pageCount > 2 ? 2 : 1
        let contentText = document.page(at: contentPageIndex)?.string ?? ""
        let contentHasBranding = contentText.contains(branding)
        let contentHasCopyright = contentText.contains(copyright)
        #expect(contentHasBranding)
        #expect(contentHasCopyright)
        #endif
    }

    @Test("Role inventory report includes table of contents without links")
    func roleInventoryReportIncludesTableOfContentsWithoutLinks() throws {
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
        let document = try #require(PDFDocument(data: data))
        let tocPage = try #require(document.page(at: 1))
        let tocText = try #require(tocPage.string)

        let hasTOC = tocText.contains("Table of Contents")
        let hasSheet = tocText.contains("Sheet")
        let hasPage = tocText.contains("Page")
        let hasInventory = tocText.contains("Selected Roles Inventory")
        let hasDialogue = tocText.contains("Dialogue")
        let hasMarkers = tocText.contains("Markers")
        let hasDotLeaders = tocText.contains("....")
        #expect(hasTOC)
        #expect(hasSheet)
        #expect(hasPage)
        #expect(hasInventory)
        #expect(hasDialogue)
        #expect(hasMarkers)
        #expect(!hasDotLeaders)
        #endif
    }

    @Test("Full report includes all workbook sections in PDF")
    func fullReportIncludesAllWorkbookSectionsInPDF() throws {
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
        let document = try #require(PDFDocument(data: data))
        let tocText = try #require(document.page(at: 1)?.string)

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
            let containsSheet = tocText.contains(sheet)
            #expect(containsSheet, "Expected TOC to include \(sheet)")
        }

        var combinedContent = ""
        for pageIndex in 2..<document.pageCount {
            combinedContent += document.page(at: pageIndex)?.string ?? ""
        }

        let hasHero = combinedContent.contains("Hero")
        let hasLowerThird = combinedContent.contains("Lower Third")
        let hasCrossDissolve = combinedContent.contains("Cross Dissolve")
        let hasBlur = combinedContent.contains("Blur")
        let hasMissingMedia = combinedContent.contains("/Volumes/Media/missing.mov")
        #expect(hasHero)
        #expect(hasLowerThird)
        #expect(hasCrossDissolve)
        #expect(hasBlur)
        #expect(hasMissingMedia)
        #endif
    }
}
