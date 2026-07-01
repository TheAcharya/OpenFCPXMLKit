//
//  FCPXMLReportClipCategory.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Clip categories for role inventory rows (Selected Roles workbook layout).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Category strings used on Selected Roles and per-role inventory sheets.
    enum ReportClipCategory: String, Sendable, Equatable, CaseIterable {
        case primaryTitle = "Primary Title"
        case connectedTitle = "Connected Title"
        case primaryVideo = "Primary Video"
        case connectedVideo = "Connected Video"
        case primaryAudio = "Primary Audio"
        case connectedAudio = "Connected Audio"
        case primarySyncedAudio = "Primary Synced Audio"
        case connectedSyncedAudio = "Connected Synced Audio"
        case primaryGap = "Primary Gap"
        case primaryClip = "Primary Clip"
        case connectedClip = "Connected Clip"
        case connectedGenerator = "Connected Generator"
        case secondaryTitle = "Secondary Title"
        case secondaryAudio = "Secondary Audio"
        case caption = "Caption"
        
        var isVideoCategory: Bool {
            switch self {
            case .primaryVideo, .connectedVideo, .primaryClip, .connectedClip, .connectedGenerator:
                return true
            default:
                return false
            }
        }
        
        var isCaptionCategory: Bool {
            self == .caption
        }
        
        var isAudioCategory: Bool {
            switch self {
            case .primaryAudio, .connectedAudio, .primarySyncedAudio, .connectedSyncedAudio,
                 .secondaryAudio:
                return true
            default:
                return false
            }
        }
        
        var isTitleCategory: Bool {
            switch self {
            case .primaryTitle, .connectedTitle, .secondaryTitle:
                return true
            default:
                return false
            }
        }
        
        /// Workbook-facing label (sentence-style casing used on Selected Roles exports).
        var workbookExportLabel: String {
            switch self {
            case .primaryTitle:
                return "Primary title"
            case .connectedTitle:
                return "Connected title"
            case .primaryVideo:
                return "Primary video"
            case .connectedVideo:
                return "Connected video"
            case .primaryAudio:
                return "Primary audio"
            case .connectedAudio:
                return "Connected audio"
            case .primarySyncedAudio:
                return "Primary synced audio"
            case .connectedSyncedAudio:
                return "Connected synced audio"
            case .primaryGap:
                return "Primary gap"
            case .primaryClip:
                return "Primary clip"
            case .connectedClip:
                return "Connected clip"
            case .connectedGenerator:
                return "Connected generator"
            case .secondaryTitle:
                return "Secondary title"
            case .secondaryAudio:
                return "Secondary audio"
            case .caption:
                return "Caption"
            }
        }
        
        static func matchingWorkbookLabel(_ label: String) -> Self? {
            if let category = Self(rawValue: label) {
                return category
            }
            
            return allCases.first { $0.workbookExportLabel == label }
        }
        
        enum Placement {
            case primary
            case connected
            case secondary
        }
        
        static func placement(for extracted: ExtractedElement) -> Placement {
            if isSecondaryStoryline(extracted) {
                return .secondary
            }
            
            if isConnectedToMainTimeline(extracted) {
                return .connected
            }
            
            return .primary
        }
        
        private static func isConnectedToMainTimeline(_ extracted: ExtractedElement) -> Bool {
            if (extracted.element.fcpLane ?? 0) != 0 {
                return true
            }
            
            // Some multicam interior elements carry lane `0` locally but are effectively connected
            // when their containing `mc-clip` host is on a connected lane.
            guard extracted.breadcrumbs.contains(where: { $0.fcpElementType == .mcClip }) else {
                return false
            }
            
            for ancestor in extracted.breadcrumbs {
                guard ancestor.fcpElementType == .mcClip else { continue }
                if (ancestor.fcpLane ?? 0) != 0 {
                    return true
                }
            }
            
            return false
        }
        
        private static func isSecondaryStoryline(_ extracted: ExtractedElement) -> Bool {
            extracted.breadcrumbs.contains { ancestor in
                ancestor.fcpElementType == .spine && ancestor.fcpOffset != nil
            }
        }
        
        static func titleCategory(for extracted: ExtractedElement) -> Self {
            switch placement(for: extracted) {
            case .primary:
                return .primaryTitle
            case .connected:
                return .connectedTitle
            case .secondary:
                return .secondaryTitle
            }
        }
        
        static func videoCategory(
            for extracted: ExtractedElement,
            elementType: ElementType
        ) -> Self {
            switch placement(for: extracted) {
            case .primary:
                switch elementType {
                case .mcClip:
                    if mcClipHasConnectedHostAncestor(extracted) {
                        return .connectedClip
                    }
                    return .primaryClip
                case .liveDrawing:
                    return .connectedGenerator
                default:
                    return .primaryVideo
                }
            case .connected:
                switch elementType {
                case .mcClip:
                    if extracted.element.fcpIsAudioOnlyMulticamInventoryHost() {
                        return .connectedVideo
                    }
                    return .connectedClip
                case .liveDrawing:
                    return .connectedGenerator
                default:
                    return .connectedVideo
                }
            case .secondary:
                switch elementType {
                case .title, .liveDrawing:
                    return .secondaryTitle
                default:
                    return .connectedVideo
                }
            }
        }
        
        static func hostEmbeddedAudioCategory(
            for extracted: ExtractedElement,
            hostElementType: ElementType?
        ) -> Self {
            if hostElementType == .mcClip {
                switch placement(for: extracted) {
                case .primary:
                    if mcClipHasConnectedHostAncestor(extracted) {
                        return .connectedClip
                    }
                    return .primaryClip
                case .connected:
                    return .connectedClip
                case .secondary:
                    return .secondaryAudio
                }
            }
            
            return embeddedAudioCategory(for: extracted)
        }
        
        private static func mcClipHasConnectedHostAncestor(_ extracted: ExtractedElement) -> Bool {
            guard extracted.element.fcpElementType == .mcClip else {
                return false
            }
            
            return hasConnectedHostAncestor(in: extracted.breadcrumbs)
        }
        
        /// Lane-zero `mc-clip` elements reached through connected hosts while expanding multicam
        /// angles duplicate parent spine inventory rows and should not emit their own rows.
        static func isInteriorLaneZeroConnectedMulticamDuplicate(
            _ extracted: ExtractedElement
        ) -> Bool {
            guard extracted.element.fcpElementType == .mcClip,
                  (extracted.element.fcpLane ?? 0) == 0
            else {
                return false
            }
            
            return hasConnectedHostAncestor(in: extracted.breadcrumbs)
        }
        
        static func hasConnectedHostAncestor(
            in breadcrumbs: [any OFKXMLElement]
        ) -> Bool {
            for ancestor in breadcrumbs {
                guard let ancestorType = ancestor.fcpElementType else { continue }
                switch ancestorType {
                case .assetClip, .clip, .refClip, .syncClip, .mcClip, .liveDrawing:
                    if (ancestor.fcpLane ?? 0) != 0 {
                        return true
                    }
                default:
                    continue
                }
            }
            
            return false
        }
        
        static func isGeneratorVideo(_ extracted: ExtractedElement) -> Bool {
            guard let video = extracted.element.fcpAsVideo else {
                return false
            }
            
            let ref = video.ref
            guard !ref.isEmpty,
                  let resource = extracted.element.fcpResource(forID: ref, in: extracted.resources),
                  let uid = resource.fcpUID
            else {
                return false
            }
            
            return uid.localizedCaseInsensitiveContains("Generators.localized")
        }
        
        static func leafVideoCategory(for extracted: ExtractedElement) -> Self {
            if isGeneratorVideo(extracted) {
                return .connectedGenerator
            }
            
            return videoCategory(for: extracted, elementType: .video)
        }
        
        static func embeddedAudioCategory(for extracted: ExtractedElement) -> Self {
            switch placement(for: extracted) {
            case .primary:
                return .primaryAudio
            case .connected:
                return .connectedAudio
            case .secondary:
                return .secondaryAudio
            }
        }
        
        /// Category for `sync-source` audio-role components on sync-clips.
        static func syncedAudioCategory(for extracted: ExtractedElement) -> Self {
            switch placement(for: extracted) {
            case .primary:
                return .primarySyncedAudio
            case .connected, .secondary:
                // Workbook exports use Connected Audio for sync-source rows off the primary spine.
                return .connectedAudio
            }
        }
        
        static func audioCategory(
            for extracted: ExtractedElement,
            elementType: ElementType,
            isSynced: Bool
        ) -> Self {
            if isSynced {
                return syncedAudioCategory(for: extracted)
            }
            
            return embeddedAudioCategory(for: extracted)
        }
    }
}
