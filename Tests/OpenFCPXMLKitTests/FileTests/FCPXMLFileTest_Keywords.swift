//
//  FCPXMLFileTest_Keywords.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Keywords.fcpxml, EventsWithKeywords.fcpxml, KeywordsWithinFolders.fcpxml.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_Keywords: XCTestCase {

    func testParse() throws {
        let fcpxml = try loadFCPXMLSample(named: "Keywords")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
    }

    func testEventsWithKeywords() throws {
        let fcpxml = try loadFCPXMLSample(named: "EventsWithKeywords")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        
        // Verify keywords exist in events
        var foundKeywords = false
        for event in events {
            let eventElement = event.element
            guard let clips = eventElement.eventClips else { continue }
            for clip in clips {
                let annotations = clip.fcpxAnnotations
                let keywords = annotations.filter { $0.fcpxType == FCPXMLElementType.keyword }
                if !keywords.isEmpty {
                    foundKeywords = true
                    break
                }
            }
            if foundKeywords {
                break
            }
        }
        XCTAssertTrue(foundKeywords, "Expected to find keywords in at least one event")
    }

    func testKeywordsWithinFolders() throws {
        let fcpxml = try loadFCPXMLSample(named: "KeywordsWithinFolders")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let events = fcpxml.allEvents()
        XCTAssertFalse(events.isEmpty, "Expected at least one event")
        
        // Verify keyword collections and folders exist in events
        var foundKeywordCollections = false
        var foundCollectionFolders = false
        for event in events {
            let eventElement = event.element
            let keywordCollections = eventElement.childElements.filter { $0.name == "keyword-collection" }
            let collectionFolders = eventElement.childElements.filter { $0.name == "collection-folder" }
            if !keywordCollections.isEmpty {
                foundKeywordCollections = true
            }
            if !collectionFolders.isEmpty {
                foundCollectionFolders = true
            }
            if foundKeywordCollections && foundCollectionFolders {
                break
            }
        }
        XCTAssertTrue(foundKeywordCollections || foundCollectionFolders, "Expected keyword collections or folders in events")
    }
}
