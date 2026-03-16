//
//  FCPXMLElementTextStyleDefinitionChildren.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
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
    var fcpTextStyleDefinitions: LazyFilterSequence<[any PNXMLElement]> { get nonmutating set }
}

extension FCPXMLElementTextStyleDefinitionChildren {
    public var fcpTextStyleDefinitions: LazyFilterSequence<[any PNXMLElement]> {
        get { element.fcpTextStyleDefinitions }
        nonmutating set { element.fcpTextStyleDefinitions = newValue }
    }
}

extension PNXMLElement {
    // Note: returns bare XML; model objects not yet implemented for this element.
    
    /// FCPXML: Returns child `text-style-def` elements.
    public var fcpTextStyleDefinitions: LazyFilterSequence<[any PNXMLElement]> {
        get {
            childElements
                .filter(whereFCPElementType: .textStyleDef)
        }
        set {
            _updateChildElements(ofType: .textStyleDef, with: newValue)
        }
    }
}
