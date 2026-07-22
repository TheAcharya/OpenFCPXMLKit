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
        ///
        /// Effects contexts only consider matching media types (video/caption for video effects,
        /// audio for audio effects) so a clip that only writes `audioRole` cannot paint a video
        /// filter with Dialogue/Effects green text. Markers may still cross types.
        ///
        /// Falls back to the first eligible role sorted by type then name.
        public func preferredRole(
            from roles: [AnyInterpolatedRole],
            context: Context
        ) -> AnyInterpolatedRole? {
            let candidates = rolesEligible(for: context, in: roles)
            
            for name in rolePriority(for: context) {
                if let match = candidates.first(where: { $0.wrapped.role.lowercased() == name }) {
                    return match
                }
            }
            
            return candidates.sortedByRoleTypeThenByName().first
        }
        
        /// Roles that may surface for the given report context.
        private func rolesEligible(
            for context: Context,
            in roles: [AnyInterpolatedRole]
        ) -> [AnyInterpolatedRole] {
            switch context {
            case .markers:
                return roles
            case .videoEffects:
                return roles.filter { $0.isVideo || $0.isCaption }
            case .audioEffects:
                return roles.filter(\.isAudio)
            }
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
        ///
        /// FCP reserved defaults are Video, Titles, Dialogue, Effects, and Music
        /// (plus caption formats such as SRT). Custom library roles such as VFX,
        /// Atmosphere, Score Composer, or Sound Mix are **not** FCP defaults — put
        /// those in ``ReportOptions/roleDisplayPreference`` when a project needs them.
        ///
        /// Effects contexts also filter by ``RoleType`` (video vs audio), so any
        /// custom role of the correct type is still eligible via the sorted fallback
        /// even when it is absent from these priority tables.
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
                "srt"
            ],
            audioEffectRolePriority: [
                "dialogue",
                "effects",
                "music"
            ]
        )
    }
}
