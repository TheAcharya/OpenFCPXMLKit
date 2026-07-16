//
//  FCPXMLSummaryRoleDurationAggregator.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Aggregates role inventory component rows into Summary sheet role totals.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Builds Summary role-duration rows from component-level inventory clips.
    enum SummaryRoleDurationAggregator {
        private enum SummarySection {
            case visual
            case audio
        }
        
        static func roleDurationRows(
            from components: [RoleInventoryClipComponent],
            projectDurationSeconds: Double,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat = .smpteFrames,
            overlapAware: Bool = false,
            projectionWindows: [MediaUsageWindow]? = nil
        ) -> [SummaryRoleDurationRow] {
            let subroleIndex = RoleInventoryRoleSheetOrdering.subroleRoleIndex(from: components)
            let roleNames = uniqueRoleNames(from: components, subroleIndex: subroleIndex)
            let categoriesByRole = roleCategoriesByName(
                from: components,
                subroleIndex: subroleIndex
            )
            let occupancy = projectionWindows.map { TimelineOccupancyIndex(windows: $0) }
            
            let rowData = roleNames
                .compactMap { roleName -> (SummaryRoleDurationRow, SummarySection, Double)? in
                    let categories = categoriesByRole[roleName] ?? []
                    let totalSeconds = estimatedTotalSeconds(
                        for: roleName,
                        in: components,
                        categories: categories,
                        subroleIndex: subroleIndex,
                        overlapAware: overlapAware,
                        occupancy: occupancy
                    )
                    guard totalSeconds > 0 else { return nil }
                    
                    let percent = projectDurationSeconds > 0
                        ? totalSeconds / projectDurationSeconds
                        : 0
                    
                    let row = SummaryRoleDurationRow(
                        roleSubrole: roleName,
                        estimatedTotal: timecodeString(
                            seconds: totalSeconds,
                            timeline: timeline,
                            resources: resources,
                            timecodeFormat: timecodeFormat
                        ),
                        percentOfTotal: percent
                    )
                    
                    guard !row.estimatedTotal.isEmpty else { return nil }
                    
                    return (
                        row,
                        summarySection(for: roleName, categories: categories),
                        totalSeconds
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 {
                        return lhs.1 == .visual
                    }
                    
                    if lhs.2 != rhs.2 {
                        return lhs.2 > rhs.2
                    }
                    
                    return lhs.0.roleSubrole.localizedStandardCompare(rhs.0.roleSubrole) == .orderedAscending
                }
            
            return insertingSectionSubtotals(
                rowData,
                projectDurationSeconds: projectDurationSeconds,
                timeline: timeline,
                resources: resources,
                timecodeFormat: timecodeFormat,
                overlapAware: overlapAware,
                occupancy: occupancy,
                components: components
            )
        }
        
        private static func insertingSectionSubtotals(
            _ rows: [(row: SummaryRoleDurationRow, section: SummarySection, seconds: Double)],
            projectDurationSeconds: Double,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat,
            overlapAware: Bool = false,
            occupancy: TimelineOccupancyIndex? = nil,
            components: [RoleInventoryClipComponent] = []
        ) -> [SummaryRoleDurationRow] {
            guard !rows.isEmpty else { return [] }
            
            var result: [SummaryRoleDurationRow] = []
            var visualSeconds = 0.0
            var insertedVisualSubtotal = false
            let visualComponents = components.filter {
                summarySection(
                    for: mainRoleName(in: $0.roleSubroleField),
                    categories: [$0.category]
                ) == .visual
            }
            
            for entry in rows {
                if entry.section == .audio, !insertedVisualSubtotal {
                    let subtotalSeconds: Double
                    if overlapAware {
                        subtotalSeconds = unionSeconds(for: visualComponents)
                    } else {
                        subtotalSeconds = visualSeconds
                    }
                    if subtotalSeconds > 0 {
                        result.append(
                            subtotalRow(
                                seconds: subtotalSeconds,
                                projectDurationSeconds: projectDurationSeconds,
                                timeline: timeline,
                                resources: resources,
                                timecodeFormat: timecodeFormat
                            )
                        )
                    }
                    insertedVisualSubtotal = true
                }
                
                if entry.section == .visual {
                    visualSeconds += entry.seconds
                }
                
                result.append(entry.row)
            }
            
            return result
        }
        
        private static func subtotalRow(
            seconds: Double,
            projectDurationSeconds: Double,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> SummaryRoleDurationRow {
            let percent = projectDurationSeconds > 0
                ? seconds / projectDurationSeconds
                : 0
            
            return SummaryRoleDurationRow(
                roleSubrole: "",
                estimatedTotal: timecodeString(
                    seconds: seconds,
                    timeline: timeline,
                    resources: resources,
                    timecodeFormat: timecodeFormat
                ),
                percentOfTotal: percent
            )
        }
        
        private static func summarySection(
            for roleName: String,
            categories: Set<ReportClipCategory>
        ) -> SummarySection {
            let mainRole = mainRoleName(in: roleName)
            
            switch mainRole.lowercased() {
            case "gap", "titles", "video", "srt":
                return .visual
            case "dialogue", "effects", "music":
                return .audio
            default:
                return dominantSection(for: categories)
            }
        }
        
        private static func dominantSection(
            for categories: Set<ReportClipCategory>
        ) -> SummarySection {
            let audioCount = categories.filter(\.isAudioCategory).count
            let visualCount = categories.filter {
                $0.isVideoCategory || $0.isTitleCategory || $0.isCaptionCategory || $0 == .primaryGap
            }.count
            
            return audioCount > visualCount ? .audio : .visual
        }
        
        private static func roleCategoriesByName(
            from components: [RoleInventoryClipComponent],
            subroleIndex: [String: Set<String>]
        ) -> [String: Set<ReportClipCategory>] {
            var categoriesByRole: [String: Set<ReportClipCategory>] = [:]
            
            for component in components {
                let targets = RoleInventoryRoleSheetOrdering.sheetRoleTargets(
                    forRoleField: component.roleSubroleField,
                    subroleIndex: subroleIndex
                )
                
                for roleName in targets {
                    categoriesByRole[roleName, default: []].insert(component.category)
                }
            }
            
            return categoriesByRole
        }
        
        private static func uniqueRoleNames(
            from components: [RoleInventoryClipComponent],
            subroleIndex: [String: Set<String>]
        ) -> [String] {
            var names: Set<String> = []
            
            for component in components {
                let targets = RoleInventoryRoleSheetOrdering.sheetRoleTargets(
                    forRoleField: component.roleSubroleField,
                    subroleIndex: subroleIndex
                )
                names.formUnion(targets)
            }
            
            return Array(names)
        }
        
        private static func roleNames(in roleField: String) -> [String] {
            RoleInventoryRoleSheetOrdering.roleNames(in: roleField)
        }
        
        private static func mainRoleName(in roleName: String) -> String {
            guard let separator = roleName.range(of: " ▸ ") else {
                return roleName
            }
            
            return String(roleName[..<separator.lowerBound])
        }
        
        private static func estimatedTotalSeconds(
            for roleName: String,
            in components: [RoleInventoryClipComponent],
            categories: Set<ReportClipCategory>,
            subroleIndex: [String: Set<String>],
            overlapAware: Bool = false,
            occupancy: TimelineOccupancyIndex? = nil
        ) -> Double {
            let matching = components.filter { component in
                RoleInventoryRoleSheetOrdering.sheetRoleTargets(
                    forRoleField: component.roleSubroleField,
                    subroleIndex: subroleIndex
                ).contains(roleName)
            }

            let policyFiltered: [RoleInventoryClipComponent]
            switch aggregationPolicy(
                for: roleName,
                matching: matching,
                categories: categories
            ) {
            case .exactRoleField:
                policyFiltered = matching.filter { $0.roleSubroleField == roleName }
            case .videoCategories:
                policyFiltered = matching.filter { $0.category.isVideoCategory }
            case .audioCategories:
                policyFiltered = matching.filter { $0.category.isAudioCategory }
            case .captionCategories:
                policyFiltered = matching.filter { $0.category.isCaptionCategory }
            case .allMatchingComponents:
                policyFiltered = matching
            }

            if overlapAware {
                // Prefer projection occupancy when windows carry matching role annotations.
                if let occupancy,
                   let fromWindows = occupiedSecondsFromWindows(
                    occupancy: occupancy,
                    roleName: roleName
                   ),
                   fromWindows > 0
                {
                    return fromWindows
                }
                return unionSeconds(for: policyFiltered)
            }

            return policyFiltered.reduce(0) { $0 + $1.durationSeconds }
        }

        private static func unionSeconds(for components: [RoleInventoryClipComponent]) -> Double {
            let intervals: [TimelineOccupancyIndex.Interval] = components.compactMap { component in
                guard let start = component.timelineStartSeconds,
                      let end = component.timelineEndSeconds,
                      end > start
                else { return nil }
                return TimelineOccupancyIndex.Interval(start: start, end: end)
            }
            if intervals.isEmpty {
                return components.reduce(0) { $0 + $1.durationSeconds }
            }
            return TimelineOccupancyIndex.unionDuration(intervals)
        }

        private static func occupiedSecondsFromWindows(
            occupancy: TimelineOccupancyIndex,
            roleName: String
        ) -> Double? {
            let hasAnnotatedRoles = occupancy.windows.contains { !$0.roles.isEmpty }
            guard hasAnnotatedRoles else { return nil }
            let main = mainRoleName(in: roleName).lowercased()
            return occupancy.occupiedDuration { window in
                window.roles.contains { role in
                    let raw = role.wrapped.rawValue.lowercased()
                    return raw == main
                        || raw.hasPrefix(main + ".")
                        || roleName.lowercased().contains(raw)
                }
            }
        }
        
        private enum AggregationPolicy {
            case exactRoleField
            case videoCategories
            case audioCategories
            case captionCategories
            case allMatchingComponents
        }
        
        private static func aggregationPolicy(
            for roleName: String,
            matching: [RoleInventoryClipComponent],
            categories: Set<ReportClipCategory>
        ) -> AggregationPolicy {
            switch roleName {
            case "Titles", "Gap":
                return .exactRoleField
            case "Video":
                return .videoCategories
            default:
                break
            }
            
            let mainRole = mainRoleName(in: roleName)
            let hasSubrole = roleName.contains(" ▸ ")
            
            if !hasSubrole, mainRole.lowercased() == "dialogue" {
                return .exactRoleField
            }
            
            if isBuiltInAudioMainRole(mainRole) {
                return .audioCategories
            }
            
            if hasSubrole {
                let audioCount = matching.filter(\.category.isAudioCategory).count
                let videoCount = matching.filter(\.category.isVideoCategory).count
                
                if audioCount > 0, videoCount > 0 {
                    return audioCount >= videoCount ? .audioCategories : .videoCategories
                }
            }
            
            if mainRole.lowercased() == "srt"
                || categories.allSatisfy(\.isCaptionCategory)
            {
                return .captionCategories
            }
            
            let videoCount = matching.filter(\.category.isVideoCategory).count
            let audioCount = matching.filter(\.category.isAudioCategory).count
            let captionCount = matching.filter(\.category.isCaptionCategory).count
            
            if captionCount > 0, videoCount == 0, audioCount == 0 {
                return .captionCategories
            }
            if videoCount > 0, audioCount == 0, captionCount == 0 {
                return .videoCategories
            }
            if audioCount > 0, videoCount == 0, captionCount == 0 {
                return .audioCategories
            }
            
            return .allMatchingComponents
        }
        
        private static func isBuiltInAudioMainRole(_ mainRole: String) -> Bool {
            switch mainRole.lowercased() {
            case "dialogue", "effects", "music":
                return true
            default:
                return false
            }
        }
        
        private static func timecodeString(
            seconds: Double,
            timeline: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            timecodeFormat: ReportTimecodeFormat
        ) -> String {
            guard let frameRate = timeline._fcpTimecodeFrameRate(in: resources),
                  let timecode = try? Timecode(
                    .realTime(seconds: max(0, seconds)),
                    at: frameRate
                  )
            else { return "" }
            
            return ReportFormatting.timecodeString(timecode, format: timecodeFormat)
        }
    }
}
