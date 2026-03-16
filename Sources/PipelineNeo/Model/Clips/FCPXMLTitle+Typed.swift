//
//  FCPXMLTitle+Typed.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Typed text style models for Title.
//

import Foundation

extension FinalCutPro.FCPXML.Title {
    /// Returns typed text style definitions from the title.
    public var typedTextStyleDefinitions: [FinalCutPro.FCPXML.TextStyleDefinition] {
        get {
            Array(element.fcpTextStyleDefinitions.compactMap { styleDefElement -> FinalCutPro.FCPXML.TextStyleDefinition? in
                guard let id = styleDefElement.fcpID else { return nil }
                let name = styleDefElement.fcpName
                
                // Parse text-style children
                let textStyles = Array(styleDefElement.fcpTextStyles.compactMap { textStyleElement -> FinalCutPro.FCPXML.TextStyle? in
                    guard let textStyle = parseTextStyle(from: textStyleElement) else { return nil }
                    return textStyle
                })
                
                return FinalCutPro.FCPXML.TextStyleDefinition(id: id, name: name, textStyles: textStyles)
            })
        }
        nonmutating set {
            // Remove existing text-style-def elements
            element.removeChildren { $0.name == "text-style-def" }
            
            // Add new text-style-def elements
            for styleDef in newValue {
                let styleDefElement = PNXMLDefaultFactory().makeElement(name: "text-style-def")
                styleDefElement.fcpID = styleDef.id
                if let name = styleDef.name {
                    styleDefElement.fcpName = name
                }
                
                // Add text-style children
                for textStyle in styleDef.textStyles {
                    let textStyleElement = createTextStyleElement(from: textStyle)
                    styleDefElement.addChild(textStyleElement)
                }
                
                element.addChild(styleDefElement)
            }
        }
    }
    
    /// Helper to parse TextStyle from XML element.
    private func parseTextStyle(from element: any PNXMLElement) -> FinalCutPro.FCPXML.TextStyle? {
        let ref = element.fcpRef
        let value = element.stringValue
        
        let font = element.stringValue(forAttributeNamed: "font")
        let fontSizeString = element.stringValue(forAttributeNamed: "fontSize")
        let fontSize = fontSizeString.flatMap { Int($0) }
        let fontFace = element.stringValue(forAttributeNamed: "fontFace")
        let fontColor = element.stringValue(forAttributeNamed: "fontColor")
        let backgroundColor = element.stringValue(forAttributeNamed: "backgroundColor")
        let boldString = element.stringValue(forAttributeNamed: "bold")
        let isBold = boldString == "1"
        let italicString = element.stringValue(forAttributeNamed: "italic")
        let isItalic = italicString == "1"
        let strokeColor = element.stringValue(forAttributeNamed: "strokeColor")
        let strokeWidthString = element.stringValue(forAttributeNamed: "strokeWidth")
        let strokeWidth = strokeWidthString.flatMap { Double($0) }
        let baselineString = element.stringValue(forAttributeNamed: "baseline")
        let baseline = baselineString.flatMap { Double($0) }
        let shadowColor = element.stringValue(forAttributeNamed: "shadowColor")
        let shadowOffset = element.stringValue(forAttributeNamed: "shadowOffset")
        let shadowBlurRadiusString = element.stringValue(forAttributeNamed: "shadowBlurRadius")
        let shadowBlurRadius = shadowBlurRadiusString.flatMap { Double($0) }
        let kerningString = element.stringValue(forAttributeNamed: "kerning")
        let kerning = kerningString.flatMap { Double($0) }
        let alignmentString = element.stringValue(forAttributeNamed: "alignment")
        let lineSpacingString = element.stringValue(forAttributeNamed: "lineSpacing")
        let lineSpacing = lineSpacingString.flatMap { Double($0) }
        let tabStopsString = element.stringValue(forAttributeNamed: "tabStops")
        let tabStops = tabStopsString.flatMap { Double($0) }
        let baselineOffsetString = element.stringValue(forAttributeNamed: "baselineOffset")
        let baselineOffset = baselineOffsetString.flatMap { Double($0) }
        let underlineString = element.stringValue(forAttributeNamed: "underline")
        let isUnderlined = underlineString == "1"
        
        // Parse param elements
        let parameters = Array(element.childElements
            .filter { $0.name == "param" }
            .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
            })
        
        var textStyle = FinalCutPro.FCPXML.TextStyle(referenceID: ref, value: value, parameters: parameters)
        textStyle.font = font
        textStyle.fontSize = fontSize
        textStyle.fontFace = fontFace
        textStyle.fontColor = fontColor
        textStyle.backgroundColor = backgroundColor
        if isBold { textStyle.isBold = true }
        if isItalic { textStyle.isItalic = true }
        textStyle.strokeColor = strokeColor
        textStyle.strokeWidth = strokeWidth
        textStyle.baseline = baseline
        textStyle.shadowColor = shadowColor
        textStyle.shadowOffset = shadowOffset
        textStyle.shadowBlurRadius = shadowBlurRadius
        textStyle.kerning = kerning
        textStyle.alignment = alignmentString.flatMap { .init(rawValue: $0) }
        textStyle.lineSpacing = lineSpacing
        textStyle.tabStops = tabStops
        textStyle.baselineOffset = baselineOffset
        if isUnderlined { textStyle.isUnderlined = true }

        return textStyle
    }
    
    /// Helper to create XML element from TextStyle.
    private func createTextStyleElement(from textStyle: FinalCutPro.FCPXML.TextStyle) -> any PNXMLElement {
        let element = PNXMLDefaultFactory().makeElement(name: "text-style")
        
        if let ref = textStyle.referenceID {
            element.fcpRef = ref
        }
        if let value = textStyle.value {
            element.stringValue = value
        }
        
        if let font = textStyle.font {
            element.addAttribute(name: "font", value: font)
        }
        if let fontSize = textStyle.fontSize {
            element.addAttribute(name: "fontSize", value: String(fontSize))
        }
        if let fontFace = textStyle.fontFace {
            element.addAttribute(name: "fontFace", value: fontFace)
        }
        if let fontColor = textStyle.fontColor {
            element.addAttribute(name: "fontColor", value: fontColor)
        }
        if let backgroundColor = textStyle.backgroundColor {
            element.addAttribute(name: "backgroundColor", value: backgroundColor)
        }
        if let isBold = textStyle.isBold {
            element.addAttribute(name: "bold", value: isBold ? "1" : "0")
        }
        if let isItalic = textStyle.isItalic {
            element.addAttribute(name: "italic", value: isItalic ? "1" : "0")
        }
        if let strokeColor = textStyle.strokeColor {
            element.addAttribute(name: "strokeColor", value: strokeColor)
        }
        if let strokeWidth = textStyle.strokeWidth {
            element.addAttribute(name: "strokeWidth", value: String(strokeWidth))
        }
        if let baseline = textStyle.baseline {
            element.addAttribute(name: "baseline", value: String(baseline))
        }
        if let shadowColor = textStyle.shadowColor {
            element.addAttribute(name: "shadowColor", value: shadowColor)
        }
        if let shadowOffset = textStyle.shadowOffset {
            element.addAttribute(name: "shadowOffset", value: shadowOffset)
        }
        if let shadowBlurRadius = textStyle.shadowBlurRadius {
            element.addAttribute(name: "shadowBlurRadius", value: String(shadowBlurRadius))
        }
        if let kerning = textStyle.kerning {
            element.addAttribute(name: "kerning", value: String(kerning))
        }
        if let alignment = textStyle.alignment {
            element.addAttribute(name: "alignment", value: alignment.rawValue)
        }
        if let lineSpacing = textStyle.lineSpacing {
            element.addAttribute(name: "lineSpacing", value: String(lineSpacing))
        }
        if let tabStops = textStyle.tabStops {
            element.addAttribute(name: "tabStops", value: String(tabStops))
        }
        if let baselineOffset = textStyle.baselineOffset {
            element.addAttribute(name: "baselineOffset", value: String(baselineOffset))
        }
        if let isUnderlined = textStyle.isUnderlined {
            element.addAttribute(name: "underline", value: isUnderlined ? "1" : "0")
        }
        
        // Add param elements
        for param in textStyle.parameters {
            let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
            paramElement.addAttribute(name: "name", value: param.name)
            if let key = param.key {
                paramElement.addAttribute(name: "key", value: key)
            }
            if let value = param.value {
                paramElement.addAttribute(name: "value", value: value)
            }
            if let auxValue = param.auxValue {
                paramElement.addAttribute(name: "auxValue", value: auxValue)
            }
            if !param.isEnabled {
                paramElement.addAttribute(name: "enabled", value: "0")
            }
            element.addChild(paramElement)
        }
        
        return element
    }
}
