//
//  FCPXMLReportPDFSheetPlanTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF sheet plan colour indices shared by TOC chips and content-page tints.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportPDFSheetPlanTests: XCTestCase {
    
    func testPlannedSheetsAssignSequentialColorIndicesPerTitle() {
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
        XCTAssertGreaterThanOrEqual(planned.count, 3)
        
        for (index, entry) in planned.enumerated() {
            XCTAssertEqual(
                entry.colorIndex,
                index,
                "TOC and content pages must share sequential colour indices by sheet title"
            )
        }
        
        let lookup = FCPXMLReportPDFSheetPlan.colorIndexLookup(for: planned)
        XCTAssertEqual(
            lookup[FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName],
            0
        )
        
        let dialogueTab = FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
            for: "Dialogue"
        )
        XCTAssertEqual(lookup[dialogueTab], 1)
        XCTAssertEqual(
            lookup[FinalCutPro.FCPXML.MarkersReportSection.defaultSheetName],
            2
        )
    }
    
    func testTableOfContentsEntriesPreserveColorIndex() {
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
        
        XCTAssertEqual(toc.map(\.colorIndex), [0, 1])
        XCTAssertEqual(toc.map(\.startPage), [3, 10])
    }
}
