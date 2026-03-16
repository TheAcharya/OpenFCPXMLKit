//
//  ValidationError.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	FCPXML validation error and warning types.
//

import Foundation

/// A validation error for an FCPXML document or timeline.
@available(macOS 12.0, *)
public struct ValidationError: Sendable, Equatable, Hashable {

    /// Kind of validation error.
    public let type: ErrorType

    /// Human-readable description.
    public let message: String

    /// Optional context (e.g. clip id, asset id).
    public let context: [String: String]

    public init(type: ErrorType, message: String, context: [String: String] = [:]) {
        self.type = type
        self.message = message
        self.context = context
    }

    /// Validation error kinds.
    public enum ErrorType: String, Sendable, Equatable, Hashable {
        case missingAssetReference = "missing_asset_reference"
        case invalidTimeValue = "invalid_time_value"
        case invalidDuration = "invalid_duration"
        case invalidLane = "invalid_lane"
        case missingRequiredElement = "missing_required_element"
        case invalidAttributeValue = "invalid_attribute_value"
        case emptyTimeline = "empty_timeline"
        case invalidFormat = "invalid_format"
        case dtdValidation = "dtd_validation"
        case unknownElementName = "unknown_element_name"
    }
}

/// A validation warning for an FCPXML document or timeline.
@available(macOS 12.0, *)
public struct ValidationWarning: Sendable, Equatable, Hashable {

    /// Kind of warning.
    public let type: WarningType

    /// Human-readable description.
    public let message: String

    /// Optional context.
    public let context: [String: String]

    public init(type: WarningType, message: String, context: [String: String] = [:]) {
        self.type = type
        self.message = message
        self.context = context
    }

    /// Validation warning kinds.
    public enum WarningType: String, Sendable, Equatable, Hashable {
        case overlappingClipsOnSameLane = "overlapping_clips_same_lane"
        case unusedAsset = "unused_asset"
        case largeTimeline = "large_timeline"
        case missingMetadata = "missing_metadata"
        case negativeTimeAttribute = "negative_time_attribute"
        case structuralValidationOnly = "structural_validation_only"
    }
}
