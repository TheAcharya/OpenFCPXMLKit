//
//  FCPXMLReportRoleExclusion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Filters role-bearing report rows and inventory sheets by excluded role names.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Applies opt-out role filtering to role-bearing report sections.
    ///
    /// Matching is case- and diacritic-insensitive. Excluding a main role also excludes
    /// every `Main ▸ Subrole` value. Empty Role ▸ Subrole fields are kept. Transitions,
    /// Non-Std Effects & Templates, and Media Summary have no clip Role ▸ Subrole and
    /// are not filtered here.
    enum ReportRoleExclusion {
        static func applying(
            excludedRoleNames: [String],
            to section: RoleInventoryReportSection
        ) -> RoleInventoryReportSection {
            let patterns = normalizedPatterns(from: excludedRoleNames)
            guard !patterns.isEmpty else { return section }
            
            let filteredSelectedRoles = section.selectedRoles.filter { row in
                !isRoleFieldExcluded(row.roleSubrole, patterns: patterns)
            }
            
            let filteredRoleSheets = section.roleSheets.filter { sheet in
                !isExcluded(sheet.sheetName, patterns: patterns)
            }
            
            return RoleInventoryReportSection(
                selectedRoles: filteredSelectedRoles,
                roleSheets: filteredRoleSheets,
                metadataColumnKeys: section.metadataColumnKeys,
                showsSpeedChangeSettingsColumn: section.showsSpeedChangeSettingsColumn,
                showsScreenshotsColumn: section.showsScreenshotsColumn
            )
        }
        
        static func applying(
            excludedRoleNames: [String],
            to section: MarkersReportSection
        ) -> MarkersReportSection {
            MarkersReportSection(
                rows: filtering(section.rows, excludedRoleNames: excludedRoleNames) { $0.roleSubrole },
                showsHiddenColumn: section.showsHiddenColumn
            )
        }
        
        static func applying(
            excludedRoleNames: [String],
            to section: KeywordsReportSection
        ) -> KeywordsReportSection {
            KeywordsReportSection(
                rows: filtering(section.rows, excludedRoleNames: excludedRoleNames) { $0.roleSubrole }
            )
        }
        
        static func applying(
            excludedRoleNames: [String],
            to section: TitlesReportSection
        ) -> TitlesReportSection {
            TitlesReportSection(
                rows: filtering(section.rows, excludedRoleNames: excludedRoleNames) { $0.roleSubrole }
            )
        }
        
        static func applying(
            excludedRoleNames: [String],
            to section: EffectsReportSection
        ) -> EffectsReportSection {
            EffectsReportSection(
                rows: filtering(section.rows, excludedRoleNames: excludedRoleNames) { $0.roleSubrole }
            )
        }
        
        static func applying(
            excludedRoleNames: [String],
            to section: SpeedChangeEffectsReportSection
        ) -> SpeedChangeEffectsReportSection {
            SpeedChangeEffectsReportSection(
                rows: filtering(section.rows, excludedRoleNames: excludedRoleNames) { $0.roleSubrole }
            )
        }
        
        /// Drops inventory components whose role field matches, so Summary subtotals recompute.
        static func filteringComponents(
            _ components: [RoleInventoryClipComponent],
            excludedRoleNames: [String]
        ) -> [RoleInventoryClipComponent] {
            filtering(components, excludedRoleNames: excludedRoleNames) { $0.roleSubroleField }
        }
        
        static func isRoleFieldExcluded(
            _ roleField: String,
            excludedRoleNames: [String]
        ) -> Bool {
            isRoleFieldExcluded(roleField, patterns: normalizedPatterns(from: excludedRoleNames))
        }
        
        private static func filtering<Row>(
            _ rows: [Row],
            excludedRoleNames: [String],
            roleSubrole: (Row) -> String
        ) -> [Row] {
            let patterns = normalizedPatterns(from: excludedRoleNames)
            guard !patterns.isEmpty else { return rows }
            return rows.filter { !isRoleFieldExcluded(roleSubrole($0), patterns: patterns) }
        }
        
        private static func isRoleFieldExcluded(
            _ roleField: String,
            patterns: [String]
        ) -> Bool {
            guard !patterns.isEmpty else { return false }
            return RoleInventoryRoleSheetOrdering.roleNames(in: roleField).contains { roleName in
                isExcluded(roleName, patterns: patterns)
            }
        }
        
        private static func normalizedPatterns(from excludedRoleNames: [String]) -> [String] {
            excludedRoleNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        private static func isExcluded(_ roleName: String, patterns: [String]) -> Bool {
            let normalizedRoleName = roleName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedRoleName.isEmpty else { return false }
            
            for pattern in patterns {
                if roleNamesMatch(normalizedRoleName, pattern) {
                    return true
                }
                
                if let separator = normalizedRoleName.range(of: " ▸ ") {
                    let mainRole = String(normalizedRoleName[..<separator.lowerBound])
                    if roleNamesMatch(mainRole, pattern) {
                        return true
                    }
                }
            }
            
            return false
        }
        
        private static func roleNamesMatch(_ lhs: String, _ rhs: String) -> Bool {
            lhs.compare(rhs, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
}
