//
//  FCPXMLFileTest_Keywords.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Keywords.fcpxml, EventsWithKeywords.fcpxml, KeywordsWithinFolders.fcpxml.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test keywords")
struct FCPXMLFileTest_Keywords {

    @Test("Parse Keywords sample")
    func parse() throws {
        let fcpxml = try requireFCPXMLSample(named: "Keywords")
        #expect(fcpxml.root.element.name == "fcpxml")
    }

    @Test("Events with keywords")
    func eventsWithKeywords() throws {
        let fcpxml = try requireFCPXMLSample(named: "EventsWithKeywords")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")

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
        #expect(foundKeywords, "Expected to find keywords in at least one event")
    }

    @Test("Keywords within folders")
    func keywordsWithinFolders() throws {
        let fcpxml = try requireFCPXMLSample(named: "KeywordsWithinFolders")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let events = fcpxml.allEvents()
        let hasEvents = !events.isEmpty
        #expect(hasEvents, "Expected at least one event")

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
        let foundCollectionsOrFolders = foundKeywordCollections || foundCollectionFolders
        #expect(foundCollectionsOrFolders, "Expected keyword collections or folders in events")
    }
}

