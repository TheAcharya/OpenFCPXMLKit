//
//  FCPXMLTitleDisplayTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for title display text and font resolution.
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLTitleDisplayTests: XCTestCase {
    func testConcatenatedDisplayTextUsesPipeSeparator() throws {
        let title = try makeTitle(from: """
        <title ref="r1" name="Title">
            <text>
                <text-style ref="ts1">Hello</text-style>
                <text-style ref="ts2">World</text-style>
            </text>
            <text-style-def id="ts1">
                <text-style font="Helvetica" fontSize="28" fontFace="Regular"/>
            </text-style-def>
            <text-style-def id="ts2">
                <text-style font="Helvetica" fontSize="28" fontFace="Regular"/>
            </text-style-def>
        </title>
        """)
        
        XCTAssertEqual(title.concatenatedDisplayText(), "Hello  |  World")
    }
    
    func testConcatenatedDisplayTextSingleSegmentOmitsSeparator() throws {
        let title = try makeTitle(from: """
        <title ref="r1" name="Title">
            <text>
                <text-style ref="ts1">Solo</text-style>
            </text>
            <text-style-def id="ts1">
                <text-style font="Helvetica" fontSize="28" fontFace="Regular"/>
            </text-style-def>
        </title>
        """)
        
        XCTAssertEqual(title.concatenatedDisplayText(), "Solo")
    }
    
    func testTypedTextSegmentsPreservesStyleReferences() throws {
        let title = try makeTitle(from: """
        <title ref="r1" name="Title">
            <text>
                <text-style ref="ts1">A</text-style>
                <text-style ref="ts2">B</text-style>
            </text>
            <text-style-def id="ts1">
                <text-style font="Helvetica" fontSize="28" fontFace="Regular"/>
            </text-style-def>
            <text-style-def id="ts2">
                <text-style font="Gill Sans" fontSize="56" fontFace="Regular"/>
            </text-style-def>
        </title>
        """)
        
        let segments = title.typedTextSegments
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].styleReference, "ts1")
        XCTAssertEqual(segments[1].styleReference, "ts2")
    }
    
    func testDisplayFontSpecificationsJoinsMultipleFonts() throws {
        let title = try makeTitle(from: """
        <title ref="r1" name="Title">
            <text>
                <text-style ref="ts1">A</text-style>
                <text-style ref="ts2">B</text-style>
            </text>
            <text-style-def id="ts1">
                <text-style font="Helvetica" fontSize="28" fontFace="Regular"/>
            </text-style-def>
            <text-style-def id="ts2">
                <text-style font="Gill Sans" fontSize="56" fontFace="Regular"/>
            </text-style-def>
        </title>
        """)
        
        let fonts = title.displayFontSpecifications()
        XCTAssertTrue(fonts.contains("Helvetica 28.0"))
        XCTAssertTrue(fonts.contains("Gill Sans 56.0"))
    }
    
    func testDisplayFontSpecificationFromStyleElement() {
        let styleElement = OFKXMLDefaultFactory().makeElement(name: "text-style")
        styleElement.addAttribute(name: "font", value: "Helvetica")
        styleElement.addAttribute(name: "fontSize", value: "28")
        styleElement.addAttribute(name: "fontFace", value: "Regular")
        
        let spec = FinalCutPro.FCPXML.TextStyle.displayFontSpecification(from: styleElement)
        XCTAssertEqual(spec, "Helvetica 28.0, Regular")
    }
    
    func testIsAppleSuppliedEffectTrueForBasicTitle() throws {
        let fcpxml = try loadFCPXMLSample(named: "DisabledClips")
        let titleElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "title")
        )
        let title = try XCTUnwrap(titleElement.fcpAsTitle)
        
        XCTAssertTrue(title.isAppleSuppliedEffect(resources: fcpxml.root.resources))
    }
    
    func testIsAppleSuppliedEffectFalseWhenRefMissing() throws {
        let title = try makeTitle(from: """
        <title name="Custom">
            <text>
                <text-style>Text</text-style>
            </text>
        </title>
        """)
        
        XCTAssertFalse(title.isAppleSuppliedEffect(resources: nil))
    }
    
    private func makeTitle(from xmlFragment: String) throws -> FinalCutPro.FCPXML.Title {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                <effect id="r1" name="Basic Title" uid=".../Titles.localized/Basic Title.moti"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                \(xmlFragment)
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let titleElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "title")
        )
        return try XCTUnwrap(titleElement.fcpAsTitle)
    }
}
