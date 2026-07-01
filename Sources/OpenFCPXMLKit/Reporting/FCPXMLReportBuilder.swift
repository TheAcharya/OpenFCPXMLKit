//
//  FCPXMLReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds structured reports from FCPXML documents.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Builds ``Report`` instances from parsed FCPXML.
    ///
    /// ```swift
    /// let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
    /// let report = await fcpxml.buildReport(options: .markersOnly)
    /// ```
    public struct ReportBuilder: Sendable {
        public var options: ReportOptions
        public var scope: ExtractionScope
        public var onPhaseStarted: ReportBuildPhaseHandler?
        
        public init(
            options: ReportOptions = .markersOnly,
            scope: ExtractionScope = .mainTimeline,
            onPhaseStarted: ReportBuildPhaseHandler? = nil
        ) {
            self.options = options
            self.scope = scope
            self.onPhaseStarted = onPhaseStarted
        }
        
        /// Build a report from a parsed FCPXML document.
        public func build(from fcpxml: FinalCutPro.FCPXML) async throws -> Report {
            let project = try resolveProject(in: fcpxml)
            return await build(from: project, fcpxml: fcpxml)
        }
        
        /// Build a report from a single project.
        public func build(
            from project: Project,
            fcpxml: FinalCutPro.FCPXML
        ) async -> Report {
            let timelineElement = project.sequence.element
            let eventName = project.element
                .ancestorElements(includingSelf: false)
                .first(whereFCPElementType: .event)?
                .fcpName
            
            var report = Report(
                projectName: project.name ?? "",
                eventName: eventName,
                workbookCoverSheet: options.workbookCoverSheet
            )
            
            if options.includeMarkers {
                onPhaseStarted?(.markers)
                report.markers = await MarkersReportBuilder.build(
                    from: timelineElement,
                    scope: scope,
                    includeChapterMarkers: options.includeChapterMarkersInMarkersReport,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            }
            
            // Subsequent build-order steps: keywords, transitions, titles, effects, summary, role inventory.
            if options.includeKeywords {
                onPhaseStarted?(.keywords)
                report.keywords = await KeywordsReportBuilder.build(
                    from: timelineElement,
                    scope: scope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            }
            if options.includeTitlesAndGenerators {
                onPhaseStarted?(.titlesAndGenerators)
                report.titlesAndGenerators = await TitlesReportBuilder.build(
                    from: timelineElement,
                    scope: scope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            }
            if options.includeTransitions {
                onPhaseStarted?(.transitions)
                report.transitions = await TransitionsReportBuilder.build(
                    from: timelineElement,
                    scope: scope
                )
            }
            if options.includeEffects {
                onPhaseStarted?(.effects)
                report.effects = await EffectsReportBuilder.build(
                    from: timelineElement,
                    scope: scope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            }
            if options.includeSpeedChangeEffects {
                onPhaseStarted?(.speedChangeEffects)
                report.speedChangeEffects = await SpeedChangeEffectsReportBuilder.build(
                    from: timelineElement,
                    scope: scope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            }
            if options.includeSummary {
                onPhaseStarted?(.summary)
                report.summary = await SummaryReportBuilder.build(
                    from: project,
                    document: fcpxml.xml,
                    baseURL: options.mediaBaseURL,
                    scope: scope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            }
            if options.includeRoleInventory {
                onPhaseStarted?(.roleInventory)
                var roleInventory = await RoleInventoryReportBuilder.build(
                    from: timelineElement,
                    scope: scope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
                if !options.excludedRoles.isEmpty {
                    roleInventory = ReportRoleExclusion.applying(
                        excludedRoleNames: options.excludedRoles,
                        to: roleInventory
                    )
                }
                report.roleInventory = roleInventory
            }
            
            return report
        }
        
        private func resolveProject(in fcpxml: FinalCutPro.FCPXML) throws -> Project {
            let projects = fcpxml.allProjects()
            
            if let name = options.projectName {
                guard let project = projects.first(where: { $0.name == name }) else {
                    throw ReportError.projectNotFound(name)
                }
                return project
            }
            
            guard let project = projects.first else {
                throw ReportError.noProjectsFound
            }
            
            return project
        }
    }
    
    /// Errors thrown while building reports.
    public enum ReportError: Error, LocalizedError, Sendable {
        case noProjectsFound
        case projectNotFound(String)
        
        public var errorDescription: String? {
            switch self {
            case .noProjectsFound:
                return "No projects were found in the FCPXML document."
            case let .projectNotFound(name):
                return "No project named \"\(name)\" was found in the FCPXML document."
            }
        }
    }
}

extension FinalCutPro.FCPXML {
    /// Convenience entry point for building a report from this document.
    public func buildReport(
        options: ReportOptions = .markersOnly,
        scope: ExtractionScope = .mainTimeline,
        onPhaseStarted: ReportBuildPhaseHandler? = nil
    ) async throws -> Report {
        try await ReportBuilder(
            options: options,
            scope: scope,
            onPhaseStarted: onPhaseStarted
        ).build(from: self)
    }
}
