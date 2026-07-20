//
//  FCPXMLNonStandardEffectsTemplatesReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Non-standard / missing Motion template and effect report models.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// One row on the Non-Standard Effects & Templates sheet.
    public struct NonStandardEffectTemplateReportRow: Sendable, Equatable {
        public static let columnHeaders = [
            "Name",
            "Kind",
            "Status",
            "Path",
            "UID"
        ]
        
        public var name: String
        public var kind: String
        public var status: String
        public var path: String
        public var uid: String
        
        public init(
            name: String,
            kind: String,
            status: String = "",
            path: String = "",
            uid: String = ""
        ) {
            self.name = name
            self.kind = kind
            self.status = status
            self.path = path
            self.uid = uid
        }
        
        public var columnValues: [String] {
            [name, kind, status, path, uid]
        }
    }
    
    /// Non-Apple / missing template inventory (effects, titles, transitions, generators).
    public struct NonStandardEffectsTemplatesReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Non-Std Effects & Templates"
        
        public var rows: [NonStandardEffectTemplateReportRow]
        
        public init(rows: [NonStandardEffectTemplateReportRow] = []) {
            self.rows = rows
        }
    }
}
