//
//  FCPXMLClipParsing.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Clip parsing utilities (keywords, annotations).
//

import Foundation
import SwiftTimecode

extension OFKXMLElement {
    /// FCPXML: Returns keywords applied to the element if the element is a clip,
    /// otherwise returns keywords applied to the first ancestor clip.
    func _fcpApplicableKeywords(
        constrainToKeywordRanges: Bool = true,
        breadcrumbs: [any OFKXMLElement]? = nil,
        resources: (any OFKXMLElement)? = nil
    ) -> [FinalCutPro.FCPXML.Keyword] {
        // find nearest timeline and determine its absolute start timecode
        guard let (timeline, timelineAncestors) = fcpAncestorTimeline(
            ancestors: breadcrumbs,
            includingSelf: true
        )
        else { return [] }
        
        // get parent clip's keywords
        let keywords = timeline.children(whereFCPElement: .keyword)
        
        // if self is a timeline, just return all keywords
        if timeline === self { return Array(keywords) }
        
        // if we're not constraining to keyword ranges, just return all keywords
        if !constrainToKeywordRanges { return Array(keywords) }
        
        // otherwise, determine what keywords apply based on their ranges.
        // keywords can apply to a partial region of a clip, so check if element is in range.
        
        guard let absoluteStart = _fcpCalculateAbsoluteStart(
            ancestors: breadcrumbs,
            resources: resources
        ),
            let absoluteStartAsTimecode = try? _fcpTimecode(
                fromRealTime: absoluteStart,
                frameRateSource: .mainTimeline,
                breadcrumbs: breadcrumbs,
                resources: resources
            )
        else {
            // if marker timecode cannot be determined, just return all of the clip's keywords
            return Array(keywords)
        }
        
        // determine what keywords encompass the marker's position
        
        var applicableKeywords: [FinalCutPro.FCPXML.Keyword] = []
        for keyword in keywords {
            if let kwAbsRange = keyword.absoluteRangeAsTimecode(
                timeline: timeline,
                timelineAncestors: timelineAncestors,
                resources: resources
            ) {
                if kwAbsRange.contains(absoluteStartAsTimecode) {
                    // marker is within keyword range
                    applicableKeywords.append(keyword)
                }
            } else {
                // keyword range cannot be determined
                
                // if start and duration attributes are missing, assume the keyword
                // applies to the entire clip
                if keyword.element.fcpStart == nil,
                    keyword.element.fcpDuration == nil
                {
                    applicableKeywords.append(keyword)
                }
            }
        }
        
        return applicableKeywords
    }
    
    /// FCPXML: Returns metadata applicable to the element.
    func _fcpApplicableMetadata(
        breadcrumbs: [any OFKXMLElement]? = nil,
        resources: (any OFKXMLElement)? = nil
    ) -> [FinalCutPro.FCPXML.Metadata.Metadatum] {
        // find nearest timeline and determine its absolute start timecode
        guard let (timeline, _ /* timelineAncestors */) = fcpAncestorTimeline(
            ancestors: breadcrumbs,
            includingSelf: true
        )
        else { return [] }
        
        func flatten(metadataIn e: (any OFKXMLElement)?) -> [FinalCutPro.FCPXML.Metadata.Metadatum] {
            e?.children(whereFCPElement: .metadata)
                .flatMap(\.metadatumContents)
            ?? []
        }
        
        // special case: `mc-clip`
        //
        // - markers:
        //     - can exist as children in `mc-clip`
        // - markers and/or metadata:
        //     - can also exist as children in `multicam` -> `mc-angle` -> <first non-gap clip>
        // - metadata never seems to exist within the `mc-clip` itself however
        //
        // which means:
        // - if ancestor clip (or if self is a clip):
        //   - is a `mc-clip`
        //     1. get `mc-clip` local metadata
        //     2. get metadata from the clip within the multicam angle it points to
        //     3. also get metadata from the resource the clip references
        //   - is an `asset-clip`, regardless of whether it's in a main timeline or it's within a multicam resource's angle
        //     - parse using default behavior for other clip types (fall through):
        //       1. get local clip metadata
        //       2. get the clip's resource's metadata
        if let mcClip = timeline.fcpAsMCClip {
            // let multicam = mcClip.multicamResource
            
            // 1. get `mc-clip` local metadata
            let mcClipMetadataFlat = flatten(metadataIn: mcClip.element)
            
            // 2. get metadata from the clip within the multicam angle it points to
            let (_ /* audioMCAngle */, videoMCAngle) = mcClip.audioVideoMCAngles
            let angleTimeline = videoMCAngle?.element._fcpFirstChildTimelineElement(excluding: [.gap])
            let angleMetadataFlat = flatten(metadataIn: angleTimeline)
            
            // 3. also get metadata from the resource the clip references
            let angleResource = angleTimeline?.fcpResource()
            let angleResourceMetadataFlat = flatten(metadataIn: angleResource)
            
            // combine
            let combinedMetadataFlat = Array(angleResourceMetadataFlat) + Array(angleMetadataFlat) + Array(mcClipMetadataFlat)
            return combinedMetadataFlat
        }
        
        // special case: `sync-clip`
        //
        // - `sync-clip` can contain local metadata
        // - metadata needs to be also pulled from the first internal video timeline from the `sync-clip`'s resource
        if let syncClip = timeline.fcpAsSyncClip {
            // get local clip metadata
            let timelineMetadataFlat = flatten(metadataIn: syncClip.element)
            
            // get media metadata
            let firstInteriorClip = syncClip.element._fcpFirstChildTimelineElement()
            let resource = firstInteriorClip?.fcpResource()
            let resourceMetadataFlat = flatten(metadataIn: resource)
            
            // combine
            let combinedMetadataFlat = Array(resourceMetadataFlat) + Array(timelineMetadataFlat)
            return combinedMetadataFlat
        }
        
        // special case: `ref-clip`
        //
        // - `ref-clip` itself may contain metadata
        // - the `media` resource it references can contain a `metadata` child within its `sequence`
        if let refClip = timeline.fcpAsRefClip {
            // get clip metadata
            let refClipMetadataFlat = flatten(metadataIn: refClip.element)
            
            // get `media` metadata
            let sequence = refClip.mediaSequence
            let sequenceMetadataFlat = flatten(metadataIn: sequence?.element)
            
            // combine
            let combinedMetadataFlat = Array(sequenceMetadataFlat) + Array(refClipMetadataFlat)
            return combinedMetadataFlat
        }
        
        // fall through to default behavior for other clip types:
        
        // get clip metadata
        let timelineMetadataFlat = flatten(metadataIn: timeline)
        
        // get media metadata
        let resource = self.fcpResource()
        let resourceMetadataFlat = flatten(metadataIn: resource)
        
        // combine
        let combinedMetadataFlat = Array(resourceMetadataFlat) + Array(timelineMetadataFlat)
        return combinedMetadataFlat
    }
    
    /// Returns true when the element references or contains audio components.
    func fcpCarriesAudio(resources: (any OFKXMLElement)? = nil) -> Bool {
        if childElements.contains(where: { $0.name == "audio" }) {
            return true
        }
        
        if childElements.contains(where: { $0.name == "audio-channel-source" }) {
            return true
        }
        
        if fcpHasSyncSourceAudioRoles {
            return true
        }
        
        if let mcClip = fcpAsMCClip,
           mcClip.sources.contains(where: { $0.sourceEnable != .video })
        {
            return true
        }
        
        if fcpAsSyncClip != nil, _fcpContainsDescendant(named: "audio") {
            return true
        }
        
        if let refClip = fcpAsRefClip, refClip.useAudioSubroles, !refClip.audioRoleSources.isEmpty {
            return true
        }
        
        if let ref = fcpRef,
           let asset = fcpResource(forID: ref, in: resources)?.fcpAsAsset,
           asset.hasAudio
        {
            return true
        }
        
        return false
    }
    
    /// Workbook-style clip name, including active multicam angle suffixes for `mc-clip` elements.
    /// - Parameter preferAudioAngle: when true, `mc-clip` names resolve to the active audio
    ///   angle (used for audio-component inventory rows); otherwise the video angle is used.
    func fcpWorkbookClipName(
        resources: (any OFKXMLElement)? = nil,
        preferAudioAngle: Bool = false
    ) -> String {
        guard fcpElementType == .mcClip,
              let mcClip = fcpAsMCClip,
              let baseName = fcpName,
              !baseName.isEmpty,
              let ref = fcpRef,
              let multicam = fcpResource(forID: ref, in: resources)?
            .fcpAsMedia?
            .multicam
        else {
            return fcpName ?? ""
        }
        
        let angleSelection = multicam.audioVideoMCAngles(forMulticamSources: mcClip.sources)
        // Audio-component inventory rows are named after the active audio angle; all other
        // rows (video and default) use the video angle. When only one distinct angle exists
        // the fallbacks converge on it.
        let preferredAngle = preferAudioAngle
            ? (angleSelection.audioMCAngle ?? angleSelection.videoMCAngle)
            : (angleSelection.videoMCAngle ?? angleSelection.audioMCAngle)
        
        if let interiorName = preferredAngle?.element
            ._fcpFirstChildTimelineElement(excluding: [.gap])?
            .fcpName?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !interiorName.isEmpty,
           interiorName.localizedCaseInsensitiveContains(" Cam ")
        {
            return interiorName
        }
        
        guard let angleName = preferredAngle?.name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !angleName.isEmpty
        else {
            return baseName
        }
        
        if angleName.localizedCaseInsensitiveContains(" Cam ") {
            return angleName
        }
        
        if baseName.localizedCaseInsensitiveContains(angleName) {
            return baseName
        }
        
        return "\(baseName) \(angleName)"
    }
    
    /// Returns true when the element references or contains video components.
    func fcpCarriesVideo(resources: (any OFKXMLElement)? = nil) -> Bool {
        if childElements.contains(where: { $0.name == "video" }) {
            return true
        }
        
        if let ref = fcpRef,
           let asset = fcpResource(forID: ref, in: resources)?.fcpAsAsset,
           asset.hasVideo
        {
            return true
        }
        
        switch fcpElementType {
        case .video, .refClip, .mcClip, .syncClip, .liveDrawing:
            return true
        case .clip, .assetClip:
            return false
        default:
            return false
        }
    }
    
    /// Whether the clip exposes role-based audio through `sync-source` children.
    var fcpHasSyncSourceAudioRoles: Bool {
        if let syncClip = fcpAsSyncClip {
            return syncClip.syncSources.contains { !$0.audioRoleSources.isEmpty }
        }
        
        return childElements.contains { child in
            child.fcpElementType == .syncSource
                && child.childElements.contains { $0.name == "audio-role-source" }
        }
    }
    
    /// Nested connected hosts with their own active `audio-channel-source` role assignments
    /// still contribute distinct inventory rows (for example user-defined surround stems).
    func fcpHasActiveInventoryAudioChannelSources() -> Bool {
        childElements.contains { child in
            guard child.fcpElementType == .audioChannelSource,
                  child.fcpGetEnabled(default: true),
                  let channelSource = child.fcpAsAudioChannelSource,
                  channelSource.active,
                  channelSource.role != nil
            else {
                return false
            }
            
            return true
        }
    }
    
    /// Connected storyline `asset-clip` elements on negative lanes inside another
    /// inventory host are represented through that parent, not as separate workbook rows.
    func fcpIsNestedConnectedInventoryHost() -> Bool {
        let lane = fcpLane ?? 0
        guard lane < 0 else {
            return false
        }
        
        switch fcpElementType {
        case .assetClip:
            // A connected asset-clip that remaps its own channels via active
            // audio-channel-source elements is a standalone connected-audio host (for
            // example an atmosphere or effects clip anchored inside a sync-clip), so it is
            // inventoried in its own right rather than through the parent host.
            if fcpHasActiveInventoryAudioChannelSources() {
                return false
            }
        case .clip:
            guard fcpCarriesVideo() == false else {
                return false
            }

            if fcpHasActiveInventoryAudioChannelSources() {
                return false
            }
        default:
            return false
        }
        
        return ancestorElements(includingSelf: false).contains { ancestor in
            guard let ancestorType = ancestor.fcpElementType else { return false }
            switch ancestorType {
            case .assetClip, .clip, .refClip, .syncClip, .mcClip, .liveDrawing:
                return true
            default:
                return false
            }
        }
    }
    
    /// Primary-lane disabled `ref-clip` elements are omitted from role inventory workbooks.
    /// Connected-lane disabled `ref-clip` hosts may still contribute connected video rows.
    func fcpIsExcludedFromRoleInventory() -> Bool {
        guard fcpElementType == .refClip else { return false }
        guard fcpGetEnabled(default: true) == false else { return false }
        return (fcpLane ?? 0) == 0
    }
    
    /// Connected nested `mc-clip` elements with `srcEnable="audio"` are inventoried as
    /// connected video anchors, not as separate connected clip audio splits.
    func fcpIsAudioOnlyMulticamInventoryHost() -> Bool {
        guard fcpElementType == .mcClip,
              let mcClip = fcpAsMCClip,
              mcClip.srcEnable == .audio
        else {
            return false
        }
        
        return (fcpLane ?? 0) != 0
    }
    
    /// Disabled `ref-clip` hosts and audio-only connected multicam hosts should not emit
    /// separate role-inventory audio component rows.
    func fcpIsExcludedFromRoleInventoryAudio() -> Bool {
        if fcpElementType == .refClip, fcpGetEnabled(default: true) == false {
            return true
        }
        
        return fcpIsAudioOnlyMulticamInventoryHost()
    }
    
    /// Connected `ref-clip` hosts that should use the `Video, Dialogue` workbook anchor field.
    func fcpUsesConnectedVideoDialogueAnchor(resources: (any OFKXMLElement)? = nil) -> Bool {
        guard fcpElementType == .refClip, (fcpLane ?? 0) != 0 else {
            return false
        }
        
        if fcpAsRefClip?.useAudioSubroles == true {
            return true
        }
        
        if fcpCarriesAudio(resources: resources) {
            return true
        }
        
        return ancestorElements(includingSelf: false).contains { ancestor in
            guard ancestor.fcpElementType == .syncClip else { return false }
            
            return ancestor.childElements.contains { $0.fcpElementType == .syncSource }
        }
    }
    
    /// Connected `asset-clip` elements without an explicit `videoRole` use the generic `Video`
    /// inventory label instead of roles inherited from a parent `clip` wrapper.
    func fcpUsesGenericVideoInventoryLabel() -> Bool {
        guard fcpElementType == .assetClip,
              (fcpLane ?? 0) != 0,
              fcpScanlineVideoInventoryRoleLabel() == nil
        else {
            return false
        }
        
        return fcpAsAssetClip?.videoRole == nil
    }
    
    /// Tech-final scanline overlays use the `videoRole` attribute as the inventory label.
    func fcpScanlineVideoInventoryRoleLabel() -> String? {
        guard fcpElementType == .assetClip,
              let videoRole = fcpAsAssetClip?.videoRole?.rawValue,
              videoRole.localizedCaseInsensitiveContains("scanline")
        else {
            return nil
        }
        
        return videoRole
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}

