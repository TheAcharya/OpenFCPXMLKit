//
//  FCPXMLElement.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Core protocol for all FCPXML wrapper model objects.
//

import Foundation
import SwiftTimecode

/// Protocol which all FCPXML wrapper model objects conform.
public protocol FCPXMLElement where Self: Equatable, Self: Hashable {
    /// The wrapped XML element object.
    var element: any PNXMLElement { get }

    /// The FCPXML element type of the model instance.
    var elementType: FinalCutPro.FCPXML.ElementType { get }

    /// All FCPXML element types the model object is capable of handling.
    ///
    /// Most model objects only handle a single type.
    /// However some model objects are 'meta types' and can handle more than one, such as
    /// ``FinalCutPro/FCPXML/Marker`` which handles both `marker` and `chapter-marker`.
    static var supportedElementTypes: Set<FinalCutPro.FCPXML.ElementType> { get }

    /// Initialize a new empty element with defaults.
    init()

    /// Wrap a FCPXML element.
    /// Returns `nil` if the element does not match the model element type.
    init?(element: any PNXMLElement)
}

extension FCPXMLElement /* : Equatable */ {
    public static func == <O: FCPXMLElement>(lhs: Self, rhs: O) -> Bool {
        lhs.element === rhs.element
    }

    public static func == (lhs: any PNXMLElement, rhs: Self) -> Bool {
        lhs === rhs.element
    }

    public static func == (lhs: Self, rhs: any PNXMLElement) -> Bool {
        lhs.element === rhs
    }
}

extension FCPXMLElement /* : Hashable */ {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(element))
    }
}

// MARK: - Utilities

extension FCPXMLElement {
    func _isElementTypeSupported(element: (any PNXMLElement)? = nil) -> Bool {
        let e = element ?? self.element
        guard let et = e.fcpElementType,
              Self.supportedElementTypes.contains(et)
        else { return false }
        return true
    }
}
