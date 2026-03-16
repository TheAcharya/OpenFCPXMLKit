//
//  FoundationXMLElement.swift
//  Pipeline Neo
//
//  Foundation backend adapter for PNXMLElement.
//  Wraps Foundation's XMLElement and delegates all operations to it.
//
//  This file is conditionally compiled for platforms where Foundation XML is available.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation

// MARK: - FoundationXMLElement

/// A Foundation-backed XML element that conforms to `PNXMLElement`.
///
/// Wraps Foundation's `XMLElement` and delegates all calls to it.
/// This is a reference type (class) so that mutations to the wrapped element
/// are visible through all references, matching Foundation's `XMLElement` semantics.
///
/// Use `underlyingElement` for direct access to the wrapped `XMLElement`
/// during incremental migration.
public final class FoundationXMLElement: PNXMLElement {

    // MARK: - Escape Hatch

    /// The underlying Foundation `XMLElement` for direct access during incremental migration.
    public let underlyingElement: XMLElement

    // MARK: - Initialization

    /// Wraps an existing Foundation `XMLElement`.
    ///
    /// - Parameter element: The Foundation `XMLElement` to wrap.
    public init(_ element: XMLElement) {
        self.underlyingElement = element
    }

    /// Creates a new element with the given tag name.
    ///
    /// - Parameter name: The tag name for the element.
    public convenience init(name: String) {
        self.init(XMLElement(name: name))
    }

    /// Creates a new element with the given tag name and string value.
    ///
    /// - Parameters:
    ///   - name: The tag name for the element.
    ///   - stringValue: The text content for the element.
    public convenience init(name: String, stringValue: String) {
        self.init(XMLElement(name: name, stringValue: stringValue))
    }

    /// Creates a new element by parsing an XML string fragment.
    ///
    /// - Parameter xmlString: An XML string representing a single element.
    /// - Throws: If the string cannot be parsed as an XML element.
    public convenience init(xmlString: String) throws {
        let element = try XMLElement(xmlString: xmlString)
        self.init(element)
    }

    // MARK: - PNXMLNode Conformance

    public var name: String? {
        get { underlyingElement.name }
        set { underlyingElement.name = newValue }
    }

    public var stringValue: String? {
        get { underlyingElement.stringValue }
        set { underlyingElement.stringValue = newValue }
    }

    public var xmlString: String {
        underlyingElement.xmlString
    }

    public var parent: (any PNXMLElement)? {
        guard let parentElement = underlyingElement.parent as? XMLElement else {
            return nil
        }
        return FoundationXMLElement(parentElement)
    }

    public var children: [any PNXMLNode]? {
        underlyingElement.children?.map { child in
            if let element = child as? XMLElement {
                return FoundationXMLElement(element) as any PNXMLNode
            }
            return FoundationXMLNode(child) as any PNXMLNode
        }
    }

    // MARK: - PNXMLElement: Attribute Access

    public func attribute(forName name: String) -> String? {
        underlyingElement.attribute(forName: name)?.stringValue
    }

    public func addAttribute(name: String, value: String?) {
        if let value {
            let attr = XMLNode.attribute(
                withName: name,
                stringValue: value
            ) as! XMLNode // swiftlint:disable:this force_cast
            // Remove existing attribute with same name first to avoid duplicates
            underlyingElement.removeAttribute(forName: name)
            underlyingElement.addAttribute(attr)
        } else {
            underlyingElement.removeAttribute(forName: name)
        }
    }

    public func removeAttribute(forName name: String) {
        underlyingElement.removeAttribute(forName: name)
    }

    public var attributes: [(name: String, value: String)] {
        (underlyingElement.attributes ?? []).compactMap { node in
            guard let attrName = node.name, let attrValue = node.stringValue else {
                return nil
            }
            return (name: attrName, value: attrValue)
        }
    }

    // MARK: - PNXMLElement: Child Access

    public func elements(forName name: String) -> [any PNXMLElement] {
        underlyingElement.elements(forName: name).map { FoundationXMLElement($0) }
    }

    public func addChild(_ child: any PNXMLNode) {
        if let foundationElement = child as? FoundationXMLElement {
            underlyingElement.addChild(foundationElement.underlyingElement)
        } else if let foundationNode = child as? FoundationXMLNode {
            underlyingElement.addChild(foundationNode.underlyingNode)
        } else {
            // Fallback: create an XMLElement from the child's xmlString
            if let parsed = try? XMLElement(xmlString: child.xmlString) {
                underlyingElement.addChild(parsed)
            }
        }
    }

    public func removeChild(at index: Int) {
        underlyingElement.removeChild(at: index)
    }

    public func insertChild(_ child: any PNXMLNode, at index: Int) {
        if let foundationElement = child as? FoundationXMLElement {
            underlyingElement.insertChild(foundationElement.underlyingElement, at: index)
        } else if let foundationNode = child as? FoundationXMLNode {
            underlyingElement.insertChild(foundationNode.underlyingNode, at: index)
        } else {
            // Fallback: create an XMLElement from the child's xmlString
            if let parsed = try? XMLElement(xmlString: child.xmlString) {
                underlyingElement.insertChild(parsed, at: index)
            }
        }
    }

    // MARK: - PNXMLElement: Serialization

    public var xmlCompactString: String {
        underlyingElement.xmlString(options: [.nodeCompactEmptyElement])
    }
}

// MARK: - FoundationXMLNode

/// A Foundation-backed XML node that conforms to `PNXMLNode`.
///
/// Wraps Foundation's `XMLNode` for non-element nodes (text, comments, etc.).
/// Element nodes should use `FoundationXMLElement` instead.
///
/// Use `underlyingNode` for direct access to the wrapped `XMLNode`
/// during incremental migration.
public final class FoundationXMLNode: PNXMLNode {

    // MARK: - Escape Hatch

    /// The underlying Foundation `XMLNode` for direct access during incremental migration.
    public let underlyingNode: XMLNode

    // MARK: - Initialization

    /// Wraps an existing Foundation `XMLNode`.
    ///
    /// - Parameter node: The Foundation `XMLNode` to wrap.
    public init(_ node: XMLNode) {
        self.underlyingNode = node
    }

    // MARK: - PNXMLNode Conformance

    public var name: String? {
        get { underlyingNode.name }
        set { underlyingNode.name = newValue }
    }

    public var stringValue: String? {
        get { underlyingNode.stringValue }
        set { underlyingNode.stringValue = newValue }
    }

    public var xmlString: String {
        underlyingNode.xmlString
    }

    public var parent: (any PNXMLElement)? {
        guard let parentElement = underlyingNode.parent as? XMLElement else {
            return nil
        }
        return FoundationXMLElement(parentElement)
    }

    public var children: [any PNXMLNode]? {
        underlyingNode.children?.map { child in
            if let element = child as? XMLElement {
                return FoundationXMLElement(element) as any PNXMLNode
            }
            return FoundationXMLNode(child) as any PNXMLNode
        }
    }
}

#endif
