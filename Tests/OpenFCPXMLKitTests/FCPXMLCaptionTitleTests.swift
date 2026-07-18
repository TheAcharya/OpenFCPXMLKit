//
//  FCPXMLCaptionTitleTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for Caption/Title text styles and text-style-def integration.
//

import Foundation
import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("Caption and title text styles")
struct FCPXMLCaptionTitleTests {

    // MARK: - TextStyle Tests

    @Test("TextStyle initialization")
    func textStyleInitialization() {
        let textStyle = FinalCutPro.FCPXML.TextStyle(
            referenceID: "ts1",
            value: "Hello World"
        )

        #expect(textStyle.referenceID == "ts1")
        #expect(textStyle.value == "Hello World")
    }

    @Test("TextStyle with formatting")
    func textStyleWithFormatting() {
        var textStyle = FinalCutPro.FCPXML.TextStyle()
        textStyle.font = "Helvetica"
        textStyle.fontSize = 24
        textStyle.fontColor = "1.0 1.0 1.0 1.0"
        textStyle.isBold = true
        textStyle.alignment = .center

        #expect(textStyle.font == "Helvetica")
        #expect(textStyle.fontSize == 24)
        #expect(textStyle.fontColor == "1.0 1.0 1.0 1.0")
        #expect(textStyle.isBold == true)
        #expect(textStyle.alignment == .center)
    }

    @Test("TextStyle Codable round-trip")
    func textStyleCodable() throws {
        var textStyle = FinalCutPro.FCPXML.TextStyle()
        textStyle.font = "Helvetica"
        textStyle.fontSize = 24
        textStyle.isBold = true

        let encoder = JSONEncoder()
        let data = try encoder.encode(textStyle)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.TextStyle.self, from: data)

        #expect(decoded.font == textStyle.font)
        #expect(decoded.fontSize == textStyle.fontSize)
        #expect(decoded.isBold == textStyle.isBold)
    }

    // MARK: - TextStyleDefinition Tests

    @Test("TextStyleDefinition initialization")
    func textStyleDefinitionInitialization() {
        var textStyle = FinalCutPro.FCPXML.TextStyle()
        textStyle.font = "Helvetica"
        textStyle.fontSize = 24
        let styleDef = FinalCutPro.FCPXML.TextStyleDefinition(
            id: "ts1",
            name: "Default Style",
            textStyles: [textStyle]
        )

        #expect(styleDef.id == "ts1")
        #expect(styleDef.name == "Default Style")
        #expect(styleDef.textStyles.count == 1)
    }

    @Test("TextStyleDefinition Codable round-trip")
    func textStyleDefinitionCodable() throws {
        var textStyle = FinalCutPro.FCPXML.TextStyle()
        textStyle.font = "Helvetica"
        let styleDef = FinalCutPro.FCPXML.TextStyleDefinition(
            id: "ts1",
            name: "Style",
            textStyles: [textStyle]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(styleDef)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.TextStyleDefinition.self, from: data)

        #expect(decoded.id == styleDef.id)
        #expect(decoded.name == styleDef.name)
        #expect(decoded.textStyles.count == styleDef.textStyles.count)
    }

    // MARK: - Caption Integration Tests

    @Test("Caption with text-style-def from XML")
    func captionWithTextStyleDefinition() throws {
        let xmlString = """
        <caption duration="5s">
            <text-style-def id="ts1" name="Caption Style">
                <text-style font="Helvetica" fontSize="24" fontColor="1.0 1.0 1.0 1.0" bold="1"/>
            </text-style-def>
        </caption>
        """

        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let captionElement = try #require(xmlDoc.rootElement())
        let caption = try #require(FinalCutPro.FCPXML.Caption(element: captionElement))

        let styleDefs = caption.typedTextStyleDefinitions
        #expect(styleDefs.count == 1)
        #expect(styleDefs[0].id == "ts1")
        #expect(styleDefs[0].name == "Caption Style")
        #expect(styleDefs[0].textStyles.count == 1)
        #expect(styleDefs[0].textStyles[0].font == "Helvetica")
    }

    @Test("Caption text-style-def round-trip")
    func captionTextStyleDefinitionRoundTrip() {
        let caption = FinalCutPro.FCPXML.Caption(duration: Fraction(5, 1))

        var textStyle = FinalCutPro.FCPXML.TextStyle()
        textStyle.font = "Helvetica"
        textStyle.fontSize = 24
        textStyle.fontColor = "1.0 1.0 1.0 1.0"
        textStyle.isBold = true

        let styleDef = FinalCutPro.FCPXML.TextStyleDefinition(
            id: "ts1",
            name: "Caption Style",
            textStyles: [textStyle]
        )

        caption.typedTextStyleDefinitions = [styleDef]

        let retrieved = caption.typedTextStyleDefinitions
        #expect(retrieved.count == 1)
        #expect(retrieved[0].id == "ts1")
        #expect(retrieved[0].textStyles[0].font == "Helvetica")

        // Verify XML structure
        let styleDefElements = caption.element.childElements.filter { $0.name == "text-style-def" }
        #expect(styleDefElements.count == 1)
    }

    // MARK: - Title Integration Tests

    @Test("Title with text-style-def from XML")
    func titleWithTextStyleDefinition() throws {
        let xmlString = """
        <title ref="r1" duration="5s">
            <text-style-def id="ts1" name="Title Style">
                <text-style font="Helvetica" fontSize="48" fontColor="1.0 1.0 0.0 1.0" alignment="center"/>
            </text-style-def>
        </title>
        """

        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let titleElement = try #require(xmlDoc.rootElement())
        let title = try #require(FinalCutPro.FCPXML.Title(element: titleElement))

        let styleDefs = title.typedTextStyleDefinitions
        #expect(styleDefs.count == 1)
        #expect(styleDefs[0].id == "ts1")
        #expect(styleDefs[0].name == "Title Style")
        #expect(styleDefs[0].textStyles.count == 1)
        #expect(styleDefs[0].textStyles[0].font == "Helvetica")
        #expect(styleDefs[0].textStyles[0].fontSize == 48)
    }

    @Test("Title text-style-def round-trip")
    func titleTextStyleDefinitionRoundTrip() {
        let title = FinalCutPro.FCPXML.Title(ref: "r1", duration: Fraction(5, 1))

        var textStyle = FinalCutPro.FCPXML.TextStyle()
        textStyle.font = "Helvetica"
        textStyle.fontSize = 48
        textStyle.fontColor = "1.0 1.0 0.0 1.0"
        textStyle.alignment = .center

        let styleDef = FinalCutPro.FCPXML.TextStyleDefinition(
            id: "ts1",
            name: "Title Style",
            textStyles: [textStyle]
        )

        title.typedTextStyleDefinitions = [styleDef]

        let retrieved = title.typedTextStyleDefinitions
        #expect(retrieved.count == 1)
        #expect(retrieved[0].id == "ts1")
        #expect(retrieved[0].textStyles[0].font == "Helvetica")
        #expect(retrieved[0].textStyles[0].alignment == .center)

        // Verify XML structure
        let styleDefElements = title.element.childElements.filter { $0.name == "text-style-def" }
        #expect(styleDefElements.count == 1)
    }

    // MARK: - Text textStyles Children

    @Test("Text textStyles init and setter replace text-style children")
    func textTextStylesInitAndSetterReplaceTextStyleChildren() {
        let first = FinalCutPro.FCPXML.TextStyle.makeElement(
            from: FinalCutPro.FCPXML.TextStyle(referenceID: "ts1", value: "One")
        )
        let second = FinalCutPro.FCPXML.TextStyle.makeElement(
            from: FinalCutPro.FCPXML.TextStyle(referenceID: "ts2", value: "Two")
        )
        let third = FinalCutPro.FCPXML.TextStyle.makeElement(
            from: FinalCutPro.FCPXML.TextStyle(referenceID: "ts3", value: "Three")
        )

        let text = FinalCutPro.FCPXML.Text(
            alignment: .center,
            textStyles: [first, second]
        )

        #expect(text.alignment == .center)
        #expect(text.textStyles.count == 2)
        #expect(
            text.element.childElements.filter { $0.fcpElementType == .textStyle }.count == 2
        )
        #expect(text.textStyles.first?.fcpRef == "ts1")

        text.textStyles = [third]

        #expect(text.textStyles.count == 1)
        #expect(text.textStyles.first?.fcpRef == "ts3")
        #expect(
            text.element.childElements.filter { $0.fcpElementType == .textStyle }.count == 1,
            "Setter must replace existing text-style children, not append"
        )
    }

    // MARK: - File Tests

    @Test("CaptionSample contains captions with text and style defs")
    func captionSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "CaptionSample")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let projects = fcpxml.allProjects()
        #expect(!projects.isEmpty, "Expected at least one project")

        let project = try #require(projects.first)
        let sequence = try #require(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)

        // Find captions in the spine
        var foundCaptions = false
        for element in storyElements {
            if element.name == "asset-clip" {
                let captions = element.childElements.filter { $0.name == "caption" }
                if !captions.isEmpty {
                    foundCaptions = true
                    // Verify caption has text and text-style-def
                    for caption in captions {
                        let textElements = caption.childElements.filter { $0.name == "text" }
                        let styleDefElements = caption.childElements.filter { $0.name == "text-style-def" }
                        let hasTextAndStyle = !(textElements.isEmpty || styleDefElements.isEmpty)
                        #expect(hasTextAndStyle, "Caption should have text and style definition")
                    }
                    break
                }
            }
        }
        #expect(foundCaptions, "Should find captions in CaptionSample")
    }
}
