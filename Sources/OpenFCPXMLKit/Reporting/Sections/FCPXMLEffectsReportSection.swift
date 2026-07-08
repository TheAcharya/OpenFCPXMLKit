//
//  FCPXMLEffectsReportSection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Video & Audio Effects report section model.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// One row in the Video & Audio Effects report sheet.
    public struct EffectReportRow: Sendable, Equatable {
        public var effect: String
        public var settings: String
        public var enabled: String
        public var isApple: String
        public var clipName: String
        public var roleSubrole: String
        public var timelineIn: String
        public var timelineOut: String
        
        public static let columnHeaders: [String] = columnHeaders(timecodeFormat: .smpteFrames)
        
        public static func columnHeaders(
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) -> [String] {
            [
                "Effect",
                "Settings",
                "Enabled",
                "Apple",
                "Clip Name",
                "Role ▸ Subrole",
                timecodeFormat.formattedColumnHeader("Timeline In"),
                timecodeFormat.formattedColumnHeader("Timeline Out")
            ]
        }
        
        public init(
            effect: String,
            settings: String,
            enabled: String,
            isApple: String,
            clipName: String,
            roleSubrole: String,
            timelineIn: String,
            timelineOut: String
        ) {
            self.effect = effect
            self.settings = settings
            self.enabled = enabled
            self.isApple = isApple
            self.clipName = clipName
            self.roleSubrole = roleSubrole
            self.timelineIn = timelineIn
            self.timelineOut = timelineOut
        }
        
        /// Maps a semantic extracted effect to a workbook row.
        init?(
            from effect: ExtractedEffect,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) {
            let timelineContext = effect.timelineContext ?? effect.host
            
            guard let timelineIn = timelineContext.value(
                forContext: .absoluteStartAsTimecode(frameRateSource: .mainTimeline)
            ),
            let timelineOut = timelineContext.value(
                forContext: .absoluteEndAsTimecode(frameRateSource: .mainTimeline)
            )
            else { return nil }
            
            self.init(
                effect: effect.name,
                settings: ReportFormatting.effectSettingsDisplay(for: effect),
                enabled: ReportFormatting.enabledCheckmark(for: effect),
                isApple: ReportFormatting.appleCheckmark(forAppleSupplied: effect.isAppleSupplied),
                clipName: effect.host.displayClipName(),
                roleSubrole: ReportFormatting.effectRoleSubrole(
                    for: effect,
                    roleDisplayPreference: roleDisplayPreference
                ),
                timelineIn: ReportFormatting.timecodeString(timelineIn, format: timecodeFormat),
                timelineOut: ReportFormatting.timecodeString(timelineOut, format: timecodeFormat)
            )
        }
        
        public var columnValues: [String] {
            [
                effect,
                settings,
                enabled,
                isApple,
                clipName,
                roleSubrole,
                timelineIn,
                timelineOut
            ]
        }
    }
    
    /// Video & Audio Effects report section.
    public struct EffectsReportSection: ReportSection, Sendable, Equatable {
        public static let defaultSheetName = "Video & Audio Effects"
        public var rows: [EffectReportRow]
        
        public init(rows: [EffectReportRow] = []) {
            self.rows = rows
        }
    }
}
