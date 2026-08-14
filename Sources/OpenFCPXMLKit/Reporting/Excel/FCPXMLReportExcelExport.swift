//
//  FCPXMLReportExcelExport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	XLKit-based Excel export of ``FinalCutPro/FCPXML/Report`` models.
//

import Foundation
import XLKit

extension FinalCutPro.FCPXML {
    /// Maps ``Report`` to Excel workbooks using XLKit.
    public enum ReportExcelExport {
        /// Builds an XLKit workbook from a structured FCPXML report.
        ///
        /// Only non-`nil` report sections are written. Sheet order follows reference
        /// full-workbook exports: role inventory (when present), then Markers, Keywords,
        /// Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects,
        /// Summary, and Media Summary.
        /// - Parameter createdOn: Timestamp written on the Excel cover **Created on** row (**A2**).
        ///   Defaults to now; pass a fixed date in tests.
        @MainActor
        public static func makeWorkbook(
            from report: Report,
            createdOn: Date = Date()
        ) -> Workbook {
            FCPXMLReportWorkbookExporter.makeWorkbook(from: report, createdOn: createdOn)
        }
        
        /// Writes a report to an `.xlsx` file at the given URL.
        ///
        /// When ``Report/protectSheets`` is `true`, every worksheet is edit-locked
        /// (XLKit sheet protection without a password). This is not file encryption.
        /// When ``RoleInventoryReportSection/showsScreenshotsColumn`` is `true`, Source In
        /// frame grabs are embedded into Role Inventory Screenshot cells before save.
        @MainActor
        public static func export(_ report: Report, to url: URL) async throws {
            let workbook = makeWorkbook(from: report)
            if let roleInventory = report.roleInventory,
               roleInventory.showsScreenshotsColumn
            {
                await FCPXMLReportWorkbookScreenshotEmbedder.embedScreenshots(
                    into: workbook,
                    roleInventory: roleInventory
                )
            }
            try await workbook.save(to: url)
        }
        
        /// Sanitizes a string for use as an Excel worksheet name.
        public static func sanitizeSheetName(_ name: String) -> String {
            FCPXMLReportWorkbookExporter.sanitizeSheetName(name)
        }
    }
}
