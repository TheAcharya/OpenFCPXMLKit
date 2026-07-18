//
//  FCPXMLFileTest_360Video.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: 360Video.fcpxml — 360 video with projection, stereoscopic, adjust-colorConform, bookmarks, smart collections.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test 360 video")
struct FCPXMLFileTest_360Video {

    @Test("Parse 360Video sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")
    }

    @Test("Format projection and stereoscopic")
    func formatProjectionAndStereoscopic() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let resources = fcpxml.root.resources
        let formats = resources.childElements.filter { $0.name == "format" }
        let hasFormats = !formats.isEmpty
        #expect(hasFormats, "Expected format resource")

        let formatElement = try #require(formats.first, "No format element found")
        let format = try #require(formatElement.fcpAsFormat)
        #expect(format.projection == "equirectangular", "Format should have equirectangular projection")
        #expect(format.stereoscopic == "mono", "Format should have mono stereoscopic")
        #expect(format.width == 4096)
        #expect(format.height == 2048)
    }

    @Test("Adjust colorConform")
    func adjustColorConform() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let projects = fcpxml.allProjects()
        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        let hasStoryElements = !storyElements.isEmpty
        #expect(hasStoryElements, "Expected story elements in spine")

        let clipElement = try #require(
            storyElements.first(where: { $0.name == "clip" }),
            "No clip element found"
        )

        let clip = try #require(clipElement.fcpAsClip)
        let colorConform = clip.colorConformAdjustment
        #expect(colorConform != nil, "Clip should have colorConform adjustment")

        if let colorConform {
            #expect(colorConform.isEnabled, "ColorConform should be enabled")
            #expect(colorConform.autoOrManual == .manual, "ColorConform should be manual")
            #expect(colorConform.conformType == .conformNone, "ColorConform type should be conformNone")
            #expect(colorConform.peakNitsOfPQSource == "1000")
            #expect(colorConform.peakNitsOfSDRToPQSource == "203")
        }
    }

    @Test("MediaRep bookmark")
    func mediaRepBookmark() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let resources = fcpxml.root.resources
        let assets = resources.childElements.filter { $0.name == "asset" }
        let hasAssets = !assets.isEmpty
        #expect(hasAssets, "Expected asset resource")

        let assetElement = try #require(assets.first, "No asset element found")

        let mediaReps = assetElement.childElements.filter { $0.name == "media-rep" }
        let hasMediaReps = !mediaReps.isEmpty
        #expect(hasMediaReps, "Expected media-rep element")

        let mediaRepElement = try #require(mediaReps.first, "No media-rep element found")

        let mediaRep = try #require(mediaRepElement.fcpAsMediaRep)
        let bookmark = mediaRep.bookmark
        #expect(bookmark != nil, "MediaRep should have bookmark element")

        if let bookmark {
            let bookmarkData = bookmark.stringValue
            #expect(bookmarkData != nil, "Bookmark should have string value")
            let bookmarkNonEmpty = !(bookmarkData?.isEmpty ?? true)
            #expect(bookmarkNonEmpty, "Bookmark should not be empty")
        }
    }

    @Test("Smart collections")
    func smartCollections() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        #expect(smartCollections.count > 0, "Expected smart collections")

        for collectionElement in smartCollections {
            let collection = try #require(collectionElement.fcpAsSmartCollection)
            let hasName = !collection.name.isEmpty
            #expect(hasName, "Smart collection should have name")
        }
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "360Video")
        _ = try requireFCPXMLSampleData(named: "360Video")
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        #expect(doc.rootElement()?.name == "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        #expect(parsed.rootElement()?.name == "fcpxml")
    }

    @Test("Round trip")
    func roundTrip() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let xmlString = fcpxml.root.element.xmlString
        let xmlNonEmpty = !xmlString.isEmpty
        #expect(xmlNonEmpty)

        let xmlData = try #require(xmlString.data(using: .utf8), "Failed to convert XML string to data")
        let reloaded = try FinalCutPro.FCPXML(fileContent: xmlData)
        #expect(reloaded.version == .ver1_13)

        let resources = reloaded.root.resources
        let formats = resources.childElements.filter { $0.name == "format" }
        let formatElement = try #require(formats.first, "Format not found after round trip")
        let format = try #require(formatElement.fcpAsFormat, "Format not found after round trip")
        #expect(format.projection == "equirectangular")
        #expect(format.stereoscopic == "mono")
    }
}

