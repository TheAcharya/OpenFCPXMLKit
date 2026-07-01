//
//  FCPXMLSpeedChangeEffectsReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Speed Change Effects report section model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Speed change (retime) report section. Rows reuse ``EffectReportRow`` columns.
    public struct SpeedChangeEffectsReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Speed Change Effects"
        
        public var rows: [EffectReportRow]
        
        public init(rows: [EffectReportRow] = []) {
            self.rows = rows
        }
    }
}
