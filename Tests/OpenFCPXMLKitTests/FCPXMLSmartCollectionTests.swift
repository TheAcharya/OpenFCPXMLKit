//
//  FCPXMLSmartCollectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for SmartCollection models and match rules.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Smart collection")
struct FCPXMLSmartCollectionTests {

    // MARK: - SmartCollectionRule Tests

    @Test("SmartCollectionRule raw values")
    func smartCollectionRuleRawValues() {
        #expect(FinalCutPro.FCPXML.SmartCollectionRule.includes.rawValue == "includes")
        #expect(FinalCutPro.FCPXML.SmartCollectionRule.isExactly.rawValue == "is")
        #expect(FinalCutPro.FCPXML.SmartCollectionRule.isNot.rawValue == "isNot")
        #expect(FinalCutPro.FCPXML.SmartCollectionRule.includesAny.rawValue == "includesAny")
    }

    // MARK: - MatchText Tests

    @Test("MatchText initialization")
    func matchTextInitialization() {
        let matchText = FinalCutPro.FCPXML.MatchText(
            rule: .includes,
            value: "test",
            scope: "all",
            isEnabled: true
        )

        #expect(matchText.rule == .includes)
        #expect(matchText.value == "test")
        #expect(matchText.scope == "all")
        #expect(matchText.isEnabled)
    }

    @Test("MatchText equality")
    func matchTextEquality() {
        let match1 = FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        let match2 = FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        let match3 = FinalCutPro.FCPXML.MatchText(rule: .doesNotInclude, value: "test")

        #expect(match1 == match2)
        #expect(match1 != match3)
    }

    @Test("MatchText Codable round-trip")
    func matchTextCodable() throws {
        let matchText = FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test", scope: "all")
        let encoder = JSONEncoder()
        let data = try encoder.encode(matchText)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.MatchText.self, from: data)

        #expect(decoded.rule == matchText.rule)
        #expect(decoded.value == matchText.value)
        #expect(decoded.scope == matchText.scope)
    }

    // MARK: - MatchRatings Tests

    @Test("MatchRatings initialization")
    func matchRatingsInitialization() {
        let matchRatings = FinalCutPro.FCPXML.MatchRatings(value: .favorites)

        #expect(matchRatings.value == .favorites)
        #expect(matchRatings.isEnabled)
    }

    @Test("MatchRatings Codable round-trip")
    func matchRatingsCodable() throws {
        let matchRatings = FinalCutPro.FCPXML.MatchRatings(value: .rejected)
        let encoder = JSONEncoder()
        let data = try encoder.encode(matchRatings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.MatchRatings.self, from: data)

        #expect(decoded.value == .rejected)
    }

    // MARK: - MatchMedia Tests

    @Test("MatchMedia initialization")
    func matchMediaInitialization() {
        let matchMedia = FinalCutPro.FCPXML.MatchMedia(rule: .isExactly, type: .videoOnly)

        #expect(matchMedia.rule == .isExactly)
        #expect(matchMedia.type == .videoOnly)
        #expect(matchMedia.isEnabled)
    }

    @Test("MatchMedia media type raw values")
    func matchMediaTypes() {
        #expect(FinalCutPro.FCPXML.MatchMedia.MediaType.videoWithAudio.rawValue == "videoWithAudio")
        #expect(FinalCutPro.FCPXML.MatchMedia.MediaType.videoOnly.rawValue == "videoOnly")
        #expect(FinalCutPro.FCPXML.MatchMedia.MediaType.audioOnly.rawValue == "audioOnly")
        #expect(FinalCutPro.FCPXML.MatchMedia.MediaType.stills.rawValue == "stills")
    }

    // MARK: - MatchClip Tests

    @Test("MatchClip initialization")
    func matchClipInitialization() {
        let matchClip = FinalCutPro.FCPXML.MatchClip(rule: .isExactly, type: .project)

        #expect(matchClip.rule == .isExactly)
        #expect(matchClip.type == .project)
    }

    @Test("MatchClip item type raw values")
    func matchClipItemTypes() {
        #expect(FinalCutPro.FCPXML.MatchClip.ItemType.audition.rawValue == "audition")
        #expect(FinalCutPro.FCPXML.MatchClip.ItemType.compound.rawValue == "compound")
        #expect(FinalCutPro.FCPXML.MatchClip.ItemType.multicam.rawValue == "multicam")
    }

    // MARK: - MatchProperty Tests

    @Test("MatchProperty initialization")
    func matchPropertyInitialization() {
        let matchProperty = FinalCutPro.FCPXML.MatchProperty(
            key: .scene,
            rule: .includes,
            value: "Scene 1"
        )

        #expect(matchProperty.key == .scene)
        #expect(matchProperty.value == "Scene 1")
    }

    @Test("MatchProperty key raw values")
    func matchPropertyKeys() {
        #expect(FinalCutPro.FCPXML.MatchProperty.PropertyKey.reel.rawValue == "reel")
        #expect(FinalCutPro.FCPXML.MatchProperty.PropertyKey.scene.rawValue == "scene")
        #expect(FinalCutPro.FCPXML.MatchProperty.PropertyKey.take.rawValue == "take")
    }

    // MARK: - MatchTime Tests

    @Test("MatchTime initialization")
    func matchTimeInitialization() {
        let matchTime = FinalCutPro.FCPXML.MatchTime(
            type: .contentCreated,
            rule: .isAfter,
            value: "2024-01-01"
        )

        #expect(matchTime.type == .contentCreated)
        #expect(matchTime.rule == .isAfter)
        #expect(matchTime.value == "2024-01-01")
    }

    // MARK: - MatchTimeRange Tests

    @Test("MatchTimeRange initialization")
    func matchTimeRangeInitialization() {
        let matchTimeRange = FinalCutPro.FCPXML.MatchTimeRange(
            type: .dateImported,
            rule: .isInLast,
            value: "30",
            units: .day
        )

        #expect(matchTimeRange.type == .dateImported)
        #expect(matchTimeRange.units == .day)
    }

    // MARK: - MatchKeywords Tests

    @Test("MatchKeywords initialization")
    func matchKeywordsInitialization() {
        let keywordNames = [
            FinalCutPro.FCPXML.KeywordName(value: "keyword1"),
            FinalCutPro.FCPXML.KeywordName(value: "keyword2")
        ]
        let matchKeywords = FinalCutPro.FCPXML.MatchKeywords(
            rule: .includesAny,
            keywordNames: keywordNames
        )

        #expect(matchKeywords.keywordNames.count == 2)
        #expect(matchKeywords.rule == .includesAny)
    }

    // MARK: - MatchShot Tests

    @Test("MatchShot initialization")
    func matchShotInitialization() {
        let shotTypes = [
            FinalCutPro.FCPXML.ShotType(value: .closeUp),
            FinalCutPro.FCPXML.ShotType(value: .wideShot)
        ]
        let matchShot = FinalCutPro.FCPXML.MatchShot(
            rule: .includesAny,
            shotTypes: shotTypes
        )

        #expect(matchShot.shotTypes.count == 2)
    }

    // MARK: - MatchStabilization Tests

    @Test("MatchStabilization initialization")
    func matchStabilizationInitialization() {
        let stabilizationTypes = [
            FinalCutPro.FCPXML.StabilizationType(value: .excessiveShake)
        ]
        let matchStab = FinalCutPro.FCPXML.MatchStabilization(
            rule: .includesAny,
            stabilizationTypes: stabilizationTypes
        )

        #expect(matchStab.stabilizationTypes.count == 1)
    }

    // MARK: - MatchRoles Tests

    @Test("MatchRoles initialization")
    func matchRolesInitialization() {
        let roles = [
            FinalCutPro.FCPXML.Role(name: "Dialogue"),
            FinalCutPro.FCPXML.Role(name: "Music")
        ]
        let matchRoles = FinalCutPro.FCPXML.MatchRoles(
            rule: .includesAny,
            roles: roles
        )

        #expect(matchRoles.roles.count == 2)
    }

    // MARK: - SmartCollection Tests

    @Test("SmartCollection initialization")
    func smartCollectionInitialization() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(
            name: "Test Collection",
            match: .all
        )

        #expect(smartCollection.name == "Test Collection")
        #expect(smartCollection.match == .all)
    }

    @Test("SmartCollection match criteria")
    func smartCollectionMatchCriteria() {
        let collectionAny = FinalCutPro.FCPXML.SmartCollection(name: "Any", match: .any)
        let collectionAll = FinalCutPro.FCPXML.SmartCollection(name: "All", match: .all)

        #expect(collectionAny.match == .any)
        #expect(collectionAll.match == .all)
    }

    @Test("SmartCollection matchTexts")
    func smartCollectionMatchTexts() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Test", match: .all)

        let matchTexts = [
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test1"),
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test2")
        ]

        smartCollection.matchTexts = matchTexts

        #expect(smartCollection.matchTexts.count == 2)
        #expect(smartCollection.matchTexts[0].value == "test1")
    }

    @Test("SmartCollection matchRatings")
    func smartCollectionMatchRatings() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Favorites", match: .all)

        let matchRatings = [
            FinalCutPro.FCPXML.MatchRatings(value: .favorites)
        ]

        smartCollection.matchRatings = matchRatings

        #expect(smartCollection.matchRatings.count == 1)
        #expect(smartCollection.matchRatings[0].value == .favorites)
    }

    @Test("SmartCollection matchMedias")
    func smartCollectionMatchMedias() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Video", match: .any)

        let matchMedias = [
            FinalCutPro.FCPXML.MatchMedia(rule: .isExactly, type: .videoOnly),
            FinalCutPro.FCPXML.MatchMedia(rule: .isExactly, type: .videoWithAudio)
        ]

        smartCollection.matchMedias = matchMedias

        #expect(smartCollection.matchMedias.count == 2)
    }

    @Test("SmartCollection from XML")
    func smartCollectionFromXML() throws {
        let xmlString = """
        <smart-collection name="Projects" match="all">
            <match-clip rule="is" type="project"/>
        </smart-collection>
        """

        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let smartCollectionElement = try #require(xmlDoc.rootElement())
        let smartCollection = try #require(
            FinalCutPro.FCPXML.SmartCollection(element: smartCollectionElement)
        )

        #expect(smartCollection.name == "Projects")
        #expect(smartCollection.match == .all)
        #expect(smartCollection.matchClips.count == 1)
        #expect(smartCollection.matchClips[0].type == .project)
    }

    @Test("SmartCollection to XML")
    func smartCollectionToXML() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Test", match: .all)
        smartCollection.matchTexts = [
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        ]

        #expect(smartCollection.element.name == "smart-collection")
        #expect(smartCollection.element.stringValue(forAttributeNamed: "name") == "Test")
        #expect(smartCollection.element.stringValue(forAttributeNamed: "match") == "all")

        let matchTextElements = smartCollection.element.childElements.filter { $0.name == "match-text" }
        #expect(matchTextElements.count == 1)
    }

    @Test("SmartCollection Codable round-trip")
    func smartCollectionCodable() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Test", match: .all)
        smartCollection.matchTexts = [
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        ]
        smartCollection.matchRatings = [
            FinalCutPro.FCPXML.MatchRatings(value: .favorites)
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(smartCollection)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.SmartCollection.self, from: data)

        #expect(decoded.name == smartCollection.name)
        #expect(decoded.match == smartCollection.match)
        #expect(decoded.matchTexts.count == 1)
        #expect(decoded.matchRatings.count == 1)
    }

    @Test("SmartCollection XML round-trip")
    func smartCollectionRoundTrip() throws {
        let xmlString = """
        <smart-collection name="All Video" match="any">
            <match-media rule="is" type="videoOnly"/>
            <match-media rule="is" type="videoWithAudio"/>
        </smart-collection>
        """

        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let smartCollectionElement = try #require(xmlDoc.rootElement())
        let smartCollection = try #require(
            FinalCutPro.FCPXML.SmartCollection(element: smartCollectionElement)
        )

        #expect(smartCollection.name == "All Video")
        #expect(smartCollection.match == .any)
        #expect(smartCollection.matchMedias.count == 2)

        // Verify XML structure is preserved
        let matchMediaElements = smartCollection.element.childElements.filter { $0.name == "match-media" }
        #expect(matchMediaElements.count == 2)
    }

    // MARK: - MatchUsage (FCPXML 1.9+)

    @Test("MatchUsage initialization")
    func matchUsageInitialization() {
        let matchUsage = FinalCutPro.FCPXML.MatchUsage(rule: .unused, isEnabled: true)
        #expect(matchUsage.rule == .unused)
        #expect(matchUsage.isEnabled)
    }

    @Test("MatchUsage Codable round-trip")
    func matchUsageCodable() throws {
        let matchUsage = FinalCutPro.FCPXML.MatchUsage(rule: .used)
        let data = try JSONEncoder().encode(matchUsage)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchUsage.self, from: data)
        #expect(decoded.rule == .used)
    }

    // MARK: - MatchRepresentation (FCPXML 1.10+)

    @Test("MatchRepresentation initialization")
    func matchRepresentationInitialization() {
        let matchRep = FinalCutPro.FCPXML.MatchRepresentation(type: .proxy, rule: .isMissing, isEnabled: true)
        #expect(matchRep.type == .proxy)
        #expect(matchRep.rule == .isMissing)
    }

    @Test("MatchRepresentation Codable round-trip")
    func matchRepresentationCodable() throws {
        let matchRep = FinalCutPro.FCPXML.MatchRepresentation(type: .optimized, rule: .isAvailable)
        let data = try JSONEncoder().encode(matchRep)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchRepresentation.self, from: data)
        #expect(decoded.type == .optimized)
    }

    // MARK: - MatchMarkers (FCPXML 1.10+)

    @Test("MatchMarkers initialization")
    func matchMarkersInitialization() {
        let matchMarkers = FinalCutPro.FCPXML.MatchMarkers(type: .incomplete, isEnabled: true)
        #expect(matchMarkers.type == .incomplete)
    }

    @Test("MatchMarkers Codable round-trip")
    func matchMarkersCodable() throws {
        let matchMarkers = FinalCutPro.FCPXML.MatchMarkers(type: .allTodo)
        let data = try JSONEncoder().encode(matchMarkers)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchMarkers.self, from: data)
        #expect(decoded.type == .allTodo)
    }

    // MARK: - MatchAnalysisType (FCPXML 1.14)

    @Test("MatchAnalysisType initialization")
    func matchAnalysisTypeInitialization() {
        let matchAnalysis = FinalCutPro.FCPXML.MatchAnalysisType(rule: .isAvailable, value: .transcript, isEnabled: true)
        #expect(matchAnalysis.rule == .isAvailable)
        #expect(matchAnalysis.value == .transcript)
    }

    @Test("MatchAnalysisType Codable round-trip")
    func matchAnalysisTypeCodable() throws {
        let matchAnalysis = FinalCutPro.FCPXML.MatchAnalysisType(rule: .isMissing, value: .visual)
        let data = try JSONEncoder().encode(matchAnalysis)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchAnalysisType.self, from: data)
        #expect(decoded.value == .visual)
    }

    // MARK: - SmartCollection with MatchUsage, MatchRepresentation, MatchMarkers, MatchAnalysisType

    @Test("SmartCollection MatchUsage round-trip")
    func smartCollectionMatchUsageRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Unused", match: .all)
        smartCollection.matchUsages = [FinalCutPro.FCPXML.MatchUsage(rule: .unused)]
        #expect(smartCollection.matchUsages.count == 1)
        #expect(smartCollection.matchUsages[0].rule == .unused)
        let elements = smartCollection.element.childElements.filter { $0.name == "match-usage" }
        #expect(elements.count == 1)
        #expect(elements[0].stringValue(forAttributeNamed: "rule") == "unused")
    }

    @Test("SmartCollection MatchRepresentation round-trip")
    func smartCollectionMatchRepresentationRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Proxy", match: .all)
        smartCollection.matchRepresentations = [
            FinalCutPro.FCPXML.MatchRepresentation(type: .proxy, rule: .isMissing)
        ]
        #expect(smartCollection.matchRepresentations.count == 1)
        #expect(smartCollection.matchRepresentations[0].type == .proxy)
    }

    @Test("SmartCollection MatchMarkers round-trip")
    func smartCollectionMatchMarkersRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Todo", match: .all)
        smartCollection.matchMarkers = [FinalCutPro.FCPXML.MatchMarkers(type: .complete)]
        #expect(smartCollection.matchMarkers.count == 1)
        #expect(smartCollection.matchMarkers[0].type == .complete)
    }

    @Test("SmartCollection MatchAnalysisType round-trip")
    func smartCollectionMatchAnalysisTypeRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Transcript", match: .all)
        smartCollection.matchAnalysisTypes = [
            FinalCutPro.FCPXML.MatchAnalysisType(rule: .isAvailable, value: .transcript)
        ]
        #expect(smartCollection.matchAnalysisTypes.count == 1)
        #expect(smartCollection.matchAnalysisTypes[0].value == .transcript)
    }

    @Test("SmartCollection from XML with MatchUsage and MatchMarkers")
    func smartCollectionFromXMLWithMatchUsageAndMatchMarkers() throws {
        let xmlString = """
        <smart-collection name="Mixed" match="all">
            <match-usage enabled="1" rule="used"/>
            <match-markers enabled="1" type="allTodo"/>
        </smart-collection>
        """
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let el = try #require(xmlDoc.rootElement())
        let sc = try #require(FinalCutPro.FCPXML.SmartCollection(element: el))
        #expect(sc.matchUsages.count == 1)
        #expect(sc.matchUsages[0].rule == .used)
        #expect(sc.matchMarkers.count == 1)
        #expect(sc.matchMarkers[0].type == .allTodo)
    }

    // MARK: - Library Integration Tests

    @Test("Library smartCollections")
    func librarySmartCollections() throws {
        let xmlString = """
        <library>
            <smart-collection name="Projects" match="all">
                <match-clip rule="is" type="project"/>
            </smart-collection>
            <smart-collection name="Favorites" match="all">
                <match-ratings value="favorites"/>
            </smart-collection>
        </library>
        """

        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let rootElement = try #require(xmlDoc.rootElement())
        let library = try #require(FinalCutPro.FCPXML.Library(element: rootElement))

        let smartCollections = Array(library.smartCollections)
        #expect(smartCollections.count == 2)
        #expect(smartCollections[0].name == "Projects")
        #expect(smartCollections[1].name == "Favorites")
    }

    // MARK: - Event Integration Tests

    @Test("Event smartCollections")
    func eventSmartCollections() throws {
        let xmlString = """
        <event name="Test Event">
            <smart-collection name="Video Clips" match="any">
                <match-media rule="is" type="videoOnly"/>
            </smart-collection>
        </event>
        """

        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let rootElement = try #require(xmlDoc.rootElement())
        let event = try #require(FinalCutPro.FCPXML.Event(element: rootElement))

        let smartCollections = Array(event.smartCollections)
        #expect(smartCollections.count == 1)
        #expect(smartCollections[0].name == "Video Clips")
    }
}
