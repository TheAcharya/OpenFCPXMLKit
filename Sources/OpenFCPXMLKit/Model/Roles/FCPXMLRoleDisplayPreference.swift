//
//  FCPXMLRoleDisplayPreference.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Role priority tables for choosing which role to surface on compound clips.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Chooses which inherited role to prefer when a clip carries more than one.
    ///
    /// Built-in FCP main-role names live in ``builtIn``. Project-specific role names
    /// (for example custom library roles) belong in ``ReportOptions/roleDisplayPreference``.
    public struct RoleDisplayPreference: Sendable, Equatable {
        /// Workbook contexts that pick a single preferred role.
        public enum Context: Sendable {
            case markers
            case videoEffects
            case audioEffects
        }
        
        public var markerRolePriority: [String]
        public var videoEffectRolePriority: [String]
        public var audioEffectRolePriority: [String]
        
        public init(
            markerRolePriority: [String],
            videoEffectRolePriority: [String],
            audioEffectRolePriority: [String]
        ) {
            self.markerRolePriority = markerRolePriority
            self.videoEffectRolePriority = videoEffectRolePriority
            self.audioEffectRolePriority = audioEffectRolePriority
        }
        
        public func rolePriority(for context: Context) -> [String] {
            switch context {
            case .markers:
                return markerRolePriority
            case .videoEffects:
                return videoEffectRolePriority
            case .audioEffects:
                return audioEffectRolePriority
            }
        }
        
        /// Returns the preferred role from an inherited role list, if any match the priority table.
        /// Falls back to the first role sorted by type (video, audio, caption) then name.
        public func preferredRole(
            from roles: [AnyInterpolatedRole],
            context: Context
        ) -> AnyInterpolatedRole? {
            for name in rolePriority(for: context) {
                if let match = roles.first(where: { $0.wrapped.role.lowercased() == name }) {
                    return match
                }
            }
            
            return roles.sortedByRoleTypeThenByName().first
        }
        
        /// Sort rank when a keyword expands to multiple main-role display strings.
        public static func keywordSortRank(for mainRoleDisplay: String) -> Int {
            switch mainRoleDisplay.lowercased() {
            case "video": return 0
            case "dialogue": return 1
            case "titles": return 2
            case "srt": return 3
            case "effects": return 4
            case "music": return 5
            default: return 100
            }
        }
        
        /// Default priorities using Final Cut Pro built-in main role names only.
        public static let builtIn = RoleDisplayPreference(
            markerRolePriority: [
                "dialogue",
                "video",
                "titles",
                "srt",
                "effects",
                "music"
            ],
            videoEffectRolePriority: [
                "video",
                "titles",
                "dialogue",
                "srt",
                "effects",
                "music"
            ],
            audioEffectRolePriority: [
                "dialogue",
                "effects",
                "music",
                "video",
                "titles",
                "srt"
            ]
        )
    }
}
