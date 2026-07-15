//
//  FCPXMLRoleInventoryClipCollector.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Collects component-level clip rows for role inventory and summary aggregation.
//

import Foundation
internal import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// One component row used for Selected Roles–style aggregation.
    struct RoleInventoryClipComponent: Sendable, Equatable {
        var roleSubroleField: String
        var category: ReportClipCategory
        var durationSeconds: Double
    }
    
    /// A collected clip component with extraction context for inventory row building.
    struct RoleInventoryClipEntry {
        var extracted: ExtractedElement
        var category: ReportClipCategory
        var roleSubroleField: String
        /// When true, timeline in/out use `audioStart` / `audioDuration` (split edits).
        var usesAudioTimelineBounds: Bool = false
        /// When true, timeline in is floored to the previous frame boundary.
        var usesFlooredTimelineStart: Bool = false
        /// When true, timeline out is floored to the previous frame boundary.
        var usesFlooredTimelineEnd: Bool = false
        /// When true, an `mc-clip` row is named after its active audio angle rather than
        /// its video angle (used for audio-component rows).
        var usesAudioAngleClipName: Bool = false
    }
    
    /// Walks the main timeline and emits component rows (video/audio/title/gap/caption hosts).
    enum RoleInventoryClipCollector {
        private static let hostTypes: Set<ElementType> = [
            .assetClip, .clip, .refClip, .syncClip, .mcClip, .liveDrawing
        ]
        
        private static let leafTypes: Set<ElementType> = [
            .title, .gap, .caption, .video, .audio
        ]
        
        static func collect(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) async -> [RoleInventoryClipComponent] {
            await collectEntries(
                from: timeline,
                scope: scope,
                roleDisplayPreference: roleDisplayPreference
            )
            .compactMap { entry in
                guard let durationSeconds = clipDurationSeconds(from: entry) else {
                    return nil
                }
                
                return RoleInventoryClipComponent(
                    roleSubroleField: entry.roleSubroleField,
                    category: entry.category,
                    durationSeconds: durationSeconds
                )
            }
        }
        
        static func collectEntries(
            from timeline: any OFKXMLElement,
            scope: ExtractionScope,
            roleDisplayPreference: RoleDisplayPreference = .builtIn
        ) async -> [RoleInventoryClipEntry] {
            var inventoryScope = ExtractionScope.reportMainTimelineVisible(modifying: scope)
            inventoryScope.auditions = .all
            inventoryScope.mcClipAngles = .all
            inventoryScope.extractionPredicate = roleInventoryExtractionPredicate(
                basePredicate: scope.extractionPredicate
            )
            
            let extracted = await timeline.fcpExtract(
                types: hostTypes.union(leafTypes),
                scope: inventoryScope
            )
            
            var rows: [RoleInventoryClipEntry] = []
            
            for element in extracted {
                guard let durationSeconds = clipDurationSeconds(
                    from: element,
                    usesAudioTimelineBounds: false
                ) else { continue }
                
                switch element.element.fcpElementType {
                case .title:
                    appendRow(
                        to: &rows,
                        from: element,
                        category: .titleCategory(for: element),
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference
                    )
                case .gap:
                    appendRow(
                        to: &rows,
                        from: element,
                        category: .primaryGap,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference
                    )
                case .caption:
                    appendRow(
                        to: &rows,
                        from: element,
                        category: .caption,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference
                    )
                case .video:
                    guard !shouldSkipLeafMedia(element) else { continue }
                    appendRow(
                        to: &rows,
                        from: element,
                        category: .leafVideoCategory(for: element),
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference
                    )
                case .audio:
                    guard !shouldSkipLeafMedia(element) else { continue }
                    appendRow(
                        to: &rows,
                        from: element,
                        category: .embeddedAudioCategory(for: element),
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference
                    )
                case .assetClip, .clip, .refClip, .syncClip, .mcClip, .liveDrawing:
                    collectHostComponents(
                        from: element,
                        durationSeconds: durationSeconds,
                        into: &rows,
                        roleDisplayPreference: roleDisplayPreference
                    )
                default:
                    continue
                }
            }
            
            return rows
        }
        
        private static func collectHostComponents(
            from extracted: ExtractedElement,
            durationSeconds: Double,
            into rows: inout [RoleInventoryClipEntry],
            roleDisplayPreference: RoleDisplayPreference
        ) {
            let element = extracted.element
            let resources = extracted.resources
            let elementType = element.fcpElementType
            
            let carriesVideo = element.fcpCarriesVideo(resources: resources)
            let carriesAudio = element.fcpCarriesAudio(resources: resources)
            let channelSources = audioChannelSourceElements(in: element)
            let channelRoleField = channelSources.isEmpty
                ? ""
                : roleFieldFromAudioChannelSources(element)
            let usesChannelRolesOnVideoAndAudio = channelSources.isEmpty == false
                && (elementType == .assetClip || elementType == .refClip)
            let syncSources = syncSourceElements(in: element)
            let usesSyncSourceRoles = elementType == .syncClip && !syncSources.isEmpty
            let isAudioChannelSourceOnlyHost = !channelSources.isEmpty
                && element.childElements.contains(where: { $0.fcpElementType == .video }) == false
                && (element.fcpRef ?? "").isEmpty
            
            if element.fcpIsAudioOnlyMulticamInventoryHost() {
                let roleField = mcClipInventoryRoleField(
                    for: extracted,
                    element: element,
                    roleDisplayPreference: roleDisplayPreference
                )
                appendRow(
                    to: &rows,
                    from: extracted,
                    category: .connectedClip,
                    durationSeconds: durationSeconds,
                    roleDisplayPreference: roleDisplayPreference,
                    explicitRoleSubroleField: roleField.isEmpty ? "Video, Dialogue" : roleField,
                    usesAudioAngleClipName: true
                )
            } else if !isAudioChannelSourceOnlyHost, carriesVideo {
                let placement = ReportClipCategory.placement(for: extracted)
                
                if usesSyncSourceRoles, placement == .primary {
                    let roleField = primarySyncClipVideoRoleField(
                        for: extracted,
                        roleDisplayPreference: roleDisplayPreference
                    )
                    
                    appendRow(
                        to: &rows,
                        from: extracted,
                        category: .primaryVideo,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference,
                        explicitRoleSubroleField: roleField
                    )
                } else {
                    let category = ReportClipCategory.videoCategory(
                        for: extracted,
                        elementType: elementType ?? .video
                    )
                    let roleField = hostVideoRoleField(
                        for: extracted,
                        category: category,
                        usesSyncSourceRoles: usesSyncSourceRoles,
                        syncSources: syncSources,
                        usesChannelRolesOnVideoAndAudio: usesChannelRolesOnVideoAndAudio,
                        channelRoleField: channelRoleField,
                        elementType: elementType,
                        roleDisplayPreference: roleDisplayPreference
                    )
                    
                    appendRow(
                        to: &rows,
                        from: extracted,
                        category: category,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference,
                        explicitRoleSubroleField: roleField
                    )
                }
            } else if !isAudioChannelSourceOnlyHost,
                      usesSyncSourceRoles,
                      shouldIncludeVideoInSyncSourceRoleField(for: extracted)
            {
                let placement = ReportClipCategory.placement(for: extracted)
                
                if placement == .primary {
                    let roleField = primarySyncClipVideoRoleField(
                        for: extracted,
                        roleDisplayPreference: roleDisplayPreference
                    )
                    
                    appendRow(
                        to: &rows,
                        from: extracted,
                        category: .primaryVideo,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference,
                        explicitRoleSubroleField: roleField
                    )
                } else {
                    let category = ReportClipCategory.videoCategory(
                        for: extracted,
                        elementType: .video
                    )
                    let roleField = combinedVideoAndSyncSourceRoleField(
                        for: extracted,
                        syncSources: syncSources,
                        roleDisplayPreference: roleDisplayPreference
                    )
                    
                    appendRow(
                        to: &rows,
                        from: extracted,
                        category: category,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference,
                        explicitRoleSubroleField: roleField
                    )
                }
            }
            
            if carriesAudio, !element.fcpIsExcludedFromRoleInventoryAudio() {
                let roleSources = directAudioRoleSourceElements(in: element)
                let shouldSplitRoleSources = elementType != .syncClip
                    && elementType != .mcClip
                    && channelSources.isEmpty
                    && !roleSources.isEmpty
                let category = ReportClipCategory.hostEmbeddedAudioCategory(
                    for: extracted,
                    hostElementType: elementType
                )
                
                if elementType == .mcClip {
                    let roleField = mcClipInventoryRoleField(
                        for: extracted,
                        element: element,
                        roleDisplayPreference: roleDisplayPreference
                    )
                    if !roleField.isEmpty {
                        appendRow(
                            to: &rows,
                            from: extracted,
                            category: category,
                            durationSeconds: durationSeconds,
                            roleDisplayPreference: roleDisplayPreference,
                            explicitRoleSubroleField: roleField,
                            usesAudioAngleClipName: true
                        )
                    }
                } else if usesSyncSourceRoles {
                    let placement = ReportClipCategory.placement(for: extracted)
                    let syncedRoleField = placement == .primary
                        ? (channelOrderedSyncedAudioField(
                            for: extracted,
                            syncSources: syncSources
                        )
                            ?? roleFieldFromSyncSources(
                                syncSources,
                                roleDisplayPreference: roleDisplayPreference
                            ))
                        : combinedVideoAndSyncSourceRoleField(
                            for: extracted,
                            syncSources: syncSources,
                            roleDisplayPreference: roleDisplayPreference
                        )
                    
                    if !syncedRoleField.isEmpty {
                        appendRow(
                            to: &rows,
                            from: extracted,
                            category: .syncedAudioCategory(for: extracted),
                            durationSeconds: durationSeconds,
                            roleDisplayPreference: roleDisplayPreference,
                            explicitRoleSubroleField: syncedRoleField
                        )
                    }
                    
                    if placement == .primary {
                        let combinedRoleField = combinedVideoAndSyncSourceRoleField(
                            for: extracted,
                            syncSources: syncSources,
                            roleDisplayPreference: roleDisplayPreference
                        )
                        
                        if !combinedRoleField.isEmpty {
                            appendRow(
                                to: &rows,
                                from: extracted,
                                category: .primaryAudio,
                                durationSeconds: durationSeconds,
                                roleDisplayPreference: roleDisplayPreference,
                                explicitRoleSubroleField: combinedRoleField
                            )
                        }
                    }
                } else if elementType == .syncClip,
                          ReportClipCategory.placement(for: extracted) == .primary
                {
                    // Preserve the existing decision of whether a synced-audio row is emitted
                    // (Final Cut Pro omits it for silenced/occluded clips) while adopting the
                    // channel-ordered subrole content when a row is produced.
                    let inheritedRoleField = roleFieldFromInheritedAudio(
                        for: extracted,
                        roleDisplayPreference: roleDisplayPreference
                    )
                    let syncedRoleField = inheritedRoleField.isEmpty
                        ? ""
                        : (channelOrderedAudioFieldFromChannels(for: extracted)
                            ?? inheritedRoleField)
                    
                    if !syncedRoleField.isEmpty {
                        appendRow(
                            to: &rows,
                            from: extracted,
                            category: .primarySyncedAudio,
                            durationSeconds: durationSeconds,
                            roleDisplayPreference: roleDisplayPreference,
                            explicitRoleSubroleField: syncedRoleField
                        )
                    } else {
                        appendRow(
                            to: &rows,
                            from: extracted,
                            category: category,
                            durationSeconds: durationSeconds,
                            roleDisplayPreference: roleDisplayPreference
                        )
                    }
                } else if !channelSources.isEmpty {
                    // Final Cut Pro reports an audio-channel-source host as a single row listing
                    // every mapped channel subrole in `srcCh` order (including disabled channels
                    // and the trailing `<Blank>`), rather than one row per active channel.
                    if let roleField = channelOrderedAudioChannelSourceField(for: element) {
                        appendRow(
                            to: &rows,
                            from: extracted,
                            category: category,
                            durationSeconds: durationSeconds,
                            roleDisplayPreference: roleDisplayPreference,
                            explicitRoleSubroleField: roleField
                        )
                    }
                } else if shouldSplitRoleSources {
                    for roleSource in roleSources {
                        guard let audioRoleSource = roleSource.fcpAsAudioRoleSource else {
                            continue
                        }
                        
                        let roleField = ReportFormatting.inventoryRoleSubroleDisplay(
                            from: .assigned(.audio(audioRoleSource.role))
                        )
                        
                        appendRow(
                            to: &rows,
                            from: extracted,
                            category: category,
                            durationSeconds: durationSeconds,
                            roleDisplayPreference: roleDisplayPreference,
                            explicitRoleSubroleField: roleField
                        )
                    }
                } else if isPrimarySpineAVAssetClip(element, resources: resources) {
                    appendRow(
                        to: &rows,
                        from: extracted,
                        category: category,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference,
                        explicitRoleSubroleField: primarySpineAVAssetClipRoleField(
                            for: extracted,
                            roleDisplayPreference: roleDisplayPreference
                        )
                    )
                } else {
                    appendRow(
                        to: &rows,
                        from: extracted,
                        category: category,
                        durationSeconds: durationSeconds,
                        roleDisplayPreference: roleDisplayPreference
                    )
                }
            }
        }
        
        private static func isPrimarySpineAVAssetClip(
            _ element: any OFKXMLElement,
            resources: (any OFKXMLElement)?
        ) -> Bool {
            guard element.fcpElementType == .assetClip,
                  (element.fcpLane ?? 0) == 0,
                  element.fcpCarriesVideo(resources: resources),
                  element.fcpCarriesAudio(resources: resources)
            else { return false }
            
            return true
        }
        
        private static func primarySpineAVAssetClipRoleField(
            for extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            var displays = ["Video"]
            displays.append(
                contentsOf: inheritedRoleDisplays(
                    for: extracted,
                    matchingRoleTypes: [.audio],
                    roleDisplayPreference: roleDisplayPreference
                )
            )
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func syncSourceElements(
            in host: any OFKXMLElement
        ) -> [any OFKXMLElement] {
            host.childElements.filter { $0.fcpElementType == .syncSource }
        }
        
        private static func primarySyncClipVideoRoleField(
            for extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            var displays = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: [.video, .caption],
                roleDisplayPreference: roleDisplayPreference
            )
            
            // Only synthesize a generic `Video` label when the clip carries video but
            // no explicit video role was derived. When a custom video role is already
            // present (for example `VFX ▸ VFX-Background`) Final Cut Pro does not prepend
            // a redundant `Video` component, matching reference report output.
            let videoDisplays = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: [.video],
                roleDisplayPreference: roleDisplayPreference
            )
            
            if extracted.element.fcpCarriesVideo(resources: extracted.resources),
               videoDisplays.isEmpty
            {
                displays.insert("Video", at: 0)
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func hostVideoRoleField(
            for extracted: ExtractedElement,
            category: ReportClipCategory,
            usesSyncSourceRoles: Bool,
            syncSources: [any OFKXMLElement],
            usesChannelRolesOnVideoAndAudio: Bool,
            channelRoleField: String,
            elementType: ElementType?,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            if usesSyncSourceRoles {
                return combinedVideoAndSyncSourceRoleField(
                    for: extracted,
                    syncSources: syncSources,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            if usesChannelRolesOnVideoAndAudio {
                return combinedVideoAndChannelRoleField(
                    for: extracted,
                    channelRoleField: channelRoleField,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            if elementType == .mcClip {
                return filteredInheritedRoleField(
                    for: extracted,
                    category: category,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            if elementType == .syncClip,
               category == .connectedVideo,
               !usesSyncSourceRoles
            {
                return combinedVideoAndInheritedAudioRoleField(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            if elementType == .refClip,
               category == .connectedVideo,
               extracted.element.fcpUsesConnectedVideoDialogueAnchor(
                   resources: extracted.resources
               )
            {
                return combinedVideoAndInheritedAudioRoleField(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            if let scanlineLabel = extracted.element.fcpScanlineVideoInventoryRoleLabel(),
               category.isVideoCategory
            {
                return scanlineLabel
            }
            
            if isPrimarySpineAVAssetClip(
                extracted.element,
                resources: extracted.resources
            ) {
                return primarySpineAVAssetClipRoleField(
                    for: extracted,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            if extracted.element.fcpUsesGenericVideoInventoryLabel(),
               category.isVideoCategory
            {
                return "Video"
            }
            
            return filteredInheritedRoleField(
                for: extracted,
                category: category,
                roleDisplayPreference: roleDisplayPreference
            )
        }
        
        private static func combinedVideoAndSyncSourceRoleField(
            for extracted: ExtractedElement,
            syncSources: [any OFKXMLElement],
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            var displays: [String] = []
            
            if shouldIncludeVideoInSyncSourceRoleField(for: extracted) {
                displays.append("Video")
            }
            
            let syncDisplays = syncSources.flatMap {
                roleDisplaysFromSyncSource(
                    $0,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            return ReportFormatting.inventoryCombinedRoleField(
                from: displays + syncDisplays
            )
        }
        
        private static func shouldIncludeVideoInSyncSourceRoleField(
            for extracted: ExtractedElement
        ) -> Bool {
            if extracted.element.fcpCarriesVideo(resources: extracted.resources) {
                return true
            }
            
            return extracted.value(forContext: .inheritedRoles).contains { role in
                role.roleType == .video
            }
        }
        
        private static func roleDisplaysFromSyncSource(
            _ syncSource: any OFKXMLElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> [String] {
            syncSource.childElements.compactMap { roleSource -> String? in
                guard roleSource.fcpElementType == .audioRoleSource,
                      let audioRoleSource = roleSource.fcpAsAudioRoleSource,
                      audioRoleSource.active
                else {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(audioRoleSource.role))
                )
                
                guard !display.isEmpty else { return nil }
                
                if display == "Dialogue" {
                    return nil
                }
                
                return display
            }
        }
        
        private static func retainsFullyOccludedHostForRoleInventory(
            _ extracted: ExtractedElement
        ) -> Bool {
            let element = extracted.element
            
            if !audioChannelSourceElements(in: element).isEmpty {
                return true
            }
            if !directAudioRoleSourceElements(in: element).isEmpty {
                return true
            }
            if !syncSourceElements(in: element).isEmpty {
                return true
            }
            if element.fcpIsAudioOnlyMulticamInventoryHost() {
                return true
            }
            if element.fcpElementType == .caption {
                return true
            }
            if element.fcpElementType == .syncClip,
               (element.fcpLane ?? 0) != 0,
               shouldIncludeDialogueAnchorInConnectedSyncClipVideoField(for: extracted)
            {
                return true
            }
            
            return false
        }
        
        private static func roleInventoryExtractionPredicate(
            basePredicate: (@Sendable (ExtractedElement) -> Bool)?
        ) -> @Sendable (ExtractedElement) -> Bool {
            { extracted in
                if extracted.element.fcpIsExcludedFromRoleInventory() {
                    return false
                }
                
                if extracted.element.fcpIsNestedConnectedInventoryHost() {
                    return false
                }
                
                if ReportClipCategory.isInteriorLaneZeroConnectedMulticamDuplicate(extracted) {
                    return false
                }
                
                if extracted.value(forContext: .effectiveOcclusion) == .fullyOccluded {
                    return retainsFullyOccludedHostForRoleInventory(extracted)
                }
                
                return basePredicate?(extracted) ?? true
            }
        }
        
        private static func shouldSkipLeafMedia(_ extracted: ExtractedElement) -> Bool {
            let lane = extracted.element.fcpLane ?? 0
            
            if lane > 0 {
                return false
            }
            
            if lane < 0 {
                return true
            }
            
            for ancestor in extracted.element.ancestorElements(includingSelf: false) {
                guard let elementType = ancestor.fcpElementType else { continue }
                if hostTypes.contains(elementType) {
                    return true
                }
            }
            
            return false
        }
        
        private static func roleFieldFromInheritedAudio(
            for extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            let displays = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: [.audio],
                roleDisplayPreference: roleDisplayPreference
            ).filter { display in
                display != "Dialogue"
                    && !display.localizedCaseInsensitiveContains("<Blank>")
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func directAudioRoleSourceElements(
            in host: any OFKXMLElement
        ) -> [any OFKXMLElement] {
            host.childElements.filter { $0.fcpElementType == .audioRoleSource }
        }
        
        private static func audioChannelSourceElements(
            in host: any OFKXMLElement
        ) -> [any OFKXMLElement] {
            host.childElements.filter { $0.fcpElementType == .audioChannelSource }
        }
        
        private static func audioRoleSourceElementsOnMCSources(
            in mcClip: any OFKXMLElement
        ) -> [any OFKXMLElement] {
            mcClip.childElements
                .filter { $0.fcpElementType == .mcSource }
                .filter { source in
                    guard let mcSource = source.fcpAsMulticamSource else { return false }
                    switch mcSource.sourceEnable {
                    case .all, .audio:
                        return true
                    case .video, .none:
                        return false
                    }
                }
                .flatMap { source in
                    source.childElements.filter { $0.fcpElementType == .audioRoleSource }
                }
        }
        
        private static func roleFieldFromMCSources(_ mcClip: any OFKXMLElement) -> String {
            let displays = audioRoleSourceElementsOnMCSources(in: mcClip).compactMap { source -> String? in
                guard let audioRoleSource = source.fcpAsAudioRoleSource else { return nil }
                
                if source.fcpGetEnabled(default: true) == false {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(audioRoleSource.role))
                )
                
                guard !display.isEmpty else { return nil }
                if display == "Dialogue" { return nil }
                return display
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func mcClipInventoryRoleField(
            for extracted: ExtractedElement,
            element: any OFKXMLElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            // Final Cut Pro reports a multicam clip's audio using the selected audio angle's
            // channel layout: every channel in `srcCh` order (bare main-role channels skipped,
            // the trailing `<Blank>` retained). Prefer that when the angle exposes an authored
            // channel group; fall back to the merged mc-source/inherited role set otherwise.
            if let channelOrdered = channelOrderedMulticamAngleAudioField(element) {
                return channelOrdered
            }
            
            let sourceRoles = roleFieldFromMCSources(element)
            let inheritedRoles = roleFieldFromInheritedAudio(
                for: extracted,
                roleDisplayPreference: roleDisplayPreference
            )
            let angleAudioRoles = roleFieldFromMulticamAngleAudio(element)
            
            let mergedDisplays = RoleInventoryRoleSheetOrdering.roleNames(in: sourceRoles)
                + RoleInventoryRoleSheetOrdering.roleNames(in: inheritedRoles)
                + RoleInventoryRoleSheetOrdering.roleNames(in: angleAudioRoles)
            
            if mergedDisplays.isEmpty {
                return ""
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: mergedDisplays)
        }
        
        /// Channel-ordered audio subrole field for a multicam clip, derived from the selected
        /// audio angle's authored channel group. Channels are listed in `srcCh` order, bare
        /// main-role channels are skipped, and a `<Blank>` channel is kept only when it is the
        /// final (highest `srcCh`) channel. Returns `nil` when the angle has no channel group.
        private static func channelOrderedMulticamAngleAudioField(
            _ host: any OFKXMLElement
        ) -> String? {
            guard let mcClip = host.fcpAsMCClip else { return nil }
            
            let selectedAngles = mcClip.audioVideoMCAngles
            let angleElement = selectedAngles.audioMCAngle?.element
                ?? selectedAngles.videoMCAngle?.element
            guard let timelineElement = angleElement?
                ._fcpFirstChildTimelineElement(excluding: [.gap])
            else {
                return nil
            }
            
            let channels = primaryAudioChannelElements(under: timelineElement)
            guard !channels.isEmpty else { return nil }
            
            let maxChannelIndex = channels.map(audioChannelIndex).max()
            
            let ordered = channels.compactMap { channel -> (order: Int, display: String)? in
                guard let role = channel.fcpAsAudio?.role else { return nil }
                
                let rawRole = channel.stringValue(forAttributeNamed: "role") ?? ""
                let subComponent = audioSubroleComponent(rawRole)
                guard !subComponent.isEmpty else { return nil }
                
                let index = audioChannelIndex(channel)
                if subComponent == "<Blank>", index != maxChannelIndex {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(role))
                )
                
                return (index, display)
            }
            
            guard !ordered.isEmpty else { return nil }
            
            let displays = ordered
                .sorted { $0.order < $1.order }
                .map(\.display)
            
            return ReportFormatting.inventoryChannelOrderedRoleField(from: displays)
        }
        
        private static func roleFieldFromMulticamAngleAudio(
            _ host: any OFKXMLElement
        ) -> String {
            guard let mcClip = host.fcpAsMCClip else {
                return ""
            }
            
            let selectedAngles = mcClip.audioVideoMCAngles
            let angleElement = selectedAngles.audioMCAngle?.element ?? selectedAngles.videoMCAngle?.element
            guard let timelineElement = angleElement?._fcpFirstChildTimelineElement(excluding: [.gap]) else {
                return ""
            }
            
            let displays = audioRoles(includingDescendantsOf: timelineElement).compactMap { role in
                ReportFormatting.inventoryRoleSubroleDisplay(from: .assigned(.audio(role)))
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func audioRoles(
            includingDescendantsOf element: any OFKXMLElement
        ) -> [FinalCutPro.FCPXML.AudioRole] {
            var roles: [FinalCutPro.FCPXML.AudioRole] = []
            
            if let audio = element.fcpAsAudio,
               let role = audio.role
            {
                roles.append(role)
            }
            
            if let channelSource = element.fcpAsAudioChannelSource,
               let role = channelSource.role
            {
                roles.append(role)
            }
            
            for child in element.childElements {
                roles.append(contentsOf: audioRoles(includingDescendantsOf: child))
            }
            
            return roles.removingDuplicates()
        }
        
        private static func combinedVideoAndInheritedAudioRoleField(
            for extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            var displays: [String] = []
            let usesDialogueAnchor = extracted.element.fcpUsesConnectedVideoDialogueAnchor(
                resources: extracted.resources
            )
                || shouldIncludeDialogueAnchorInConnectedSyncClipVideoField(for: extracted)
            
            if shouldIncludeVideoInSyncSourceRoleField(for: extracted) {
                if usesDialogueAnchor {
                    displays.append("Video")
                } else {
                    displays.append(
                        inventoryVideoAnchorDisplay(
                            for: extracted,
                            roleDisplayPreference: roleDisplayPreference
                        )
                    )
                }
            }
            
            if usesDialogueAnchor {
                displays.append("Dialogue")
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func shouldIncludeDialogueAnchorInConnectedSyncClipVideoField(
            for extracted: ExtractedElement
        ) -> Bool {
            if extracted.element.fcpCarriesAudio(resources: extracted.resources) {
                return true
            }
            
            return extracted.element._fcpContainsDescendant(named: "audio")
        }
        
        private static func inventoryVideoAnchorDisplay(
            for extracted: ExtractedElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            let inheritedVideo = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: [.video],
                roleDisplayPreference: roleDisplayPreference
            )
            
            if let customRole = inheritedVideo.first,
               !customRole.isEmpty,
               customRole != "Video"
            {
                return customRole
            }
            
            return "Video"
        }
        
        private static func roleFieldFromAudioChannelSources(
            _ host: any OFKXMLElement
        ) -> String {
            let displays = audioChannelSourceElements(in: host).compactMap { source -> String? in
                guard source.fcpElementType == .audioChannelSource,
                      let channelSource = source.fcpAsAudioChannelSource,
                      channelSource.active,
                      let audioRole = channelSource.role
                else {
                    return nil
                }
                
                if source.fcpGetEnabled(default: true) == false {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(audioRole))
                )
                
                guard !display.isEmpty else { return nil }
                return display
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func combinedVideoAndChannelRoleField(
            for extracted: ExtractedElement,
            channelRoleField: String,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            var videoDisplays = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: [.video, .caption],
                roleDisplayPreference: roleDisplayPreference
            )
            
            if extracted.element.fcpCarriesVideo(resources: extracted.resources),
               !videoDisplays.contains(where: { $0 == "Video" })
            {
                videoDisplays.insert(
                    inventoryVideoAnchorDisplay(
                        for: extracted,
                        roleDisplayPreference: roleDisplayPreference
                    ),
                    at: 0
                )
            }
            
            let channelDisplays = channelRoleField
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            return ReportFormatting.inventoryCombinedRoleField(
                from: videoDisplays + channelDisplays
            )
        }
        
        private static func filteredInheritedRoleField(
            for extracted: ExtractedElement,
            category: ReportClipCategory,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            let matchingRoleTypes = roleTypes(for: category)
            let displays = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: matchingRoleTypes,
                roleDisplayPreference: roleDisplayPreference
            )
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func roleTypes(for category: ReportClipCategory) -> Set<RoleType>? {
            if category.isVideoCategory {
                return [.video, .caption]
            }
            
            if category.isAudioCategory {
                return [.audio]
            }
            
            return nil
        }
        
        private static func inheritedRoleDisplays(
            for extracted: ExtractedElement,
            matchingRoleTypes: Set<RoleType>?,
            roleDisplayPreference: RoleDisplayPreference
        ) -> [String] {
            var roles = extracted.value(forContext: .inheritedRoles)
            
            if let matchingRoleTypes {
                roles = roles.filter { matchingRoleTypes.contains($0.roleType) }
            }
            
            return sortInheritedRoles(roles)
                .map { ReportFormatting.inventoryRoleSubroleDisplay(from: $0) }
                .filter { !$0.isEmpty }
                .removingDuplicates()
        }
        
        private static func sortInheritedRoles(
            _ roles: [AnyInterpolatedRole]
        ) -> [AnyInterpolatedRole] {
            roles
                .enumerated()
                .sorted { lhs, rhs in
                    let lhsRank = roleTypeSortRank(lhs.element.roleType)
                    let rhsRank = roleTypeSortRank(rhs.element.roleType)
                    
                    if lhsRank != rhsRank {
                        return lhsRank < rhsRank
                    }
                    
                    // Preserve original parser/extraction order within each role type.
                    return lhs.offset < rhs.offset
                }
                .map(\.element)
        }
        
        private static func roleTypeSortRank(_ roleType: RoleType) -> Int {
            switch roleType {
            case .video: return 0
            case .audio: return 1
            case .caption: return 2
            }
        }
        
        private static func roleFieldFromSyncSource(
            _ syncSource: any OFKXMLElement,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            roleFieldFromSyncSources(
                [syncSource],
                roleDisplayPreference: roleDisplayPreference
            )
        }
        
        private static func roleFieldFromSyncSources(
            _ syncSources: [any OFKXMLElement],
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            let displays = syncSources.flatMap {
                roleDisplaysFromSyncSource(
                    $0,
                    roleDisplayPreference: roleDisplayPreference
                )
            }
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        /// Synced-audio subrole field for a sync-clip, ordered to match Final Cut Pro.
        ///
        /// Final Cut Pro lists the clip's `sync-source` audio-role-sources — which determine
        /// *which* subroles appear (including inactive channels and a `<Blank>` channel when
        /// present) — but orders them by the channel `srcCh` of the underlying `audio` element
        /// group rather than by `sync-source` document order or alphabetically. Bare main-role
        /// entries (for example a lone `dialogue`) are omitted. Returns `nil` when the clip has
        /// no `sync-source` audio-role entries so callers can fall back to other derivations.
        private static func channelOrderedSyncedAudioField(
            for extracted: ExtractedElement,
            syncSources: [any OFKXMLElement]
        ) -> String? {
            let roleEntries = syncSources.flatMap { syncSource in
                syncSource.childElements.filter { $0.fcpElementType == .audioRoleSource }
            }
            guard !roleEntries.isEmpty else { return nil }
            
            let channels = primaryAudioChannelElements(under: extracted.element)
            let channelOrder = audioChannelSrcChByRole(channels)
            // Final Cut Pro reports a `<Blank>` channel only when it is the clip's final
            // (highest `srcCh`) channel; blank channels in the middle of the layout are omitted.
            let maxChannelIndex = channels.map(audioChannelIndex).max()
            
            let ordered = roleEntries.enumerated().compactMap {
                index, roleSource -> (order: Int, fallback: Int, display: String)? in
                guard let audioRoleSource = roleSource.fcpAsAudioRoleSource else { return nil }
                
                let rawRole = roleSource.stringValue(forAttributeNamed: "role") ?? ""
                let subComponent = audioSubroleComponent(rawRole)
                
                // Skip bare main-role entries (an unnamed channel such as `dialogue`); these
                // render as a blank subrole but are not reported as channels.
                guard !subComponent.isEmpty else { return nil }
                
                let srcCh = channelOrder[rawRole] ?? Int.max
                
                // A `<Blank>` channel is reported only when it is the clip's final (highest
                // `srcCh`) channel; blank channels in the middle of the layout are omitted.
                if subComponent == "<Blank>", srcCh != maxChannelIndex {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(audioRoleSource.role))
                )
                
                return (srcCh, index, display)
            }
            
            guard !ordered.isEmpty else { return nil }
            
            // Without any channel `srcCh` information there is nothing to order by; defer to the
            // caller's grouped fallback so behaviour is unchanged for channel-less clips.
            guard ordered.contains(where: { $0.order != Int.max }) else { return nil }
            
            let displays = ordered
                .sorted { lhs, rhs in
                    lhs.order != rhs.order ? lhs.order < rhs.order : lhs.fallback < rhs.fallback
                }
                .map(\.display)
            
            return ReportFormatting.inventoryChannelOrderedRoleField(from: displays)
        }
        
        /// Synced-audio subrole field derived directly from the clip's primary `audio` channel
        /// group, for sync-clips that have no `sync-source` summary. Every named channel is
        /// reported in `srcCh` order (with the same trailing-`<Blank>` rule as the sync-source
        /// path). Returns `nil` when the clip has no authored channel group.
        private static func channelOrderedAudioFieldFromChannels(
            for extracted: ExtractedElement
        ) -> String? {
            let channels = primaryAudioChannelElements(under: extracted.element)
            guard !channels.isEmpty else { return nil }
            
            let maxChannelIndex = channels.map(audioChannelIndex).max()
            
            let ordered = channels.compactMap { channel -> (order: Int, display: String)? in
                guard let role = channel.fcpAsAudio?.role else { return nil }
                
                let rawRole = channel.stringValue(forAttributeNamed: "role") ?? ""
                let subComponent = audioSubroleComponent(rawRole)
                guard !subComponent.isEmpty else { return nil }
                
                let index = audioChannelIndex(channel)
                if subComponent == "<Blank>", index != maxChannelIndex {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(role))
                )
                
                return (index, display)
            }
            
            guard !ordered.isEmpty else { return nil }
            
            let displays = ordered
                .sorted { $0.order < $1.order }
                .map(\.display)
            
            return ReportFormatting.inventoryChannelOrderedRoleField(from: displays)
        }
        
        /// Combined subrole field for an audio-channel-source host (a connected audio clip whose
        /// channels are remapped via `audio-channel-source`). Channels are reported in `srcCh`
        /// order, bare main-role channels are skipped, disabled channels are retained, and a
        /// `<Blank>` channel is kept only when it is the final (highest `srcCh`) channel.
        /// Returns `nil` when the host has no named channel.
        private static func channelOrderedAudioChannelSourceField(
            for host: any OFKXMLElement
        ) -> String? {
            let sources = audioChannelSourceElements(in: host)
            guard !sources.isEmpty else { return nil }
            
            let maxChannelIndex = sources.map(audioChannelIndex).max()
            
            let ordered = sources.compactMap { source -> (order: Int, display: String)? in
                guard let audioRole = source.fcpAsAudioChannelSource?.role else { return nil }
                
                let rawRole = source.stringValue(forAttributeNamed: "role") ?? ""
                let subComponent = audioSubroleComponent(rawRole)
                guard !subComponent.isEmpty else { return nil }
                
                let index = audioChannelIndex(source)
                if subComponent == "<Blank>", index != maxChannelIndex {
                    return nil
                }
                
                let display = ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.audio(audioRole))
                )
                
                return (index, display)
            }
            
            guard !ordered.isEmpty else { return nil }
            
            let displays = ordered
                .sorted { $0.order < $1.order }
                .map(\.display)
            
            return ReportFormatting.inventoryChannelOrderedRoleField(from: displays)
        }
        
        /// Subrole component of an FCPXML role string (for example `MIX L` for `dialogue.MIX L`,
        /// or an empty string for a bare `dialogue`).
        private static func audioSubroleComponent(_ rawRole: String) -> String {
            rawRole
                .split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
                .dropFirst()
                .first
                .map(String.init) ?? ""
        }
        
        /// Maps each authored channel role string (for example `dialogue.MIX L`) to its `srcCh`
        /// index within the supplied channel group.
        private static func audioChannelSrcChByRole(
            _ channels: [any OFKXMLElement]
        ) -> [String: Int] {
            var map: [String: Int] = [:]
            
            for channel in channels {
                guard let role = channel.stringValue(forAttributeNamed: "role") else { continue }
                let index = audioChannelIndex(channel)
                // Preserve the first (lowest srcCh) assignment when a role repeats.
                if let existing = map[role], existing <= index { continue }
                map[role] = index
            }
            
            return map
        }
        
        /// Returns the clip's primary `audio` channel group (the first authored channel parent
        /// plus its channel children) ordered by `srcCh`.
        private static func primaryAudioChannelElements(
            under clip: any OFKXMLElement
        ) -> [any OFKXMLElement] {
            guard let parent = firstAudioChannelParent(in: clip) else { return [] }
            
            var channels = [parent]
            channels.append(
                contentsOf: parent.childElements.filter { child in
                    child.fcpElementType == .audio
                        && child.stringValue(forAttributeNamed: "srcCh") != nil
                }
            )
            
            return channels.sorted { audioChannelIndex($0) < audioChannelIndex($1) }
        }
        
        /// Depth-first search for the first `audio` element carrying a `srcCh` attribute, which
        /// is the parent of an authored channel group.
        private static func firstAudioChannelParent(
            in element: any OFKXMLElement
        ) -> (any OFKXMLElement)? {
            for child in element.childElements {
                if child.fcpElementType == .audio,
                   child.stringValue(forAttributeNamed: "srcCh") != nil
                {
                    return child
                }
                
                if let found = firstAudioChannelParent(in: child) {
                    return found
                }
            }
            
            return nil
        }
        
        /// Leading integer of a channel's `srcCh` attribute (for example `2` for `"2"`, or `1`
        /// for `"1, 2"`), used to order channels within a group.
        private static func audioChannelIndex(_ element: any OFKXMLElement) -> Int {
            guard let raw = element.stringValue(forAttributeNamed: "srcCh") else {
                return Int.max
            }
            
            let leading = raw.prefix { $0.isNumber }
            return Int(leading) ?? Int.max
        }
        
        private static func appendRow(
            to rows: inout [RoleInventoryClipEntry],
            from extracted: ExtractedElement,
            category: ReportClipCategory,
            durationSeconds: Double,
            roleDisplayPreference: RoleDisplayPreference,
            explicitRoleSubroleField: String? = nil,
            usesAudioAngleClipName: Bool = false
        ) {
            let roleField = explicitRoleSubroleField ?? roleSubroleField(
                for: extracted,
                category: category,
                roleDisplayPreference: roleDisplayPreference
            )
            guard !roleField.isEmpty else { return }
            
            rows.append(
                RoleInventoryClipEntry(
                    extracted: extracted,
                    category: category,
                    roleSubroleField: roleField,
                    usesAudioTimelineBounds: RoleInventoryTimelineBounds.usesAudioTimelineBounds(
                        category: category,
                        element: extracted.element
                    ),
                    usesFlooredTimelineStart: RoleInventoryTimelineBounds.usesFlooredTimelineStart(
                        for: extracted,
                        category: category
                    ),
                    usesFlooredTimelineEnd: RoleInventoryTimelineBounds.usesFlooredTimelineEnd(
                        for: extracted,
                        category: category
                    ),
                    usesAudioAngleClipName: usesAudioAngleClipName
                )
            )
        }
        
        private static func roleSubroleField(
            for extracted: ExtractedElement,
            category: ReportClipCategory,
            roleDisplayPreference: RoleDisplayPreference
        ) -> String {
            if extracted.element.fcpElementType == .title {
                return "Titles"
            }
            
            if extracted.element.fcpElementType == .gap {
                return "Gap"
            }
            
            if extracted.element.fcpElementType == .caption,
               let captionRole = extracted.element.fcpAsCaption?.role
            {
                return ReportFormatting.inventoryRoleSubroleDisplay(
                    from: .assigned(.caption(captionRole))
                )
            }
            
            let displays = inheritedRoleDisplays(
                for: extracted,
                matchingRoleTypes: roleTypes(for: category),
                roleDisplayPreference: roleDisplayPreference
            )
            
            return ReportFormatting.inventoryCombinedRoleField(from: displays)
        }
        
        private static func clipDurationSeconds(
            from entry: RoleInventoryClipEntry
        ) -> Double? {
            clipDurationSeconds(
                from: entry.extracted,
                usesAudioTimelineBounds: entry.usesAudioTimelineBounds
            )
        }
        
        private static func clipDurationSeconds(
            from extracted: ExtractedElement,
            usesAudioTimelineBounds: Bool
        ) -> Double? {
            if let span = RoleInventoryTimelineBounds.mainTimelineSpan(
                for: extracted,
                usesAudioTimelineBounds: usesAudioTimelineBounds
            ) {
                return max(0, span.end - span.start)
            }
            
            guard let timecode = extracted.duration(frameRateSource: .mainTimeline) else {
                return extracted.element.fcpDuration?.doubleValue
            }
            
            return timecode.realTimeValue
        }
    }
}
