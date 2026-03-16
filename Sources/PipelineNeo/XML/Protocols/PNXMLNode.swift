//
//  PNXMLNode.swift
//  Pipeline Neo
//
//  Platform-agnostic XML node protocol.
//  Mirrors the Foundation XMLNode API surface used by PipelineNeo,
//  plus convenience properties from swift-extensions (parentElement, childElements, etc.).
//
//  IMPORTANT: This file must NOT import AppKit or reference Foundation XML types directly.
//

import Foundation

// MARK: - PNXMLNode

/// A platform-agnostic protocol representing an XML node.
///
/// On macOS the conforming type wraps `XMLNode`; on iOS / other platforms
/// the conforming type wraps an AEXML (or other cross-platform) node.
///
/// This protocol is intentionally **not** `Sendable`. Operations protocols
/// that wrap node instances may add `Sendable` conformance where appropriate.
public protocol PNXMLNode: AnyObject {

    // MARK: - Core Properties

    /// The name of the node (element tag name, attribute name, etc.).
    var name: String? { get set }

    /// The text content of the node.
    var stringValue: String? { get set }

    /// The XML string representation of this node and its descendants.
    var xmlString: String { get }

    // MARK: - Tree Traversal

    /// The parent element of this node, or `nil` if this node is the root.
    var parent: (any PNXMLElement)? { get }

    /// The child nodes of this node, or `nil` if the node cannot have children.
    var children: [any PNXMLNode]? { get }

    // MARK: - Convenience (mirrors swift-extensions XMLNode conveniences)

    /// Returns `self` cast to `PNXMLElement`, or `nil` if this node is not an element.
    var asElement: (any PNXMLElement)? { get }

    /// Returns `parent` cast to `PNXMLElement`, or `nil`.
    /// Equivalent to swift-extensions `XMLNode.parentElement`.
    var parentElement: (any PNXMLElement)? { get }

    /// Returns child nodes that are elements (filters out text nodes, comments, etc.).
    /// Equivalent to swift-extensions `XMLNode.childElements`.
    var childElements: [any PNXMLElement] { get }
}

// MARK: - Default Implementations

extension PNXMLNode {
    /// Default: attempts to cast `self` to `any PNXMLElement`.
    public var asElement: (any PNXMLElement)? {
        self as? (any PNXMLElement)
    }

    /// Default: returns `parent` (which is already typed as `(any PNXMLElement)?`).
    public var parentElement: (any PNXMLElement)? {
        parent
    }

    /// Default: filters `children` to only those conforming to `PNXMLElement`.
    public var childElements: [any PNXMLElement] {
        (children ?? []).compactMap { $0 as? (any PNXMLElement) }
    }
}
