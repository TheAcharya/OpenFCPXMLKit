//
//  OFKXMLNode.swift
//  OpenFCPXMLKit
//
//  Platform-agnostic XML node protocol.
//  Mirrors the Foundation XMLNode API surface used by OpenFCPXMLKit,
//  plus convenience properties from swift-extensions (parentElement, childElements, etc.).
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

import Foundation

// MARK: - OFKXMLNode

/// A platform-agnostic protocol representing an XML node.
///
/// On macOS the conforming type wraps `XMLNode`; on iOS / other platforms
/// the conforming type wraps an AEXML (or other cross-platform) node.
///
/// This protocol is intentionally **not** `Sendable`. Operations protocols
/// that wrap node instances may add `Sendable` conformance where appropriate.
public protocol OFKXMLNode: AnyObject {

    // MARK: - Core Properties

    /// The name of the node (element tag name, attribute name, etc.).
    var name: String? { get set }

    /// The text content of the node.
    var stringValue: String? { get set }

    /// The XML string representation of this node and its descendants.
    var xmlString: String { get }

    // MARK: - Tree Traversal

    /// The parent element of this node, or `nil` if this node is the root.
    var parent: (any OFKXMLElement)? { get }

    /// The child nodes of this node, or `nil` if the node cannot have children.
    var children: [any OFKXMLNode]? { get }

    // MARK: - Convenience (mirrors swift-extensions XMLNode conveniences)

    /// Returns `self` cast to `OFKXMLElement`, or `nil` if this node is not an element.
    var asElement: (any OFKXMLElement)? { get }

    /// Returns `parent` cast to `OFKXMLElement`, or `nil`.
    /// Equivalent to swift-extensions `XMLNode.parentElement`.
    var parentElement: (any OFKXMLElement)? { get }

    /// Returns child nodes that are elements (filters out text nodes, comments, etc.).
    /// Equivalent to swift-extensions `XMLNode.childElements`.
    var childElements: [any OFKXMLElement] { get }
}

// MARK: - Default Implementations

extension OFKXMLNode {
    /// Default: attempts to cast `self` to `any OFKXMLElement`.
    public var asElement: (any OFKXMLElement)? {
        self as? (any OFKXMLElement)
    }

    /// Default: returns `parent` (which is already typed as `(any OFKXMLElement)?`).
    public var parentElement: (any OFKXMLElement)? {
        parent
    }

    /// Default: filters `children` to only those conforming to `OFKXMLElement`.
    public var childElements: [any OFKXMLElement] {
        (children ?? []).compactMap { $0 as? (any OFKXMLElement) }
    }
}
