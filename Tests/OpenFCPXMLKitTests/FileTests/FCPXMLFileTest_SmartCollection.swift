//
//  FCPXMLFileTest_SmartCollection.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	File Tests: Smart collections from various FCPXML samples.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("File test smart collection")
struct FCPXMLFileTest_SmartCollection {

    // MARK: - Basic Smart Collection Parsing

    @Test("Smart collections from 360Video")
    func smartCollectionsFrom360Video() throws {
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

    @Test("Smart collections from TimelineSample")
    func smartCollectionsFromTimelineSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "TimelineSample")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }
        #expect(smartCollections.count > 0, "Expected smart collections")

        var foundProjects = false
        var foundAllVideo = false
        var foundFavorites = false

        for collectionElement in smartCollections {
            guard let collection = collectionElement.fcpAsSmartCollection else { continue }

            if collection.name == "Projects" {
                foundProjects = true
                #expect(collection.match == .all, "Projects should match all")
                #expect(collection.matchClips.count == 1, "Projects should have one match-clip")
                if let matchClip = collection.matchClips.first {
                    #expect(matchClip.type == .project, "Match clip type should be project")
                }
            } else if collection.name == "All Video" {
                foundAllVideo = true
                #expect(collection.match == .any, "All Video should match any")
                #expect(collection.matchMedias.count == 2, "All Video should have two match-media rules")
            } else if collection.name == "Favorites" {
                foundFavorites = true
                #expect(collection.match == .all, "Favorites should match all")
                #expect(collection.matchRatings.count == 1, "Favorites should have one match-ratings")
                if let matchRating = collection.matchRatings.first {
                    #expect(matchRating.value == .favorites, "Rating value should be favorites")
                }
            }
        }

        #expect(foundProjects, "Should find Projects smart collection")
        #expect(foundAllVideo, "Should find All Video smart collection")
        #expect(foundFavorites, "Should find Favorites smart collection")
    }

    // MARK: - Match Types Testing

    @Test("Match clip smart collection")
    func matchClipSmartCollection() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

        let projectsCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "Projects"
        }

        let projectsElement = try #require(projectsCollection, "Should find Projects smart collection")
        let collection = try #require(projectsElement.fcpAsSmartCollection, "Should find Projects smart collection")

        #expect(collection.name == "Projects")
        #expect(collection.match == .all)
        #expect(collection.matchClips.count == 1)
        #expect(collection.matchClips[0].type == .project)
        #expect(collection.matchClips[0].rule == .isExactly)
    }

    @Test("Match media smart collection")
    func matchMediaSmartCollection() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

        let allVideoCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "All Video"
        }

        let allVideoElement = try #require(allVideoCollection, "Should find All Video smart collection")
        let collection = try #require(allVideoElement.fcpAsSmartCollection, "Should find All Video smart collection")

        #expect(collection.name == "All Video")
        #expect(collection.match == .any)
        #expect(collection.matchMedias.count == 2)

        let mediaTypes = collection.matchMedias.map { $0.type }
        let hasVideoOnly = mediaTypes.contains(.videoOnly)
        let hasVideoWithAudio = mediaTypes.contains(.videoWithAudio)
        #expect(hasVideoOnly)
        #expect(hasVideoWithAudio)
    }

    @Test("Match ratings smart collection")
    func matchRatingsSmartCollection() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

        let favoritesCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "Favorites"
        }

        let favoritesElement = try #require(favoritesCollection, "Should find Favorites smart collection")
        let collection = try #require(favoritesElement.fcpAsSmartCollection, "Should find Favorites smart collection")

        #expect(collection.name == "Favorites")
        #expect(collection.match == .all)
        #expect(collection.matchRatings.count == 1)
        #expect(collection.matchRatings[0].value == .favorites)
    }

    // MARK: - Multiple Samples Testing

    @Test("Smart collections from multiple samples")
    func smartCollectionsFromMultipleSamples() throws {
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
            let fcpxml = try requireFCPXMLSample(named: sampleName)
            let library = try #require(fcpxml.root.library, "Sample \(sampleName) should have library")
            let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

            #expect(smartCollections.count > 0, "Sample \(sampleName) should have smart collections")

            for collectionElement in smartCollections {
                let collection = try #require(
                    collectionElement.fcpAsSmartCollection,
                    "Smart collection in \(sampleName) should parse correctly"
                )
                let hasName = !collection.name.isEmpty
                #expect(hasName, "Smart collection in \(sampleName) should have name")
            }
        }
    }

    // MARK: - Match Attribute Testing

    @Test("Match all attribute")
    func matchAllAttribute() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

        let projectsCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "Projects"
        }

        let projectsElement = try #require(projectsCollection, "Should find Projects smart collection")
        let collection = try #require(projectsElement.fcpAsSmartCollection, "Should find Projects smart collection")

        #expect(collection.match == .all)
        #expect(projectsElement.stringValue(forAttributeNamed: "match") == "all")
    }

    @Test("Match any attribute")
    func matchAnyAttribute() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

        let allVideoCollection = smartCollections.first { element in
            element.stringValue(forAttributeNamed: "name") == "All Video"
        }

        let allVideoElement = try #require(allVideoCollection, "Should find All Video smart collection")
        let collection = try #require(allVideoElement.fcpAsSmartCollection, "Should find All Video smart collection")

        #expect(collection.match == .any)
        #expect(allVideoElement.stringValue(forAttributeNamed: "match") == "any")
    }

    // MARK: - Library Integration

    @Test("Library smartCollections property")
    func librarySmartCollectionsProperty() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)

        let smartCollections = Array(library.smartCollections)
        #expect(smartCollections.count > 0, "Library should have smart collections")

        for collection in smartCollections {
            let nameNonEmpty = !collection.name.isEmpty
            #expect(nameNonEmpty, "Smart collection should have non-empty name")
        }
    }

    // MARK: - Round-Trip Testing

    @Test("Smart collection round trip")
    func smartCollectionRoundTrip() throws {
        let fcpxml = try requireFCPXMLSample(named: "360Video")
        let library = try #require(fcpxml.root.library)
        let smartCollections = library.element.childElements.filter { $0.name == "smart-collection" }

        let firstCollectionElement = try #require(smartCollections.first, "Should find at least one smart collection")
        let originalCollection = try #require(
            firstCollectionElement.fcpAsSmartCollection,
            "Should find at least one smart collection"
        )

        let recreatedElement = originalCollection.element
        #expect(recreatedElement.name == "smart-collection")
        #expect(recreatedElement.stringValue(forAttributeNamed: "name") == originalCollection.name)
        #expect(recreatedElement.stringValue(forAttributeNamed: "match") == originalCollection.match.rawValue)

        let reparsedCollection = try #require(recreatedElement.fcpAsSmartCollection)
        #expect(reparsedCollection.name == originalCollection.name)
        #expect(reparsedCollection.match == originalCollection.match)
    }
}
