//
//  PNXMLElement.swift
//  Pipeline Neo
//
//  Platform-agnostic XML element protocol.
//  Mirrors the Foundation XMLElement API surface used by PipelineNeo,
//  plus convenience methods from swift-extensions (stringValue(forAttributeNamed:),
//  addAttribute(withName:value:), childElements, firstChildElement(named:), etc.).
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

import Foundation

// MARK: - PNXMLElement

/// A platform-agnostic protocol representing an XML element.
///
/// Conforms to `PNXMLNode` and adds attribute access, child manipulation,
/// and convenience methods that mirror both Foundation `XMLElement` and the
/// swift-extensions convenience API.
///
/// This protocol is intentionally **not** `Sendable`. Operations protocols
/// that wrap element instances may add `Sendable` conformance where appropriate.
public protocol PNXMLElement: PNXMLNode {

    // MARK: - Attribute Access (Core)

    /// Returns the attribute node for the given name, or `nil` if not present.
    /// The returned string is the attribute's value.
    ///
    /// Mirrors `XMLElement.attribute(forName:)?.stringValue`.
    func attribute(forName name: String) -> String?

    /// Adds or replaces an attribute with the given name and value.
    /// If `value` is `nil`, the attribute is removed.
    ///
    /// Mirrors swift-extensions `XMLElement.addAttribute(withName:value:)`.
    func addAttribute(name: String, value: String?)

    /// Removes the attribute with the given name.
    ///
    /// Mirrors `XMLElement.removeAttribute(forName:)`.
    func removeAttribute(forName name: String)

    /// All attributes as an array of `(name, value)` pairs.
    /// Returns an empty array if the element has no attributes.
    var attributes: [(name: String, value: String)] { get }

    // MARK: - Child Access (Core)

    /// Returns child elements whose tag name matches the given string.
    ///
    /// Mirrors `XMLElement.elements(forName:)`.
    func elements(forName name: String) -> [any PNXMLElement]

    /// Appends a child node to this element.
    ///
    /// Mirrors `XMLElement.addChild(_:)`.
    func addChild(_ child: any PNXMLNode)

    /// Removes the child node at the given index.
    ///
    /// Mirrors `XMLElement.removeChild(at:)`.
    func removeChild(at index: Int)

    /// Inserts a child node at the given index.
    ///
    /// Mirrors `XMLElement.insertChild(_:at:)`.
    func insertChild(_ child: any PNXMLNode, at index: Int)

    // MARK: - Serialization

    /// The XML string representation, formatted with indentation.
    ///
    /// Inherited from `PNXMLNode.xmlString`.
    // var xmlString: String { get }  // already declared in PNXMLNode

    /// A compact XML string representation (no extraneous whitespace).
    var xmlCompactString: String { get }

    // MARK: - Convenience: Attribute Helpers (mirrors swift-extensions)

    /// Gets an attribute value as `String`.
    ///
    /// Equivalent to swift-extensions `XMLElement.stringValue(forAttributeNamed:)`.
    func stringValue(forAttributeNamed attributeName: String) -> String?

    /// Adds multiple attributes from an ordered array of `(name, value)` pairs.
    ///
    /// Equivalent to swift-extensions `XMLElement.addAttributes(_:)`.
    func addAttributes(_ attributes: [(name: String, value: String)])

    /// Gets a `Bool` attribute value.
    /// Valid strings: `"1"`, `"true"` for `true`; `"0"`, `"false"` for `false`.
    ///
    /// Equivalent to swift-extensions `XMLElement.getBool(forAttribute:)`.
    func getBool(forAttribute attributeName: String) -> Bool?

    /// Sets a `Bool` attribute value with default-removal behavior.
    ///
    /// Equivalent to swift-extensions `XMLElement.set(bool:forAttribute:defaultValue:removeIfDefault:useInt:)`.
    func set(
        bool newValue: Bool?,
        forAttribute attributeName: String,
        defaultValue: Bool,
        removeIfDefault: Bool,
        useInt: Bool
    )

    /// Sets a `Bool` attribute value.
    ///
    /// Equivalent to swift-extensions `XMLElement.set(bool:forAttribute:useInt:)`.
    func set(
        bool newValue: Bool?,
        forAttribute attributeName: String,
        useInt: Bool
    )

    /// Gets an `Int` attribute value.
    ///
    /// Equivalent to swift-extensions `XMLElement.getInt(forAttribute:)`.
    func getInt(forAttribute attributeName: String) -> Int?

    /// Sets an `Int` attribute value.
    ///
    /// Equivalent to swift-extensions `XMLElement.set(int:forAttribute:)`.
    func set(int newValue: Int?, forAttribute attributeName: String)

    /// Gets a `URL` attribute value.
    ///
    /// Equivalent to swift-extensions `XMLElement.getURL(forAttribute:)`.
    func getURL(forAttribute attributeName: String) -> URL?

    /// Sets a `URL` attribute value.
    ///
    /// Equivalent to swift-extensions `XMLElement.set(url:forAttribute:)`.
    func set(url newValue: URL?, forAttribute attributeName: String)

    // MARK: - Convenience: Child Helpers (mirrors swift-extensions)

    /// Returns the first immediate child element whose name matches.
    ///
    /// Equivalent to swift-extensions `XMLElement.firstChildElement(named:)`.
    func firstChildElement(named name: String) -> (any PNXMLElement)?

    /// Returns the first immediate child element containing an attribute with the given name.
    ///
    /// Equivalent to swift-extensions `XMLElement.firstChildElement(withAttribute:)`.
    func firstChildElement(
        withAttribute attributeName: String
    ) -> (element: any PNXMLElement, attributeValue: String)?

    /// Appends multiple child nodes.
    ///
    /// Equivalent to swift-extensions `XMLElement.addChildren(_:)`.
    func addChildren(_ children: [any PNXMLNode])

    /// Removes child elements matching a predicate.
    ///
    /// Equivalent to swift-extensions `XMLElement.removeChildren(where:)`.
    func removeChildren(where shouldBeRemoved: (_ child: any PNXMLElement) throws -> Bool) rethrows

    /// Removes all child nodes.
    ///
    /// Equivalent to swift-extensions `XMLElement.removeAllChildren()`.
    func removeAllChildren()

    // MARK: - Convenience: Ancestor Traversal (mirrors swift-extensions)

    /// Returns ancestors of this element, starting from the parent.
    /// If `includingSelf` is `true`, `self` is yielded first.
    ///
    /// Equivalent to swift-extensions `XMLElement.ancestorElements(includingSelf:)`.
    func ancestorElements(includingSelf: Bool) -> [any PNXMLElement]
}

// MARK: - Default Implementations

extension PNXMLElement {

    // MARK: Attribute Convenience Defaults

    /// Default: delegates to `attribute(forName:)`.
    public func stringValue(forAttributeNamed attributeName: String) -> String? {
        attribute(forName: attributeName)
    }

    /// Default: iterates and calls `addAttribute(name:value:)` for each pair.
    public func addAttributes(_ attributes: [(name: String, value: String)]) {
        for attr in attributes {
            addAttribute(name: attr.name, value: attr.value)
        }
    }

    /// Default implementation for `getBool(forAttribute:)`.
    public func getBool(forAttribute attributeName: String) -> Bool? {
        guard let value = stringValue(forAttributeNamed: attributeName) else { return nil }
        switch value {
        case "0", "false", "FALSE": return false
        case "1", "true", "TRUE": return true
        default: return nil
        }
    }

    /// Default implementation for `set(bool:forAttribute:defaultValue:removeIfDefault:useInt:)`.
    public func set(
        bool newValue: Bool?,
        forAttribute attributeName: String,
        defaultValue: Bool,
        removeIfDefault: Bool = false,
        useInt: Bool = false
    ) {
        guard let newValue else {
            addAttribute(name: attributeName, value: nil)
            return
        }
        if removeIfDefault, newValue == defaultValue {
            addAttribute(name: attributeName, value: nil)
            return
        }
        set(bool: newValue, forAttribute: attributeName, useInt: useInt)
    }

    /// Default implementation for `set(bool:forAttribute:useInt:)`.
    public func set(
        bool newValue: Bool?,
        forAttribute attributeName: String,
        useInt: Bool = false
    ) {
        guard let newValue else {
            addAttribute(name: attributeName, value: nil)
            return
        }
        let str: String
        if useInt {
            str = newValue ? "1" : "0"
        } else {
            str = newValue ? "true" : "false"
        }
        addAttribute(name: attributeName, value: str)
    }

    /// Default implementation for `getInt(forAttribute:)`.
    public func getInt(forAttribute attributeName: String) -> Int? {
        guard let value = stringValue(forAttributeNamed: attributeName) else { return nil }
        return Int(value)
    }

    /// Default implementation for `set(int:forAttribute:)`.
    public func set(int newValue: Int?, forAttribute attributeName: String) {
        addAttribute(name: attributeName, value: newValue.map(String.init))
    }

    /// Default implementation for `getURL(forAttribute:)`.
    public func getURL(forAttribute attributeName: String) -> URL? {
        guard let value = stringValue(forAttributeNamed: attributeName) else { return nil }
        return URL(string: value)
    }

    /// Default implementation for `set(url:forAttribute:)`.
    public func set(url newValue: URL?, forAttribute attributeName: String) {
        addAttribute(name: attributeName, value: newValue?.absoluteString)
    }

    // MARK: Child Convenience Defaults

    /// Default: filters `childElements` by name.
    public func firstChildElement(named name: String) -> (any PNXMLElement)? {
        childElements.first { $0.name == name }
    }

    /// Default: finds first child element with the given attribute.
    public func firstChildElement(
        withAttribute attributeName: String
    ) -> (element: any PNXMLElement, attributeValue: String)? {
        for child in childElements {
            if let value = child.attribute(forName: attributeName) {
                return (element: child, attributeValue: value)
            }
        }
        return nil
    }

    /// Default: iterates and calls `addChild(_:)` for each node.
    public func addChildren(_ children: [any PNXMLNode]) {
        for child in children {
            addChild(child)
        }
    }

    /// Default: removes matching children by collecting indices in reverse.
    /// Iterates the full `children` array (which includes text nodes) so that
    /// the indices passed to `removeChild(at:)` are correct.
    public func removeChildren(
        where shouldBeRemoved: (_ child: any PNXMLElement) throws -> Bool
    ) rethrows {
        guard let allChildren = children else { return }
        var indicesToRemove: [Int] = []
        for (idx, child) in allChildren.enumerated() {
            if let element = child as? (any PNXMLElement),
               try shouldBeRemoved(element) {
                indicesToRemove.append(idx)
            }
        }
        // Remove in reverse order so indices remain valid.
        for index in indicesToRemove.reversed() {
            removeChild(at: index)
        }
    }

    /// Default: removes children from last to first.
    public func removeAllChildren() {
        guard let kids = children else { return }
        for index in stride(from: kids.count - 1, through: 0, by: -1) {
            removeChild(at: index)
        }
    }

    // MARK: Ancestor Traversal Default

    /// Default: walks up the parent chain.
    public func ancestorElements(includingSelf: Bool) -> [any PNXMLElement] {
        var result: [any PNXMLElement] = []
        if includingSelf {
            result.append(self)
        }
        var current: (any PNXMLElement)? = self.parent
        while let ancestor = current {
            result.append(ancestor)
            current = ancestor.parent
        }
        return result
    }
}
