//
//  SmartCollectionTests.swift
//  PipelineNeoTests
//  © 2026 • Licensed under MIT License
//

import XCTest
@testable import PipelineNeo

final class SmartCollectionTests: XCTestCase {
    
    // MARK: - SmartCollectionRule Tests
    
    func testSmartCollectionRuleRawValues() {
        XCTAssertEqual(FinalCutPro.FCPXML.SmartCollectionRule.includes.rawValue, "includes")
        XCTAssertEqual(FinalCutPro.FCPXML.SmartCollectionRule.isExactly.rawValue, "is")
        XCTAssertEqual(FinalCutPro.FCPXML.SmartCollectionRule.isNot.rawValue, "isNot")
        XCTAssertEqual(FinalCutPro.FCPXML.SmartCollectionRule.includesAny.rawValue, "includesAny")
    }
    
    // MARK: - MatchText Tests
    
    func testMatchTextInitialization() {
        let matchText = FinalCutPro.FCPXML.MatchText(
            rule: .includes,
            value: "test",
            scope: "all",
            isEnabled: true
        )
        
        XCTAssertEqual(matchText.rule, .includes)
        XCTAssertEqual(matchText.value, "test")
        XCTAssertEqual(matchText.scope, "all")
        XCTAssertTrue(matchText.isEnabled)
    }
    
    func testMatchTextEquality() {
        let match1 = FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        let match2 = FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        let match3 = FinalCutPro.FCPXML.MatchText(rule: .doesNotInclude, value: "test")
        
        XCTAssertEqual(match1, match2)
        XCTAssertNotEqual(match1, match3)
    }
    
    func testMatchTextCodable() throws {
        let matchText = FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test", scope: "all")
        let encoder = JSONEncoder()
        let data = try encoder.encode(matchText)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.MatchText.self, from: data)
        
        XCTAssertEqual(decoded.rule, matchText.rule)
        XCTAssertEqual(decoded.value, matchText.value)
        XCTAssertEqual(decoded.scope, matchText.scope)
    }
    
    // MARK: - MatchRatings Tests
    
    func testMatchRatingsInitialization() {
        let matchRatings = FinalCutPro.FCPXML.MatchRatings(value: .favorites)
        
        XCTAssertEqual(matchRatings.value, .favorites)
        XCTAssertTrue(matchRatings.isEnabled)
    }
    
    func testMatchRatingsCodable() throws {
        let matchRatings = FinalCutPro.FCPXML.MatchRatings(value: .rejected)
        let encoder = JSONEncoder()
        let data = try encoder.encode(matchRatings)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.MatchRatings.self, from: data)
        
        XCTAssertEqual(decoded.value, .rejected)
    }
    
    // MARK: - MatchMedia Tests
    
    func testMatchMediaInitialization() {
        let matchMedia = FinalCutPro.FCPXML.MatchMedia(rule: .isExactly, type: .videoOnly)
        
        XCTAssertEqual(matchMedia.rule, .isExactly)
        XCTAssertEqual(matchMedia.type, .videoOnly)
        XCTAssertTrue(matchMedia.isEnabled)
    }
    
    func testMatchMediaTypes() {
        XCTAssertEqual(FinalCutPro.FCPXML.MatchMedia.MediaType.videoWithAudio.rawValue, "videoWithAudio")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchMedia.MediaType.videoOnly.rawValue, "videoOnly")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchMedia.MediaType.audioOnly.rawValue, "audioOnly")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchMedia.MediaType.stills.rawValue, "stills")
    }
    
    // MARK: - MatchClip Tests
    
    func testMatchClipInitialization() {
        let matchClip = FinalCutPro.FCPXML.MatchClip(rule: .isExactly, type: .project)
        
        XCTAssertEqual(matchClip.rule, .isExactly)
        XCTAssertEqual(matchClip.type, .project)
    }
    
    func testMatchClipItemTypes() {
        XCTAssertEqual(FinalCutPro.FCPXML.MatchClip.ItemType.audition.rawValue, "audition")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchClip.ItemType.compound.rawValue, "compound")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchClip.ItemType.multicam.rawValue, "multicam")
    }
    
    // MARK: - MatchProperty Tests
    
    func testMatchPropertyInitialization() {
        let matchProperty = FinalCutPro.FCPXML.MatchProperty(
            key: .scene,
            rule: .includes,
            value: "Scene 1"
        )
        
        XCTAssertEqual(matchProperty.key, .scene)
        XCTAssertEqual(matchProperty.value, "Scene 1")
    }
    
    func testMatchPropertyKeys() {
        XCTAssertEqual(FinalCutPro.FCPXML.MatchProperty.PropertyKey.reel.rawValue, "reel")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchProperty.PropertyKey.scene.rawValue, "scene")
        XCTAssertEqual(FinalCutPro.FCPXML.MatchProperty.PropertyKey.take.rawValue, "take")
    }
    
    // MARK: - MatchTime Tests
    
    func testMatchTimeInitialization() {
        let matchTime = FinalCutPro.FCPXML.MatchTime(
            type: .contentCreated,
            rule: .isAfter,
            value: "2024-01-01"
        )
        
        XCTAssertEqual(matchTime.type, .contentCreated)
        XCTAssertEqual(matchTime.rule, .isAfter)
        XCTAssertEqual(matchTime.value, "2024-01-01")
    }
    
    // MARK: - MatchTimeRange Tests
    
    func testMatchTimeRangeInitialization() {
        let matchTimeRange = FinalCutPro.FCPXML.MatchTimeRange(
            type: .dateImported,
            rule: .isInLast,
            value: "30",
            units: .day
        )
        
        XCTAssertEqual(matchTimeRange.type, .dateImported)
        XCTAssertEqual(matchTimeRange.units, .day)
    }
    
    // MARK: - MatchKeywords Tests
    
    func testMatchKeywordsInitialization() {
        let keywordNames = [
            FinalCutPro.FCPXML.KeywordName(value: "keyword1"),
            FinalCutPro.FCPXML.KeywordName(value: "keyword2")
        ]
        let matchKeywords = FinalCutPro.FCPXML.MatchKeywords(
            rule: .includesAny,
            keywordNames: keywordNames
        )
        
        XCTAssertEqual(matchKeywords.keywordNames.count, 2)
        XCTAssertEqual(matchKeywords.rule, .includesAny)
    }
    
    // MARK: - MatchShot Tests
    
    func testMatchShotInitialization() {
        let shotTypes = [
            FinalCutPro.FCPXML.ShotType(value: .closeUp),
            FinalCutPro.FCPXML.ShotType(value: .wideShot)
        ]
        let matchShot = FinalCutPro.FCPXML.MatchShot(
            rule: .includesAny,
            shotTypes: shotTypes
        )
        
        XCTAssertEqual(matchShot.shotTypes.count, 2)
    }
    
    // MARK: - MatchStabilization Tests
    
    func testMatchStabilizationInitialization() {
        let stabilizationTypes = [
            FinalCutPro.FCPXML.StabilizationType(value: .excessiveShake)
        ]
        let matchStab = FinalCutPro.FCPXML.MatchStabilization(
            rule: .includesAny,
            stabilizationTypes: stabilizationTypes
        )
        
        XCTAssertEqual(matchStab.stabilizationTypes.count, 1)
    }
    
    // MARK: - MatchRoles Tests
    
    func testMatchRolesInitialization() {
        let roles = [
            FinalCutPro.FCPXML.Role(name: "Dialogue"),
            FinalCutPro.FCPXML.Role(name: "Music")
        ]
        let matchRoles = FinalCutPro.FCPXML.MatchRoles(
            rule: .includesAny,
            roles: roles
        )
        
        XCTAssertEqual(matchRoles.roles.count, 2)
    }
    
    // MARK: - SmartCollection Tests
    
    func testSmartCollectionInitialization() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(
            name: "Test Collection",
            match: .all
        )
        
        XCTAssertEqual(smartCollection.name, "Test Collection")
        XCTAssertEqual(smartCollection.match, .all)
    }
    
    func testSmartCollectionMatchCriteria() {
        let collectionAny = FinalCutPro.FCPXML.SmartCollection(name: "Any", match: .any)
        let collectionAll = FinalCutPro.FCPXML.SmartCollection(name: "All", match: .all)
        
        XCTAssertEqual(collectionAny.match, .any)
        XCTAssertEqual(collectionAll.match, .all)
    }
    
    func testSmartCollectionMatchTexts() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Test", match: .all)
        
        let matchTexts = [
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test1"),
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test2")
        ]
        
        smartCollection.matchTexts = matchTexts
        
        XCTAssertEqual(smartCollection.matchTexts.count, 2)
        XCTAssertEqual(smartCollection.matchTexts[0].value, "test1")
    }
    
    func testSmartCollectionMatchRatings() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Favorites", match: .all)
        
        let matchRatings = [
            FinalCutPro.FCPXML.MatchRatings(value: .favorites)
        ]
        
        smartCollection.matchRatings = matchRatings
        
        XCTAssertEqual(smartCollection.matchRatings.count, 1)
        XCTAssertEqual(smartCollection.matchRatings[0].value, .favorites)
    }
    
    func testSmartCollectionMatchMedias() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Video", match: .any)
        
        let matchMedias = [
            FinalCutPro.FCPXML.MatchMedia(rule: .isExactly, type: .videoOnly),
            FinalCutPro.FCPXML.MatchMedia(rule: .isExactly, type: .videoWithAudio)
        ]
        
        smartCollection.matchMedias = matchMedias
        
        XCTAssertEqual(smartCollection.matchMedias.count, 2)
    }
    
    func testSmartCollectionFromXML() throws {
        let xmlString = """
        <smart-collection name="Projects" match="all">
            <match-clip rule="is" type="project"/>
        </smart-collection>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let smartCollectionElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let smartCollection = FinalCutPro.FCPXML.SmartCollection(element: smartCollectionElement) else {
            XCTFail("Failed to create SmartCollection from XML")
            return
        }
        
        XCTAssertEqual(smartCollection.name, "Projects")
        XCTAssertEqual(smartCollection.match, .all)
        XCTAssertEqual(smartCollection.matchClips.count, 1)
        XCTAssertEqual(smartCollection.matchClips[0].type, .project)
    }
    
    func testSmartCollectionToXML() {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Test", match: .all)
        smartCollection.matchTexts = [
            FinalCutPro.FCPXML.MatchText(rule: .includes, value: "test")
        ]
        
        XCTAssertEqual(smartCollection.element.name, "smart-collection")
        XCTAssertEqual(smartCollection.element.stringValue(forAttributeNamed: "name"), "Test")
        XCTAssertEqual(smartCollection.element.stringValue(forAttributeNamed: "match"), "all")
        
        let matchTextElements = smartCollection.element.childElements.filter { $0.name == "match-text" }
        XCTAssertEqual(matchTextElements.count, 1)
    }
    
    func testSmartCollectionCodable() throws {
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
        
        XCTAssertEqual(decoded.name, smartCollection.name)
        XCTAssertEqual(decoded.match, smartCollection.match)
        XCTAssertEqual(decoded.matchTexts.count, 1)
        XCTAssertEqual(decoded.matchRatings.count, 1)
    }
    
    func testSmartCollectionRoundTrip() throws {
        let xmlString = """
        <smart-collection name="All Video" match="any">
            <match-media rule="is" type="videoOnly"/>
            <match-media rule="is" type="videoWithAudio"/>
        </smart-collection>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let smartCollectionElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let smartCollection = FinalCutPro.FCPXML.SmartCollection(element: smartCollectionElement) else {
            XCTFail("Failed to create SmartCollection")
            return
        }
        
        XCTAssertEqual(smartCollection.name, "All Video")
        XCTAssertEqual(smartCollection.match, .any)
        XCTAssertEqual(smartCollection.matchMedias.count, 2)
        
        // Verify XML structure is preserved
        let matchMediaElements = smartCollection.element.childElements.filter { $0.name == "match-media" }
        XCTAssertEqual(matchMediaElements.count, 2)
    }

    // MARK: - MatchUsage (FCPXML 1.9+)

    func testMatchUsageInitialization() {
        let matchUsage = FinalCutPro.FCPXML.MatchUsage(rule: .unused, isEnabled: true)
        XCTAssertEqual(matchUsage.rule, .unused)
        XCTAssertTrue(matchUsage.isEnabled)
    }

    func testMatchUsageCodable() throws {
        let matchUsage = FinalCutPro.FCPXML.MatchUsage(rule: .used)
        let data = try JSONEncoder().encode(matchUsage)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchUsage.self, from: data)
        XCTAssertEqual(decoded.rule, .used)
    }

    // MARK: - MatchRepresentation (FCPXML 1.10+)

    func testMatchRepresentationInitialization() {
        let matchRep = FinalCutPro.FCPXML.MatchRepresentation(type: .proxy, rule: .isMissing, isEnabled: true)
        XCTAssertEqual(matchRep.type, .proxy)
        XCTAssertEqual(matchRep.rule, .isMissing)
    }

    func testMatchRepresentationCodable() throws {
        let matchRep = FinalCutPro.FCPXML.MatchRepresentation(type: .optimized, rule: .isAvailable)
        let data = try JSONEncoder().encode(matchRep)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchRepresentation.self, from: data)
        XCTAssertEqual(decoded.type, .optimized)
    }

    // MARK: - MatchMarkers (FCPXML 1.10+)

    func testMatchMarkersInitialization() {
        let matchMarkers = FinalCutPro.FCPXML.MatchMarkers(type: .incomplete, isEnabled: true)
        XCTAssertEqual(matchMarkers.type, .incomplete)
    }

    func testMatchMarkersCodable() throws {
        let matchMarkers = FinalCutPro.FCPXML.MatchMarkers(type: .allTodo)
        let data = try JSONEncoder().encode(matchMarkers)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchMarkers.self, from: data)
        XCTAssertEqual(decoded.type, .allTodo)
    }

    // MARK: - MatchAnalysisType (FCPXML 1.14)

    func testMatchAnalysisTypeInitialization() {
        let matchAnalysis = FinalCutPro.FCPXML.MatchAnalysisType(rule: .isAvailable, value: .transcript, isEnabled: true)
        XCTAssertEqual(matchAnalysis.rule, .isAvailable)
        XCTAssertEqual(matchAnalysis.value, .transcript)
    }

    func testMatchAnalysisTypeCodable() throws {
        let matchAnalysis = FinalCutPro.FCPXML.MatchAnalysisType(rule: .isMissing, value: .visual)
        let data = try JSONEncoder().encode(matchAnalysis)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.MatchAnalysisType.self, from: data)
        XCTAssertEqual(decoded.value, .visual)
    }

    // MARK: - SmartCollection with MatchUsage, MatchRepresentation, MatchMarkers, MatchAnalysisType

    func testSmartCollectionMatchUsageRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Unused", match: .all)
        smartCollection.matchUsages = [FinalCutPro.FCPXML.MatchUsage(rule: .unused)]
        XCTAssertEqual(smartCollection.matchUsages.count, 1)
        XCTAssertEqual(smartCollection.matchUsages[0].rule, .unused)
        let elements = smartCollection.element.childElements.filter { $0.name == "match-usage" }
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements[0].stringValue(forAttributeNamed: "rule"), "unused")
    }

    func testSmartCollectionMatchRepresentationRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Proxy", match: .all)
        smartCollection.matchRepresentations = [
            FinalCutPro.FCPXML.MatchRepresentation(type: .proxy, rule: .isMissing)
        ]
        XCTAssertEqual(smartCollection.matchRepresentations.count, 1)
        XCTAssertEqual(smartCollection.matchRepresentations[0].type, .proxy)
    }

    func testSmartCollectionMatchMarkersRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Todo", match: .all)
        smartCollection.matchMarkers = [FinalCutPro.FCPXML.MatchMarkers(type: .complete)]
        XCTAssertEqual(smartCollection.matchMarkers.count, 1)
        XCTAssertEqual(smartCollection.matchMarkers[0].type, .complete)
    }

    func testSmartCollectionMatchAnalysisTypeRoundTrip() throws {
        let smartCollection = FinalCutPro.FCPXML.SmartCollection(name: "Transcript", match: .all)
        smartCollection.matchAnalysisTypes = [
            FinalCutPro.FCPXML.MatchAnalysisType(rule: .isAvailable, value: .transcript)
        ]
        XCTAssertEqual(smartCollection.matchAnalysisTypes.count, 1)
        XCTAssertEqual(smartCollection.matchAnalysisTypes[0].value, .transcript)
    }

    func testSmartCollectionFromXMLWithMatchUsageAndMatchMarkers() throws {
        let xmlString = """
        <smart-collection name="Mixed" match="all">
            <match-usage enabled="1" rule="used"/>
            <match-markers enabled="1" type="allTodo"/>
        </smart-collection>
        """
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let el = xmlDoc.rootElement() else { XCTFail("No root"); return }
        guard let sc = FinalCutPro.FCPXML.SmartCollection(element: el) else { XCTFail("No SmartCollection"); return }
        XCTAssertEqual(sc.matchUsages.count, 1)
        XCTAssertEqual(sc.matchUsages[0].rule, .used)
        XCTAssertEqual(sc.matchMarkers.count, 1)
        XCTAssertEqual(sc.matchMarkers[0].type, .allTodo)
    }

    // MARK: - Library Integration Tests
    
    func testLibrarySmartCollections() throws {
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
        guard let rootElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let library = FinalCutPro.FCPXML.Library(element: rootElement) else {
            XCTFail("Failed to create Library")
            return
        }
        
        let smartCollections = Array(library.smartCollections)
        XCTAssertEqual(smartCollections.count, 2)
        XCTAssertEqual(smartCollections[0].name, "Projects")
        XCTAssertEqual(smartCollections[1].name, "Favorites")
    }
    
    // MARK: - Event Integration Tests
    
    func testEventSmartCollections() throws {
        let xmlString = """
        <event name="Test Event">
            <smart-collection name="Video Clips" match="any">
                <match-media rule="is" type="videoOnly"/>
            </smart-collection>
        </event>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let rootElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let event = FinalCutPro.FCPXML.Event(element: rootElement) else {
            XCTFail("Failed to create Event")
            return
        }
        
        let smartCollections = Array(event.smartCollections)
        XCTAssertEqual(smartCollections.count, 1)
        XCTAssertEqual(smartCollections[0].name, "Video Clips")
    }
}
