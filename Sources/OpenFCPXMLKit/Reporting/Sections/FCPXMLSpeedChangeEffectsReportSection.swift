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
        /// Status text when the Speed Change Effects sheet is enabled but has no rows.
        public static let emptyStatusMessage = "No Speed Change Effects Found"
        
        public var rows: [EffectReportRow]
        
        public init(rows: [EffectReportRow] = []) {
            self.rows = rows
        }
    }
}
