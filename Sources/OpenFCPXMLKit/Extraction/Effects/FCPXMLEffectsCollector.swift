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
        ///
        /// Includes spine `<clip>` / `<video>` wrappers and compound hosts so
        /// `adjust-transform` on those elements appears on Video & Audio Effects.
        static let extractedEffectHostTypes: Set<ElementType> = [
            .title,
            .assetClip,
            .syncClip,
            .refClip,
            .mcClip,
            .clip,
            .video
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
            
            for mask in element.childElements where mask.name == "filter-video-mask" {
                for filter in mask.childElements where filter.name == "filter-video" {
                    appendFilterEffect(
                        filter,
                        defaultName: filter.stringValue(forAttributeNamed: "name") ?? "Video Effect",
                        host: host,
                        kind: .filterVideo,
                        into: &effects
                    )
                }
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
                        resources: host.resources,
                        auditions: host.auditions,
                        mcClipAngles: host.mcClipAngles
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
                resources: host.resources,
                auditions: host.auditions,
                mcClipAngles: host.mcClipAngles
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
            let parameters = inspectorParamValues(from: filter)
            let settings: ExtractedEffect.Settings = parameters.isEmpty
                ? .empty
                : .namedValues(parameters)
            
            effects.append(
                ExtractedEffect(
                    host: host,
                    timelineContext: nil,
                    effectElement: filter,
                    kind: kind,
                    name: name,
                    settings: settings,
                    sortOrder: 0,
                    isAppleSupplied: isAppleSuppliedFilter(filter, resources: host.resources)
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
            var amounts: [Double] = []
            if let amountString = blend.stringValue(forAttributeNamed: "amount"),
               let amount = Double(amountString)
            {
                amounts.append(amount)
            }
            amounts.append(contentsOf: blendAmountSamples(from: blend))
            amounts = uniquedScalars(amounts)
            
            var sortOrder = 0
            for amount in amounts where !isIdentityOpacity(amount) {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: blend,
                        kind: .compositing,
                        name: "Compositing",
                        settings: .opacityPercent(amount),
                        sortOrder: sortOrder,
                        isAppleSupplied: true
                    )
                )
                sortOrder += 1
            }
            
            if let mode = blend.stringValue(forAttributeNamed: "mode")?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !mode.isEmpty
            {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: blend,
                        kind: .compositing,
                        name: "Compositing",
                        settings: .namedValues([
                            ExtractedEffect.NamedValue(name: "Blend Mode", value: mode)
                        ]),
                        sortOrder: sortOrder,
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
            let samples = TransformAdjustment.componentSamples(from: transform)
            
            var components: [ExtractedEffect.Settings] = []
            for position in samples.positions where !isIdentityPosition(position) {
                components.append(.transformCenter(position))
            }
            for rotation in samples.rotations where !isIdentityRotation(rotation) {
                components.append(.transformRotation(rotation))
            }
            for scale in samples.scales where !isIdentityScale(scale) {
                components.append(.transformScale(scale))
            }
            
            for (index, settings) in components.enumerated() {
                effects.append(
                    ExtractedEffect(
                        host: host,
                        timelineContext: nil,
                        effectElement: transform,
                        kind: .transform,
                        name: "Transform",
                        settings: settings,
                        sortOrder: index,
                        isAppleSupplied: true
                    )
                )
            }
        }
        
        private static func isIdentityPosition(_ position: Point) -> Bool {
            abs(position.x) < 0.0001 && abs(position.y) < 0.0001
        }
        
        private static func isIdentityRotation(_ rotation: Double) -> Bool {
            abs(rotation) < 0.0001
        }
        
        private static func isIdentityScale(_ scale: Point) -> Bool {
            abs(scale.x - 1) < 0.0001 && abs(scale.y - 1) < 0.0001
        }
        
        private static func isIdentityOpacity(_ amount: Double) -> Bool {
            abs(amount - 1) < 0.0001
        }
        
        private static func isAppleSuppliedFilter(
            _ filter: any OFKXMLElement,
            resources: (any OFKXMLElement)?
        ) -> Bool {
            guard let ref = filter.stringValue(forAttributeNamed: "ref"),
                  let resource = filter.fcpResource(forID: ref, in: resources),
                  let effect = resource.fcpAsEffect
            else {
                return false
            }
            return effect.isAppleSupplied
        }
        
        /// Motion graph internals that are not inspector labels.
        private static let skippedInspectorParamNames: Set<String> = [
            "value",
            "vertex",
            "vertex point"
        ]
        
        private static func inspectorParamValues(
            from element: any OFKXMLElement
        ) -> [ExtractedEffect.NamedValue] {
            var values: [ExtractedEffect.NamedValue] = []
            collectInspectorParamValues(from: element, into: &values)
            return uniquedNamedValues(values)
        }
        
        private static func collectInspectorParamValues(
            from element: any OFKXMLElement,
            into values: inout [ExtractedEffect.NamedValue]
        ) {
            for param in element.childElements where param.name == "param" {
                let name = param.stringValue(forAttributeNamed: "name")?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if isInspectorParamName(name) {
                    if let value = param.stringValue(forAttributeNamed: "value"),
                       isInspectorParamValue(value)
                    {
                        values.append(ExtractedEffect.NamedValue(name: name, value: value))
                    }
                    if let animation = param.firstChildElement(named: "keyframeAnimation") {
                        for keyframe in animation.childElements where keyframe.name == "keyframe" {
                            if let value = keyframe.stringValue(forAttributeNamed: "value"),
                               isInspectorParamValue(value)
                            {
                                values.append(ExtractedEffect.NamedValue(name: name, value: value))
                            }
                        }
                    }
                }
                collectInspectorParamValues(from: param, into: &values)
            }
        }
        
        private static func isInspectorParamName(_ name: String) -> Bool {
            !name.isEmpty && !skippedInspectorParamNames.contains(name.lowercased())
        }
        
        /// Values FCP shows in the inspector — not Motion `data` blobs or empty names.
        private static func isInspectorParamValue(_ value: String) -> Bool {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 80 else { return false }
            if trimmed.hasPrefix("PD94") { return false }
            if trimmed.count > 40 {
                let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+/="))
                if trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
                    return false
                }
            }
            return true
        }
        
        private static func uniquedNamedValues(
            _ values: [ExtractedEffect.NamedValue]
        ) -> [ExtractedEffect.NamedValue] {
            var seen: Set<ExtractedEffect.NamedValue> = []
            var result: [ExtractedEffect.NamedValue] = []
            for value in values where seen.insert(value).inserted {
                result.append(value)
            }
            return result
        }
        
        private static func blendAmountSamples(from blend: any OFKXMLElement) -> [Double] {
            var amounts: [Double] = []
            for param in blend.childElements where param.name == "param" {
                let name = param.stringValue(forAttributeNamed: "name")?.lowercased()
                guard name == nil || name == "amount" else { continue }
                if let value = param.stringValue(forAttributeNamed: "value"),
                   let amount = Double(value)
                {
                    amounts.append(amount)
                }
                if let animation = param.firstChildElement(named: "keyframeAnimation") {
                    for keyframe in animation.childElements where keyframe.name == "keyframe" {
                        if let value = keyframe.stringValue(forAttributeNamed: "value"),
                           let amount = Double(value)
                        {
                            amounts.append(amount)
                        }
                    }
                }
            }
            return amounts
        }
        
        private static func uniquedScalars(_ values: [Double]) -> [Double] {
            var seen: Set<String> = []
            var result: [Double] = []
            for value in values {
                let key = String(format: "%.4f", value)
                if seen.insert(key).inserted {
                    result.append(value)
                }
            }
            return result
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
