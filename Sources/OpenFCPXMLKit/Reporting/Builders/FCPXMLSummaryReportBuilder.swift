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
    /// Builds the Summary sheet: project metrics, per-role estimated totals, and missing media paths.
    enum SummaryReportBuilder {
        static func build(
            from project: Project,
            document: any OFKXMLDocument,
            baseURL: URL?,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) async -> SummaryReportSection {
            let resources = resourcesElement(in: document)
            let sequence = project.sequence
            let timelineElement = sequence.element
            let projectSummary = projectSummary(
                for: project,
                sequence: sequence,
                resources: resources
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
                resources: resources
            )
            
            let missingMediaPaths = missingMediaPaths(
                in: document,
                baseURL: baseURL
            )
            
            return SummaryReportSection(
                projectSummary: projectSummary,
                roleDurations: roleDurations,
                missingMediaPaths: missingMediaPaths
            )
        }
        
        private static func resourcesElement(in document: any OFKXMLDocument) -> (any OFKXMLElement)? {
            document.rootElement()?.firstChildElement(named: "resources")
        }
        
        private static func projectSummary(
            for project: Project,
            sequence: Sequence,
            resources: (any OFKXMLElement)?
        ) -> ProjectSummary {
            let duration = projectDurationTimecode(
                for: sequence,
                resources: resources
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
            resources: (any OFKXMLElement)?
        ) -> String {
            guard let duration = sequence.duration,
                  let timecode = try? sequence.element._fcpTimecode(
                    fromRational: duration,
                    frameRateSource: .mainTimeline,
                    breadcrumbs: [],
                    resources: resources
                  )
            else { return "" }
            
            return ReportFormatting.timecodeString(timecode)
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
        
        private static func missingMediaPaths(
            in document: any OFKXMLDocument,
            baseURL: URL?
        ) -> [String] {
            let extractor = MediaExtractor()
            let result = extractor.extractMediaReferences(from: document, baseURL: baseURL)
            let fileManager = FileManager.default
            
            var missingPaths: Set<String> = []
            
            for reference in result.references {
                guard let url = reference.url, url.isFileURL else { continue }
                let path = url.path
                guard !path.isEmpty else { continue }
                if !fileManager.fileExists(atPath: path) {
                    missingPaths.insert(path)
                }
            }
            
            return missingPaths.sorted()
        }
    }
}
