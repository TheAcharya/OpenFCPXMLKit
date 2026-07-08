//
//  FCPXMLSummaryReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Summary report section from FCPXML.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds the Summary sheet: project metrics and per-role estimated totals.
    enum SummaryReportBuilder {
        static func build(
            from project: Project,
            document: any OFKXMLDocument,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) async -> SummaryReportSection {
            let resources = resourcesElement(in: document)
            let sequence = project.sequence
            let timelineElement = sequence.element
            let projectSummary = projectSummary(
                for: project,
                sequence: sequence,
                resources: resources,
                timecodeFormat: timecodeFormat
            )
            
            let projectDurationSeconds = projectDurationSeconds(
                for: sequence,
                resources: resources
            )
            
            let inventoryComponents = await RoleInventoryClipCollector.collect(
                from: timelineElement,
                scope: scope,
                roleDisplayPreference: roleDisplayPreference
            )
            
            let roleDurations = SummaryRoleDurationAggregator.roleDurationRows(
                from: inventoryComponents,
                projectDurationSeconds: projectDurationSeconds,
                timeline: timelineElement,
                resources: resources,
                timecodeFormat: timecodeFormat
            )
            
            return SummaryReportSection(
                projectSummary: projectSummary,
                roleDurations: roleDurations
            )
        }
        
        private static func resourcesElement(in document: any OFKXMLDocument) -> (any OFKXMLElement)? {
            document.rootElement()?.firstChildElement(named: "resources")
        }
        
        private static func projectSummary(
            for project: Project,
            sequence: Sequence,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> ProjectSummary {
            let duration = projectDurationTimecode(
                for: sequence,
                resources: resources,
                timecodeFormat: timecodeFormat
            )
            
            let format = sequence.element._fcpFirstDefinedFormatResourceForElementOrAncestors(
                in: resources
            )
            
            let resolution: String
            if let width = format?.width, let height = format?.height {
                resolution = "\(width) × \(height)"
            } else {
                resolution = ""
            }
            
            let frameRate: String
            if let frameDuration = format?.frameDuration,
               frameDuration.numerator > 0 {
                let fps = Double(frameDuration.denominator) / Double(frameDuration.numerator)
                frameRate = String(Int(round(fps)))
            } else {
                frameRate = ""
            }
            
            let audioSampleRate = sequence.audioRate.map(summaryAudioSampleRateDisplay) ?? ""
            
            return ProjectSummary(
                title: project.name ?? "",
                duration: duration,
                resolution: resolution,
                frameRate: frameRate,
                audioSampleRate: audioSampleRate
            )
        }
        
        private static func summaryAudioSampleRateDisplay(
            _ audioRate: AudioRate
        ) -> String {
            "\(audioRate.rawValueForSequence)Hz"
        }
        
        private static func projectDurationTimecode(
            for sequence: Sequence,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> String {
            guard let duration = sequence.duration,
                  let timecode = try? sequence.element._fcpTimecode(
                    fromRational: duration,
                    frameRateSource: .mainTimeline,
                    breadcrumbs: [],
                    resources: resources
                  )
            else { return "" }
            
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }
        
        private static func projectDurationSeconds(
            for sequence: Sequence,
            resources: (any OFKXMLElement)?
        ) -> Double {
            guard let duration = sequence.duration else { return 0 }
            
            if let timecode = try? sequence.element._fcpTimecode(
                fromRational: duration,
                frameRateSource: .mainTimeline,
                breadcrumbs: [],
                resources: resources
            ) {
                return timecode.realTimeValue
            }
            
            return duration.doubleValue
        }
    }
}
