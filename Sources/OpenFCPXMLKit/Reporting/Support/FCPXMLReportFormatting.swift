//
//  FCPXMLReportFormatting.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Formatting helpers for report output.
//

import Foundation
import SwiftTimecode
internal import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Formats extracted values into workbook report column strings.
    enum ReportFormatting {
        /// SMPTE timecode for workbook cells (format controlled by ``ReportTimecodeFormat``).
        ///
        /// Default is ``ReportTimecodeFormat/smpteFrames`` (`HH:MM:SS:FF` or `HH:MM:SS;FF`).
        static func timecodeString(
            _ timecode: Timecode,
            format: ReportTimecodeFormat = .smpteFrames
        ) -> String {
            switch format {
            case .smpteFrames:
                return timecode.stringValue()
            case .frames:
                return String(timecode.frameCount.wholeFrames)
            case .feetAndFrames:
                return timecode.feetAndFramesValue.stringValue
            case .smpteNoFrames:
                return String(
                    format: "%02d:%02d:%02d",
                    timecode.hours,
                    timecode.minutes,
                    timecode.seconds
                )
            }
        }
        
        /// Compares formatted timeline position strings for row sorting.
        static func compareTimelinePositions(
            _ lhs: String,
            _ rhs: String,
            format: ReportTimecodeFormat
        ) -> ComparisonResult {
            switch format {
            case .frames:
                return compareNumericIntegers(lhs, rhs)
            case .feetAndFrames:
                return compareFeetAndFrames(lhs, rhs)
            default:
                return lhs.localizedStandardCompare(rhs)
            }
        }
        
        private static func compareNumericIntegers(
            _ lhs: String,
            _ rhs: String
        ) -> ComparisonResult {
            let left = Int(lhs) ?? Int.min
            let right = Int(rhs) ?? Int.min
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
            return .orderedSame
        }
        
        private static func compareFeetAndFrames(
            _ lhs: String,
            _ rhs: String
        ) -> ComparisonResult {
            let left = parseFeetAndFrames(lhs)
            let right = parseFeetAndFrames(rhs)
            
            if left.feet != right.feet {
                return left.feet < right.feet ? .orderedAscending : .orderedDescending
            }
            if left.frames != right.frames {
                return left.frames < right.frames ? .orderedAscending : .orderedDescending
            }
            return .orderedSame
        }
        
        private static func parseFeetAndFrames(_ value: String) -> (feet: Int, frames: Int) {
            let parts = value.split(separator: "+", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let feet = Int(parts[0]),
                  let frames = Int(parts[1])
            else {
                return (Int.min, Int.min)
            }
            return (feet, frames)
        }
        
        static func markerReportType(
            for configuration: Marker.Configuration
        ) -> MarkerReportType {
            switch configuration {
            case .standard:
                return .standard
            case let .toDo(completed: completed):
                return completed ? .completedToDo : .incompleteToDo
            case .chapter:
                return .chapter
            case .analysis:
                return .analysis
            }
        }
        
        static func roleSubroleDisplay(
            from roles: [AnyInterpolatedRole]
        ) -> String {
            guard let primary = roles.first else { return "" }
            return roleSubroleDisplay(from: primary)
        }
        
        static func roleSubroleDisplay(
            from role: AnyInterpolatedRole
        ) -> String {
            let wrapped = role.titleCasedDefaultRole(derivedOnly: true).wrapped
            
            if let subRole = wrapped.subRole, !subRole.isEmpty {
                return "\(wrapped.role.titleCased) ▸ \(subRole)"
            }
            
            return wrapped.role.titleCased
        }
        
        /// Role display for Selected Roles inventory rows (workbook export casing).
        static func inventoryRoleSubroleDisplay(
            from role: AnyInterpolatedRole
        ) -> String {
            switch role.wrapped {
            case let .video(videoRole):
                return inventoryRoleDisplay(
                    mainRole: videoRole.role,
                    subRole: videoRole.subRole,
                    isBuiltInMainRole: videoRole.isMainRoleBuiltIn
                )
            case let .audio(audioRole):
                return inventoryRoleDisplay(
                    mainRole: audioRole.role,
                    subRole: audioRole.subRole,
                    isBuiltInMainRole: audioRole.isMainRoleBuiltIn
                )
            case let .caption(captionRole):
                let mainDisplay = inventoryMainRoleDisplay(
                    mainRole: captionRole.role,
                    isBuiltInMainRole: captionRole.isMainRoleBuiltIn
                )
                
                let languageCode = captionRole.captionFormat
                    .split(separator: ".", maxSplits: 1)
                    .dropFirst()
                    .first
                    .map(String.init)
                
                guard let languageCode, !languageCode.isEmpty else { return mainDisplay }
                return "\(mainDisplay) ▸ \(inventoryCaptionLanguageDisplay(languageCode))"
            }
        }
        
        private static func inventoryRoleDisplay(
            mainRole: String,
            subRole: String?,
            isBuiltInMainRole: Bool
        ) -> String {
            let mainDisplay = inventoryMainRoleDisplay(
                mainRole: mainRole,
                isBuiltInMainRole: isBuiltInMainRole
            )
            
            guard let subRole, !subRole.isEmpty else {
                if usesBlankSubroleWhenEmpty(mainRole: mainRole) {
                    return "\(mainDisplay) ▸ <Blank>"
                }
                return mainDisplay
            }
            
            if subRole == "<Blank>" {
                return "\(mainDisplay) ▸ <Blank>"
            }
            
            return "\(mainDisplay) ▸ \(inventorySubroleDisplay(subRole))"
        }
        
        private static func inventoryMainRoleDisplay(
            mainRole: String,
            isBuiltInMainRole: Bool
        ) -> String {
            if isBuiltInMainRole {
                if mainRole == mainRole.uppercased(), !mainRole.contains(" ") {
                    return mainRole
                }
                return mainRole.titleCased
            }
            
            if mainRole == mainRole.uppercased(), !mainRole.contains(" ") {
                return mainRole
            }
            
            return mainRole.wordTitleCased
        }
        
        private static func usesBlankSubroleWhenEmpty(mainRole: String) -> Bool {
            switch mainRole.lowercased() {
            case "dialogue":
                return true
            default:
                return false
            }
        }
        
        private static func inventorySubroleDisplay(_ subRole: String) -> String {
            if subRole == "<Blank>" {
                return "<Blank>"
            }
            
            if subRole.contains("-") {
                let parts = subRole.split(separator: "-", omittingEmptySubsequences: false)
                if parts.count == 2,
                   parts[0] == parts[0].uppercased(),
                   parts[0] != parts[0].lowercased()
                {
                    return subRole
                }
                
                return parts.map { part in
                    String(part).wordTitleCased
                }.joined(separator: "-")
            }
            
            if subRole.contains("_") {
                return subRole
                    .split(separator: "_", omittingEmptySubsequences: false)
                    .map { String($0).wordTitleCased }
                    .joined(separator: "_")
            }
            if subRole == subRole.uppercased(), subRole != subRole.lowercased() {
                return subRole.wordTitleCased
            }
            
            if subRole.contains(" ") {
                return subRole.wordTitleCased
            }
            
            if subRole.dropFirst().contains(where: \.isUppercase) {
                return subRole.prefix(1).uppercased() + subRole.dropFirst().lowercased()
            }
            
            return subRole.titleCased
        }
        
        private static func inventoryCaptionLanguageDisplay(_ languageCode: String) -> String {
            if languageCode.contains("-") {
                return languageCode
            }
            
            return languageCode.prefix(1).uppercased() + languageCode.dropFirst().lowercased()
        }
        
        /// Combines role displays such as `Video` and `Dialogue ▸ Mix L` into workbook role fields.
        static func inventoryCombinedRoleField(from displays: [String]) -> String {
            guard !displays.isEmpty else { return "" }
            
            var mainOnlyRoles: [String] = []
            var subrolePairs: [(main: String, sub: String)] = []
            
            for display in displays {
                if let separator = display.range(of: " ▸ ") {
                    let mainRole = String(display[..<separator.lowerBound])
                    let subrole = String(display[separator.upperBound...])
                    subrolePairs.append((mainRole, subrole))
                } else {
                    mainOnlyRoles.append(display)
                }
            }
            
            mainOnlyRoles = mainOnlyRoles.removingDuplicates()
            subrolePairs = deduplicatedSubrolePairs(subrolePairs)
            subrolePairs = subrolePairs.filter { pair in
                guard pair.sub == "<Blank>" else { return true }
                
                let hasOtherSubrolesForMain = subrolePairs.contains {
                    $0.main == pair.main && $0.sub != "<Blank>"
                }
                return !hasOtherSubrolesForMain
            }
            
            let hasVideo = mainOnlyRoles.contains("Video")
            var segments: [String] = []
            
            let sortedMainOnlyRoles = mainOnlyRoles.sorted { lhs, rhs in
                if lhs == "Video" { return true }
                if rhs == "Video" { return false }
                return lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
            segments.append(contentsOf: sortedMainOnlyRoles)
            
            let mainRoles = subrolePairs.map(\.main).removingDuplicates().sorted()
            for mainRole in mainRoles {
                let subroles = subrolePairs
                    .filter { $0.main == mainRole }
                    .map(\.sub)
                    .removingDuplicates()
                    .sorted {
                        inventoryGroupedSubroleSortKey($0, preferMixFirst: !hasVideo)
                            < inventoryGroupedSubroleSortKey($1, preferMixFirst: !hasVideo)
                    }
                
                guard !subroles.isEmpty else { continue }
                
                if subroles == ["<Blank>"] {
                    // A lone built-in audio role with no explicit subrole uses Final Cut Pro's
                    // implicit default subrole (for example `Dialogue ▸ Dialogue-1`). When the
                    // same main role carries sibling subroles, the blank component is dropped
                    // by the filter above instead.
                    segments.append("\(mainRole) ▸ \(mainRole)-1")
                } else if hasVideo {
                    let firstSubrole = subroles[0]
                    let remainingSubroles = subroles.dropFirst()
                    var segment = "\(mainRole) ▸ \(firstSubrole)"
                    if !remainingSubroles.isEmpty {
                        segment += ", " + remainingSubroles.joined(separator: ", ")
                    }
                    segments.append(segment)
                } else {
                    segments.append("\(mainRole) ▸ \(subroles.joined(separator: ", "))")
                }
            }
            
            return segments.joined(separator: ", ")
        }
        
        /// Combines role displays while preserving the supplied order (no sorting) and keeping
        /// every subrole, including `<Blank>` channels. Used for synced-audio channel lists,
        /// which Final Cut Pro reports in `srcCh` order exactly as authored.
        static func inventoryChannelOrderedRoleField(from displays: [String]) -> String {
            var mainOrder: [String] = []
            var subrolesByMain: [String: [String]] = [:]
            var mainOnly: [String] = []
            var seen = Set<String>()
            
            for display in displays {
                guard seen.insert(display).inserted else { continue }
                
                guard let separator = display.range(of: " ▸ ") else {
                    if !mainOnly.contains(display) { mainOnly.append(display) }
                    continue
                }
                
                let mainRole = String(display[..<separator.lowerBound])
                let subrole = String(display[separator.upperBound...])
                
                if subrolesByMain[mainRole] == nil {
                    mainOrder.append(mainRole)
                    subrolesByMain[mainRole] = []
                }
                subrolesByMain[mainRole]?.append(subrole)
            }
            
            var segments = mainOnly
            for mainRole in mainOrder {
                let subroles = subrolesByMain[mainRole] ?? []
                segments.append(
                    subroles.isEmpty
                        ? mainRole
                        : "\(mainRole) ▸ \(subroles.joined(separator: ", "))"
                )
            }
            
            return segments.joined(separator: ", ")
        }
        
        private static func deduplicatedSubrolePairs(
            _ pairs: [(main: String, sub: String)]
        ) -> [(main: String, sub: String)] {
            var seen = Set<String>()
            var results: [(main: String, sub: String)] = []
            
            for pair in pairs {
                let key = "\(pair.main)\u{0000}\(pair.sub)"
                guard seen.insert(key).inserted else { continue }
                results.append(pair)
            }
            
            return results
        }
        
        private static func inventoryGroupedSubroleSortRank(
            _ subrole: String,
            preferMixFirst: Bool
        ) -> Int {
            let lower = subrole.lowercased()
            if lower.hasPrefix("mix") { return preferMixFirst ? 0 : 2 }
            if lower.hasPrefix("boom") { return preferMixFirst ? 1 : 0 }
            if lower.hasPrefix("r_") { return 3 }
            if subrole == "<Blank>" { return 4 }
            return 2
        }
        
        private static func inventoryGroupedSubroleSortKey(
            _ subrole: String,
            preferMixFirst: Bool
        ) -> (Int, Int, String) {
            let normalized = normalizedSubroleToken(subrole)
            return (
                inventoryGroupedSubroleSortRank(subrole, preferMixFirst: preferMixFirst),
                inventoryChannelOrderRank(for: normalized),
                normalized
            )
        }
        
        private static func normalizedSubroleToken(_ subrole: String) -> String {
            subrole
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "-", with: "")
        }
        
        private static func inventoryChannelOrderRank(for normalizedSubrole: String) -> Int {
            switch normalizedSubrole {
            case "mixl":
                return 0
            case "mixr":
                return 1
            case "boom1":
                return 2
            case "boom2":
                return 3
            case "rslate":
                return 4
            case "rfahd":
                return 5
            default:
                return 99
            }
        }
        
        private static func inventorySubroleSortRank(_ subrole: String) -> Int {
            inventoryGroupedSubroleSortRank(subrole, preferMixFirst: true)
        }
        
        /// Main role name only (no subrole), as used on the Markers report sheet.
        static func mainRoleDisplay(
            from role: AnyInterpolatedRole
        ) -> String {
            let wrapped = role.titleCasedDefaultRole(derivedOnly: true).wrapped
            
            if case let .video(videoRole) = wrapped, !videoRole.isMainRoleBuiltIn {
                return videoRole.role.wordTitleCased
            }
            
            return wrapped.role.titleCased
        }
        
        static func metadataString(
            from metadata: [Metadata.Metadatum],
            key: Metadata.Key
        ) -> String {
            metadata
                .first(where: { $0.key == key })
                .map { metadataDisplayValue(for: $0) } ?? ""
        }
        
        static func metadataString(
            from metadata: [Metadata.Metadatum],
            keyString: String
        ) -> String {
            metadata
                .first(where: { $0.keyString == keyString })
                .map { metadataDisplayValue(for: $0) } ?? ""
        }
        
        /// String form of a single metadatum (`value` attribute or child string array).
        static func metadataDisplayValue(for metadatum: Metadata.Metadatum) -> String {
            if let array = metadatum.valueArray, !array.isEmpty {
                return array.joined(separator: ", ")
            }
            return metadatum.value ?? ""
        }
        
        /// All metadata key/value pairs keyed by raw FCPXML metadata key.
        static func inventoryMetadataValueMap(
            from metadata: [Metadata.Metadatum]
        ) -> [String: String] {
            var values: [String: String] = [:]
            for item in metadata where !item.keyString.isEmpty {
                values[item.keyString] = metadataDisplayValue(for: item)
            }
            return values
        }
        
        static func inventoryAudioRateDisplay(_ audioRate: AudioRate) -> String {
            let raw = audioRate.rawValueForSequence
            if raw.hasSuffix("k") {
                return "\(raw.dropLast()) kHz"
            }
            return "\(raw)Hz"
        }
        
        static func inventoryVideoFrameRateDisplay(frameDuration: Fraction) -> String {
            guard frameDuration.numerator > 0 else { return "" }
            let fps = Double(frameDuration.denominator) / Double(frameDuration.numerator)
            let nearest = fps.rounded()
            if abs(fps - nearest) < 0.001 {
                return "\(Int(nearest)) fps"
            }
            return String(format: "%.3f fps", fps)
        }
        
        static func inventoryFrameSizeDisplay(width: Int?, height: Int?) -> String {
            guard let width, let height else { return "" }
            return "\(width) × \(height)"
        }
        
        static func inventoryFrameRateSampleRateDisplay(
            for clipContext: ExtractedElement,
            category: ReportClipCategory
        ) -> String {
            let element = clipContext.element
            let resources = clipContext.resources
            
            if category.isAudioCategory, !category.isVideoCategory {
                if let asset = element._fcpFirstResourceForElementOrAncestors(in: resources)?.fcpAsAsset,
                   let audioRate = asset.audioRate
                {
                    return inventoryAudioRateDisplay(audioRate)
                }
                
                if let sequence = inventoryAncestorSequence(for: clipContext),
                   let audioRate = sequence.audioRate
                {
                    return inventoryAudioRateDisplay(audioRate)
                }
                
                return ""
            }
            
            if let format = element._fcpFirstDefinedFormatResourceForElementOrAncestors(in: resources),
               let frameDuration = format.frameDuration
            {
                return inventoryVideoFrameRateDisplay(frameDuration: frameDuration)
            }
            
            return ""
        }
        
        static func inventoryFrameSizeDisplay(
            for clipContext: ExtractedElement,
            category: ReportClipCategory
        ) -> String {
            inventoryFrameSizeOrAudioConfigDisplay(for: clipContext, category: category)
        }
        
        /// Video frame size, or audio layout/channel config for audio-only inventory rows.
        static func inventoryFrameSizeOrAudioConfigDisplay(
            for clipContext: ExtractedElement,
            category: ReportClipCategory
        ) -> String {
            if category.isAudioCategory, !category.isVideoCategory {
                return inventoryAudioConfigDisplay(for: clipContext)
            }
            
            guard shouldIncludeFrameSize(for: category) else { return "" }
            
            let format = clipContext.element._fcpFirstDefinedFormatResourceForElementOrAncestors(
                in: clipContext.resources
            )
            return inventoryFrameSizeDisplay(width: format?.width, height: format?.height)
        }
        
        /// Audio layout / channel count for the Frame Size / Audio Config column.
        static func inventoryAudioConfigDisplay(
            for clipContext: ExtractedElement
        ) -> String {
            if let asset = clipContext.element._fcpFirstResourceForElementOrAncestors(
                in: clipContext.resources
            )?.fcpAsAsset {
                let channels = asset.audioChannels
                if channels == 1 { return "1 Mono" }
                if channels == 2 { return "Stereo" }
                if channels > 2 { return "\(channels) Channels" }
            }
            
            if let sequence = inventoryAncestorSequence(for: clipContext),
               let layout = sequence.audioLayout
            {
                switch layout {
                case .mono: return "Mono"
                case .stereo: return "Stereo"
                case .surround: return "Surround"
                }
            }
            
            return ""
        }
        
        private static func shouldIncludeFrameSize(for category: ReportClipCategory) -> Bool {
            if category.isAudioCategory, !category.isVideoCategory {
                return false
            }
            
            if category.isTitleCategory || category.isCaptionCategory || category == .primaryGap {
                return false
            }
            
            return category.isVideoCategory
                || category == .primaryClip
                || category == .connectedClip
                || category == .connectedGenerator
        }
        
        static func inventorySourceFileInfo(
            for clipContext: ExtractedElement
        ) -> (name: String, path: String) {
            guard let url = clipContext.element.fcpMediaURL(in: clipContext.resources) else {
                return ("", "")
            }
            return (url.lastPathComponent, url.path)
        }
        
        static func clipNotesDisplay(for element: any OFKXMLElement) -> String {
            element.firstChildElement(whereFCPElementType: .note)?.stringValue ?? ""
        }
        
        private static func inventoryAncestorSequence(
            for clipContext: ExtractedElement
        ) -> Sequence? {
            if let sequence = clipContext.element.fcpAsSequence {
                return sequence
            }
            
            for ancestor in clipContext.breadcrumbs.reversed() {
                if let sequence = ancestor.fcpAsSequence {
                    return sequence
                }
            }
            
            return nil
        }
        
        static func enabledCheckmark(for element: any OFKXMLElement) -> String {
            element.fcpGetEnabled(default: true) ? "✓" : "✗"
        }
        
        static func appleCheckmark(forAppleSupplied isAppleSupplied: Bool) -> String {
            isAppleSupplied ? "✓" : ""
        }
        
        static func appleCheckmarkForTitle(isAppleSupplied: Bool) -> String {
            isAppleSupplied ? "✓" : "✗"
        }
        
        static func markerRoleSubrole(
            for extracted: some FCPXMLExtractedElement,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) -> String {
            guard let preferred = extracted.preferredRole(
                for: .markers,
                using: roleDisplayPreference
            ) else { return "" }
            return mainRoleDisplay(from: preferred.collapsingSubRole())
        }
        
        /// Main-role labels for a marker, one per host component.
        ///
        /// When the host clip carries both video and audio, the marker is reported once per
        /// component (for example `Video` and `Dialogue`), matching Final Cut Pro's marker
        /// role attribution. Single-component hosts (video-only, audio-only, titles) yield a
        /// single label.
        static func markerRoleDisplays(
            for extracted: some FCPXMLExtractedElement,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) -> [String] {
            let preferred = markerRoleSubrole(
                for: extracted,
                roleDisplayPreference: roleDisplayPreference
            )
            
            guard let clipContext = extracted.ancestorClipContext() else {
                return preferred.isEmpty ? [] : [preferred]
            }
            
            let host = clipContext.element
            let resources = extracted.resources
            
            guard host.fcpCarriesVideo(resources: resources),
                  host.fcpCarriesAudio(resources: resources)
            else {
                return preferred.isEmpty ? [] : [preferred]
            }
            
            let roles = extracted.inheritedRoles(for: .markers)
            
            let videoDisplay = firstMainRoleDisplay(in: roles, ofType: .video) ?? "Video"
            let audioDisplay = firstMainRoleDisplay(in: roles, ofType: .audio)
                ?? (preferred.isEmpty ? "Dialogue" : preferred)
            
            return [videoDisplay, audioDisplay]
        }
        
        static func firstMainRoleDisplay(
            in roles: [AnyInterpolatedRole],
            ofType roleType: RoleType
        ) -> String? {
            for role in roles where role.roleType == roleType {
                let display = mainRoleDisplay(from: role.collapsingSubRole())
                if !display.isEmpty { return display }
            }
            return nil
        }
        
        static func titleRoleSubrole(
            for extracted: some FCPXMLExtractedElement,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) -> String {
            guard extracted.element.fcpElementType == .title else {
                return markerRoleSubrole(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            return "Titles"
        }
        
        static func effectRoleSubrole(
            for effect: ExtractedEffect,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) -> String {
            switch effect.kind {
            case .filterAudio, .volume, .implicitVolume:
                if let preferred = effect.host.preferredRole(
                    for: .audioEffects,
                    using: roleDisplayPreference
                ) {
                    return mainRoleDisplay(from: preferred.collapsingSubRole())
                }
                // FCP default when `audioRole` is omitted from the host.
                return "Dialogue"
            case .filterVideo, .transform, .compositing, .spatialConform:
                if effect.host.element.fcpElementType == .title {
                    return titleRoleSubrole(
                        for: effect.host,
                        roleDisplayPreference: roleDisplayPreference
                    )
                }
                if let preferred = effect.host.preferredRole(
                    for: .videoEffects,
                    using: roleDisplayPreference
                ) {
                    return mainRoleDisplay(from: preferred.collapsingSubRole())
                }
                // FCP default when `videoRole` is omitted from an asset-clip (common in exports).
                return "Video"
            }
        }

        static func effectRoleSubrole(
            kind: ExtractedEffect.Kind,
            hostElementType: String,
            roles: [AnyInterpolatedRole],
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) -> String {
            switch kind {
            case .filterAudio, .volume, .implicitVolume:
                if let preferred = roleDisplayPreference.preferredRole(
                    from: roles,
                    context: .audioEffects
                ) ?? roles.first(where: { $0.isAudio }) {
                    return mainRoleDisplay(from: preferred.collapsingSubRole())
                }
                return firstMainRoleDisplay(in: roles, ofType: .audio) ?? "Dialogue"
            case .filterVideo, .transform, .compositing, .spatialConform:
                if hostElementType == ElementType.title.rawValue {
                    return "Titles"
                }
                if let preferred = roleDisplayPreference.preferredRole(
                    from: roles,
                    context: .videoEffects
                ) ?? roles.first(where: { $0.isVideo }) {
                    return mainRoleDisplay(from: preferred.collapsingSubRole())
                }
                return firstMainRoleDisplay(in: roles, ofType: .video) ?? "Video"
            }
        }

        static func keywordRoleDisplays(
            for extracted: some FCPXMLExtractedElement,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) -> [String] {
            let roles = extracted.keywordInheritedRoles()
            
            let displays = roles
                .map { mainRoleDisplay(from: $0.collapsingSubRole()) }
                .removingDuplicates()
            
            guard !displays.isEmpty else { return [""] }
            
            return displays.sorted { lhs, rhs in
                let lhsRank = RoleDisplayPreference.keywordSortRank(for: lhs)
                let rhsRank = RoleDisplayPreference.keywordSortRank(for: rhs)
                if lhsRank != rhsRank { return lhsRank < rhsRank }
                return lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
        }
        
        static func transitionCategory(
            for placement: Transition.SpinePlacement
        ) -> String {
            switch placement {
            case .primary:
                return "Primary transition"
            case .secondary:
                return "Secondary transition"
            }
        }
        
        static func enabledCheckmark(for effect: ExtractedEffect) -> String {
            let isEnabled = EffectsCollector.isEffectEnabled(
                effectElement: effect.effectElement,
                host: effect.host.element
            )
            return enabledCheckmark(forEnabled: isEnabled)
        }
        
        static func enabledCheckmark(forEnabled isEnabled: Bool) -> String {
            isEnabled ? "✓" : "✗"
        }
        
        /// Marker label format used on Selected Roles inventory rows.
        static func inventoryMarkerLabel(
            name: String,
            configuration: Marker.Configuration
        ) -> String {
            switch configuration {
            case .standard:
                return name
            case .chapter:
                return "\(name) (Chapter)"
            case let .toDo(completed: completed):
                return completed
                    ? "\(name) (Completed to-do)"
                    : "\(name) (Incomplete to-do)"
            case .analysis:
                return "\(name) (Analysis)"
            }
        }
        
        static func effectSettingsDisplay(for effect: ExtractedEffect) -> String {
            effectSettingsDisplay(for: effect.settings)
        }

        static func effectSettingsDisplay(for settings: ExtractedEffect.Settings) -> String {
            switch settings {
            case .empty:
                return ""
            case .text(let value):
                return value
            case .decibels(let amount):
                return String(format: "%.1f dB", amount)
            case .opacityPercent(let amount):
                return String(format: "Opacity %.1f%%", amount)
            case .conformType(let typeString):
                return typeString.prefix(1).uppercased() + typeString.dropFirst()
            case .transformCenter(let position):
                return String(
                    format: "Center %.1f px, %.1f px",
                    position.x,
                    position.y
                )
            case .transformRotation(let rotation):
                return String(format: "Rotation %.1f°", rotation)
            case .transformScale(let scale):
                let averageScale = ((scale.x + scale.y) / 2) * 100
                return String(format: "Scale %.1f%%", averageScale)
            }
        }
    }
}

private extension String {
    /// Capitalizes every whitespace-delimited word (report display names).
    /// Distinct from SwiftExtensions ``StringProtocol/titleCased``, which is particle-aware title case.
    var wordTitleCased: String {
        split(separator: " ").map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }
}

