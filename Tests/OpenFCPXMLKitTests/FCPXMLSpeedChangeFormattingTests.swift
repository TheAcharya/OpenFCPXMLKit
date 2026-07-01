//
//  FCPXMLSpeedChangeFormattingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for time-map retime display formatting.
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLSpeedChangeFormattingTests: XCTestCase {
    private typealias SpeedChangeFormatting = FinalCutPro.FCPXML.SpeedChangeFormatting
    
    func testRetimeDisplayFormatsReverseSpeedFromTimeMap() throws {
        let timeMap = try timeMap(from: """
        <timeMap>
            <timept time="158445100/2500s" value="158591200/2500s" interp="smooth2"/>
            <timept time="158591200/2500s" value="158445100/2500s" interp="smooth2"/>
        </timeMap>
        """)
        
        let display = SpeedChangeFormatting.retimeDisplay(from: timeMap)
        
        XCTAssertEqual(display?.effect, "Retime -100.0%")
        XCTAssertEqual(display?.settings, "-100.0%")
    }
    
    func testRetimeDisplayReturnsNilForSingleTimePoint() throws {
        let timeMap = try timeMap(from: """
        <timeMap>
            <timept time="0s" value="0s" interp="smooth2"/>
        </timeMap>
        """)
        
        XCTAssertNil(SpeedChangeFormatting.retimeDisplay(from: timeMap))
    }
    
    private func timeMap(from xml: String) throws -> FinalCutPro.FCPXML.TimeMap {
        let fcpxml = try parseInlineFCPXML("""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <clip offset="0s" name="Clip" duration="10s">
                                    \(xml)
                                </clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let element = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "timeMap")
        )
        return try XCTUnwrap(FinalCutPro.FCPXML.TimeMap(element: element))
    }
}
