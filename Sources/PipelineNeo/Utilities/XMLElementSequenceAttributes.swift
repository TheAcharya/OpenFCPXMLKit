//
//  XMLElementSequenceAttributes.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Sequence extensions for finding elements by attributes and names.
//

import Foundation

// MARK: - Attribute-Based Lookups

extension Sequence where Element == any PNXMLElement {
    /// Returns the first element that has the given attribute, and the attribute's string value.
    func first(withAttribute name: String) -> (element: any PNXMLElement, attributeValue: String)? {
        for element in self {
            if let value = element.attribute(forName: name) {
                return (element: element, attributeValue: value)
            }
        }
        return nil
    }

    /// Returns the first element where the attribute has the given value.
    func first(whereAttribute name: String, hasValue value: String) -> (any PNXMLElement)? {
        for element in self {
            if element.attribute(forName: name) == value {
                return element
            }
        }
        return nil
    }
}

// MARK: - Name-Based Filtering (mirrors SwiftExtensions XMLElement sequence methods)

extension Sequence where Element == any PNXMLElement {
    /// Filters by the given XML element name.
    func filter(
        whereElementNamed nodeName: String
    ) -> [any PNXMLElement] {
        filter { $0.name == nodeName }
    }

    /// Filters by any of the given XML element names.
    func filter(
        whereElementNamed nodeNames: [String]
    ) -> [any PNXMLElement] {
        filter {
            guard let name = $0.name else { return false }
            return nodeNames.contains(name)
        }
    }

    /// Returns the first element with the given XML node name.
    func first(
        whereElementNamed nodeName: String
    ) -> (any PNXMLElement)? {
        first { $0.name == nodeName }
    }

    /// Returns the first element with any of the given XML node names.
    func first(
        whereElementNamed nodeNames: [String]
    ) -> (any PNXMLElement)? {
        first {
            guard let name = $0.name else { return false }
            return nodeNames.contains(name)
        }
    }
}
