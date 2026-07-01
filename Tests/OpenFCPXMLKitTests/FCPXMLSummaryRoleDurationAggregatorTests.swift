//
//  FCPXMLSummaryRoleDurationAggregatorTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLSummaryRoleDurationAggregatorTests: XCTestCase {
    private typealias Aggregator = FinalCutPro.FCPXML.SummaryRoleDurationAggregator
    private typealias Component = FinalCutPro.FCPXML.RoleInventoryClipComponent
    
    func testAudioMainRolesUseAudioCategoryTotalsOnly() throws {
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
                        <sequence format="r1" duration="200s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="200s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let components = [
            Component(
                roleSubroleField: "Video, Dialogue ▸ Boom 1",
                category: .connectedVideo,
                durationSeconds: 100
            ),
            Component(
                roleSubroleField: "Dialogue ▸ Boom 1",
                category: .connectedAudio,
                durationSeconds: 40
            )
        ]
        
        let rows = Aggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 200,
            timeline: timeline,
            resources: fcpxml.root.resources
        )
        
        let boomRow = try XCTUnwrap(rows.first { $0.roleSubrole == "Dialogue ▸ Boom 1" })
        XCTAssertEqual(boomRow.percentOfTotal, 0.2, accuracy: 0.0001)
    }
    
    func testBareDialogueRoleUsesExactRoleFieldMatch() throws {
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
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="100s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let components = [
            Component(
                roleSubroleField: "Dialogue",
                category: .primaryAudio,
                durationSeconds: 30
            ),
            Component(
                roleSubroleField: "Video, Dialogue",
                category: .connectedVideo,
                durationSeconds: 60
            )
        ]
        
        let rows = Aggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources
        )
        
        let dialogueRow = try XCTUnwrap(rows.first { $0.roleSubrole == "Dialogue" })
        XCTAssertEqual(dialogueRow.percentOfTotal, 0.3, accuracy: 0.0001)
    }
    
    func testRoleRowsUseWorkbookOrdering() throws {
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
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="100s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let components = [
            Component(roleSubroleField: "Dialogue ▸ Boom 1", category: .connectedAudio, durationSeconds: 10),
            Component(roleSubroleField: "Video", category: .primaryVideo, durationSeconds: 10),
            Component(roleSubroleField: "Titles", category: .primaryTitle, durationSeconds: 10)
        ]
        
        let rows = Aggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources
        )
        
        let roleNames = rows.map(\.roleSubrole).filter { !$0.isEmpty }
        XCTAssertEqual(roleNames.first, "Titles")
        XCTAssertTrue(roleNames.contains("Video"))
        XCTAssertTrue(roleNames.last?.hasPrefix("Dialogue") == true)
    }
    
    func testSRTRolesUseCaptionCategoryTotals() throws {
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
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="100s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let components = [
            Component(
                roleSubroleField: "SRT ▸ de-DE",
                category: .caption,
                durationSeconds: 25
            ),
            Component(
                roleSubroleField: "Video, SRT ▸ de-DE",
                category: .connectedVideo,
                durationSeconds: 60
            )
        ]
        
        let rows = Aggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources
        )
        
        let srtRow = try XCTUnwrap(rows.first { $0.roleSubrole == "SRT ▸ de-DE" })
        XCTAssertEqual(srtRow.percentOfTotal, 0.25, accuracy: 0.0001)
    }
    
    func testUserDefinedAudioMainRoleUsesAudioCategoryTotals() throws {
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
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="100s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let components = [
            Component(
                roleSubroleField: "Ambient Beds ▸ Boom 1",
                category: .connectedAudio,
                durationSeconds: 40
            ),
            Component(
                roleSubroleField: "Video, Ambient Beds ▸ Boom 1",
                category: .connectedVideo,
                durationSeconds: 100
            )
        ]
        
        let rows = Aggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources
        )
        
        let boomRow = try XCTUnwrap(rows.first { $0.roleSubrole == "Ambient Beds ▸ Boom 1" })
        XCTAssertEqual(boomRow.percentOfTotal, 0.4, accuracy: 0.0001)
    }
    
    func testSharedSubroleFanOutAppliesToUserDefinedMainRoles() throws {
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
                        <sequence format="r1" duration="100s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <gap name="Gap" offset="0s" duration="100s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """)
        
        let timeline = try XCTUnwrap(fcpxml.allProjects().first?.sequence.element)
        let components = [
            Component(
                roleSubroleField: "Primary Dialog ▸ Boom 1",
                category: .connectedAudio,
                durationSeconds: 40
            ),
            Component(
                roleSubroleField: "Ambient Beds ▸ Boom 1",
                category: .connectedAudio,
                durationSeconds: 40
            )
        ]
        
        let rows = Aggregator.roleDurationRows(
            from: components,
            projectDurationSeconds: 100,
            timeline: timeline,
            resources: fcpxml.root.resources
        )
        
        let primaryRow = try XCTUnwrap(rows.first { $0.roleSubrole == "Primary Dialog ▸ Boom 1" })
        let ambientRow = try XCTUnwrap(rows.first { $0.roleSubrole == "Ambient Beds ▸ Boom 1" })
        XCTAssertEqual(primaryRow.percentOfTotal, 0.8, accuracy: 0.0001)
        XCTAssertEqual(ambientRow.percentOfTotal, 0.8, accuracy: 0.0001)
    }
}
