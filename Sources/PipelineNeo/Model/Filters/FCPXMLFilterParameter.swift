//
//  FCPXMLFilterParameter.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Parameter model for effect and filter parameters.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A parameter for an effect or filter.
    ///
    /// Parameters can contain nested parameters, values, fade in/out effects, and keyframe animations.
    public struct FilterParameter: Sendable, Equatable, Hashable, Codable {
        /// The name of the parameter.
        public var name: String
        
        /// The key of the parameter.
        public var key: String?
        
        /// The value of the parameter.
        public var value: String?
        
        /// Auxiliary value. FCPXML 1.11+; backward compatible with 1.5 (omit when version < 1.11).
        public var auxValue: String?
        
        /// A Boolean value indicating whether the parameter is enabled.
        public var isEnabled: Bool
        
        /// The fade in effect for the parameter.
        public var fadeIn: FadeIn?
        
        /// The fade out effect for the parameter.
        public var fadeOut: FadeOut?
        
        /// The keyframe animation for the parameter.
        public var keyframeAnimation: KeyframeAnimation?
        
        /// The child parameters of the parameter.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case name, key, value, auxValue
            case isEnabled = "enabled"
            case fadeIn
            case fadeOut
            case keyframeAnimation
            case parameters = "param"
        }
        
        /// Initializes a new parameter.
        /// - Parameters:
        ///   - name: The name of the parameter.
        ///   - key: The key of the parameter (default: `nil`).
        ///   - value: The value of the parameter (default: `nil`).
        ///   - auxValue: The auxiliary value (FCPXML 1.11+; omit for 1.5–1.10, default: `nil`).
        ///   - isEnabled: Whether the parameter is enabled (default: `true`).
        ///   - fadeIn: The fade in effect (default: `nil`).
        ///   - fadeOut: The fade out effect (default: `nil`).
        ///   - keyframeAnimation: The keyframe animation (default: `nil`).
        ///   - parameters: Child parameters (default: `[]`).
        public init(
            name: String,
            key: String? = nil,
            value: String? = nil,
            auxValue: String? = nil,
            isEnabled: Bool = true,
            fadeIn: FadeIn? = nil,
            fadeOut: FadeOut? = nil,
            keyframeAnimation: KeyframeAnimation? = nil,
            parameters: [FilterParameter] = []
        ) {
            self.name = name
            self.key = key
            self.value = value
            self.auxValue = auxValue
            self.isEnabled = isEnabled
            self.fadeIn = fadeIn
            self.fadeOut = fadeOut
            self.keyframeAnimation = keyframeAnimation
            self.parameters = parameters
        }
    }
}

// MARK: - From param element

extension FinalCutPro.FCPXML.FilterParameter {
    /// Creates a filter parameter from a `param` XML element (e.g. name, key, value, auxValue, enabled).
    /// auxValue is FCPXML 1.11+; ignored when reading 1.5 documents, omitted when writing to 1.5.
    public init?(paramElement: any PNXMLElement) {
        guard paramElement.name == "param",
              let name = paramElement.stringValue(forAttributeNamed: "name") else {
            return nil
        }
        let key = paramElement.stringValue(forAttributeNamed: "key")
        let value = paramElement.stringValue(forAttributeNamed: "value")
        let auxValue = paramElement.stringValue(forAttributeNamed: "auxValue")
        let enabledString = paramElement.stringValue(forAttributeNamed: "enabled") ?? "1"
        let isEnabled = enabledString == "1"
        self.init(
            name: name,
            key: key,
            value: value,
            auxValue: auxValue,
            isEnabled: isEnabled
        )
    }
}

extension FinalCutPro.FCPXML {
    /// Keyed data associated with filters and effects.
    ///
    /// Used for storing effect configuration and data.
    public struct KeyedData: Sendable, Equatable, Hashable, Codable {
        /// The key of the data.
        public var key: String?
        
        /// The value of the data.
        public var value: String
        
        private enum CodingKeys: String, CodingKey {
            case key
            case value = ""
        }
        
        /// Initializes a new keyed data value.
        /// - Parameters:
        ///   - key: The key of the data (default: `nil`).
        ///   - value: The value of the data.
        public init(key: String? = nil, value: String) {
            self.key = key
            self.value = value
        }
    }
}
