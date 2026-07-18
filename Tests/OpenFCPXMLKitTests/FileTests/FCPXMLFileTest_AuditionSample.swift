//
//  FCPXMLFileTest_AuditionSample.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: AuditionSample.fcpxml — audition element with multiple asset-clips, adjust-colorConform, conform-rate, keywords.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("File test audition sample")
struct FCPXMLFileTest_AuditionSample {

    @Test("Parse AuditionSample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "AuditionSample")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")
        let projects = fcpxml.allProjects()
        let hasProjects = !projects.isEmpty
        #expect(hasProjects, "Expected at least one project")
    }

    @Test("Audition element")
    func auditionElement() throws {
        let fcpxml = try requireFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        let hasStoryElements = !storyElements.isEmpty
        #expect(hasStoryElements, "Expected story elements in spine")

        let auditionElement = try #require(
            storyElements.first(where: { $0.name == "audition" }),
            "No audition element found"
        )

        let audition = try #require(auditionElement.fcpAsAudition)
        let clips = audition.clips
        #expect(clips.count > 0, "Audition should contain clips")

        let activeClip = audition.activeClip
        #expect(activeClip != nil, "Audition should have an active clip")

        let inactiveClips = audition.inactiveClips
        #expect(inactiveClips.count > 0, "Audition should have inactive clips")
    }

    @Test("Audition clips have adjustments")
    func auditionClipsHaveAdjustments() throws {
        let fcpxml = try requireFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)

        let auditionElement = try #require(
            storyElements.first(where: { $0.name == "audition" }),
            "No audition element found"
        )
        let audition = try #require(auditionElement.fcpAsAudition)

        var foundColorConform = false
        for clipElement in audition.clips {
            if clipElement.firstChildElement(named: "adjust-colorConform") != nil {
                foundColorConform = true
                break
            }
        }
        #expect(foundColorConform, "Asset clips in audition should have colorConform adjustment")
    }

    @Test("Conform rate")
    func conformRate() throws {
        let fcpxml = try requireFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)

        let auditionElement = try #require(
            storyElements.first(where: { $0.name == "audition" }),
            "No audition element found"
        )
        let audition = try #require(auditionElement.fcpAsAudition)

        var foundConformRate = false
        for clip in audition.clips {
            guard let assetClip = clip.fcpAsAssetClip else { continue }
            if let conformRate = assetClip.conformRate {
                foundConformRate = true
                let scaleDisabled = !conformRate.scaleEnabled
                #expect(scaleDisabled, "ConformRate scaleEnabled should be false")
                #expect(conformRate.srcFrameRate?.rawValue == "29.97", "ConformRate srcFrameRate should be 29.97")
                break
            }
        }
        #expect(foundConformRate, "Should find a clip with conform-rate")
    }

    @Test("Keywords in audition")
    func keywordsInAudition() throws {
        let fcpxml = try requireFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        let project = try #require(projects.first, "No project found")

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)

        let auditionElement = try #require(
            storyElements.first(where: { $0.name == "audition" }),
            "No audition element found"
        )
        let audition = try #require(auditionElement.fcpAsAudition)

        var foundKeyword = false
        for clipElement in audition.clips {
            let annotations = clipElement.fcpxAnnotations
            let keywords = annotations.filter { $0.fcpxType == .keyword }
            if !keywords.isEmpty {
                foundKeyword = true
                break
            }
        }
        #expect(foundKeyword, "Should find keywords in audition clips")
    }

    @Test("Load via loader and parse via service")
    func loadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "AuditionSample")
        _ = try requireFCPXMLSampleData(named: "AuditionSample")
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        #expect(doc.rootElement()?.name == "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        #expect(parsed.rootElement()?.name == "fcpxml")
    }
}

