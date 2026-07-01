//
//  FCPXMLSmartCollectionRule.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Rule enum for smart collection match criteria.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Enumerates the rules that can be applied when matching on various criteria in a smart collection.
    public enum SmartCollectionRule: String, Sendable, Equatable, Hashable, Codable {
        /// Does not include the specified value.
        case doesNotInclude
        
        /// Does not include all of the specified values.
        case doesNotIncludeAll
        
        /// Does not include any of the specified values.
        case doesNotIncludeAny
        
        /// Includes the specified value.
        case includes
        
        /// Includes all of the specified values.
        case includesAll
        
        /// Includes any of the specified values.
        case includesAny
        
        /// Matches if the value is after the specified time.
        case isAfter
        
        /// Matches if the value is before the specified time.
        case isBefore
        
        /// Matches if the value is exactly equal to the specified value.
        case isExactly = "is"
        
        /// Matches if the value is within the last specified time range.
        case isInLast
        
        /// Matches if the value is not within the last specified time range.
        case isNotInLast
        
        /// Matches if the value is not exactly equal to the specified value.
        case isNot = "isNot"
        
        /// Matches if the value starts with the specified text.
        case startsWith
        
        /// Matches if the value ends with the specified text.
        case endsWith
    }
}
