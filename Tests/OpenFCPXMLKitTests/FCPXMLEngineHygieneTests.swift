//
// FCPXMLEngineHygieneTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Engine hygiene: project-once, version-strip honesty, projection smoke budget.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLEngineHygieneTests: XCTestCase {

    // MARK: - Version strip vs report honesty

    func testConvertTo15StripsHeroEyeAndDoesNotReinventOnWrite() throws {
        let factory = FoundationXMLFactory()
        let document = factory.makeDocument()
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.14")
        document.setRootElement(root)

        let resources = factory.makeElement(name: "resources")
        let format = factory.makeElement(name: "format")
        format.addAttribute(name: "id", value: "r1")
        format.addAttribute(name: "frameDuration", value: "100/2400s")
        format.addAttribute(name: "width", value: "1920")
        format.addAttribute(name: "height", value: "1080")
        format.addAttribute(name: "heroEye", value: "left")
        resources.addChild(format)

        let asset = factory.makeElement(name: "asset")
        asset.addAttribute(name: "id", value: "r2")
        asset.addAttribute(name: "name", value: "A")
        asset.addAttribute(name: "hasVideo", value: "1")
        asset.addAttribute(name: "duration", value: "5s")
        asset.addAttribute(name: "heroEyeOverride", value: "right")
        let mediaRep = factory.makeElement(name: "media-rep")
        mediaRep.addAttribute(name: "kind", value: "original-media")
        mediaRep.addAttribute(name: "src", value: "file:///tmp/engine-hygiene.mov")
        asset.addChild(mediaRep)
        resources.addChild(asset)
        root.addChild(resources)

        let library = factory.makeElement(name: "library")
        let event = factory.makeElement(name: "event")
        event.addAttribute(name: "name", value: "E")
        let project = factory.makeElement(name: "project")
        project.addAttribute(name: "name", value: "P")
        let sequence = factory.makeElement(name: "sequence")
        sequence.addAttribute(name: "format", value: "r1")
        sequence.addAttribute(name: "duration", value: "5s")
        sequence.addAttribute(name: "tcStart", value: "0s")
        let spine = factory.makeElement(name: "spine")
        let clip = factory.makeElement(name: "asset-clip")
        clip.addAttribute(name: "ref", value: "r2")
        clip.addAttribute(name: "offset", value: "0s")
        clip.addAttribute(name: "name", value: "Clip")
        clip.addAttribute(name: "duration", value: "5s")
        spine.addChild(clip)
        sequence.addChild(spine)
        project.addChild(sequence)
        event.addChild(project)
        library.addChild(event)
        root.addChild(library)

        let originalFormat = try XCTUnwrap(FinalCutPro.FCPXML.Format(element: format))
        XCTAssertEqual(originalFormat.heroEye, "left")

        let converter = FCPXMLVersionConverter()
        let converted = try converter.convert(document, to: .v1_5)
        XCTAssertEqual(converted.rootElement()?.stringValue(forAttributeNamed: "version"), "1.5")

        let convertedFormat = converted.rootElement()?
            .childElements
            .first { $0.name == "resources" }?
            .childElements
            .first { $0.name == "format" }
        XCTAssertNil(
            convertedFormat?.attribute(forName: "heroEye"),
            "1.5 write path must not retain Format heroEye (1.13+)"
        )

        let convertedAsset = converted.rootElement()?
            .childElements
            .first { $0.name == "resources" }?
            .childElements
            .first { $0.name == "asset" }
        XCTAssertNil(
            convertedAsset?.attribute(forName: "heroEyeOverride"),
            "1.5 write path must not retain Asset heroEyeOverride (1.13+)"
        )
    }

    // MARK: - Project-once

    func testReportBuilderProjectsTimelineOnceForFullOptions() async throws {
        let fcpxml = try parseInlineFCPXML(Self.simpleAssetClipXML)
        let counter = CountingTimelineProjector()
        var options = FinalCutPro.FCPXML.ReportOptions.full
        options.mediaBaseURL = URL(fileURLWithPath: "/tmp")

        _ = try await FinalCutPro.FCPXML.ReportBuilder(
            options: options,
            timelineProjector: counter
        ).build(from: fcpxml)

        XCTAssertEqual(
            counter.projectCallCount,
            1,
            "Full report must project the timeline once, not per consuming sheet"
        )
    }

    func testReportBuilderSkipsProjectionWhenNoConsumingSections() async throws {
        let fcpxml = try parseInlineFCPXML(Self.simpleAssetClipXML)
        let counter = CountingTimelineProjector()
        // No section that consumes Projection (Transitions now project; use an empty report).
        let options = FinalCutPro.FCPXML.ReportOptions(
            includeMarkers: false,
            includeKeywords: false,
            includeTitlesAndGenerators: false,
            includeTransitions: false,
            includeEffects: false,
            includeSpeedChangeEffects: false,
            includeSummary: false,
            includeMediaSummary: false,
            includeRoleInventory: false
        )

        _ = try await FinalCutPro.FCPXML.ReportBuilder(
            options: options,
            timelineProjector: counter
        ).build(from: fcpxml)

        XCTAssertEqual(counter.projectCallCount, 0)
    }

    func testProjectionSmokeBudgetOnComplexSampleWhenAvailable() async throws {
        let fcpxml: FinalCutPro.FCPXML
        do {
            fcpxml = try loadFCPXMLSample(named: FCPXMLSampleName.complex.rawValue)
        } catch {
            throw XCTSkip("Complex.fcpxml not available")
        }
        let source = try XCTUnwrap(fcpxml.allReportTimelineSources().first)
        let projector = FinalCutPro.FCPXML.TimelineProjector()

        let started = ContinuousClock.now
        let windows = try await projector.project(from: source, fcpxml: fcpxml)
        let elapsed = ContinuousClock.now - started

        XCTAssertFalse(windows.isEmpty)
        // Soft CI budget: long-form OFK Complex projection should stay interactive.
        // Generous ceiling avoids flaky failures on loaded hosts.
        XCTAssertLessThan(
            elapsed,
            .seconds(30),
            "Complex projection exceeded soft 30s budget (\(elapsed))"
        )
    }

    // MARK: - Helpers

    private final class CountingTimelineProjector: FinalCutPro.FCPXML.TimelineProjecting, @unchecked Sendable {
        /// Single-threaded report builds call project serially; no lock required.
        private(set) var projectCallCount = 0

        func project(
            from source: FinalCutPro.FCPXML.ReportTimelineSource,
            fcpxml: FinalCutPro.FCPXML,
            options: FinalCutPro.FCPXML.TimelineProjectionOptions,
            onWindow: (FinalCutPro.FCPXML.MediaUsageWindow) throws -> Void
        ) async throws {
            projectCallCount += 1
            try await FinalCutPro.FCPXML.TimelineProjector()
                .project(from: source, fcpxml: fcpxml, options: options, onWindow: onWindow)
        }
    }

    private static let simpleAssetClipXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="10s">
                    <media-rep kind="original-media" src="file:///tmp/p5-hygiene.mov"/>
                </asset>
            </resources>
            <library><event name="E"><project name="P">
                <sequence format="r1" duration="5s" tcStart="0s">
                    <spine>
                        <asset-clip ref="r2" offset="0s" name="Clip" duration="5s"/>
                    </spine>
                </sequence>
            </project></event></library>
        </fcpxml>
        """
}
