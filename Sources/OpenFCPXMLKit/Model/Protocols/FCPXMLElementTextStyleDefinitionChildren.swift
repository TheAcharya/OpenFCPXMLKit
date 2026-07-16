//
// FCPXMLElementTextStyleDefinitionChildren.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Protocol for elements with text-style-def children.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementTextStyleDefinitionChildren: FCPXMLElement {
    /// Child `text-style-def` elements as typed models.
    var typedTextStyleDefinitions: [FinalCutPro.FCPXML.TextStyleDefinition] { get nonmutating set }

    /// Child `text-style-def` elements (raw XML).
    var fcpTextStyleDefinitions: LazyFilterSequence<[any OFKXMLElement]> { get nonmutating set }
}

extension FCPXMLElementTextStyleDefinitionChildren {
    public var fcpTextStyleDefinitions: LazyFilterSequence<[any OFKXMLElement]> {
        get { element.fcpTextStyleDefinitions }
        nonmutating set { element.fcpTextStyleDefinitions = newValue }
    }

    public var typedTextStyleDefinitions: [FinalCutPro.FCPXML.TextStyleDefinition] {
        get { element.fcpTypedTextStyleDefinitions }
        nonmutating set { element.fcpTypedTextStyleDefinitions = newValue }
    }
}

extension OFKXMLElement {
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

    /// FCPXML: Returns child `text-style-def` elements as typed ``TextStyleDefinition`` models.
    public var fcpTypedTextStyleDefinitions: [FinalCutPro.FCPXML.TextStyleDefinition] {
        get {
            Array(fcpTextStyleDefinitions.compactMap { styleDefElement -> FinalCutPro.FCPXML.TextStyleDefinition? in
                guard let id = styleDefElement.fcpID else { return nil }
                let name = styleDefElement.fcpName
                let textStyles = Array(styleDefElement.fcpTextStyles.compactMap { textStyleElement in
                    FinalCutPro.FCPXML.TextStyle.parse(from: textStyleElement)
                })
                return FinalCutPro.FCPXML.TextStyleDefinition(id: id, name: name, textStyles: textStyles)
            })
        }
        set {
            removeChildren { $0.name == "text-style-def" }
            for styleDef in newValue {
                let styleDefElement = OFKXMLDefaultFactory().makeElement(name: "text-style-def")
                styleDefElement.fcpID = styleDef.id
                if let name = styleDef.name {
                    styleDefElement.fcpName = name
                }
                for textStyle in styleDef.textStyles {
                    styleDefElement.addChild(FinalCutPro.FCPXML.TextStyle.makeElement(from: textStyle))
                }
                addChild(styleDefElement)
            }
        }
    }
}
