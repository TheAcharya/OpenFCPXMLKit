//
//  FCPXMLLeafAnnotationWalkTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Regression: keyword/marker children must not be walked as timeline containers.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Leaf annotation walk")
struct FCPXMLLeafAnnotationWalkTests {

    /// Dense enough that walking each keyword through occlusion would blow a hang budget.
    private let denseKeywordCount = 2500
    private let hangBudget: Duration = .seconds(5)

    @Test("Projectable story elements exclude keyword and marker leaves")
    func projectableStoryElementsExcludeKeywordAndMarkerLeaves() throws {
        let fcpxml = try parseInlineFCPXML(xmlWithKeywords(count: 3, includeMarker: true))
        let clip = try #require(
            fcpxml.allReportTimelineSources().first?
                .sequence.spine.element.fcpStoryElements
                .first { $0.fcpElementType == .assetClip }
        )

        let storyTypes = clip.fcpStoryElements.compactMap(\.fcpElementType)
        #expect(storyTypes.contains(.keyword))
        #expect(storyTypes.contains(.marker))

        let projectableTypes = clip.fcpProjectableStoryElements.compactMap(\.fcpElementType)
        #expect(!projectableTypes.contains(.keyword))
        #expect(!projectableTypes.contains(.marker))
        #expect(clip.fcpProjectableStoryElements.isEmpty)
    }

    @Test("Projection of a clip with thousands of keywords stays within hang budget")
    func projectionOfDenseKeywordsStaysWithinHangBudget() async throws {
        let fcpxml = try parseInlineFCPXML(xmlWithKeywords(count: denseKeywordCount, includeMarker: true))
        let source = try #require(fcpxml.allReportTimelineSources().first)
        let projector = FinalCutPro.FCPXML.TimelineProjector()

        let started = ContinuousClock.now
        let result = try await projector.projectDetailed(
            from: source,
            fcpxml: fcpxml,
            options: .init(includeAnnotations: true)
        )
        let elapsed = ContinuousClock.now - started

        #expect(elapsed < hangBudget)
        #expect(result.windows.count == 2)
        let keywordCount = result.clipAnnotations.reduce(0) { $0 + $1.keywords.count }
        #expect(keywordCount == denseKeywordCount)
        let markerCount = result.clipAnnotations.reduce(0) { $0 + $1.markers.count }
        #expect(markerCount == 1)
    }

    @Test("Role-inventory extraction does not recurse into dense keyword children")
    func roleInventoryExtractionDoesNotRecurseIntoDenseKeywords() async throws {
        let fcpxml = try parseInlineFCPXML(xmlWithKeywords(count: denseKeywordCount, includeMarker: true))
        let timeline = try #require(fcpxml.allReportTimelineSources().first?.sequence.element)

        let started = ContinuousClock.now
        let extracted = await timeline.fcpExtract(
            types: [.assetClip, .clip, .title, .video, .audio],
            scope: .reportMainTimelineVisible()
        )
        let elapsed = ContinuousClock.now - started

        #expect(elapsed < hangBudget)
        #expect(extracted.count == 1)
        #expect(extracted.first?.element.fcpElementType == .assetClip)
    }

    @Test("Keyword extraction still returns dense keyword children")
    func keywordExtractionStillReturnsDenseKeywordChildren() async throws {
        let fcpxml = try parseInlineFCPXML(xmlWithKeywords(count: 25, includeMarker: true))
        let timeline = try #require(fcpxml.allReportTimelineSources().first?.sequence.element)
        let extracted = await timeline.fcpExtract(
            types: [.keyword],
            scope: .reportMainTimelineVisible()
        )
        #expect(extracted.count == 25)
    }

    @Test("Resource id lookup finds assets among many siblings")
    func resourceIDLookupFindsAssetsAmongManySiblings() throws {
        var extras = ""
        extras.reserveCapacity(80 * 300)
        for index in 0..<300 {
            extras += """
                <asset id="extra\(index)" name="E\(index)" start="0s" duration="1s" hasVideo="1">
                    <media-rep kind="original-media" src="file:///tmp/e\(index).mov"/>
                </asset>

            """
        }
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                    \(extras)
                    <asset id="r2" name="Target" start="0s" duration="5s" hasVideo="1" hasAudio="1">
                        <media-rep kind="original-media" src="file:///tmp/target.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="Event">
                        <project name="Project">
                            <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="Clip" start="0s" duration="5s"/>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """)
        let resources = fcpxml.root.resources
        let found = resources.firstChildElement(withID: "r2")
        #expect(found?.fcpName == "Target")
        #expect(resources.firstChildElement(withID: "extra0")?.fcpName == "E0")
        #expect(resources.firstChildElement(withID: "missing") == nil)
    }

    private func xmlWithKeywords(count: Int, includeMarker: Bool) -> String {
        var keywords = ""
        keywords.reserveCapacity(count * 64)
        for index in 0..<count {
            keywords += "<keyword start=\"0s\" duration=\"5s\" value=\"kw\(index)\"/>\n"
        }
        let marker = includeMarker
            ? "<marker start=\"1s\" duration=\"1/24s\" value=\"Note\"/>\n"
            : ""
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="ClipA" start="0s" duration="5s" hasVideo="1" hasAudio="1" videoSources="1" audioSources="1" audioChannels="2" audioRate="48000">
                        <media-rep kind="original-media" src="file:///tmp/ClipA.mov"/>
                    </asset>
                </resources>
                <library>
                    <event name="Event">
                        <project name="Project">
                            <sequence format="r1" duration="5s" tcStart="0s" tcFormat="NDF">
                                <spine>
                                    <asset-clip ref="r2" offset="0s" name="ClipA" start="0s" duration="5s">
                                        \(keywords)
                                        \(marker)
                                    </asset-clip>
                                </spine>
                            </sequence>
                        </project>
                    </event>
                </library>
            </fcpxml>
            """
    }
}
