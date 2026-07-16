//
// WindowAnnotationBuilder.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Builds Sendable role / effect / breadcrumb / marker / keyword / title annotations.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Resolves window annotations from the live walk context (XML stays local to Projection).
    enum WindowAnnotationBuilder {
        static func annotations(
            for element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            options: TimelineProjectionOptions,
            channelKind: MediaChannel.Kind
        ) -> (
            roles: [AnyInterpolatedRole],
            effects: [WindowEffectAnnotation],
            breadcrumbs: [WindowBreadcrumb]
        ) {
            guard options.includeAnnotations else {
                return ([], [], [])
            }

            let roles = element._fcpInheritedRoles(
                ancestors: ancestors,
                resources: resources,
                auditions: options.auditions,
                mcClipAngles: options.mcClipAngles
            )
            .flattenedInterpolatedRoles()
            .filter { role in
                switch channelKind {
                case .video: return role.isVideo || role.isCaption
                case .audio: return role.isAudio
                }
            }

            let effects = effectAnnotations(on: element)
            let breadcrumbs = breadcrumbPath(element: element, ancestors: ancestors)
            return (roles, effects, breadcrumbs)
        }

        /// Clip/title-hosted markers, keywords, and title facts (once per host, not per channel).
        static func clipAnnotations(
            for element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            absoluteStart: Fraction,
            options: TimelineProjectionOptions
        ) -> ProjectedClipAnnotations? {
            guard options.includeAnnotations else { return nil }

            let markers = markerAnnotations(
                on: element,
                absoluteStart: absoluteStart
            )
            let keywords = keywordAnnotations(
                on: element,
                absoluteStart: absoluteStart
            )
            let title = titleAnnotation(
                for: element,
                resources: resources,
                absoluteStart: absoluteStart
            )
            let transition = transitionAnnotation(
                for: element,
                ancestors: ancestors,
                resources: resources,
                absoluteStart: absoluteStart
            )
            let effects = reportEffectAnnotations(
                for: element,
                ancestors: ancestors,
                resources: resources,
                absoluteStart: absoluteStart,
                options: options
            )
            guard !markers.isEmpty
                || !keywords.isEmpty
                || title != nil
                || transition != nil
                || !effects.isEmpty
            else { return nil }

            let roles = element._fcpInheritedRoles(
                ancestors: ancestors,
                resources: resources,
                auditions: options.auditions,
                mcClipAngles: options.mcClipAngles
            )
            .flattenedInterpolatedRoles()

            let hostType = element.fcpElementType?.rawValue ?? element.name ?? ""
            let displayName = clipDisplayName(
                for: element,
                ancestors: ancestors,
                resources: resources
            )

            return ProjectedClipAnnotations(
                clipDisplayName: displayName,
                hostElementType: hostType,
                roles: roles,
                carriesVideo: element.fcpCarriesVideo(resources: resources),
                carriesAudio: element.fcpCarriesAudio(resources: resources),
                markers: markers,
                keywords: keywords,
                title: title,
                transition: transition,
                effects: effects
            )
        }

        static func breadcrumbPath(
            element: any OFKXMLElement,
            ancestors: [any OFKXMLElement]
        ) -> [WindowBreadcrumb] {
            // Furthest ancestor → leaf (readable path).
            let ordered = Array(ancestors.reversed()) + [element]
            return ordered.compactMap { node in
                guard let type = node.fcpElementType else { return nil }
                return WindowBreadcrumb(
                    elementType: type.rawValue,
                    name: node.fcpName,
                    lane: node.fcpLane
                )
            }
        }

        static func effectAnnotations(on element: any OFKXMLElement) -> [WindowEffectAnnotation] {
            var result: [WindowEffectAnnotation] = []
            for child in element.childElements {
                guard let name = child.name else { continue }
                if let kind = kind(forElementName: name) {
                    let display = child.stringValue(forAttributeNamed: "name")
                        ?? defaultDisplayName(for: kind, elementName: name)
                    result.append(WindowEffectAnnotation(name: display, kind: kind))
                }
            }
            return result
        }

        private static func titleAnnotation(
            for element: any OFKXMLElement,
            resources: (any OFKXMLElement)?,
            absoluteStart: Fraction
        ) -> WindowTitleAnnotation? {
            guard let title = element.fcpAsTitle else { return nil }

            let duration = title.duration
            let timelineOut = ProjectionTiming.adding(absoluteStart, duration)

            return WindowTitleAnnotation(
                titleText: title.concatenatedDisplayText(),
                font: title.displayFontSpecifications(),
                enabled: title.enabled,
                isAppleSupplied: title.isAppleSuppliedEffect(resources: resources),
                timelineIn: absoluteStart,
                timelineOut: timelineOut,
                duration: duration
            )
        }

        private static func transitionAnnotation(
            for element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            absoluteStart: Fraction
        ) -> WindowTransitionAnnotation? {
            guard let transition = element.fcpAsTransition else { return nil }

            let duration = transition.duration
            let timelineOut = ProjectionTiming.adding(absoluteStart, duration)
            let placement = Transition.spinePlacement(
                parentElement: ancestors.first,
                breadcrumbs: ancestors
            )

            return WindowTransitionAnnotation(
                name: transition.name ?? "Transition",
                placement: placement,
                isAppleSupplied: transition.isAppleSuppliedPrimaryEffect(in: resources),
                timelineIn: absoluteStart,
                timelineOut: timelineOut,
                duration: duration
            )
        }

        /// Collects report effects via ``EffectsCollector`` (shared semantics with Extraction).
        private static func reportEffectAnnotations(
            for element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            absoluteStart: Fraction,
            options: TimelineProjectionOptions
        ) -> [WindowReportEffectAnnotation] {
            guard let type = element.fcpElementType,
                  EffectsCollector.extractedEffectHostTypes.contains(type)
            else { return [] }

            let host = ExtractedElement(
                element: element,
                breadcrumbs: ancestors,
                resources: resources,
                auditions: options.auditions,
                mcClipAngles: options.mcClipAngles
            )
            let hostDuration = element.fcpDuration ?? .zero
            let hostOut = ProjectionTiming.adding(absoluteStart, hostDuration)
            let hostOcclusion = element._fcpEffectiveOcclusion(ancestors: ancestors)

            return EffectsCollector.effects(on: host).compactMap { effect in
                if effect.kind == .filterVideo, hostOcclusion != .notOccluded {
                    return nil
                }

                let timing = effectTimeline(
                    for: effect,
                    hostElement: element,
                    hostAbsoluteStart: absoluteStart,
                    hostAbsoluteOut: hostOut
                )

                return WindowReportEffectAnnotation(
                    name: effect.name,
                    kind: effect.kind,
                    settings: effect.settings,
                    enabled: EffectsCollector.isEffectEnabled(
                        effectElement: effect.effectElement,
                        host: element
                    ),
                    isAppleSupplied: effect.isAppleSupplied,
                    sortOrder: effect.sortOrder,
                    timelineIn: timing.in,
                    timelineOut: timing.out
                )
            }
        }

        private static func effectTimeline(
            for effect: ExtractedEffect,
            hostElement: any OFKXMLElement,
            hostAbsoluteStart: Fraction,
            hostAbsoluteOut: Fraction
        ) -> (in: Fraction, out: Fraction) {
            guard let context = effect.timelineContext,
                  context.element !== effect.host.element
            else {
                return (hostAbsoluteStart, hostAbsoluteOut)
            }

            let nestedStart = ProjectionTiming.absoluteStart(
                offset: context.element.fcpOffset,
                parentAbsoluteStart: hostAbsoluteStart,
                parentLocalStart: ProjectionTiming.localStartForChildren(of: hostElement)
            )
            let nestedDuration = context.element.fcpDuration ?? (hostElement.fcpDuration ?? .zero)
            let nestedOut = ProjectionTiming.adding(nestedStart, nestedDuration)
            return (nestedStart, nestedOut)
        }

        private static func clipDisplayName(
            for element: any OFKXMLElement,
            ancestors: [any OFKXMLElement],
            resources: (any OFKXMLElement)?
        ) -> String {
            if element.fcpElementType == .title {
                return titleEffectDisplayName(for: element, resources: resources)
            }
            return element.fcpName
                ?? ancestors.first(where: { $0.fcpName != nil })?.fcpName
                ?? ""
        }

        private static func titleEffectDisplayName(
            for element: any OFKXMLElement,
            resources: (any OFKXMLElement)?
        ) -> String {
            if let ref = element.fcpRef,
               let resourceName = element.fcpResource(forID: ref, in: resources)?.fcpName,
               !resourceName.isEmpty
            {
                return resourceName
            }
            return element.fcpName ?? ""
        }

        private static func markerAnnotations(
            on element: any OFKXMLElement,
            absoluteStart: Fraction
        ) -> [WindowMarkerAnnotation] {
            let hostStart = element.fcpStart ?? .zero
            let reel = element._fcpMetadataChildStringValue(forKey: .reel) ?? ""
            let scene = element._fcpMetadataChildStringValue(forKey: .scene) ?? ""

            var result: [WindowMarkerAnnotation] = []
            for child in element.childElements {
                guard let marker = FinalCutPro.FCPXML.Marker(element: child),
                      let configuration = child.fcpMarkerConfiguration
                else { continue }

                let sourcePosition = marker.start
                let relative = ProjectionTiming.subtracting(sourcePosition, hostStart)
                let timelinePosition = ProjectionTiming.adding(absoluteStart, relative)

                result.append(
                    WindowMarkerAnnotation(
                        name: marker.name,
                        kind: windowMarkerKind(for: configuration),
                        notes: marker.note ?? "",
                        timelinePosition: timelinePosition,
                        sourcePosition: sourcePosition,
                        reel: reel,
                        scene: scene
                    )
                )
            }
            return result
        }

        private static func keywordAnnotations(
            on element: any OFKXMLElement,
            absoluteStart: Fraction
        ) -> [WindowKeywordAnnotation] {
            let hostStart = element.fcpStart ?? .zero
            let reel = element._fcpMetadataChildStringValue(forKey: .reel) ?? ""
            let scene = element._fcpMetadataChildStringValue(forKey: .scene) ?? ""

            var result: [WindowKeywordAnnotation] = []
            for child in element.childElements {
                guard let keyword = child.fcpAsKeyword else { continue }
                let sourceStart = keyword.start
                let duration = keyword.duration ?? .zero
                let relative = ProjectionTiming.subtracting(sourceStart, hostStart)
                let timelineIn = ProjectionTiming.adding(absoluteStart, relative)
                let timelineOut = ProjectionTiming.adding(timelineIn, duration)

                result.append(
                    WindowKeywordAnnotation(
                        keyword: child.fcpValue ?? keyword.keywords.joined(separator: ", "),
                        notes: keyword.note ?? "",
                        timelineIn: timelineIn,
                        timelineOut: timelineOut,
                        duration: duration,
                        reel: reel,
                        scene: scene
                    )
                )
            }
            return result
        }

        private static func windowMarkerKind(
            for configuration: Marker.Configuration
        ) -> WindowMarkerKind {
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

        private static func kind(forElementName name: String) -> WindowEffectAnnotation.Kind? {
            switch name {
            case "adjust-volume": return .volume
            case "adjust-transform": return .transform
            case "adjust-crop": return .crop
            case "adjust-blend", "adjust-compositing": return .compositing
            case "adjust-stabilization": return .stabilization
            case "adjust-loudness": return .loudness
            case "adjust-noiseReduction": return .noiseReduction
            case "adjust-humReduction": return .humReduction
            case "adjust-EQ", "adjust-equalization": return .equalization
            case "filter-video": return .filterVideo
            case "filter-audio": return .filterAudio
            default:
                if name.hasPrefix("adjust-") || name.hasPrefix("filter-") {
                    return .other
                }
                return nil
            }
        }

        private static func defaultDisplayName(
            for kind: WindowEffectAnnotation.Kind,
            elementName: String
        ) -> String {
            switch kind {
            case .volume: return "volume"
            case .transform: return "Transform"
            case .crop: return "Crop"
            case .compositing: return "Compositing"
            case .stabilization: return "Stabilization"
            case .loudness: return "Loudness"
            case .noiseReduction: return "Noise Reduction"
            case .humReduction: return "Hum Reduction"
            case .equalization: return "EQ"
            case .filterVideo, .filterAudio, .other: return elementName
            }
        }
    }
}
