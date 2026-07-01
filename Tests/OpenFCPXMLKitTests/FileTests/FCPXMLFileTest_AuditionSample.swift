//
//  FCPXMLFileTest_AuditionSample.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: AuditionSample.fcpxml — audition element with multiple asset-clips, adjust-colorConform, conform-rate, keywords.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_AuditionSample: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "AuditionSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")
    }

    func testAuditionElement() throws {
        let fcpxml = try loadFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        XCTAssertFalse(storyElements.isEmpty, "Expected story elements in spine")
        
        // Find the audition element
        guard let auditionElement = storyElements.first(where: { $0.name == "audition" }) else {
            XCTFail("No audition element found")
            return
        }
        
        let audition = try XCTUnwrap(auditionElement.fcpAsAudition)
        let clips = audition.clips
        XCTAssertGreaterThan(clips.count, 0, "Audition should contain clips")
        
        // First clip is the active audition
        let activeClip = audition.activeClip
        XCTAssertNotNil(activeClip, "Audition should have an active clip")
        
        // Should have inactive clips
        let inactiveClips = audition.inactiveClips
        XCTAssertGreaterThan(inactiveClips.count, 0, "Audition should have inactive clips")
    }

    func testAuditionClipsHaveAdjustments() throws {
        let fcpxml = try loadFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        
        guard let auditionElement = storyElements.first(where: { $0.name == "audition" }),
              let audition = auditionElement.fcpAsAudition else {
            XCTFail("No audition element found")
            return
        }
        
        // Check that clips have adjust-colorConform (access via element since AssetClip doesn't have adjustment properties)
        var foundColorConform = false
        for clipElement in audition.clips {
            if clipElement.firstChildElement(named: "adjust-colorConform") != nil {
                foundColorConform = true
                break
            }
        }
        XCTAssertTrue(foundColorConform, "Asset clips in audition should have colorConform adjustment")
    }

    func testConformRate() throws {
        let fcpxml = try loadFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        
        guard let auditionElement = storyElements.first(where: { $0.name == "audition" }),
              let audition = auditionElement.fcpAsAudition else {
            XCTFail("No audition element found")
            return
        }
        
        // Find clip with conform-rate
        var foundConformRate = false
        for clip in audition.clips {
            guard let assetClip = clip.fcpAsAssetClip else { continue }
            if let conformRate = assetClip.conformRate {
                foundConformRate = true
                XCTAssertFalse(conformRate.scaleEnabled, "ConformRate scaleEnabled should be false")
                XCTAssertEqual(conformRate.srcFrameRate?.rawValue, "29.97", "ConformRate srcFrameRate should be 29.97")
                break
            }
        }
        XCTAssertTrue(foundConformRate, "Should find a clip with conform-rate")
    }

    func testKeywordsInAudition() throws {
        let fcpxml = try loadFCPXMLSample(named: "AuditionSample")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        
        guard let auditionElement = storyElements.first(where: { $0.name == "audition" }),
              let audition = auditionElement.fcpAsAudition else {
            XCTFail("No audition element found")
            return
        }
        
        // Check for keywords in clips (access via fcpxAnnotations)
        var foundKeyword = false
        for clipElement in audition.clips {
            let annotations = clipElement.fcpxAnnotations
            let keywords = annotations.filter { $0.fcpxType == .keyword }
            if !keywords.isEmpty {
                foundKeyword = true
                break
            }
        }
        XCTAssertTrue(foundKeyword, "Should find keywords in audition clips")
    }

    func testLoadViaLoaderAndParseViaService() throws {
        let url = urlForFCPXMLSample(named: "AuditionSample")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("AuditionSample.fcpxml not found")
        }
        let loader = FCPXMLFileLoader()
        let doc = try loader.loadDocument(from: url)
        XCTAssertEqual(doc.rootElement()?.name, "fcpxml")
        let service = FCPXMLService()
        let data = try Data(contentsOf: url)
        let parsed = try service.parseFCPXML(from: data)
        XCTAssertEqual(parsed.rootElement()?.name, "fcpxml")
    }
}
