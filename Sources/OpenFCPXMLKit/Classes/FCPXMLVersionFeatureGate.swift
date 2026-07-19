//
//  FCPXMLVersionFeatureGate.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	First-class DTD-derived version gates for elements and attributes.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Shared registry of FCPXML features gated by document version.
    ///
    /// Derived from public DTD introductions (clean-room). Used by:
    /// - Detached ``Authoring`` omit-on-write via ``VersionAvailability``
    /// - ``FCPXMLVersionConverter`` fallback stripping when a DTD allowlist is unavailable
    ///
    /// Prefer DTD allowlist stripping when embedded/bundle DTDs are present; this registry
    /// is the explicit per-feature API and the converter fallback source of truth.
    public enum VersionFeatureGate {
        /// Element name and the versions that may include it.
        public struct ElementFeature: Sendable, Hashable, Equatable {
            public var name: String
            public var availability: VersionAvailability

            public init(name: String, availability: VersionAvailability) {
                self.name = name
                self.availability = availability
            }
        }

        /// Attribute on a named element and the versions that may include it.
        public struct AttributeFeature: Sendable, Hashable, Equatable {
            public var element: String
            public var attribute: String
            public var availability: VersionAvailability

            public init(element: String, attribute: String, availability: VersionAvailability) {
                self.element = element
                self.attribute = attribute
                self.availability = availability
            }
        }

        /// Elements introduced after FCPXML 1.5 (omit when encoding/converting older).
        public static let elements: [ElementFeature] = [
            .init(name: "match-usage", availability: .from(.v1_9)),
            .init(name: "object-tracker", availability: .from(.v1_10)),
            .init(name: "adjust-cinematic", availability: .from(.v1_10)),
            .init(name: "match-representation", availability: .from(.v1_10)),
            .init(name: "match-markers", availability: .from(.v1_10)),
            .init(name: "adjust-colorConform", availability: .from(.v1_11)),
            .init(name: "adjust-voiceIsolation", availability: .from(.v1_11)),
            .init(name: "live-drawing", availability: .from(.v1_11)),
            .init(name: "adjust-stereo-3D", availability: .from(.v1_13)),
            .init(name: "hidden-clip-marker", availability: .from(.v1_13)),
            .init(name: "match-analysis-type", availability: .from(.v1_14)),
        ]

        /// Attributes introduced after FCPXML 1.5.
        public static let attributes: [AttributeFeature] = [
            .init(element: "param", attribute: "auxValue", availability: .from(.v1_11)),
            .init(element: "keyframe", attribute: "auxValue", availability: .from(.v1_11)),
            .init(element: "format", attribute: "heroEye", availability: .from(.v1_13)),
            .init(element: "asset", attribute: "heroEyeOverride", availability: .from(.v1_13)),
        ]

        /// Availability for a known element name, or ``VersionAvailability/always`` if unlisted.
        public static func availability(forElement name: String) -> VersionAvailability {
            elements.first { $0.name == name }?.availability ?? .always
        }

        /// Availability for a known attribute on an element, or ``VersionAvailability/always``.
        public static func availability(
            forAttribute attribute: String,
            onElement element: String
        ) -> VersionAvailability {
            attributes.first {
                $0.element == element && $0.attribute == attribute
            }?.availability ?? .always
        }

        /// Element names that must be omitted at `version`.
        public static func elementNamesToOmit(at version: FCPXMLVersion) -> Set<String> {
            Set(
                elements
                    .filter { !$0.availability.contains(version) }
                    .map(\.name)
            )
        }

        /// Attribute names to omit on `element` at `version`.
        public static func attributeNamesToOmit(
            onElement element: String,
            at version: FCPXMLVersion
        ) -> Set<String> {
            Set(
                attributes
                    .filter { $0.element == element && !$0.availability.contains(version) }
                    .map(\.attribute)
            )
        }
    }
}
