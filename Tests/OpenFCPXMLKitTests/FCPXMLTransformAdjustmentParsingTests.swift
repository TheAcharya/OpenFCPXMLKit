//
//  FCPXMLTransformAdjustmentParsingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for parsing adjust-transform XML into TransformAdjustment.
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLTransformAdjustmentParsingTests: XCTestCase {
    private typealias TransformAdjustment = FinalCutPro.FCPXML.TransformAdjustment
    
    func testTransformAdjustmentFromAdjustElementParsesAllAttributes() {
        let element = makeAdjustTransformElement(
            position: "100 200",
            scale: "1.5 1.5",
            rotation: "45",
            anchor: "50 50",
            enabled: "0"
        )
        
        let adjustment = TransformAdjustment(from: element)
        
        XCTAssertEqual(adjustment.position.x, 100)
        XCTAssertEqual(adjustment.position.y, 200)
        XCTAssertEqual(adjustment.scale.x, 1.5)
        XCTAssertEqual(adjustment.scale.y, 1.5)
        XCTAssertEqual(adjustment.rotation, 45)
        XCTAssertEqual(adjustment.anchor.x, 50)
        XCTAssertEqual(adjustment.anchor.y, 50)
        XCTAssertFalse(adjustment.isEnabled)
    }
    
    func testTransformAdjustmentFromAdjustElementUsesDefaultsForMissingAttributes() {
        let element = makeAdjustTransformElement()
        
        let adjustment = TransformAdjustment(from: element)
        
        XCTAssertEqual(adjustment.position, .zero)
        XCTAssertEqual(adjustment.scale, FinalCutPro.FCPXML.Point(x: 1, y: 1))
        XCTAssertEqual(adjustment.rotation, 0)
        XCTAssertEqual(adjustment.anchor, .zero)
        XCTAssertTrue(adjustment.isEnabled)
    }
    
    func testClipTransformAdjustmentGetterMatchesFromInitializer() throws {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Clip" duration="5s" format="r1">
                                    <adjust-transform position="10 20" scale="2 2" rotation="90"/>
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let clipElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "clip")
        )
        let transformElement = try XCTUnwrap(
            clipElement.firstChildElement(named: "adjust-transform")
        )
        let parsed = TransformAdjustment(from: transformElement)
        let clip = try XCTUnwrap(clipElement.fcpAsClip)
        
        XCTAssertEqual(clip.transformAdjustment, parsed)
    }
    
    func testPhotoshopSampleParsesNonDefaultTransformPosition() throws {
        let fcpxml = try loadFCPXMLSample(named: "PhotoshopSample1")
        
        guard let transformElement = firstDescendantElement(
            in: fcpxml.root.element,
            named: "adjust-transform"
        ) else {
            throw XCTSkip("PhotoshopSample1 has no adjust-transform")
        }
        
        let adjustment = TransformAdjustment(from: transformElement)
        
        XCTAssertEqual(adjustment.position.x, -25.463, accuracy: 0.001)
        XCTAssertEqual(adjustment.position.y, 4.81481, accuracy: 0.001)
    }
    
    private func makeAdjustTransformElement(
        position: String? = nil,
        scale: String? = nil,
        rotation: String? = nil,
        anchor: String? = nil,
        enabled: String? = nil
    ) -> any OFKXMLElement {
        let element = OFKXMLDefaultFactory().makeElement(name: "adjust-transform")
        
        if let position { element.addAttribute(name: "position", value: position) }
        if let scale { element.addAttribute(name: "scale", value: scale) }
        if let rotation { element.addAttribute(name: "rotation", value: rotation) }
        if let anchor { element.addAttribute(name: "anchor", value: anchor) }
        if let enabled { element.addAttribute(name: "enabled", value: enabled) }
        
        return element
    }
}
