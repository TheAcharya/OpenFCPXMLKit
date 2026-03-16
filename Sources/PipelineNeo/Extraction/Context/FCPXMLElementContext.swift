//
//  FCPXMLElementContext.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Element context identity and value builder.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// Element context identity and value builder to produce strongly-typed information gathered
    /// from an element.
    public struct ElementContext<Value> {
        public let valueBuilder: ValueBuilder
        
        public init(
            value: @escaping ValueBuilder
        ) {
            valueBuilder = value
        }
        
        /// Returns the context value using the associated context value builder.
        ///
        /// - Parameters:
        ///   - element: The element.
        ///   - breadcrumbs: All ancestors traversed including resource jumps.
        ///     Ordered nearest to furthest ancestor.
        ///   - resources: The document's `resources` container element.
        ///     If `nil`, the `resources` found in the document will be used if present.
        public func value(
            from element: any PNXMLElement,
            breadcrumbs: [any PNXMLElement],
            resources: (any PNXMLElement)? // `resources` container element
        ) -> Value {
            let tools = Tools(
                element: element,
                breadcrumbs: breadcrumbs,
                resources: resources
            )

            let resources = resources
                ?? element.fcpRootResources
                ?? PNXMLDefaultFactory().makeElement(name: ElementType.resources.rawValue)
            
            return valueBuilder(
                element,
                breadcrumbs,
                resources,
                tools
            )
        }
    }
}

extension FinalCutPro.FCPXML.ElementContext {
    /// Context value builder closure for an element.
    ///
    /// - Parameters:
    ///   - element: The element.
    ///   - breadcrumbs: All ancestors traversed including resource jumps.
    ///     Ordered nearest to furthest ancestor.
    ///   - resources: The document's `resources` container element provided for convenience.
    ///   - tools: Convenience methods for building context.
    public typealias ValueBuilder = (
        _ element: any PNXMLElement,
        _ breadcrumbs: [any PNXMLElement],
        _ resources: any PNXMLElement, // `resources` container element
        _ tools: Tools
    ) -> Value
}
