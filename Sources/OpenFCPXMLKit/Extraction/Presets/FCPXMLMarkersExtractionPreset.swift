//
//  FCPXMLMarkersExtractionPreset.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Extraction preset for markers and chapter markers.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// FCPXML extraction preset that extracts markers,.
    public struct MarkersExtractionPreset: FCPXMLExtractionPreset {
        public init() { }
        
        public func perform(
            on extractable: any OFKXMLElement,
            scope: FinalCutPro.FCPXML.ExtractionScope
        ) async -> [FinalCutPro.FCPXML.ExtractedMarker] {
            // Markers on connected / nested hosts remain reportable even when the host is
            // fully occluded for media occupancy. "Hidden" (outside host media range) is a
            // separate filter via ``ReportOptions/includeMarkersOutsideClipBoundaries``.
            // Keep filtering by *marker* self-occlusion off — title-local starts often trip
            // ``effectiveOcclusion`` while remaining visible in FCP (e.g. BasicMarkers).
            var markerScope = scope
            markerScope.occlusions = .allCases
            markerScope.maxContainerDepth = nil
            let basePredicate = scope.extractionPredicate
            markerScope.extractionPredicate = { extracted in
                basePredicate?(extracted) ?? true
            }

            let extracted = await extractable.fcpExtract(
                types: [.marker, .chapterMarker, .analysisMarker],
                scope: markerScope
            )
            
            let wrapped = extracted
                .map { ExtractedMarker($0) }
            
            return wrapped
        }
    }
}

extension FCPXMLExtractionPreset where Self == FinalCutPro.FCPXML.MarkersExtractionPreset {
    /// FCPXML extraction preset that extracts markers.
    public static var markers: FinalCutPro.FCPXML.MarkersExtractionPreset {
        FinalCutPro.FCPXML.MarkersExtractionPreset()
    }
}

extension FinalCutPro.FCPXML {
    // Note: OFKXMLElement is not Sendable; cannot use Task-based concurrency here.

    /// An extracted marker element with pertinent data.
    public struct ExtractedMarker: FCPXMLExtractedModelElement, @unchecked Sendable {
        public typealias Model = Marker
        public let element: any OFKXMLElement
        public let breadcrumbs: [any OFKXMLElement]
        public let resources: (any OFKXMLElement)?
        public let auditions: FinalCutPro.FCPXML.Audition.AuditionMask
        public let mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask
        
        init(_ extractedElement: ExtractedElement) {
            element = extractedElement.element
            breadcrumbs = extractedElement.breadcrumbs
            resources = extractedElement.resources
            auditions = extractedElement.auditions
            mcClipAngles = extractedElement.mcClipAngles
        }
        
        /// Return the a context value for the element.
        public func value<Value>(
            forContext contextKey: FinalCutPro.FCPXML.ElementContext<Value>
        ) -> Value {
            contextKey.value(
                from: element,
                breadcrumbs: breadcrumbs,
                resources: resources,
                auditions: auditions,
                mcClipAngles: mcClipAngles
            )
        }
        
        // Convenience getters
        
        /// Marker name.
        public var name: String {
            model.name
        }
        
        /// Marker note, if any.
        public var note: String? {
            model.note
        }
        
        /// Marker configuration.
        public var configuration: FinalCutPro.FCPXML.Marker.Configuration {
            model.configuration
        }
        
        /// Inherited roles from container(s).
        /// (convenience accessor for `.inheritedRoles` context value).
        public var roles: [AnyInterpolatedRole] {
            value(forContext: .inheritedRoles)
        }
        
        /// Applicable clip keywords.
        /// Keywords are flattened to an array of individual keyword strings, trimming leading and
        /// trailing whitespace, removing duplicates and sorting alphabetically.
        /// (convenience accessor for `.keywords(constrainToKeywordRanges:)` context value).
        public func keywords(constrainToKeywordRanges: Bool = true) -> [String] {
            value(forContext: .keywordsFlat(constrainToKeywordRanges: constrainToKeywordRanges))
        }
    }
}
