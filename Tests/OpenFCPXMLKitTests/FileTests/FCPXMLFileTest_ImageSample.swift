//
//  FCPXMLFileTest_ImageSample.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: ImageSample.fcpxml — still image asset with video element.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test image sample")
struct FCPXMLFileTest_ImageSample {

    @Test("Parse ImageSample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "ImageSample")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")
    }

    @Test("Still image asset")
    func stillImageAsset() throws {
        let fcpxml = try requireFCPXMLSample(named: "ImageSample")
        let resources = fcpxml.root.resources
        let assets = resources.childElements.filter { $0.name == "asset" }
        let hasAssets = !assets.isEmpty
        #expect(hasAssets, "Expected asset resource")

        let assetElement = try #require(assets.first, "No asset element found")

        let asset = try #require(assetElement.fcpAsAsset)
        let duration = try #require(asset.duration, "Asset should have duration attribute")
        let durationIsZero = abs(duration.doubleValue) < 0.001
        #expect(durationIsZero, "Still image should have 0 duration")
        #expect(asset.hasVideo, "Still image should have video")
        let hasAudio = asset.hasAudio
        #expect(!hasAudio, "Still image should not have audio")
    }

    @Test("Video element references still")
    func videoElementReferencesStill() throws {
        let fcpxml = try requireFCPXMLSample(named: "ImageSample")
        let projects = fcpxml.allProjects()
        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        let hasStoryElements = !storyElements.isEmpty
        #expect(hasStoryElements, "Expected story elements in spine")

        let videoElement = try #require(
            storyElements.first(where: { $0.name == "video" }),
            "No video element found"
        )

        let ref = videoElement.stringValue(forAttributeNamed: "ref")
        #expect(ref != nil, "Video element should reference an asset")
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "ImageSample")
        _ = try requireFCPXMLSampleData(named: "ImageSample")
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        #expect(doc.rootElement()?.name == "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        #expect(parsed.rootElement()?.name == "fcpxml")
    }
}

