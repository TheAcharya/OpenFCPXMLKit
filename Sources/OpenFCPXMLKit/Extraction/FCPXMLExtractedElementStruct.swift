//
//  FCPXMLExtractedElementStruct.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Extracted element with context (element, breadcrumbs, resources).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    // Note: OFKXMLElement is not Sendable; cannot use Task-based concurrency here.

    /// Extracted element and its context.
    public struct ExtractedElement: @unchecked Sendable {
        public let element: any OFKXMLElement
        public let breadcrumbs: [any OFKXMLElement]
        public let resources: (any OFKXMLElement)?
        /// Audition mask used when resolving inherited / local roles.
        public let auditions: FinalCutPro.FCPXML.Audition.AuditionMask
        /// Multicam angle mask used when resolving inherited / local roles.
        public let mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask

        init(
            element: any OFKXMLElement,
            breadcrumbs: [any OFKXMLElement],
            resources: (any OFKXMLElement)?,
            auditions: FinalCutPro.FCPXML.Audition.AuditionMask = .active,
            mcClipAngles: FinalCutPro.FCPXML.MCClip.AngleMask = .active
        ) {
            self.element = element
            self.breadcrumbs = breadcrumbs
            self.resources = resources
            self.auditions = auditions
            self.mcClipAngles = mcClipAngles
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
    }
}

extension FinalCutPro.FCPXML.ExtractedElement: FCPXMLExtractedElement { }
