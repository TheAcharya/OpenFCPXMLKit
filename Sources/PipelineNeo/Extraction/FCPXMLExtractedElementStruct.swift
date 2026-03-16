//
//  FCPXMLExtractedElementStruct.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Extracted element with context (element, breadcrumbs, resources).
//

import Foundation
import SwiftTimecode
import SwiftExtensions

extension FinalCutPro.FCPXML {
    // Note: PNXMLElement is not Sendable; cannot use Task-based concurrency here.

    /// Extracted element and its context.
    public struct ExtractedElement: @unchecked Sendable {
        public let element: any PNXMLElement
        public let breadcrumbs: [any PNXMLElement]
        public let resources: (any PNXMLElement)?

        init(
            element: any PNXMLElement,
            breadcrumbs: [any PNXMLElement],
            resources: (any PNXMLElement)?
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
