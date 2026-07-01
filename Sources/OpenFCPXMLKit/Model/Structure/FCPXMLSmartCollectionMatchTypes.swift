//
//  FCPXMLSmartCollectionMatchTypes.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Match type models for smart collection criteria.
//

import Foundation

extension FinalCutPro.FCPXML {
    // MARK: - Match Text
    
    /// A text match criterion for a smart collection.
    public struct MatchText: Sendable, Equatable, Hashable, Codable {
        /// A Boolean value indicating whether the text match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the text match.
        public var rule: SmartCollectionRule
        
        /// The text value to match.
        public var value: String
        
        /// The scope of the text match (all, notes, names, markers).
        public var scope: String?
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case rule, value, scope
        }
        
        /// Initializes a new text match.
        /// - Parameters:
        ///   - rule: The rule to use for the text match (default: `.includes`).
        ///   - value: The text value to match.
        ///   - scope: The scope of the text match (default: `nil` for "all").
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .includes, value: String, scope: String? = nil, isEnabled: Bool = true) {
            self.rule = rule
            self.value = value
            self.scope = scope
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Match Ratings
    
    /// A ratings match criterion for a smart collection.
    public struct MatchRatings: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible ratings values to match.
        public enum Value: String, Sendable, Equatable, Hashable, Codable {
            case favorites
            case rejected
        }
        
        /// A Boolean value indicating whether the ratings match is enabled.
        public var isEnabled: Bool
        
        /// The ratings value to match.
        public var value: Value
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case value
        }
        
        /// Initializes a new ratings match.
        /// - Parameters:
        ///   - value: The ratings value to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(value: Value, isEnabled: Bool = true) {
            self.value = value
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Match Media
    
    /// A media match criterion for a smart collection.
    public struct MatchMedia: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible media types to match.
        public enum MediaType: String, Sendable, Equatable, Hashable, Codable {
            case videoWithAudio
            case videoOnly
            case audioOnly
            case stills
        }
        
        /// A Boolean value indicating whether the media match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the media match.
        public var rule: SmartCollectionRule
        
        /// The media type to match.
        public var type: MediaType
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case rule, type
        }
        
        /// Initializes a new media match.
        /// - Parameters:
        ///   - rule: The rule to use for the media match (default: `.isExactly`).
        ///   - type: The media type to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .isExactly, type: MediaType, isEnabled: Bool = true) {
            self.rule = rule
            self.type = type
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Match Clip
    
    /// A clip match criterion for a smart collection.
    public struct MatchClip: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible item types to match.
        public enum ItemType: String, Sendable, Equatable, Hashable, Codable {
            case audition
            case synchronized
            case compound
            case multicam
            case layeredGraphic
            case project
        }
        
        /// A Boolean value indicating whether the clip match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the clip match.
        public var rule: SmartCollectionRule
        
        /// The item type to match.
        public var type: ItemType
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case rule, type
        }
        
        /// Initializes a new clip match.
        /// - Parameters:
        ///   - rule: The rule to use for the clip match (default: `.isExactly`).
        ///   - type: The item type to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .isExactly, type: ItemType, isEnabled: Bool = true) {
            self.rule = rule
            self.type = type
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Match Property
    
    /// A property match criterion for a smart collection.
    public struct MatchProperty: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible property keys to match.
        public enum PropertyKey: String, Sendable, Equatable, Hashable, Codable {
            case reel
            case scene
            case take
            case audioOutputChannels
            case frameSize
            case videoFrameRate
            case audioSampleRate
            case cameraName
            case cameraAngle
        }
        
        /// A Boolean value indicating whether the property match is enabled.
        public var isEnabled: Bool
        
        /// The property key to match.
        public var key: PropertyKey
        
        /// The rule to use for the property match.
        public var rule: SmartCollectionRule
        
        /// The property value to match.
        public var value: String
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case key, rule, value
        }
        
        /// Initializes a new property match.
        /// - Parameters:
        ///   - key: The property key to match.
        ///   - rule: The rule to use for the property match (default: `.includes`).
        ///   - value: The property value to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(key: PropertyKey, rule: SmartCollectionRule = .includes, value: String, isEnabled: Bool = true) {
            self.key = key
            self.rule = rule
            self.value = value
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Match Time
    
    /// A time match criterion for a smart collection.
    public struct MatchTime: Sendable, Equatable, Hashable, Codable {
        /// Specifies the type of time match.
        public enum TimeMatchType: String, Sendable, Equatable, Hashable, Codable {
            case contentCreated
            case dateImported
        }
        
        /// A Boolean value indicating whether the time match is enabled.
        public var isEnabled: Bool
        
        /// The type of the time match.
        public var type: TimeMatchType
        
        /// The rule to use for the time match.
        public var rule: SmartCollectionRule
        
        /// The time value to match.
        public var value: String
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case type, rule, value
        }
        
        /// Initializes a new time match.
        /// - Parameters:
        ///   - type: The type of the time match.
        ///   - rule: The rule to use for the time match.
        ///   - value: The time value to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(type: TimeMatchType, rule: SmartCollectionRule, value: String, isEnabled: Bool = true) {
            self.type = type
            self.rule = rule
            self.value = value
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Match Time Range
    
    /// A time range match criterion for a smart collection.
    public struct MatchTimeRange: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible units for a time range match.
        public enum Unit: String, Sendable, Equatable, Hashable, Codable {
            case hour
            case day
            case week
            case month
            case year
        }
        
        /// A Boolean value indicating whether the time range match is enabled.
        public var isEnabled: Bool
        
        /// The type of the time range match.
        public var type: MatchTime.TimeMatchType
        
        /// The rule to use for the time range match.
        public var rule: SmartCollectionRule
        
        /// The time range value to match.
        public var value: String
        
        /// The unit to use for the time range match.
        public var units: Unit?
        
        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case type, rule, value, units
        }
        
        /// Initializes a new time range match.
        /// - Parameters:
        ///   - type: The type of the time range match.
        ///   - rule: The rule to use for the time range match.
        ///   - value: The time range value to match.
        ///   - units: The unit to use for the time range match (default: `nil`).
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(type: MatchTime.TimeMatchType, rule: SmartCollectionRule, value: String, units: Unit? = nil, isEnabled: Bool = true) {
            self.type = type
            self.rule = rule
            self.value = value
            self.units = units
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Match Usage (FCPXML 1.9+)

    /// A usage match criterion for a smart collection (used vs unused in project).
    /// FCPXML 1.9+; backward compatible with 1.5 (omit when version < 1.9).
    public struct MatchUsage: Sendable, Equatable, Hashable, Codable {
        /// Rule for usage match: used or unused in project.
        public enum Rule: String, Sendable, Equatable, Hashable, Codable {
            case used
            case unused
        }

        public var isEnabled: Bool
        public var rule: Rule

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case rule
        }

        public init(rule: Rule = .used, isEnabled: Bool = true) {
            self.rule = rule
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Match Representation (FCPXML 1.10+)

    /// A representation type match (original, optimized, proxy) and availability.
    /// FCPXML 1.10+; backward compatible with 1.5 (omit when version < 1.10).
    public struct MatchRepresentation: Sendable, Equatable, Hashable, Codable {
        /// Media representation type.
        public enum RepresentationType: String, Sendable, Equatable, Hashable, Codable {
            case original
            case optimized
            case proxy
        }

        /// Availability rule: isAvailable | isMissing.
        public enum AvailabilityRule: String, Sendable, Equatable, Hashable, Codable {
            case isAvailable
            case isMissing
        }

        public var isEnabled: Bool
        public var type: RepresentationType
        public var rule: AvailabilityRule

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case type, rule
        }

        public init(type: RepresentationType, rule: AvailabilityRule = .isAvailable, isEnabled: Bool = true) {
            self.type = type
            self.rule = rule
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Match Markers (FCPXML 1.10+)

    /// A markers match criterion (all, standard, todo state, etc.).
    /// FCPXML 1.10+; backward compatible with 1.5 (omit when version < 1.10).
    public struct MatchMarkers: Sendable, Equatable, Hashable, Codable {
        /// Markers match type.
        public enum MarkersType: String, Sendable, Equatable, Hashable, Codable {
            case all
            case standard
            case allTodo
            case complete
            case incomplete
        }

        public var isEnabled: Bool
        public var type: MarkersType

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case type
        }

        public init(type: MarkersType = .all, isEnabled: Bool = true) {
            self.type = type
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Match Analysis Type (FCPXML 1.14)

    /// An analysis type match (transcript, visual availability).
    /// FCPXML 1.14+; backward compatible with 1.5 (omit when version < 1.14).
    public struct MatchAnalysisType: Sendable, Equatable, Hashable, Codable {
        /// Availability rule: isAvailable | isMissing.
        public enum AvailabilityRule: String, Sendable, Equatable, Hashable, Codable {
            case isAvailable
            case isMissing
        }

        /// Analysis type value: any | transcript | visual.
        public enum Value: String, Sendable, Equatable, Hashable, Codable {
            case any
            case transcript
            case visual
        }

        public var isEnabled: Bool
        public var rule: AvailabilityRule
        public var value: Value

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case rule, value
        }

        public init(rule: AvailabilityRule = .isAvailable, value: Value = .any, isEnabled: Bool = true) {
            self.rule = rule
            self.value = value
            self.isEnabled = isEnabled
        }
    }
}
