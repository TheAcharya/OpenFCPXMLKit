//
//  AEXMLBackendElement.swift
//  Pipeline Neo
//
//  Cross-platform XML element backend powered by AEXML.
//  Wraps `AEXMLElement` and conforms to `PNXMLElement`.
//
//  AEXML API differences handled here:
//  - Attributes are a `[String: String]` dictionary, not `XMLNode` objects.
//  - Children accessed via `.children` array (non-optional).
//  - `elements(forName:)` → filter `.children` where `.name == name`.
//  - `attribute(forName:)` → `attributes[name]`.
//  - `addAttribute(name:value:)` → `attributes[name] = value` (nil removes).
//  - `removeAttribute(forName:)` → `attributes.removeValue(forKey:)`.
//  - `addChild(_:)` → `addChild(element)` after unwrapping the wrapper.
//  - `xmlString` → `.xml` property.
//  - `xmlCompactString` → `.xmlCompact` property.
//  - `stringValue` → `.value` property (but AEXML returns `""` via `.string`
//    on error elements — we return `nil` for error elements).
//  - AEXML uses an error element sentinel: when an element lookup fails,
//    it returns a special element with a non-nil `.error` property rather
//    than returning nil. We must check `.error` before treating results
//    as valid elements.
//

import Foundation
import AEXML

// MARK: - AEXMLBackendElement

/// A cross-platform XML element that wraps an `AEXMLElement` from the AEXML library
/// and conforms to `PNXMLElement`.
///
/// This is the AEXML backend's element type, used on iOS and other platforms
/// where Foundation's `XMLDocument`/`XMLElement` are not available.
public final class AEXMLBackendElement: PNXMLElement {

    // MARK: - Underlying Storage

    /// The wrapped AEXML element.
    /// Exposed for interop with code that needs direct AEXML access.
    public let underlyingElement: AEXMLElement

    // MARK: - Initializers

    /// Wraps an existing `AEXMLElement`.
    ///
    /// - Parameter element: The AEXML element to wrap.
    public init(wrapping element: AEXMLElement) {
        self.underlyingElement = element
    }

    /// Creates a new element with the given tag name.
    ///
    /// - Parameter name: The tag name for the element.
    public convenience init(name: String) {
        self.init(wrapping: AEXMLElement(name: name))
    }

    /// Creates a new element with the given tag name and string value.
    ///
    /// - Parameters:
    ///   - name: The tag name for the element.
    ///   - stringValue: The text content for the element.
    public convenience init(name: String, stringValue: String?) {
        self.init(wrapping: AEXMLElement(name: name, value: stringValue))
    }

    /// Creates a new element with the given tag name, value, and attributes.
    ///
    /// - Parameters:
    ///   - name: The tag name for the element.
    ///   - stringValue: The text content for the element.
    ///   - attributes: A dictionary of attribute name-value pairs.
    public convenience init(name: String, stringValue: String?, attributes: [String: String]) {
        self.init(wrapping: AEXMLElement(name: name, value: stringValue, attributes: attributes))
    }

    /// Creates an element by parsing an XML string fragment.
    ///
    /// Parses the string as an `AEXMLDocument` and extracts the root element.
    ///
    /// - Parameter xmlString: An XML string representing a single element.
    /// - Throws: `PNXMLError.parsingFailure` if parsing fails.
    public convenience init(xmlString: String) throws {
        do {
            let doc = try AEXMLDocument(xml: xmlString)
            // Verify the root is not an error sentinel
            guard doc.root.error == nil else {
                throw PNXMLError.parsingFailure(
                    message: "Failed to parse XML string: root element is an error sentinel."
                )
            }
            self.init(wrapping: doc.root)
        } catch let error as PNXMLError {
            throw error
        } catch {
            throw PNXMLError.parsingFailure(
                message: "Failed to parse XML string: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - PNXMLNode: Core Properties

    /// The tag name of the element.
    public var name: String? {
        get { underlyingElement.name }
        set { underlyingElement.name = newValue ?? "" }
    }

    /// The text content of the element.
    ///
    /// Returns `nil` for AEXML error sentinel elements. Otherwise returns
    /// the element's `value` property, which is `nil` when there is no text content.
    public var stringValue: String? {
        get {
            // AEXML error sentinel check: if this element is an error element,
            // return nil rather than AEXML's default error string.
            guard underlyingElement.error == nil else { return nil }
            return underlyingElement.value
        }
        set {
            underlyingElement.value = newValue
        }
    }

    /// The XML string representation of this element and its descendants.
    ///
    /// Maps to AEXML's `.xml` property which includes indentation.
    public var xmlString: String {
        underlyingElement.xml
    }

    // MARK: - PNXMLNode: Tree Traversal

    /// The parent element, or `nil` if this is the root.
    public var parent: (any PNXMLElement)? {
        guard let aeParent = underlyingElement.parent else { return nil }
        // Don't wrap the parent if it's an AEXMLDocument (which is an AEXMLElement subclass)
        // because the document root's parent is the document itself.
        if aeParent is AEXMLDocument { return nil }
        return AEXMLBackendElement(wrapping: aeParent)
    }

    /// The child nodes of this element.
    ///
    /// AEXML's `.children` is non-optional, so we always return an array.
    /// Error sentinel elements are filtered out.
    public var children: [any PNXMLNode]? {
        underlyingElement.children
            .filter { $0.error == nil }
            .map { AEXMLBackendElement(wrapping: $0) }
    }

    // MARK: - PNXMLElement: Attribute Access

    /// Returns the value of the attribute with the given name, or `nil` if not present.
    public func attribute(forName name: String) -> String? {
        underlyingElement.attributes[name]
    }

    /// Adds or replaces an attribute. If `value` is `nil`, the attribute is removed.
    public func addAttribute(name: String, value: String?) {
        if let value {
            underlyingElement.attributes[name] = value
        } else {
            underlyingElement.attributes.removeValue(forKey: name)
        }
    }

    /// Removes the attribute with the given name.
    public func removeAttribute(forName name: String) {
        underlyingElement.attributes.removeValue(forKey: name)
    }

    /// All attributes as an array of `(name, value)` pairs.
    public var attributes: [(name: String, value: String)] {
        underlyingElement.attributes.map { (name: $0.key, value: $0.value) }
    }

    // MARK: - PNXMLElement: Child Access

    /// Returns child elements whose tag name matches the given string.
    ///
    /// Filters the `children` array by name, excluding error sentinel elements.
    public func elements(forName name: String) -> [any PNXMLElement] {
        underlyingElement.children
            .filter { $0.name == name && $0.error == nil }
            .map { AEXMLBackendElement(wrapping: $0) }
    }

    /// Appends a child node to this element.
    ///
    /// If the child is an `AEXMLBackendElement`, unwraps and delegates to AEXML.
    /// Otherwise, creates a new AEXML element from the child's properties.
    public func addChild(_ child: any PNXMLNode) {
        if let aeChild = child as? AEXMLBackendElement {
            _ = underlyingElement.addChild(aeChild.underlyingElement)
        } else {
            // Fallback: create a new AEXML element from the child's properties.
            let newElement = AEXMLElement(
                name: child.name ?? "",
                value: child.stringValue
            )
            _ = underlyingElement.addChild(newElement)
        }
    }

    /// Removes the child node at the given index.
    ///
    /// AEXML does not have a `removeChild(at:)` method, so we use
    /// `removeFromParent()` on the child at the given index.
    public func removeChild(at index: Int) {
        let validChildren = underlyingElement.children.filter { $0.error == nil }
        guard index >= 0, index < validChildren.count else { return }
        validChildren[index].removeFromParent()
    }

    /// Inserts a child node at the given index.
    ///
    /// AEXML does not have a native insert-at-index method. We implement this
    /// by removing all children after the insertion point, adding the new child,
    /// then re-adding the removed children.
    public func insertChild(_ child: any PNXMLNode, at index: Int) {
        let validChildren = underlyingElement.children.filter { $0.error == nil }
        let clampedIndex = max(0, min(index, validChildren.count))

        // Collect children that come after the insertion point.
        let tail = Array(validChildren[clampedIndex...])

        // Remove tail children from parent.
        for element in tail {
            element.removeFromParent()
        }

        // Add the new child.
        addChild(child)

        // Re-add the tail children.
        for element in tail {
            _ = underlyingElement.addChild(element)
        }
    }

    // MARK: - PNXMLElement: Serialization

    /// A compact XML string representation (no extraneous whitespace).
    ///
    /// Maps to AEXML's `.xmlCompact` property.
    public var xmlCompactString: String {
        underlyingElement.xmlCompact
    }
}
