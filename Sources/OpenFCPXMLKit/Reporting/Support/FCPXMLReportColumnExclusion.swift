//
//  FCPXMLReportColumnExclusion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Global workbook column exclusion across all report sheets.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Logical report columns that can be omitted from every applicable workbook sheet.
    public enum ReportColumn: String, Sendable, Hashable, CaseIterable {
        case row
        case roleSubrole
        case clipName
        case category
        case enabled
        case timelineIn
        case timelineOut
        case clipDuration
        case duration
        case sourceIn
        case sourceOut
        case sourceDuration
        case sourcePosition
        case duplicateFrames
        case markers
        case keywords
        case effects
        case notes
        case reel
        case scene
        case take
        case cameraAngle
        case cameraName
        case frameRateSampleRate
        case frameSize
        case sourceFileName
        case sourceFilePath
        case codecs
        case ingestDate
        case metadata
    }
    
    /// Legacy name for ``ReportColumn``.
    public typealias RoleInventoryReportColumn = ReportColumn
    
    /// Resolves user-facing column labels and filters workbook headers/rows.
    enum ReportColumnExclusion {
        static func resolve(_ labels: [String]) -> Set<ReportColumn> {
            var resolved = Set<ReportColumn>()
            for label in labels {
                if let column = resolveColumn(label) {
                    resolved.insert(column)
                }
            }
            return resolved
        }
        
        static func resolveColumn(_ label: String) -> ReportColumn? {
            let normalized = normalizeColumnLabel(label)
            guard !normalized.isEmpty else { return nil }
            
            return ReportColumn.allCases.first { column in
                column.aliases.contains { alias in
                    normalizeColumnLabel(alias).compare(
                        normalized,
                        options: [.caseInsensitive, .diacriticInsensitive]
                    ) == .orderedSame
                }
            }
        }
        
        /// Prepends the 1-based ``ReportColumn/row`` index column when it is not excluded
        /// and not already present. Used by Excel and PDF so all tabular sheets share the
        /// same Row behaviour as Selected Roles Inventory.
        static func ensuringRowColumn(
            headers: [String],
            rows: [[String]],
            excluded: Set<ReportColumn>
        ) -> (headers: [String], rows: [[String]]) {
            guard !excluded.contains(.row) else { return (headers, rows) }
            guard !headers.isEmpty else { return (headers, rows) }
            
            if headers.contains(where: { headerMatchesColumn($0, column: .row) }) {
                return (headers, rows)
            }
            
            let rowHeader = ReportColumn.row.exportHeader ?? RoleInventoryColumnLayout.rowColumnHeader
            return (
                [rowHeader] + headers,
                rows.enumerated().map { index, row in
                    [String(index + 1)] + row
                }
            )
        }
        
        /// Whether ``ReportColumn/row`` should be injected for PDF multi-page / multi-column
        /// traceability when the source headers do not already include it.
        static func allowsInjectedRowColumn(excluded: Set<ReportColumn>) -> Bool {
            !excluded.contains(.row)
        }
        
        static func filter(
            headers: [String],
            rows: [[String]],
            excluded: Set<ReportColumn>,
            metadataColumnKeys: [String] = []
        ) -> (headers: [String], rows: [[String]]) {
            let prepared = ensuringRowColumn(
                headers: headers,
                rows: rows,
                excluded: excluded
            )
            
            guard !excluded.isEmpty else { return prepared }
            
            let indices = retainedColumnIndices(
                in: prepared.headers,
                excluded: excluded,
                metadataColumnKeys: metadataColumnKeys
            )
            let filteredHeaders = indices.map { prepared.headers[$0] }
            let filteredRows = prepared.rows.map { row in
                indices.map { index in
                    index < row.count ? row[index] : ""
                }
            }
            return (filteredHeaders, filteredRows)
        }
        
        static func filter(
            headers: [String],
            excluded: Set<ReportColumn>,
            metadataColumnKeys: [String] = []
        ) -> [String] {
            filter(headers: headers, rows: [], excluded: excluded, metadataColumnKeys: metadataColumnKeys)
                .headers
        }
        
        static func isHeaderExcluded(
            _ header: String,
            excluded: Set<ReportColumn>,
            metadataColumnKeys: [String]
        ) -> Bool {
            if excluded.contains(.metadata),
               metadataColumnKeys.contains(header) || header.hasPrefix("com.apple.")
            {
                return true
            }
            
            return excluded.contains { column in
                headerMatchesColumn(header, column: column)
            }
        }
        
        static func filteredProjectSummaryMetrics(
            _ summary: ProjectSummary,
            excluded: Set<ReportColumn>
        ) -> [String] {
            let metrics: [(column: ReportColumn?, value: String)] = [
                (nil, ""),
                (nil, summary.duration),
                (.frameSize, summary.resolution),
                (.frameRateSampleRate, summary.frameRate),
                (.frameRateSampleRate, summary.audioSampleRate)
            ]
            
            return metrics.compactMap { metric in
                guard let column = metric.column else { return metric.value }
                guard !excluded.contains(column) else { return nil }
                return metric.value
            }
        }
        
        private static func retainedColumnIndices(
            in headers: [String],
            excluded: Set<ReportColumn>,
            metadataColumnKeys: [String]
        ) -> [Int] {
            headers.enumerated().compactMap { index, header in
                isHeaderExcluded(header, excluded: excluded, metadataColumnKeys: metadataColumnKeys)
                    ? nil
                    : index
            }
        }
        
        private static func headerMatches(_ lhs: String, _ rhs: String) -> Bool {
            lhs.compare(rhs, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        
        private static func headerMatchesColumn(
            _ header: String,
            column: ReportColumn
        ) -> Bool {
            if column.workbookHeaders.contains(where: { headerMatches($0, header) }) {
                return true
            }
            
            guard column.isTimecodeColumn else { return false }
            
            return FinalCutPro.FCPXML.ReportTimecodeFormat.allCases.contains { format in
                guard let exportHeader = column.workbookHeader(timecodeFormat: format) else {
                    return false
                }
                return headerMatches(exportHeader, header)
            }
        }
        
        private static func normalizeColumnLabel(_ label: String) -> String {
            label
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "•", with: "▸")
                .replacingOccurrences(of: "·", with: "▸")
                .replacingOccurrences(of: "  ", with: " ")
        }
    }
}

extension FinalCutPro.FCPXML.ReportColumn {
    /// Whether workbook cells for this column use ``ReportTimecodeFormat`` display strings.
    var isTimecodeColumn: Bool {
        switch self {
        case .timelineIn, .timelineOut, .clipDuration, .duration,
             .sourceIn, .sourceOut, .sourceDuration, .sourcePosition, .duplicateFrames:
            return true
        default:
            return false
        }
    }
    
    /// Primary inventory header for a fixed column, when exported.
    var exportHeader: String? {
        workbookHeader(timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat.smpteFrames)
    }
    
    /// Workbook header for a fixed column, adjusted for the active timecode display format.
    func workbookHeader(timecodeFormat: FinalCutPro.FCPXML.ReportTimecodeFormat) -> String? {
        guard let base = workbookHeaders.first else { return nil }
        guard isTimecodeColumn else { return base }
        return timecodeFormat.formattedColumnHeader(base)
    }
    
    /// Workbook header strings matched on any report sheet for this logical column.
    var workbookHeaders: [String] {
        switch self {
        case .row:
            return ["Row"]
        case .roleSubrole:
            return ["Role ▸ Subrole"]
        case .clipName:
            return ["Clip Name"]
        case .category:
            return ["Category"]
        case .enabled:
            return ["Enabled"]
        case .timelineIn:
            return ["Timeline In"]
        case .timelineOut:
            return ["Timeline Out"]
        case .clipDuration:
            return ["Clip Duration"]
        case .duration:
            return ["Duration"]
        case .sourceIn:
            return ["Source In"]
        case .sourceOut:
            return ["Source Out"]
        case .sourceDuration:
            return ["Source Duration"]
        case .sourcePosition:
            return ["Source Position"]
        case .duplicateFrames:
            return ["Duplicate Frames"]
        case .markers:
            return ["Markers"]
        case .keywords:
            return ["Keywords", "Keyword"]
        case .effects:
            return ["Effects", "Effect"]
        case .notes:
            return ["Notes"]
        case .reel:
            return ["Reel"]
        case .scene:
            return ["Scene"]
        case .take:
            return ["Take"]
        case .cameraAngle:
            return ["Camera Angle"]
        case .cameraName:
            return ["Camera Name"]
        case .frameRateSampleRate:
            return ["Frame Rate/Sample Rate", "Frame Rate", "Sample Rate"]
        case .frameSize:
            return [
                "Frame Size / Audio Config",
                "Frame Size/Audio Config",
                "Frame Size"
            ]
        case .sourceFileName:
            return ["Source File Name"]
        case .sourceFilePath:
            return [
                "Source File Path",
                "Missing Media",
                "Missing Original",
                "Missing Proxy"
            ]
        case .codecs:
            return ["Codecs"]
        case .ingestDate:
            return ["Ingest Date"]
        case .metadata:
            return []
        }
    }

    /// User-facing aliases accepted by ``ReportColumnExclusion``.
    fileprivate var aliases: [String] {
        switch self {
        case .row:
            return ["Row", "Row Numbers", "Row Number"]
        case .roleSubrole:
            return ["Role ▸ Subrole", "Role • Subrole", "Role Subrole", "Role-Subrole"]
        case .clipName:
            return ["Clip Name"]
        case .category:
            return ["Category"]
        case .enabled:
            return ["Enabled"]
        case .timelineIn:
            return ["Timeline In"]
        case .timelineOut:
            return ["Timeline Out"]
        case .clipDuration:
            return ["Clip Duration"]
        case .duration:
            return ["Duration"]
        case .sourceIn:
            return ["Source In"]
        case .sourceOut:
            return ["Source Out"]
        case .sourceDuration:
            return ["Source Duration"]
        case .sourcePosition:
            return ["Source Position"]
        case .duplicateFrames:
            return ["Duplicate Frames"]
        case .markers:
            return ["Markers"]
        case .keywords:
            return ["Keywords", "Keyword"]
        case .effects:
            return ["Effects", "Effect"]
        case .notes:
            return ["Notes"]
        case .reel:
            return ["Reel"]
        case .scene:
            return ["Scene"]
        case .take:
            return ["Take"]
        case .cameraAngle:
            return ["Camera Angle"]
        case .cameraName:
            return ["Camera Name"]
        case .frameRateSampleRate:
            return ["Frame Rate/Sample Rate", "Frame Rate", "Sample Rate"]
        case .frameSize:
            return [
                "Frame Size / Audio Config",
                "Frame Size/Audio Config",
                "Frame Size"
            ]
        case .sourceFileName:
            return ["Source File Name"]
        case .sourceFilePath:
            return [
                "Source File Path",
                "Missing Media",
                "Missing Original",
                "Missing Proxy"
            ]
        case .codecs:
            return ["Codecs"]
        case .ingestDate:
            return ["Ingest Date"]
        case .metadata:
            return ["Metadata"]
        }
    }
}
