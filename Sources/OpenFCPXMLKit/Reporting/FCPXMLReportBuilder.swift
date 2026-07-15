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
    ///
    /// Sections are built in ``ReportBuildPhase/enabledPhases(for:)`` order (product /
    /// workbook order). ``onPhaseStarted`` is invoked once per enabled phase before that
    /// section is assembled.
    ///
    /// Supports both normal project timelines (`library` → `event` → `project` → `sequence`)
    /// and standalone compound-clip exports (`event` → `ref-clip` → `media`/`sequence`) via
    /// ``allReportTimelineSources()``.
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
            let source = try resolveTimelineSource(in: fcpxml)
            return await build(from: source, fcpxml: fcpxml)
        }
        
        /// Build a report from a single project.
        public func build(
            from project: Project,
            fcpxml: FinalCutPro.FCPXML
        ) async -> Report {
            let eventName = project.element
                .ancestorElements(includingSelf: false)
                .first(whereFCPElementType: .event)?
                .fcpName
            let source = ReportTimelineSource(
                displayName: project.name ?? "",
                eventName: eventName,
                sequence: project.sequence,
                project: project
            )
            return await build(from: source, fcpxml: fcpxml)
        }
        
        /// Build a report from a resolved timeline source (project or compound clip).
        public func build(
            from source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML
        ) async -> Report {
            let extractionScope = reportExtractionScope()
            
            var report = Report(
                projectName: source.displayName,
                eventName: source.eventName,
                workbookCoverSheet: options.workbookCoverSheet,
                copyrightLabel: options.copyrightLabel,
                excludedColumns: ReportColumnExclusion.resolve(options.excludedColumns),
                timecodeFormat: options.timecodeFormat
            )
            
            for phase in ReportBuildPhase.enabledPhases(for: options) {
                onPhaseStarted?(phase)
                await build(phase, into: &report, source: source, fcpxml: fcpxml, scope: extractionScope)
            }
            
            return report
        }
        
        private func build(
            _ phase: ReportBuildPhase,
            into report: inout Report,
            source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            scope extractionScope: ExtractionScope
        ) async {
            let timelineElement = source.sequence.element
            
            switch phase {
            case .roleInventory:
                var roleInventory = await RoleInventoryReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                if !options.excludedRoles.isEmpty {
                    roleInventory = ReportRoleExclusion.applying(
                        excludedRoleNames: options.excludedRoles,
                        to: roleInventory
                    )
                }
                report.roleInventory = roleInventory
                
            case .markers:
                report.markers = await MarkersReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    includeChapterMarkers: options.includeChapterMarkersInMarkersReport,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .keywords:
                report.keywords = await KeywordsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .titlesAndGenerators:
                report.titlesAndGenerators = await TitlesReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .transitions:
                report.transitions = await TransitionsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .effects:
                report.effects = await EffectsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .speedChangeEffects:
                report.speedChangeEffects = await SpeedChangeEffectsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .summary:
                report.summary = await SummaryReportBuilder.build(
                    from: source,
                    document: fcpxml.xml,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat
                )
                
            case .mediaSummary:
                report.mediaSummary = MediaSummaryReportBuilder.build(
                    document: fcpxml.xml,
                    baseURL: options.mediaBaseURL
                )
            }
        }
        
        /// Scope used for timeline extraction across all report sections.
        private func reportExtractionScope() -> ExtractionScope {
            var effectiveScope = scope
            effectiveScope.includeDisabled = !options.excludeDisabledClips
            return effectiveScope
        }
        
        private func resolveTimelineSource(in fcpxml: FinalCutPro.FCPXML) throws -> ReportTimelineSource {
            let sources = fcpxml.allReportTimelineSources()
            
            if let name = options.projectName {
                guard let source = sources.first(where: { $0.displayName == name }) else {
                    throw ReportError.projectNotFound(name)
                }
                return source
            }
            
            // Prefer a real project when both projects and event-level compound clips exist
            // (e.g. CompoundClipSample embeds a compound inside a project timeline).
            if let projectSource = sources.first(where: { $0.project != nil }) {
                return projectSource
            }
            
            guard let source = sources.first else {
                throw ReportError.noProjectsFound
            }
            
            return source
        }
    }
    
    /// Errors thrown while building reports.
    public enum ReportError: Error, LocalizedError, Sendable {
        case noProjectsFound
        case projectNotFound(String)
        
        public var errorDescription: String? {
            switch self {
            case .noProjectsFound:
                return "No projects or compound-clip timelines were found in the FCPXML document."
            case let .projectNotFound(name):
                return "No project or compound clip named \"\(name)\" was found in the FCPXML document."
            }
        }
    }
}

extension FinalCutPro.FCPXML {
    /// Convenience entry point for building a report from this document.
    ///
    /// Progress callbacks follow ``ReportBuildPhase/enabledPhases(for:)`` order.
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
