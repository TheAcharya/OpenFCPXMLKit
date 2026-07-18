//
//  FCPXMLRoleInventoryRoleSheetOrdering.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tab order for per-role inventory sheets (derived from role names and clip categories).
//

import Foundation

extension FinalCutPro.FCPXML {
    enum RoleInventoryRoleSheetOrdering {
        private enum MainRoleGroup: Int {
            case gap = 0
            case caption = 1
            case title = 2
            case video = 3
            case customVideo = 4
            case audio = 5
            case customAudio = 6
            case unknown = 7
            
            /// Video-family groups receive a synthetic parent tab when only subrole
            /// sheets exist. Audio-family groups (the built-in dialogue, effects, and music
            /// roles plus custom audio roles such as atmosphere) never get an empty parent tab,
            /// matching Final Cut Pro.
            var synthesizesEmptyParentTab: Bool {
                switch self {
                case .gap, .caption, .title, .video, .customVideo:
                    return true
                case .audio, .customAudio, .unknown:
                    return false
                }
            }
        }
        
        /// Built-in main roles in their conventional workbook order. Roles outside this list
        /// (for example custom audio roles such as `atmosphere`) sort after the built-ins.
        private static let builtInMainRoleOrder: [String] = [
            "gap",
            "srt",
            "titles",
            "video",
            "dialogue",
            "effects",
            "music"
        ]
        
        static func sortedRoleNames(
            _ roleNames: [String],
            rowsByName: [String: [RoleClipReportRow]] = [:]
        ) -> [String] {
            Array(Set(roleNames)).sorted { lhs, rhs in
                sortKey(for: lhs, rowsByName: rowsByName)
                    < sortKey(for: rhs, rowsByName: rowsByName)
            }
        }
        
        /// Excel-compatible sheet tab name (31-character limit).
        static func sheetTabName(for roleName: String) -> String {
            let invalidCharacters = CharacterSet(charactersIn: ":\\/?*[]")
            let sanitized = roleName.unicodeScalars.map { scalar -> Character in
                if invalidCharacters.contains(scalar) {
                    return "_"
                }
                return Character(scalar)
            }
            
            let string = String(sanitized).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !string.isEmpty else { return "Sheet" }
            
            if string.count <= 31 {
                return string
            }
            
            return String(string.prefix(31))
        }
        
        static func roleNames(in roleField: String) -> [String] {
            let parts = roleField
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            guard !parts.isEmpty else { return [] }
            
            var names: [String] = []
            var index = 0
            
            while index < parts.count {
                let part = parts[index]
                
                if let separator = part.range(of: " ▸ ") {
                    let mainRole = String(part[..<separator.lowerBound])
                    var subroles = [String(part[separator.upperBound...])]
                    index += 1
                    
                    while index < parts.count, !parts[index].contains("▸") {
                        subroles.append(parts[index])
                        index += 1
                    }
                    
                    for subrole in subroles {
                        names.append("\(mainRole) ▸ \(subrole)")
                    }
                } else {
                    names.append(part)
                    index += 1
                }
            }
            
            return names
        }
        
        /// Bare subrole labels referenced in a combined inventory role field.
        static func subroleLabels(in roleField: String) -> Set<String> {
            Set(
                roleNames(in: roleField).compactMap { roleName in
                    parseMainAndSubrole(roleName).sub
                }
            )
        }
        
        /// Maps each subrole label to every `Main Role ▸ Subrole` name seen in the inventory.
        static func subroleRoleIndex(
            from selectedRoles: [RoleClipReportRow]
        ) -> [String: Set<String>] {
            var index: [String: Set<String>] = [:]
            
            for row in selectedRoles {
                for roleName in roleNames(in: row.roleSubrole) {
                    guard let subrole = parseMainAndSubrole(roleName).sub else { continue }
                    index[subrole, default: []].insert(roleName)
                }
            }
            
            return index
        }
        
        /// Role sheet names a row should appear on (parsed roles plus shared-subrole targets).
        static func sheetRoleTargets(
            for row: RoleClipReportRow,
            subroleIndex: [String: Set<String>]
        ) -> Set<String> {
            sheetRoleTargets(
                forRoleField: row.roleSubrole,
                subroleIndex: subroleIndex
            )
        }
        
        /// Shared-subrole sheet targets for a combined inventory role field.
        static func sheetRoleTargets(
            forRoleField roleField: String,
            subroleIndex: [String: Set<String>]
        ) -> Set<String> {
            var targets = Set(roleNames(in: roleField))
            
            for subrole in subroleLabels(in: roleField) {
                guard let sharedRoles = subroleIndex[subrole] else { continue }
                targets.formUnion(sharedRoles)
            }
            
            return targets
        }
        
        /// Maps each subrole label to every `Main Role ▸ Subrole` name in component fields.
        static func subroleRoleIndex(
            from components: [RoleInventoryClipComponent]
        ) -> [String: Set<String>] {
            var index: [String: Set<String>] = [:]
            
            for component in components {
                for roleName in roleNames(in: component.roleSubroleField) {
                    guard let subrole = parseMainAndSubrole(roleName).sub else { continue }
                    index[subrole, default: []].insert(roleName)
                }
            }
            
            return index
        }
        
        static func roleSheets(from selectedRoles: [RoleClipReportRow]) -> [RoleSheet] {
            var rolesByName: [String: [RoleClipReportRow]] = [:]
            let subroleIndex = subroleRoleIndex(from: selectedRoles)
            
            for row in selectedRoles {
                for roleName in sheetRoleTargets(for: row, subroleIndex: subroleIndex) {
                    let sheetName = sheetTabName(for: roleName)
                    rolesByName[sheetName, default: []].append(row)
                }
            }
            
            for parentName in parentNamesWithChildSheets(in: rolesByName.keys) {
                // Preserve parents that already carry bare-role rows (for example `Video`).
                if rolesByName[parentName] != nil { continue }
                
                let childRows = rowsForSortContext(roleName: parentName, rowsByName: rolesByName)
                guard mainRoleGroup(for: parentName, rows: childRows).synthesizesEmptyParentTab
                else { continue }
                
                rolesByName[parentName] = []
            }
            
            return sortedRoleNames(Array(rolesByName.keys), rowsByName: rolesByName).map { roleName in
                RoleSheet(
                    sheetName: roleName,
                    rows: rolesByName[roleName] ?? []
                )
            }
        }
        
        private static func parentNamesWithChildSheets(
            in sheetNames: some Collection<String>
        ) -> Set<String> {
            var parents = Set<String>()
            
            for name in sheetNames {
                guard let separator = name.range(of: " ▸ ") else { continue }
                parents.insert(String(name[..<separator.lowerBound]))
            }
            
            return parents
        }
        
        private static func sortKey(
            for roleName: String,
            rowsByName: [String: [RoleClipReportRow]]
        ) -> (Int, Int, String, Int, Int, String) {
            let (mainRole, subrole) = parseMainAndSubrole(roleName)
            let rows = rowsForSortContext(roleName: roleName, rowsByName: rowsByName)
            let group = mainRoleGroup(for: mainRole, rows: rows).rawValue
            let builtInRank = builtInMainRoleRank(mainRole)
            let parentRank = subrole == nil ? 0 : 1
            let subroleRank = subroleSortRank(subrole ?? "")
            let subroleLabel = subrole ?? roleName
            
            return (group, builtInRank, mainRole, parentRank, subroleRank, subroleLabel)
        }
        
        private static func parseMainAndSubrole(_ roleName: String) -> (main: String, sub: String?) {
            guard let separator = roleName.range(of: " ▸ ") else {
                return (roleName, nil)
            }
            
            return (
                String(roleName[..<separator.lowerBound]),
                String(roleName[separator.upperBound...])
            )
        }
        
        private static func builtInMainRoleRank(_ mainRole: String) -> Int {
            builtInMainRoleOrder.firstIndex(of: mainRole.lowercased()) ?? Int.max
        }
        
        private static func rowsForSortContext(
            roleName: String,
            rowsByName: [String: [RoleClipReportRow]]
        ) -> [RoleClipReportRow] {
            if let rows = rowsByName[roleName], !rows.isEmpty {
                return rows
            }
            
            let childPrefix = "\(roleName) ▸ "
            return rowsByName
                .filter { $0.key.hasPrefix(childPrefix) }
                .flatMap(\.value)
        }
        
        private static func mainRoleGroup(
            for mainRole: String,
            rows: [RoleClipReportRow]
        ) -> MainRoleGroup {
            switch mainRole.lowercased() {
            case "gap":
                return .gap
            case "srt":
                return .caption
            case "titles":
                return .title
            case "video":
                return .video
            case "dialogue", "effects", "music":
                return .audio
            default:
                break
            }
            
            guard !rows.isEmpty else { return .unknown }
            
            let videoCount = rows.filter { isVideoCategory($0.category) }.count
            let audioCount = rows.filter { isAudioCategory($0.category) }.count
            
            if videoCount > audioCount {
                return .customVideo
            }
            if audioCount > videoCount {
                return .customAudio
            }
            
            return .unknown
        }
        
        private static func isVideoCategory(_ category: String) -> Bool {
            ReportClipCategory.matchingWorkbookLabel(category)?.isVideoCategory ?? false
        }
        
        private static func isAudioCategory(_ category: String) -> Bool {
            ReportClipCategory.matchingWorkbookLabel(category)?.isAudioCategory ?? false
        }
        
        private static func subroleSortRank(_ subrole: String) -> Int {
            let lower = subrole.lowercased()
            if lower.hasPrefix("mix") { return 0 }
            if lower.hasPrefix("boom") { return 1 }
            if lower.hasPrefix("r_") { return 2 }
            return 3
        }
    }
}
