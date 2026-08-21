//
//  FCPXMLReportPDFExport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	PDF export of ``FinalCutPro/FCPXML/Report`` models.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Errors thrown while exporting a report to PDF.
    public enum ReportPDFExportError: Error, LocalizedError, Sendable {
        case couldNotCreateDocument
        case couldNotWriteFile
        
        public var errorDescription: String? {
            switch self {
            case .couldNotCreateDocument:
                return "Could not create the PDF document."
            case .couldNotWriteFile:
                return "Could not write the PDF file."
            }
        }
    }
    
    /// Maps ``Report`` to PDF documents using CoreGraphics.
    ///
    /// PDF cover/footer branding uses ``Report/exportBrandingText``, which reads
    /// ``Report/workbookCoverSheet`` — the same ``ReportWorkbookCoverSheet`` settings as Excel.
    /// Optional ``Report/copyrightLabel`` appears below branding / Created-on / Visit on the cover
    /// and centred in the running footer. Visit URL comes from ``ReportWorkbookCoverSheet/visitURL``.
    public enum ReportPDFExport {
        /// Builds PDF data from a structured FCPXML report.
        public static func makePDFData(from report: Report) throws -> Data {
            try FCPXMLReportPDFExporter.makePDFData(from: report)
        }
        
        /// Writes a report to a `.pdf` file at the given URL.
        ///
        /// The document is streamed to disk as it is drawn, so peak memory does not scale with
        /// the size of the finished PDF.
        public static func export(_ report: Report, to url: URL) throws {
            do {
                try FCPXMLReportPDFExporter.writePDF(from: report, to: url)
            } catch let error as ReportPDFExportError {
                throw error
            } catch {
                throw ReportPDFExportError.couldNotWriteFile
            }
        }
    }
}
