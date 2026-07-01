//
//  FCPXMLSmartCollectionMatchTypesComplex.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Complex match type models with child elements for smart collection criteria.
//

import Foundation

extension FinalCutPro.FCPXML {
    // MARK: - Keyword Name
    
    /// A keyword name used in keyword matches.
    public struct KeywordName: Sendable, Equatable, Hashable, Codable {
        /// The value of the keyword name.
        public var value: String
        
        /// Initializes a new keyword name.
        /// - Parameter value: The value of the keyword name.
        public init(value: String) {
            self.value = value
        }
    }
    
    // MARK: - Match Keywords
    
    /// A keywords match criterion for a smart collection.
    public struct MatchKeywords: Sendable, Equatable, Hashable, Codable {
        /// The keyword names to match.
        public var keywordNames: [KeywordName]
        
        /// A Boolean value indicating whether the keywords match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the keywords match.
        public var rule: SmartCollectionRule
        
        private enum CodingKeys: String, CodingKey {
            case keywordNames = "keyword-name"
            case isEnabled = "enabled"
            case rule
        }
        
        /// Initializes a new keywords match.
        /// - Parameters:
        ///   - rule: The rule to use for the keywords match (default: `.includesAny`).
        ///   - keywordNames: The keyword names to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .includesAny, keywordNames: [KeywordName], isEnabled: Bool = true) {
            self.rule = rule
            self.keywordNames = keywordNames
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Shot Type
    
    /// A shot type used in shot type matches.
    public struct ShotType: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible shot type values.
        public enum Value: String, Sendable, Equatable, Hashable, Codable {
            case onePerson
            case twoPersons
            case group
            case closeUp
            case mediumShot
            case wideShot
        }
        
        /// The value of the shot type.
        public var value: Value
        
        /// Initializes a new shot type.
        /// - Parameter value: The value of the shot type.
        public init(value: Value) {
            self.value = value
        }
    }
    
    // MARK: - Match Shot
    
    /// A shot type match criterion for a smart collection.
    public struct MatchShot: Sendable, Equatable, Hashable, Codable {
        /// The shot types to match.
        public var shotTypes: [ShotType]
        
        /// A Boolean value indicating whether the shot type match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the shot type match.
        public var rule: SmartCollectionRule
        
        private enum CodingKeys: String, CodingKey {
            case shotTypes = "shot-type"
            case isEnabled = "enabled"
            case rule
        }
        
        /// Initializes a new shot type match.
        /// - Parameters:
        ///   - rule: The rule to use for the shot type match (default: `.includesAny`).
        ///   - shotTypes: The shot types to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .includesAny, shotTypes: [ShotType], isEnabled: Bool = true) {
            self.rule = rule
            self.shotTypes = shotTypes
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Stabilization Type
    
    /// A stabilization type used in stabilization matches.
    public struct StabilizationType: Sendable, Equatable, Hashable, Codable {
        /// Specifies the possible stabilization type values.
        public enum Value: String, Sendable, Equatable, Hashable, Codable {
            case excessiveShake
        }
        
        /// The value of the stabilization type.
        public var value: Value
        
        /// Initializes a new stabilization type.
        /// - Parameter value: The value of the stabilization type.
        public init(value: Value) {
            self.value = value
        }
    }
    
    // MARK: - Match Stabilization
    
    /// A stabilization type match criterion for a smart collection.
    public struct MatchStabilization: Sendable, Equatable, Hashable, Codable {
        /// The stabilization types to match.
        public var stabilizationTypes: [StabilizationType]
        
        /// A Boolean value indicating whether the stabilization type match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the stabilization type match.
        public var rule: SmartCollectionRule
        
        private enum CodingKeys: String, CodingKey {
            case stabilizationTypes = "stabilization-type"
            case isEnabled = "enabled"
            case rule
        }
        
        /// Initializes a new stabilization type match.
        /// - Parameters:
        ///   - rule: The rule to use for the stabilization type match (default: `.includesAny`).
        ///   - stabilizationTypes: The stabilization types to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .includesAny, stabilizationTypes: [StabilizationType], isEnabled: Bool = true) {
            self.rule = rule
            self.stabilizationTypes = stabilizationTypes
            self.isEnabled = isEnabled
        }
    }
    
    // MARK: - Role
    
    /// A role used in role matches.
    public struct Role: Sendable, Equatable, Hashable, Codable {
        /// The name of the role.
        public var name: String
        
        /// Initializes a new role.
        /// - Parameter name: The name of the role.
        public init(name: String) {
            self.name = name
        }
    }
    
    // MARK: - Match Roles
    
    /// A roles match criterion for a smart collection.
    public struct MatchRoles: Sendable, Equatable, Hashable, Codable {
        /// The roles to match.
        public var roles: [Role]
        
        /// A Boolean value indicating whether the roles match is enabled.
        public var isEnabled: Bool
        
        /// The rule to use for the roles match.
        public var rule: SmartCollectionRule
        
        private enum CodingKeys: String, CodingKey {
            case roles = "role"
            case isEnabled = "enabled"
            case rule
        }
        
        /// Initializes a new roles match.
        /// - Parameters:
        ///   - rule: The rule to use for the roles match (default: `.includesAny`).
        ///   - roles: The roles to match.
        ///   - isEnabled: Whether the match is enabled (default: `true`).
        public init(rule: SmartCollectionRule = .includesAny, roles: [Role], isEnabled: Bool = true) {
            self.rule = rule
            self.roles = roles
            self.isEnabled = isEnabled
        }
    }
}
