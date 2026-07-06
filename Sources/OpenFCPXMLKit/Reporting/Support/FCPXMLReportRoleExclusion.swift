//
//  FCPXMLReportRoleExclusion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Filters role inventory rows and sheets by excluded role names.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Applies opt-out role filtering to a role inventory section.
    enum ReportRoleExclusion {
        static func applying(
            excludedRoleNames: [String],
            to section: RoleInventoryReportSection
        ) -> RoleInventoryReportSection {
            let patterns = normalizedPatterns(from: excludedRoleNames)
            guard !patterns.isEmpty else { return section }
            
            let filteredSelectedRoles = section.selectedRoles.filter { row in
                !RoleInventoryRoleSheetOrdering.roleNames(in: row.roleSubrole).contains { roleName in
                    isExcluded(roleName, patterns: patterns)
                }
            }
            
            let filteredRoleSheets = section.roleSheets.filter { sheet in
                !isExcluded(sheet.sheetName, patterns: patterns)
            }
            
            return RoleInventoryReportSection(
                selectedRoles: filteredSelectedRoles,
                roleSheets: filteredRoleSheets,
                metadataColumnKeys: section.metadataColumnKeys
            )
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
