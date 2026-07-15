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

        init(
            element: any OFKXMLElement,
            breadcrumbs: [any OFKXMLElement],
            resources: (any OFKXMLElement)?
        ) {
            self.element = element
            self.breadcrumbs = breadcrumbs
            self.resources = resources
        }
        
        /// Return the a context value for the element.
        public func value<Value>(
            forContext contextKey: FinalCutPro.FCPXML.ElementContext<Value>
        ) -> Value {
            contextKey.value(from: element, breadcrumbs: breadcrumbs, resources: resources)
        }
    }
}

extension FinalCutPro.FCPXML.ExtractedElement: FCPXMLExtractedElement { }
