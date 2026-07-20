//
//  FCPXMLRoleInventoryColumnLayout.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Selected Roles Inventory workbook column order (fixed + dynamic metadata keys).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Column layout for Selected Roles Inventory and per-role sheets.
    enum RoleInventoryColumnLayout {
        /// Row index column prepended to every inventory sheet.
        static let rowColumnHeader = "Row"
        
        /// Fixed inventory columns in export order (excluding ``rowColumnHeader`` and metadata keys).
        static let fixedColumns: [ReportColumn] = [
            .roleSubrole,
            .clipName,
            .category,
            .enabled,
            .timelineIn,
            .timelineOut,
            .clipDuration,
            .sourceIn,
            .sourceOut,
            .sourceDuration,
            .duplicateFrames,
            .markers,
            .keywords,
            .effects,
            .notes,
            .reel,
            .scene,
            .take,
            .cameraAngle,
            .cameraName,
            .frameRateSampleRate,
            .frameSize,
            .sourceFileName,
            .sourceFilePath,
            .codecs,
            .ingestDate
        ]
        
        /// Fixed inventory column headers excluding ``rowColumnHeader`` and dynamic metadata keys.
        static let fixedColumnHeaders: [String] = fixedColumnHeaders(timecodeFormat: .smpteFrames)
        
        static func fixedColumnHeaders(
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) -> [String] {
            fixedColumns.compactMap { $0.workbookHeader(timecodeFormat: timecodeFormat) }
        }
        
        /// Metadata keys that already have dedicated inventory columns and are omitted from
        /// the dynamic metadata key columns appended after the fixed block.
        static let metadataKeysExcludedFromDynamicColumns: Set<String> = [
            Metadata.Key.reel.rawValue,
            Metadata.Key.scene.rawValue,
            Metadata.Key.take.rawValue,
            Metadata.Key.cameraName.rawValue,
            Metadata.Key.codecs.rawValue,
            Metadata.Key.ingestDate.rawValue
        ]
        
        /// Full header row for an inventory sheet.
        static func columnHeaders(
            metadataColumnKeys: [String],
            excludedColumns: Set<ReportColumn> = [],
            timecodeFormat: ReportTimecodeFormat = .smpteFrames
        ) -> [String] {
            var headers: [String] = []
            
            if !excludedColumns.contains(.row),
               let header = ReportColumn.row.workbookHeader(timecodeFormat: timecodeFormat)
            {
                headers.append(header)
            }
            
            for column in fixedColumns {
                guard !excludedColumns.contains(column),
                      let header = column.workbookHeader(timecodeFormat: timecodeFormat)
                else { continue }
                headers.append(header)
            }
            
            if !excludedColumns.contains(.metadata) {
                headers.append(contentsOf: metadataColumnKeys)
            }
            
            return headers
        }
        
        /// Discovers sorted metadata column keys present in any inventory row.
        static func metadataColumnKeys(from rows: [RoleClipReportRow]) -> [String] {
            var keys = Set<String>()
            for row in rows {
                keys.formUnion(row.metadataValues.keys)
            }
            keys.subtract(metadataKeysExcludedFromDynamicColumns)
            return keys.sorted()
        }
        
        /// Column values for one inventory row, excluding the row index (supplied at export).
        static func columnValues(
            for row: RoleClipReportRow,
            metadataColumnKeys: [String],
            excludedColumns: Set<ReportColumn> = []
        ) -> [String] {
            columnEntries(
                for: row,
                rowIndex: 0,
                metadataColumnKeys: metadataColumnKeys,
                excludedColumns: excludedColumns
            ).map(\.value)
        }
        
        /// Column values including the 1-based row index in the first column.
        static func columnValues(
            for row: RoleClipReportRow,
            rowIndex: Int,
            metadataColumnKeys: [String],
            excludedColumns: Set<ReportColumn> = []
        ) -> [String] {
            columnEntries(
                for: row,
                rowIndex: rowIndex,
                metadataColumnKeys: metadataColumnKeys,
                excludedColumns: excludedColumns
            ).map(\.value)
        }
        
        private struct ColumnEntry {
            let header: String
            let value: String
        }
        
        private static func columnEntries(
            for row: RoleClipReportRow,
            rowIndex: Int,
            metadataColumnKeys: [String],
            excludedColumns: Set<ReportColumn>
        ) -> [ColumnEntry] {
            var entries: [ColumnEntry] = []
            
            if !excludedColumns.contains(.row),
               let header = ReportColumn.row.exportHeader
            {
                entries.append(ColumnEntry(header: header, value: String(rowIndex)))
            }
            
            for column in fixedColumns {
                guard !excludedColumns.contains(column),
                      let header = column.exportHeader
                else { continue }
                
                entries.append(
                    ColumnEntry(header: header, value: value(for: column, in: row))
                )
            }
            
            if !excludedColumns.contains(.metadata) {
                for key in metadataColumnKeys {
                    entries.append(
                        ColumnEntry(header: key, value: row.metadataValues[key] ?? "")
                    )
                }
            }
            
            return entries
        }
        
        private static func value(
            for column: ReportColumn,
            in row: RoleClipReportRow
        ) -> String {
            switch column {
            case .row, .metadata, .duration, .sourcePosition:
                return ""
            case .roleSubrole:
                return row.roleSubrole
            case .clipName:
                return row.clipName
            case .category:
                return row.category
            case .enabled:
                return row.enabled
            case .timelineIn:
                return row.timelineIn
            case .timelineOut:
                return row.timelineOut
            case .clipDuration:
                return row.clipDuration
            case .sourceIn:
                return row.sourceIn
            case .sourceOut:
                return row.sourceOut
            case .sourceDuration:
                return row.sourceDuration
            case .duplicateFrames:
                return row.duplicateFrames
            case .markers:
                return row.markers
            case .keywords:
                return row.keywords
            case .effects:
                return row.effects
            case .notes:
                return row.notes
            case .reel:
                return row.reel
            case .scene:
                return row.scene
            case .take:
                return row.take
            case .cameraAngle:
                return row.cameraAngle
            case .cameraName:
                return row.cameraName
            case .frameRateSampleRate:
                return row.frameRateSampleRate
            case .frameSize:
                return row.frameSize
            case .sourceFileName:
                return row.sourceFileName
            case .sourceFilePath:
                return row.sourceFilePath
            case .codecs:
                return row.codecs
            case .ingestDate:
                return row.ingestDate
            }
        }
    }
}

