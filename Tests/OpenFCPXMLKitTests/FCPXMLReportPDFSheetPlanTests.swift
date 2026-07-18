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

