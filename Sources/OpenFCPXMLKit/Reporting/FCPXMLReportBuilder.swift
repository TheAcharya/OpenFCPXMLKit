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
        /// Projector used when sections consume timeline windows. Defaults to ``TimelineProjector``.
        public var timelineProjector: any TimelineProjecting
        
        public init(
            options: ReportOptions = .markersOnly,
            scope: ExtractionScope = .mainTimeline,
            onPhaseStarted: ReportBuildPhaseHandler? = nil,
            timelineProjector: any TimelineProjecting = TimelineProjector()
        ) {
            self.options = options
            self.scope = scope
            self.onPhaseStarted = onPhaseStarted
            self.timelineProjector = timelineProjector
        }
        
        /// Build a report from a parsed FCPXML document.
        public func build(from fcpxml: FinalCutPro.FCPXML) async throws -> Report {
            let source = try resolveTimelineSource(in: fcpxml)
            return try await build(from: source, fcpxml: fcpxml)
        }
        
        /// Build a report from a single project.
        public func build(
            from project: Project,
            fcpxml: FinalCutPro.FCPXML
        ) async throws -> Report {
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
            return try await build(from: source, fcpxml: fcpxml)
        }
        
        /// Build a report from a resolved timeline source (project or compound clip).
        public func build(
            from source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML
        ) async throws -> Report {
            let extractionScope = reportExtractionScope()
            let timelineElement = source.sequence.element

            if options.consumesTimelineProjection {
                onPhaseStarted?(.projecting)
            }
            let projection = try await projectIfNeeded(from: source, fcpxml: fcpxml)

            // One extract for inventory + Summary when either section is enabled.
            let inventoryEntries: [RoleInventoryClipEntry]?
            if options.includeRoleInventory || options.includeSummary {
                inventoryEntries = await RoleInventoryClipCollector.collectEntries(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference
                )
            } else {
                inventoryEntries = nil
            }

            var report = Report(
                projectName: source.displayName,
                eventName: source.eventName,
                workbookCoverSheet: options.workbookCoverSheet,
                copyrightLabel: options.copyrightLabel,
                excludedColumns: ReportColumnExclusion.resolve(options.excludedColumns),
                timecodeFormat: options.timecodeFormat,
                protectSheets: options.protectSheets
            )

            for phase in ReportBuildPhase.enabledPhases(for: options) {
                onPhaseStarted?(phase)
                await build(
                    phase,
                    into: &report,
                    source: source,
                    fcpxml: fcpxml,
                    scope: extractionScope,
                    projection: projection,
                    inventoryEntries: inventoryEntries
                )
            }

            return report
        }

        private func projectIfNeeded(
            from source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML
        ) async throws -> ReportProjectionContext? {
            guard options.consumesTimelineProjection else { return nil }

            let projectionOptions = TimelineProjectionOptions.forReport(
                excludeDisabledClips: options.excludeDisabledClips,
                auditions: (options.includeRoleInventory || options.includeSummary)
                    ? FinalCutPro.FCPXML.Audition.AuditionMask.all
                    : .active,
                mcClipAngles: (options.includeRoleInventory || options.includeSummary)
                    ? FinalCutPro.FCPXML.MCClip.AngleMask.all
                    : .active,
                includeAnnotations: options.summaryOverlapAwareDurations
                    || options.emitPerSourceInventoryRows
                    || options.includeMarkers
                    || options.includeKeywords
                    || options.includeTitlesAndGenerators
                    || options.includeTransitions
                    || options.includeEffects
            )

            do {
                let detailed = try await timelineProjector.projectDetailed(
                    from: source,
                    fcpxml: fcpxml,
                    options: projectionOptions
                )
                return ReportProjectionContext(
                    windows: detailed.windows,
                    clipAnnotations: detailed.clipAnnotations
                )
            } catch {
                if options.mediaResolutionPolicy == .failLoud {
                    throw ReportError.projectionFailed(String(describing: error))
                }
                return ReportProjectionContext(windows: [], clipAnnotations: [])
            }
        }

        private func build(
            _ phase: ReportBuildPhase,
            into report: inout Report,
            source: ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            scope extractionScope: ExtractionScope,
            projection: ReportProjectionContext?,
            inventoryEntries: [RoleInventoryClipEntry]?
        ) async {
            let timelineElement = source.sequence.element

            switch phase {
            case .projecting, .savingWorkbook, .savingPDF:
                return

            case .roleInventory:
                var roleInventory = await RoleInventoryReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    entries: inventoryEntries
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
                    includeMarkersOutsideClipBoundaries: options.includeMarkersOutsideClipBoundaries,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    resources: fcpxml.root.resources
                )

            case .keywords:
                report.keywords = await KeywordsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    resources: fcpxml.root.resources
                )

            case .titlesAndGenerators:
                report.titlesAndGenerators = await TitlesReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    resources: fcpxml.root.resources
                )

            case .transitions:
                report.transitions = await TransitionsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    resources: fcpxml.root.resources
                )

            case .nonStandardEffectsTemplates:
                report.nonStandardEffectsTemplates = NonStandardEffectsTemplatesReportBuilder.build(
                    document: fcpxml.xml,
                    baseURL: options.mediaBaseURL
                )

            case .effects:
                report.effects = await EffectsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    sequence: source.sequence,
                    resources: fcpxml.root.resources
                )

            case .speedChangeEffects:
                report.speedChangeEffects = await SpeedChangeEffectsReportBuilder.build(
                    from: timelineElement,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    sequence: source.sequence
                )

            case .summary:
                let components: [RoleInventoryClipComponent]?
                if let inventoryEntries {
                    let windowIndex = projection.map {
                        ProjectionWindowIndex(windows: $0.windows)
                    }
                    components = inventoryEntries.compactMap { entry in
                        RoleInventoryClipCollector.component(
                            from: entry,
                            projectionWindows: projection?.windows,
                            windowIndex: windowIndex
                        )
                    }
                } else {
                    components = nil
                }
                report.summary = await SummaryReportBuilder.build(
                    from: source,
                    document: fcpxml.xml,
                    scope: extractionScope,
                    roleDisplayPreference: options.roleDisplayPreference,
                    timecodeFormat: options.timecodeFormat,
                    projection: projection,
                    inventoryComponents: components,
                    overlapAwareDurations: options.summaryOverlapAwareDurations
                )

            case .mediaSummary:
                report.mediaSummary = MediaSummaryReportBuilder.build(
                    document: fcpxml.xml,
                    baseURL: options.mediaBaseURL,
                    projection: projection,
                    distinguishProxyAndOriginal: options.mediaSummaryDistinguishProxyAndOriginal
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
        /// Timeline projection failed under ``ReportMediaResolutionPolicy/failLoud``.
        case projectionFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .noProjectsFound:
                return "No projects or compound-clip timelines were found in the FCPXML document."
            case let .projectNotFound(name):
                return "No project or compound clip named \"\(name)\" was found in the FCPXML document."
            case let .projectionFailed(detail):
                return "Timeline projection failed while building the report: \(detail)"
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

