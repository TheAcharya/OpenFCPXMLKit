//
//  PNXMLElement+Modular.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Modular PNXMLElement extensions with dependency-injected operations.
//

import Foundation

/// Modular PNXMLElement extensions using dependency injection
@available(macOS 12.0, *)
public extension PNXMLElement {

    /// Sets attribute using injected XML operations service
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    ///   - operations: XML operations service
    func setAttribute(name: String, value: String, using operations: XMLElementOperations) {
        operations.setAttribute(name: name, value: value, on: self)
    }

    /// Gets attribute value using injected XML operations service
    /// - Parameters:
    ///   - name: Attribute name
    ///   - operations: XML operations service
    /// - Returns: Attribute value or nil
    func getAttribute(name: String, using operations: XMLElementOperations) -> String? {
        return operations.getAttribute(name: name, from: self)
    }

    /// Adds child element using injected XML operations service
    /// - Parameters:
    ///   - child: Child element to add
    ///   - operations: XML operations service
    func addChild(_ child: any PNXMLElement, using operations: XMLElementOperations) {
        operations.addChild(child, to: self)
    }

    /// Creates child element with attributes using injected XML operations service
    /// - Parameters:
    ///   - name: Element name
    ///   - attributes: Dictionary of attributes
    ///   - operations: XML operations service
    /// - Returns: New child element
    func createChild(name: String, attributes: [String: String], using operations: XMLElementOperations) -> any PNXMLElement {
        let child = operations.createElement(name: name, attributes: attributes)
        operations.addChild(child, to: self)
        return child
    }
} 
