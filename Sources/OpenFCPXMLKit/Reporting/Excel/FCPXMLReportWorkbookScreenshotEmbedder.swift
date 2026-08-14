//
//  FCPXMLReportWorkbookScreenshotEmbedder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Embeds Role Inventory Source In screenshots into XLKit workbook sheets.
//

import Foundation
import XLKit

enum FCPXMLReportWorkbookScreenshotEmbedder {
    /// XLKit display box: long-edge thumbnails up to ``RoleInventoryScreenshotGrabber/maxLongEdgePixels``.
    private static let maxCellEdge: CGFloat =
        FinalCutPro.FCPXML.RoleInventoryScreenshotGrabber.maxLongEdgePixels
    
    /// Embeds JPEG thumbnails into every Role Inventory sheet that has a Screenshot column.
    @MainActor
    static func embedScreenshots(
        into workbook: Workbook,
        roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection
    ) async {
        guard roleInventory.showsScreenshotsColumn else { return }
        
        var cache: [String: Data] = [:]
        
        await embed(
            into: workbook,
            sheetName: FinalCutPro.FCPXML.RoleInventoryReportSection.defaultSheetName,
            rows: roleInventory.selectedRoles,
            cache: &cache
        )
        
        for roleSheet in roleInventory.roleSheets {
            let name = FCPXMLReportWorkbookExporter.sanitizeSheetName(
                FinalCutPro.FCPXML.RoleInventoryRoleSheetOrdering.sheetTabName(
                    for: roleSheet.sheetName
                )
            )
            await embed(
                into: workbook,
                sheetName: name,
                rows: roleSheet.rows,
                cache: &cache
            )
        }
    }
    
    @MainActor
    private static func embed(
        into workbook: Workbook,
        sheetName: String,
        rows: [FinalCutPro.FCPXML.RoleClipReportRow],
        cache: inout [String: Data]
    ) async {
        guard let sheet = workbook.getSheet(name: sheetName) else { return }
        guard let screenshotColumn = screenshotColumnIndex(in: sheet) else { return }
        
        for (index, row) in rows.enumerated() {
            guard let fileURL = row.screenshotMediaFileURL else { continue }
            let fileTime = row.screenshotFileTimeSeconds ?? 0
            let cacheKey = "\(fileURL.path)|\(String(format: "%.6f", fileTime))"
            
            let jpeg: Data
            if let cached = cache[cacheKey] {
                jpeg = cached
            } else if let grabbed = await FinalCutPro.FCPXML.RoleInventoryScreenshotGrabber.jpegData(
                fileURL: fileURL,
                fileTimeSeconds: fileTime
            ) {
                cache[cacheKey] = grabbed
                jpeg = grabbed
            } else {
                continue
            }
            
            let excelRow = index + 2 // header is row 1
            let coordinate = CellCoordinate(row: excelRow, column: screenshotColumn).excelAddress
            _ = try? await sheet.embedImageAutoSized(
                jpeg,
                at: coordinate,
                of: workbook,
                format: .jpeg,
                maxCellWidth: maxCellEdge,
                maxCellHeight: maxCellEdge,
                scale: 1.0
            )
        }
    }
    
    private static func screenshotColumnIndex(in sheet: Sheet) -> Int? {
        let header = FinalCutPro.FCPXML.RoleInventoryColumnLayout.screenshotColumnHeader
        for column in 1 ... 64 {
            let address = CellCoordinate(row: 1, column: column).excelAddress
            if sheet.getCell(address)?.stringValue == header
                || sheet.getCellWithFormat(address)?.value.stringValue == header
            {
                return column
            }
        }
        return nil
    }
}
