//
//  FCPXMLElementTextStyleDefinitionChildren.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with text-style-def children.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

public protocol FCPXMLElementTextStyleDefinitionChildren: FCPXMLElement {
    /// Child `text-style-def` elements.
    var fcpTextStyleDefinitions: LazyFilterSequence<[any OFKXMLElement]> { get nonmutating set }
}

extension FCPXMLElementTextStyleDefinitionChildren {
    public var fcpTextStyleDefinitions: LazyFilterSequence<[any OFKXMLElement]> {
        get { element.fcpTextStyleDefinitions }
        nonmutating set { element.fcpTextStyleDefinitions = newValue }
    }
}

extension OFKXMLElement {
    // Note: returns bare XML; model objects not yet implemented for this element.
    
    /// FCPXML: Returns child `text-style-def` elements.
    public var fcpTextStyleDefinitions: LazyFilterSequence<[any OFKXMLElement]> {
        get {
            childElements
                .filter(whereFCPElementType: .textStyleDef)
        }
        set {
            _updateChildElements(ofType: .textStyleDef, with: newValue)
        }
    }
}
