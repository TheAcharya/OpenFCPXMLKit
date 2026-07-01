//
//  FCPXMLEffectsCollector.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Collects semantic effects from timeline clip host elements.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Walks clip hosts and collects attached effects without report formatting.
    enum EffectsCollector {
        /// Clip element types that can carry effects during collection walks.
        static let effectHostTypes: Set<ElementType> = [
            .title,
            .assetClip,
            .syncClip,
            .refClip,
            .mcClip,
            .clip,
            .audio,
            .video
        ]
        
        /// Clip types extracted as top-level effect hosts.
        static let extractedEffectHostTypes: Set<ElementType> = [
            .title,
            .assetClip,
            .syncClip
        ]
        
        private static let nestedVolumeContainerNames: Set<String> = [
            "clip",
            "audio"
        ]
        
        /// Collects effects attached to a timeline clip host element.
        static func effects(on host: ExtractedElement) -> [ExtractedEffect] {
            var effects: [ExtractedEffect] = []
            collectDirectEffects(on: host.element, host: host, into: &effects)
            collectVolumeEffects(in: host.element, host: host, into: &effects)
            
            if !effects.contains(where: { $0.kind == .volume || $0.kind == .implicitVolume }),
               host.element.fcpElementType == .assetClip,
               host.element.fcpGetEnabled(default: true) == false,
               host.element.fcpCarriesAudio(resources: host.resources)
            {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: host.element,
                        kind: .implicitVolume,
                        name: "volume",
                        settings: .empty,
                        sortOrder: 0,
                        isAppleSupplied: true
                    )
                )
            }
            
            return effects
        }
        
        private static func collectDirectEffects(
            on element: any OFKXMLElement,
            host: ExtractedElement,
            into effects: inout [ExtractedEffect]
        ) {
            for filter in element.childElements where filter.name == "filter-video" {
                appendFilterEffect(
                    filter,
                    defaultName: filter.stringValue(forAttributeNamed: "name") ?? "Video Effect",
                    host: host,
                    kind: .filterVideo,
                    into: &effects
                )
            }
            
            for filter in element.childElements where filter.name == "filter-audio" {
                appendFilterEffect(
                    filter,
                    defaultName: filter.stringValue(forAttributeNamed: "name") ?? "Audio Effect",
                    host: host,
                    kind: .filterAudio,
                    into: &effects
                )
            }
            
            if let blend = element.firstChildElement(named: "adjust-blend") {
                appendBlendEffect(blend, host: host, into: &effects)
            }
            
            if let conform = element.firstChildElement(named: "adjust-conform") {
                appendConformEffect(conform, host: host, into: &effects)
            }
            
            if let transform = element.firstChildElement(named: "adjust-transform") {
                appendTransformEffects(transform, host: host, into: &effects)
            }
        }
        
        private static func collectVolumeEffects(
            in hostElement: any OFKXMLElement,
            host: ExtractedElement,
            into effects: inout [ExtractedEffect]
        ) {
            visitVolumeElements(
                element: hostElement,
                host: host,
                breadcrumbs: host.breadcrumbs,
                into: &effects
            )
            
            if hostElement.firstChildElement(named: "adjust-volume") == nil {
                collectSyncSourceVolumeEffects(in: hostElement, host: host, into: &effects)
            }
        }
        
        private static func collectSyncSourceVolumeEffects(
            in hostElement: any OFKXMLElement,
            host: ExtractedElement,
            into effects: inout [ExtractedEffect]
        ) {
            for syncSource in hostElement.childElements where syncSource.name == "sync-source" {
                for roleSource in syncSource.childElements where roleSource.name == "audio-role-source" {
                    for volume in roleSource.childElements where volume.name == "adjust-volume" {
                        appendVolumeEffects(
                            volume,
                            host: host,
                            timelineContext: nil,
                            into: &effects
                        )
                    }
                }
            }
        }
        
        private static func visitVolumeElements(
            element: any OFKXMLElement,
            host: ExtractedElement,
            breadcrumbs: [any OFKXMLElement],
            into effects: inout [ExtractedEffect]
        ) {
            if element !== host.element {
                if let name = element.name,
                   nestedVolumeContainerNames.contains(name)
                {
                    let timelineContext = ExtractedElement(
                        element: element,
                        breadcrumbs: breadcrumbs,
                        resources: host.resources
                    )
                    
                    for volume in element.childElements where volume.name == "adjust-volume" {
                        appendVolumeEffects(
                            volume,
                            host: host,
                            timelineContext: timelineContext,
                            into: &effects
                        )
                    }
                    return
                }
                
                if let elementType = element.fcpElementType,
                   extractedEffectHostTypes.contains(elementType)
                {
                    return
                }
            }
            
            let timelineContext = ExtractedElement(
                element: element,
                breadcrumbs: breadcrumbs,
                resources: host.resources
            )
            
            for volume in element.childElements where volume.name == "adjust-volume" {
                appendVolumeEffects(
                    volume,
                    host: host,
                    timelineContext: timelineContext,
                    into: &effects
                )
            }
            
            let childBreadcrumbs = breadcrumbs + [element]
            for child in element.childElements {
                visitVolumeElements(
                    element: child,
                    host: host,
                    breadcrumbs: childBreadcrumbs,
                    into: &effects
                )
            }
        }
        
        private static func appendFilterEffect(
            _ filter: any OFKXMLElement,
            defaultName: String,
            host: ExtractedElement,
            kind: ExtractedEffect.Kind,
            into effects: inout [ExtractedEffect]
        ) {
            let name = filter.stringValue(forAttributeNamed: "name") ?? defaultName
            
            effects.append(
                ExtractedEffect(
                    host: host,
                    timelineContext: nil,
                    effectElement: filter,
                    kind: kind,
                    name: name,
                    settings: .text(name),
                    sortOrder: 0,
                    isAppleSupplied: true
                )
            )
        }
        
        private static func appendVolumeEffects(
            _ volume: any OFKXMLElement,
            host: ExtractedElement,
            timelineContext: ExtractedElement?,
            into effects: inout [ExtractedEffect]
        ) {
            if let amountString = volume.stringValue(forAttributeNamed: "amount"),
               let amount = volumeAmount(fromAmountString: amountString)
            {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: timelineContext,
                        effectElement: volume,
                        kind: .volume,
                        name: "volume",
                        settings: .decibels(amount),
                        sortOrder: 0,
                        isAppleSupplied: true
                    )
                )
                return
            }
            
            effects.append(
                ExtractedEffect(
                    host: host,
                    timelineContext: timelineContext,
                    effectElement: volume,
                    kind: .volume,
                    name: "volume",
                    settings: .empty,
                    sortOrder: 0,
                    isAppleSupplied: true
                )
            )
            effects.append(
                ExtractedEffect(
                    host: host,
                    timelineContext: timelineContext,
                    effectElement: volume,
                    kind: .volume,
                    name: "volume",
                    settings: .decibels(0),
                    sortOrder: 1,
                    isAppleSupplied: true
                )
            )
        }
        
        private static func appendBlendEffect(
            _ blend: any OFKXMLElement,
            host: ExtractedElement,
            into effects: inout [ExtractedEffect]
        ) {
            if let amountString = blend.stringValue(forAttributeNamed: "amount"),
               let amount = Double(amountString)
            {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: blend,
                        kind: .compositing,
                        name: "Compositing",
                        settings: .opacityPercent(amount),
                        sortOrder: 0,
                        isAppleSupplied: true
                    )
                )
                return
            }
            
            if blend.firstChildElement(named: "param") != nil {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: blend,
                        kind: .compositing,
                        name: "Compositing",
                        settings: .empty,
                        sortOrder: 0,
                        isAppleSupplied: true
                    )
                )
            }
        }
        
        private static func appendConformEffect(
            _ conform: any OFKXMLElement,
            host: ExtractedElement,
            into effects: inout [ExtractedEffect]
        ) {
            let typeString = conform.stringValue(forAttributeNamed: "type") ?? "fit"
            
            effects.append(
                ExtractedEffect(
                    host: host,
                    timelineContext: nil,
                    effectElement: conform,
                    kind: .spatialConform,
                    name: "Spatial Conform",
                    settings: .conformType(typeString),
                    sortOrder: 0,
                    isAppleSupplied: true
                )
            )
        }
        
        private static func appendTransformEffects(
            _ transform: any OFKXMLElement,
            host: ExtractedElement,
            into effects: inout [ExtractedEffect]
        ) {
            let adjustment = TransformAdjustment(from: transform)
            
            let centerDefault = adjustment.position.x == 0 && adjustment.position.y == 0
            let rotationDefault = adjustment.rotation == 0
            let scaleDefault = adjustment.scale.x == 1 && adjustment.scale.y == 1
            
            var components: [(settings: ExtractedEffect.Settings, isNonDefault: Bool, priority: Int)] = [
                (.transformCenter(adjustment.position), !centerDefault, 2),
                (.transformRotation(adjustment.rotation), !rotationDefault, 1),
                (.transformScale(adjustment.scale), !scaleDefault, 0)
            ]
            
            components.sort { lhs, rhs in
                if lhs.isNonDefault != rhs.isNonDefault {
                    return lhs.isNonDefault && !rhs.isNonDefault
                }
                if lhs.isNonDefault {
                    return lhs.priority < rhs.priority
                }
                switch (isCenterSettings(lhs.settings), isCenterSettings(rhs.settings)) {
                case (true, false): return true
                case (false, true): return false
                default:
                    if isRotationSettings(lhs.settings) { return true }
                    if isRotationSettings(rhs.settings) { return false }
                    return lhs.priority < rhs.priority
                }
            }
            
            for (index, component) in components.enumerated() {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: transform,
                        kind: .transform,
                        name: "Transform",
                        settings: component.settings,
                        sortOrder: index,
                        isAppleSupplied: true
                    )
                )
            }
        }
        
        private static func isCenterSettings(_ settings: ExtractedEffect.Settings) -> Bool {
            if case .transformCenter = settings { return true }
            return false
        }
        
        private static func isRotationSettings(_ settings: ExtractedEffect.Settings) -> Bool {
            if case .transformRotation = settings { return true }
            return false
        }
        
        static func isEffectEnabled(
            effectElement: any OFKXMLElement,
            host: any OFKXMLElement
        ) -> Bool {
            if effectElement.name == "adjust-volume"
                || effectElement.name == "filter-video"
                || effectElement.name == "filter-audio"
                || effectElement.name == "adjust-transform"
                || effectElement.name == "adjust-blend"
                || effectElement.name == "adjust-conform"
            {
                if effectElement.stringValue(forAttributeNamed: "enabled") != nil {
                    return effectElement.fcpGetEnabled(default: true)
                }
            }
            
            return host.fcpGetEnabled(default: true)
        }
        
        private static func volumeAmount(fromAmountString amountString: String) -> Double? {
            if let volume = VolumeAdjustment(fromDecibelString: amountString) {
                return volume.amount
            }
            
            let trimmed = amountString.replacingOccurrences(of: "dB", with: "")
            return Double(trimmed)
        }
    }
}
