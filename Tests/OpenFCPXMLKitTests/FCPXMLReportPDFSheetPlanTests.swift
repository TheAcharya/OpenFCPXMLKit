//
//  FCPXMLReportPDFSheetPlanTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF sheet plan colour indices shared by TOC chips and content-page tints.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Report PDF sheet plan")
struct FCPXMLReportPDFSheetPlanTests {

    @Test("Planned sheets assign sequential color indices per title")
    func plannedSheetsAssignSequentialColorIndicesPerTitle() {
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
            projectName: "Colour Index",
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
                    FinalCutPro.FCPXML.RoleSheet(sheetName: "Dialogue", rows: [clipRow])
                ]
            )
        )

        let planned = FCPXMLReportPDFSheetPlan.plannedSheets(from: report)
        #expect(planned.count >= 3)

        for (index, entry) in planned.enumerated() {
            #expect(
                entry.colorIndex == index,
                "TOC and content pages must share sequential colour indices by sheet title"
            )
        }

        let lookup = FCPXMLReportPDFSheetPlan.colorIndexLookup(for: planned)
        #expect(
            lookup[FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName]
                == 0
        )

        let dialogueTab = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
            for: "Dialogue"
        )
        #expect(lookup[dialogueTab] == 1)
        #expect(
            lookup[FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName]
                == 2
        )
    }

    @Test("Empty Media Summary remains in PDF sheet plan")
    func emptyMediaSummaryRemainsInPDFSheetPlan() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "No Missing",
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection()
        )

        let planned = FCPXMLReportPDFSheetPlan.plannedSheets(from: report)
        #expect(
            planned.map(\.title).contains(
                FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName
            )
        )
    }

    @Test("Empty enabled section sheets remain in PDF sheet plan with status messages")
    func emptyEnabledSectionSheetsRemainInPDFSheetPlan() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Empty Sections",
            markers: FinalCutPro.FCPXML.MarkersReportSection(rows: []),
            keywords: FinalCutPro.FCPXML.KeywordsReportSection(rows: []),
            titlesAndGenerators: FinalCutPro.FCPXML.TitlesReportSection(rows: []),
            transitions: FinalCutPro.FCPXML.TransitionsReportSection(rows: []),
            nonStandardEffectsTemplates: FinalCutPro.FCPXML.NonStandardEffectsTemplatesReportSection(
                rows: []
            ),
            effects: FinalCutPro.FCPXML.EffectsReportSection(rows: []),
            speedChangeEffects: FinalCutPro.FCPXML.SpeedChangeEffectsReportSection(rows: []),
            mediaSummary: FinalCutPro.FCPXML.MediaSummaryReportSection(),
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection()
        )

        let titles = FCPXMLReportPDFSheetPlan.plannedSheets(from: report).map(\.title)
        #expect(titles.contains(FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName))
        #expect(titles.contains(FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName))
        #expect(titles.contains(FinalCutPro.FCPXML.KeywordsReportSection.defaultSheetName))
        #expect(titles.contains(FinalCutPro.FCPXML.TitlesReportSection.defaultSheetName))
        #expect(titles.contains(FinalCutPro.FCPXML.TransitionsReportSection.defaultSheetName))
        #expect(
            titles.contains(
                FinalCutPro.FCPXML.NonStandardEffectsTemplatesReportSection.defaultSheetName
            )
        )
        #expect(titles.contains(FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName))
        #expect(titles.contains(FinalCutPro.FCPXML.SpeedChangeEffectsReportSection.defaultSheetName))
        #expect(titles.contains(FinalCutPro.FCPXML.MediaSummaryReportSection.defaultSheetName))
    }

    @Test("Table of contents entries preserve color index")
    func tableOfContentsEntriesPreserveColorIndex() {
        let planned = [
            FCPXMLReportPDFSheetPlan.SheetEntry(title: "Selected Roles Inventory", colorIndex: 0),
            FCPXMLReportPDFSheetPlan.SheetEntry(title: "Markers", colorIndex: 1),
        ]
        let recorded = [
            (title: "Selected Roles Inventory", startPage: 3),
            (title: "Markers", startPage: 10),
        ]

        let toc = FCPXMLReportPDFSheetPlan.tableOfContentsEntries(
            from: planned,
            recorded: recorded
        )

        #expect(toc.map(\.colorIndex) == [0, 1])
        #expect(toc.map(\.startPage) == [3, 10])
    }
}

