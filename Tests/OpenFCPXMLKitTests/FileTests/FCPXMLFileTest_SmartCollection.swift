//
//  FCPXMLFileTest_SmartCollection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Smart collections from various FCPXML samples.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLFileTest_SmartCollection: XCTestCase {

    // MARK: - Basic Smart Collection Parsing
    
    func testSmartCollectionsFrom360Video() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        XCTAssertGreaterThan(smartCollections.count, 0, "Expected smart collections")
        
        for collectionElement in smartCollections {
            let collection = try XCTUnwrap(collectionElement.fcpAsSmartCollection)
            XCTAssertNotNil(collection.name, "Smart collection should have name")
            XCTAssertNotNil(collection.match, "Smart collection should have match attribute")
        }
    }
    
    func testSmartCollectionsFromTimelineSample() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineSample")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        XCTAssertGreaterThan(smartCollections.count, 0, "Expected smart collections")
        
        var foundProjects = false
        var foundAllVideo = false
        var foundFavorites = false
        
        for collectionElement in smartCollections {
            guard let collection = collectionElement.fcpAsSmartCollection else { continue }
            
            if collection.name == "Projects" {
                foundProjects = true
                XCTAssertEqual(collection.match, .all, "Projects should match all")
                XCTAssertEqual(collection.matchClips.count, 1, "Projects should have one match-clip")
                if let matchClip = collection.matchClips.first {
                    XCTAssertEqual(matchClip.type, .project, "Match clip type should be project")
                }
            } else if collection.name == "All Video" {
                foundAllVideo = true
                XCTAssertEqual(collection.match, .any, "All Video should match any")
                XCTAssertEqual(collection.matchMedias.count, 2, "All Video should have two match-media rules")
            } else if collection.name == "Favorites" {
                foundFavorites = true
                XCTAssertEqual(collection.match, .all, "Favorites should match all")
                XCTAssertEqual(collection.matchRatings.count, 1, "Favorites should have one match-ratings")
                if let matchRating = collection.matchRatings.first {
                    XCTAssertEqual(matchRating.value, .favorites, "Rating value should be favorites")
                }
            }
        }
        
        XCTAssertTrue(foundProjects, "Should find Projects smart collection")
        XCTAssertTrue(foundAllVideo, "Should find All Video smart collection")
        XCTAssertTrue(foundFavorites, "Should find Favorites smart collection")
    }
    
    // MARK: - Match Types Testing
    
    func testMatchClipSmartCollection() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        
        let projectsCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "Projects"
        }
        
        guard let projectsElement = projectsCollection,
              let collection = projectsElement.fcpAsSmartCollection else {
            XCTFail("Should find Projects smart collection")
            return
        }
        
        XCTAssertEqual(collection.name, "Projects")
        XCTAssertEqual(collection.match, .all)
        XCTAssertEqual(collection.matchClips.count, 1)
        XCTAssertEqual(collection.matchClips[0].type, .project)
        XCTAssertEqual(collection.matchClips[0].rule, .isExactly)
    }
    
    func testMatchMediaSmartCollection() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        
        let allVideoCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "All Video"
        }
        
        guard let allVideoElement = allVideoCollection,
              let collection = allVideoElement.fcpAsSmartCollection else {
            XCTFail("Should find All Video smart collection")
            return
        }
        
        XCTAssertEqual(collection.name, "All Video")
        XCTAssertEqual(collection.match, .any)
        XCTAssertEqual(collection.matchMedias.count, 2)
        
        let mediaTypes = collection.matchMedias.map { $0.type }
        XCTAssertTrue(mediaTypes.contains(.videoOnly))
        XCTAssertTrue(mediaTypes.contains(.videoWithAudio))
    }
    
    func testMatchRatingsSmartCollection() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        
        let favoritesCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "Favorites"
        }
        
        guard let favoritesElement = favoritesCollection,
              let collection = favoritesElement.fcpAsSmartCollection else {
            XCTFail("Should find Favorites smart collection")
            return
        }
        
        XCTAssertEqual(collection.name, "Favorites")
        XCTAssertEqual(collection.match, .all)
        XCTAssertEqual(collection.matchRatings.count, 1)
        XCTAssertEqual(collection.matchRatings[0].value, .favorites)
    }
    
    // MARK: - Multiple Samples Testing
    
    func testSmartCollectionsFromMultipleSamples() throws {
        let sampleNames = [
            "360Video",
            "TimelineSample",
            "AuditionSample",
            "ImageSample",
            "CaptionSample",
            "CompoundClipSample",
            "CutSample",
            "MulticamSample",
            "MulticamSampleWithCuts",
            "PhotoshopSample1",
            "PhotoshopSample2",
            "TimelineWithSecondaryStoryline",
            "TimelineWithSecondaryStorylineWithAudioKeyframes"
        ]
        
        for sampleName in sampleNames {
            let url = urlForFCPXMLSample(named: sampleName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                continue // Skip if sample doesn't exist
            }
            
            let fcpxml = try loadFCPXMLSample(named: sampleName)
            let library = try XCTUnwrap(fcpxml.root.library, "Sample \(sampleName) should have library")
            let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
            
            XCTAssertGreaterThan(smartCollections.count, 0, "Sample \(sampleName) should have smart collections")
            
            // Verify all smart collections can be parsed
            for collectionElement in smartCollections {
                let collection = try XCTUnwrap(
                    collectionElement.fcpAsSmartCollection,
                    "Smart collection in \(sampleName) should parse correctly"
                )
                XCTAssertNotNil(collection.name, "Smart collection in \(sampleName) should have name")
                XCTAssertNotNil(collection.match, "Smart collection in \(sampleName) should have match")
            }
        }
    }
    
    // MARK: - Match Attribute Testing
    
    func testMatchAllAttribute() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        
        let projectsCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "Projects"
        }
        
        guard let projectsElement = projectsCollection,
              let collection = projectsElement.fcpAsSmartCollection else {
            XCTFail("Should find Projects smart collection")
            return
        }
        
        XCTAssertEqual(collection.match, .all)
        XCTAssertEqual(projectsElement.stringValue(forAttributeNamed: "match"), "all")
    }
    
    func testMatchAnyAttribute() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        
        let allVideoCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "All Video"
        }
        
        guard let allVideoElement = allVideoCollection,
              let collection = allVideoElement.fcpAsSmartCollection else {
            XCTFail("Should find All Video smart collection")
            return
        }
        
        XCTAssertEqual(collection.match, .any)
        XCTAssertEqual(allVideoElement.stringValue(forAttributeNamed: "match"), "any")
    }
    
    // MARK: - Library Integration
    
    func testLibrarySmartCollectionsProperty() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        
        let smartCollections = Array(library.smartCollections)
        XCTAssertGreaterThan(smartCollections.count, 0, "Library should have smart collections")
        
        // Verify all smart collections have names
        for collection in smartCollections {
            XCTAssertFalse(collection.name.isEmpty, "Smart collection should have non-empty name")
        }
    }
    
    // MARK: - Round-Trip Testing
    
    func testSmartCollectionRoundTrip() throws {
        let fcpxml = try loadFCPXMLSample(named: "360Video")
        let library = try XCTUnwrap(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        
        guard let firstCollectionElement = smartCollections.first,
              let originalCollection = firstCollectionElement.fcpAsSmartCollection else {
            XCTFail("Should find at least one smart collection")
            return
        }
        
        // Verify the element can be recreated from the model
        let recreatedElement = originalCollection.element
        XCTAssertEqual(recreatedElement.name, "smart-collection")
        XCTAssertEqual(recreatedElement.stringValue(forAttributeNamed: "name"), originalCollection.name)
        XCTAssertEqual(recreatedElement.stringValue(forAttributeNamed: "match"), originalCollection.match.rawValue)
        
        // Verify it can be parsed again
        let reparsedCollection = try XCTUnwrap(recreatedElement.fcpAsSmartCollection)
        XCTAssertEqual(reparsedCollection.name, originalCollection.name)
        XCTAssertEqual(reparsedCollection.match, originalCollection.match)
    }
}
