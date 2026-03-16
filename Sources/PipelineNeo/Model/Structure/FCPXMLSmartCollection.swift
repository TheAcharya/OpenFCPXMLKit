//
//  FCPXMLSmartCollection.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Smart collection model for organizing clips by matching criteria.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// A smart collection that organizes clips by matching criteria.
    ///
    /// Smart collections use match criteria to automatically organize clips based on
    /// properties such as text, ratings, media type, keywords, roles, and more.
    ///
    /// - SeeAlso: [FCPXML Smart Collections Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/smart-collection
    ///   )
    public struct SmartCollection: FCPXMLElement, Equatable, Hashable, Codable {
        public let element: any PNXMLElement

        public let elementType: ElementType = .smartCollection

        public static let supportedElementTypes: Set<ElementType> = [.smartCollection]

        public init() {
            element = PNXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }

        public init?(element: any PNXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
        
        // MARK: - Codable
        
        private enum CodingKeys: String, CodingKey {
            case matchTexts = "match-text"
            case matchRatings = "match-ratings"
            case matchMedias = "match-media"
            case matchClips = "match-clip"
            case matchStabilizations = "match-stabilization"
            case matchKeywords = "match-keywords"
            case matchShots = "match-shot"
            case matchProperties = "match-property"
            case matchTimes = "match-time"
            case matchTimeRanges = "match-timeRange"
            case matchRoles = "match-roles"
            case matchUsages = "match-usage"
            case matchRepresentations = "match-representation"
            case matchMarkers = "match-markers"
            case matchAnalysisTypes = "match-analysis-type"
            case name, match
        }
        
        /// Encodes the smart collection to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(match, forKey: .match)
            try container.encodeIfPresent(matchTexts.isEmpty ? nil : matchTexts, forKey: .matchTexts)
            try container.encodeIfPresent(matchRatings.isEmpty ? nil : matchRatings, forKey: .matchRatings)
            try container.encodeIfPresent(matchMedias.isEmpty ? nil : matchMedias, forKey: .matchMedias)
            try container.encodeIfPresent(matchClips.isEmpty ? nil : matchClips, forKey: .matchClips)
            try container.encodeIfPresent(matchStabilizations.isEmpty ? nil : matchStabilizations, forKey: .matchStabilizations)
            try container.encodeIfPresent(matchKeywords.isEmpty ? nil : matchKeywords, forKey: .matchKeywords)
            try container.encodeIfPresent(matchShots.isEmpty ? nil : matchShots, forKey: .matchShots)
            try container.encodeIfPresent(matchProperties.isEmpty ? nil : matchProperties, forKey: .matchProperties)
            try container.encodeIfPresent(matchTimes.isEmpty ? nil : matchTimes, forKey: .matchTimes)
            try container.encodeIfPresent(matchTimeRanges.isEmpty ? nil : matchTimeRanges, forKey: .matchTimeRanges)
            try container.encodeIfPresent(matchRoles.isEmpty ? nil : matchRoles, forKey: .matchRoles)
            try container.encodeIfPresent(matchUsages.isEmpty ? nil : matchUsages, forKey: .matchUsages)
            try container.encodeIfPresent(matchRepresentations.isEmpty ? nil : matchRepresentations, forKey: .matchRepresentations)
            try container.encodeIfPresent(matchMarkers.isEmpty ? nil : matchMarkers, forKey: .matchMarkers)
            try container.encodeIfPresent(matchAnalysisTypes.isEmpty ? nil : matchAnalysisTypes, forKey: .matchAnalysisTypes)
        }
        
        /// Creates a smart collection from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let match = try container.decode(MatchCriteria.self, forKey: .match)
            
            self.init(name: name, match: match)
            
            matchTexts = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchText].self, forKey: .matchTexts) ?? []
            matchRatings = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchRatings].self, forKey: .matchRatings) ?? []
            matchMedias = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchMedia].self, forKey: .matchMedias) ?? []
            matchClips = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchClip].self, forKey: .matchClips) ?? []
            matchStabilizations = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchStabilization].self, forKey: .matchStabilizations) ?? []
            matchKeywords = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchKeywords].self, forKey: .matchKeywords) ?? []
            matchShots = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchShot].self, forKey: .matchShots) ?? []
            matchProperties = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchProperty].self, forKey: .matchProperties) ?? []
            matchTimes = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchTime].self, forKey: .matchTimes) ?? []
            matchTimeRanges = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchTimeRange].self, forKey: .matchTimeRanges) ?? []
            matchRoles = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchRoles].self, forKey: .matchRoles) ?? []
            matchUsages = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchUsage].self, forKey: .matchUsages) ?? []
            matchRepresentations = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchRepresentation].self, forKey: .matchRepresentations) ?? []
            matchMarkers = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchMarkers].self, forKey: .matchMarkers) ?? []
            matchAnalysisTypes = try container.decodeIfPresent([FinalCutPro.FCPXML.MatchAnalysisType].self, forKey: .matchAnalysisTypes) ?? []
        }
    }
}

// MARK: - Match Criteria

extension FinalCutPro.FCPXML.SmartCollection {
    /// Specifies the possible match criteria modes for a smart collection.
    public enum MatchCriteria: String, Sendable, Equatable, Hashable, Codable {
        /// Match any of the criteria (OR logic).
        case any
        
        /// Match all of the criteria (AND logic).
        case all
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.SmartCollection {
    public enum Attributes: String {
        case name
        case match
    }
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.SmartCollection {
    /// The name of the smart collection.
    public var name: String {
        get {
            element.stringValue(forAttributeNamed: Attributes.name.rawValue) ?? ""
        }
        nonmutating set {
            element.addAttribute(name: Attributes.name.rawValue, value: newValue)
        }
    }
    
    /// The match criteria to apply to the smart collection.
    public var match: MatchCriteria {
        get {
            guard let matchString = element.stringValue(forAttributeNamed: Attributes.match.rawValue),
                  let matchCriteria = MatchCriteria(rawValue: matchString) else {
                return .all
            }
            return matchCriteria
        }
        nonmutating set {
            element.addAttribute(name: Attributes.match.rawValue, value: newValue.rawValue)
        }
    }
}

// MARK: - Match Criteria Properties

extension FinalCutPro.FCPXML.SmartCollection {
    /// The text matches of the smart collection.
    public var matchTexts: [FinalCutPro.FCPXML.MatchText] {
        get {
            element.childElements
                .filter { $0.name == "match-text" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchText? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString),
                          let value = matchElement.stringValue(forAttributeNamed: "value") else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    let scope = matchElement.stringValue(forAttributeNamed: "scope")
                    return FinalCutPro.FCPXML.MatchText(rule: rule, value: value, scope: scope, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-text elements
            element.removeChildren { $0.name == "match-text" }
            
            // Add new match-text elements
            for matchText in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-text")
                matchElement.addAttribute(name: "enabled", value: matchText.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchText.rule.rawValue)
                matchElement.addAttribute(name: "value", value: matchText.value)
                if let scope = matchText.scope {
                    matchElement.addAttribute(name: "scope", value: scope)
                }
                element.addChild(matchElement)
            }
        }
    }
    
    /// The ratings matches of the smart collection.
    public var matchRatings: [FinalCutPro.FCPXML.MatchRatings] {
        get {
            element.childElements
                .filter { $0.name == "match-ratings" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchRatings? in
                    guard let valueString = matchElement.stringValue(forAttributeNamed: "value"),
                          let value = FinalCutPro.FCPXML.MatchRatings.Value(rawValue: valueString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchRatings(value: value, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-ratings elements
            element.removeChildren { $0.name == "match-ratings" }
            
            // Add new match-ratings elements
            for matchRating in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-ratings")
                matchElement.addAttribute(name: "enabled", value: matchRating.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "value", value: matchRating.value.rawValue)
                element.addChild(matchElement)
            }
        }
    }
    
    /// The media matches of the smart collection.
    public var matchMedias: [FinalCutPro.FCPXML.MatchMedia] {
        get {
            element.childElements
                .filter { $0.name == "match-media" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchMedia? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString),
                          let typeString = matchElement.stringValue(forAttributeNamed: "type"),
                          let type = FinalCutPro.FCPXML.MatchMedia.MediaType(rawValue: typeString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchMedia(rule: rule, type: type, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-media elements
            element.removeChildren { $0.name == "match-media" }
            
            // Add new match-media elements
            for matchMedia in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-media")
                matchElement.addAttribute(name: "enabled", value: matchMedia.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchMedia.rule.rawValue)
                matchElement.addAttribute(name: "type", value: matchMedia.type.rawValue)
                element.addChild(matchElement)
            }
        }
    }
    
    /// The clip matches of the smart collection.
    public var matchClips: [FinalCutPro.FCPXML.MatchClip] {
        get {
            element.childElements
                .filter { $0.name == "match-clip" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchClip? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString),
                          let typeString = matchElement.stringValue(forAttributeNamed: "type"),
                          let type = FinalCutPro.FCPXML.MatchClip.ItemType(rawValue: typeString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchClip(rule: rule, type: type, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-clip elements
            element.removeChildren { $0.name == "match-clip" }
            
            // Add new match-clip elements
            for matchClip in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-clip")
                matchElement.addAttribute(name: "enabled", value: matchClip.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchClip.rule.rawValue)
                matchElement.addAttribute(name: "type", value: matchClip.type.rawValue)
                element.addChild(matchElement)
            }
        }
    }
    
    /// The stabilization type matches of the smart collection.
    public var matchStabilizations: [FinalCutPro.FCPXML.MatchStabilization] {
        get {
            element.childElements
                .filter { $0.name == "match-stabilization" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchStabilization? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    
                    let stabilizationTypes = Array(matchElement.childElements
                        .filter { $0.name == "stabilization-type" }
                        .compactMap { stabElement -> FinalCutPro.FCPXML.StabilizationType? in
                            guard let valueString = stabElement.stringValue(forAttributeNamed: "value"),
                                  let value = FinalCutPro.FCPXML.StabilizationType.Value(rawValue: valueString) else {
                                return nil
                            }
                            return FinalCutPro.FCPXML.StabilizationType(value: value)
                        })
                    
                    return FinalCutPro.FCPXML.MatchStabilization(rule: rule, stabilizationTypes: stabilizationTypes, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-stabilization elements
            element.removeChildren { $0.name == "match-stabilization" }
            
            // Add new match-stabilization elements
            for matchStab in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-stabilization")
                matchElement.addAttribute(name: "enabled", value: matchStab.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchStab.rule.rawValue)
                
                for stabType in matchStab.stabilizationTypes {
                    let stabElement = PNXMLDefaultFactory().makeElement(name: "stabilization-type")
                    stabElement.addAttribute(name: "value", value: stabType.value.rawValue)
                    matchElement.addChild(stabElement)
                }
                
                element.addChild(matchElement)
            }
        }
    }
    
    /// The keywords matches of the smart collection.
    public var matchKeywords: [FinalCutPro.FCPXML.MatchKeywords] {
        get {
            element.childElements
                .filter { $0.name == "match-keywords" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchKeywords? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    
                    let keywordNames = Array(matchElement.childElements
                        .filter { $0.name == "keyword-name" }
                        .compactMap { keywordElement -> FinalCutPro.FCPXML.KeywordName? in
                            guard let value = keywordElement.stringValue(forAttributeNamed: "value") else {
                                return nil
                            }
                            return FinalCutPro.FCPXML.KeywordName(value: value)
                        })
                    
                    return FinalCutPro.FCPXML.MatchKeywords(rule: rule, keywordNames: keywordNames, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-keywords elements
            element.removeChildren { $0.name == "match-keywords" }
            
            // Add new match-keywords elements
            for matchKeywords in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-keywords")
                matchElement.addAttribute(name: "enabled", value: matchKeywords.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchKeywords.rule.rawValue)
                
                for keywordName in matchKeywords.keywordNames {
                    let keywordElement = PNXMLDefaultFactory().makeElement(name: "keyword-name")
                    keywordElement.addAttribute(name: "value", value: keywordName.value)
                    matchElement.addChild(keywordElement)
                }
                
                element.addChild(matchElement)
            }
        }
    }
    
    /// The shot type matches of the smart collection.
    public var matchShots: [FinalCutPro.FCPXML.MatchShot] {
        get {
            element.childElements
                .filter { $0.name == "match-shot" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchShot? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    
                    let shotTypes = Array(matchElement.childElements
                        .filter { $0.name == "shot-type" }
                        .compactMap { shotElement -> FinalCutPro.FCPXML.ShotType? in
                            guard let valueString = shotElement.stringValue(forAttributeNamed: "value"),
                                  let value = FinalCutPro.FCPXML.ShotType.Value(rawValue: valueString) else {
                                return nil
                            }
                            return FinalCutPro.FCPXML.ShotType(value: value)
                        })
                    
                    return FinalCutPro.FCPXML.MatchShot(rule: rule, shotTypes: shotTypes, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-shot elements
            element.removeChildren { $0.name == "match-shot" }
            
            // Add new match-shot elements
            for matchShot in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-shot")
                matchElement.addAttribute(name: "enabled", value: matchShot.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchShot.rule.rawValue)
                
                for shotType in matchShot.shotTypes {
                    let shotElement = PNXMLDefaultFactory().makeElement(name: "shot-type")
                    shotElement.addAttribute(name: "value", value: shotType.value.rawValue)
                    matchElement.addChild(shotElement)
                }
                
                element.addChild(matchElement)
            }
        }
    }
    
    /// The property matches of the smart collection.
    public var matchProperties: [FinalCutPro.FCPXML.MatchProperty] {
        get {
            element.childElements
                .filter { $0.name == "match-property" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchProperty? in
                    guard let keyString = matchElement.stringValue(forAttributeNamed: "key"),
                          let key = FinalCutPro.FCPXML.MatchProperty.PropertyKey(rawValue: keyString),
                          let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString),
                          let value = matchElement.stringValue(forAttributeNamed: "value") else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchProperty(key: key, rule: rule, value: value, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-property elements
            element.removeChildren { $0.name == "match-property" }
            
            // Add new match-property elements
            for matchProperty in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-property")
                matchElement.addAttribute(name: "enabled", value: matchProperty.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "key", value: matchProperty.key.rawValue)
                matchElement.addAttribute(name: "rule", value: matchProperty.rule.rawValue)
                matchElement.addAttribute(name: "value", value: matchProperty.value)
                element.addChild(matchElement)
            }
        }
    }
    
    /// The time matches of the smart collection.
    public var matchTimes: [FinalCutPro.FCPXML.MatchTime] {
        get {
            element.childElements
                .filter { $0.name == "match-time" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchTime? in
                    guard let typeString = matchElement.stringValue(forAttributeNamed: "type"),
                          let type = FinalCutPro.FCPXML.MatchTime.TimeMatchType(rawValue: typeString),
                          let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString),
                          let value = matchElement.stringValue(forAttributeNamed: "value") else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchTime(type: type, rule: rule, value: value, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-time elements
            element.removeChildren { $0.name == "match-time" }
            
            // Add new match-time elements
            for matchTime in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-time")
                matchElement.addAttribute(name: "enabled", value: matchTime.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "type", value: matchTime.type.rawValue)
                matchElement.addAttribute(name: "rule", value: matchTime.rule.rawValue)
                matchElement.addAttribute(name: "value", value: matchTime.value)
                element.addChild(matchElement)
            }
        }
    }
    
    /// The time range matches of the smart collection.
    public var matchTimeRanges: [FinalCutPro.FCPXML.MatchTimeRange] {
        get {
            element.childElements
                .filter { $0.name == "match-timeRange" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchTimeRange? in
                    guard let typeString = matchElement.stringValue(forAttributeNamed: "type"),
                          let type = FinalCutPro.FCPXML.MatchTime.TimeMatchType(rawValue: typeString),
                          let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString),
                          let value = matchElement.stringValue(forAttributeNamed: "value") else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    let unitsString = matchElement.stringValue(forAttributeNamed: "units")
                    let units = unitsString.flatMap { FinalCutPro.FCPXML.MatchTimeRange.Unit(rawValue: $0) }
                    return FinalCutPro.FCPXML.MatchTimeRange(type: type, rule: rule, value: value, units: units, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-timeRange elements
            element.removeChildren { $0.name == "match-timeRange" }
            
            // Add new match-timeRange elements
            for matchTimeRange in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-timeRange")
                matchElement.addAttribute(name: "enabled", value: matchTimeRange.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "type", value: matchTimeRange.type.rawValue)
                matchElement.addAttribute(name: "rule", value: matchTimeRange.rule.rawValue)
                matchElement.addAttribute(name: "value", value: matchTimeRange.value)
                if let units = matchTimeRange.units {
                    matchElement.addAttribute(name: "units", value: units.rawValue)
                }
                element.addChild(matchElement)
            }
        }
    }
    
    /// The role matches of the smart collection.
    public var matchRoles: [FinalCutPro.FCPXML.MatchRoles] {
        get {
            element.childElements
                .filter { $0.name == "match-roles" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchRoles? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.SmartCollectionRule(rawValue: ruleString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    
                    let roles = Array(matchElement.childElements
                        .filter { $0.name == "role" }
                        .compactMap { roleElement -> FinalCutPro.FCPXML.Role? in
                            guard let name = roleElement.stringValue(forAttributeNamed: "name") else {
                                return nil
                            }
                            return FinalCutPro.FCPXML.Role(name: name)
                        })
                    
                    return FinalCutPro.FCPXML.MatchRoles(rule: rule, roles: roles, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            // Remove existing match-roles elements
            element.removeChildren { $0.name == "match-roles" }
            
            // Add new match-roles elements
            for matchRoles in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-roles")
                matchElement.addAttribute(name: "enabled", value: matchRoles.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchRoles.rule.rawValue)
                
                for role in matchRoles.roles {
                    let roleElement = PNXMLDefaultFactory().makeElement(name: "role")
                    roleElement.addAttribute(name: "name", value: role.name)
                    matchElement.addChild(roleElement)
                }
                
                element.addChild(matchElement)
            }
        }
    }

    /// The usage matches of the smart collection (FCPXML 1.9+).
    public var matchUsages: [FinalCutPro.FCPXML.MatchUsage] {
        get {
            element.childElements
                .filter { $0.name == "match-usage" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchUsage? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.MatchUsage.Rule(rawValue: ruleString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchUsage(rule: rule, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            element.removeChildren { $0.name == "match-usage" }
            for matchUsage in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-usage")
                matchElement.addAttribute(name: "enabled", value: matchUsage.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchUsage.rule.rawValue)
                element.addChild(matchElement)
            }
        }
    }

    /// The representation matches of the smart collection (FCPXML 1.10+).
    public var matchRepresentations: [FinalCutPro.FCPXML.MatchRepresentation] {
        get {
            element.childElements
                .filter { $0.name == "match-representation" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchRepresentation? in
                    guard let typeString = matchElement.stringValue(forAttributeNamed: "type"),
                          let type = FinalCutPro.FCPXML.MatchRepresentation.RepresentationType(rawValue: typeString),
                          let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.MatchRepresentation.AvailabilityRule(rawValue: ruleString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchRepresentation(type: type, rule: rule, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            element.removeChildren { $0.name == "match-representation" }
            for matchRep in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-representation")
                matchElement.addAttribute(name: "enabled", value: matchRep.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "type", value: matchRep.type.rawValue)
                matchElement.addAttribute(name: "rule", value: matchRep.rule.rawValue)
                element.addChild(matchElement)
            }
        }
    }

    /// The markers matches of the smart collection (FCPXML 1.10+).
    public var matchMarkers: [FinalCutPro.FCPXML.MatchMarkers] {
        get {
            element.childElements
                .filter { $0.name == "match-markers" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchMarkers? in
                    guard let typeString = matchElement.stringValue(forAttributeNamed: "type"),
                          let type = FinalCutPro.FCPXML.MatchMarkers.MarkersType(rawValue: typeString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchMarkers(type: type, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            element.removeChildren { $0.name == "match-markers" }
            for matchMarkersItem in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-markers")
                matchElement.addAttribute(name: "enabled", value: matchMarkersItem.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "type", value: matchMarkersItem.type.rawValue)
                element.addChild(matchElement)
            }
        }
    }

    /// The analysis type matches of the smart collection (FCPXML 1.14).
    public var matchAnalysisTypes: [FinalCutPro.FCPXML.MatchAnalysisType] {
        get {
            element.childElements
                .filter { $0.name == "match-analysis-type" }
                .compactMap { matchElement -> FinalCutPro.FCPXML.MatchAnalysisType? in
                    guard let ruleString = matchElement.stringValue(forAttributeNamed: "rule"),
                          let rule = FinalCutPro.FCPXML.MatchAnalysisType.AvailabilityRule(rawValue: ruleString),
                          let valueString = matchElement.stringValue(forAttributeNamed: "value"),
                          let value = FinalCutPro.FCPXML.MatchAnalysisType.Value(rawValue: valueString) else {
                        return nil
                    }
                    let enabledString = matchElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    return FinalCutPro.FCPXML.MatchAnalysisType(rule: rule, value: value, isEnabled: isEnabled)
                }
        }
        nonmutating set {
            element.removeChildren { $0.name == "match-analysis-type" }
            for matchAnalysis in newValue {
                let matchElement = PNXMLDefaultFactory().makeElement(name: "match-analysis-type")
                matchElement.addAttribute(name: "enabled", value: matchAnalysis.isEnabled ? "1" : "0")
                matchElement.addAttribute(name: "rule", value: matchAnalysis.rule.rawValue)
                matchElement.addAttribute(name: "value", value: matchAnalysis.value.rawValue)
                element.addChild(matchElement)
            }
        }
    }
}

// MARK: - Parameterized Initializer

extension FinalCutPro.FCPXML.SmartCollection {
    /// Initializes a new smart collection.
    /// - Parameters:
    ///   - name: The name of the smart collection.
    ///   - match: The match criteria to apply to the smart collection (default: `.all`).
    public init(name: String, match: MatchCriteria = .all) {
        self.init()
        self.name = name
        self.match = match
    }
}

// MARK: - Typing

extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/SmartCollection`` model object.
    /// Call this on a `smart-collection` element only.
    public var fcpAsSmartCollection: FinalCutPro.FCPXML.SmartCollection? {
        .init(element: self)
    }
}
