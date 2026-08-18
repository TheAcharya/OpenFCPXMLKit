//
//  FCPXMLExtractedEffect.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Semantic effect extracted from a timeline clip host.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A single effect attached to a timeline clip host element.
    public struct ExtractedEffect: @unchecked Sendable {
        /// The clip host the effect belongs to.
        public let host: ExtractedElement
        
        /// Optional nested timeline element for volume rows (for example nested `clip`/`audio`).
        public let timelineContext: ExtractedElement?
        
        /// The XML element carrying the effect, when present.
        /// Implicit volume rows use the host element instead.
        public let effectElement: any OFKXMLElement
        
        /// Effect category.
        public let kind: Kind
        
        /// Display name (`volume`, filter name, `Transform`, etc.).
        public let name: String
        
        /// Structured settings before report formatting.
        public let settings: Settings
        
        /// Row ordering for multi-row effects (for example transform components).
        public let sortOrder: Int
        
        /// Whether the effect resource UID indicates an Apple-supplied template or FxPlug effect.
        /// Built-in adjustments default to `true`.
        public let isAppleSupplied: Bool
        
        public enum Kind: Sendable, Equatable, Hashable {
            case filterVideo
            case filterAudio
            case volume
            case implicitVolume
            case transform
            case compositing
            case spatialConform
        }
        
        /// An inspector-visible name/value pair (filter parameters, blend mode, …).
        public struct NamedValue: Sendable, Equatable, Hashable {
            public var name: String
            public var value: String
            
            public init(name: String, value: String) {
                self.name = name
                self.value = value
            }
        }
        
        public enum Settings: Sendable, Equatable, Hashable {
            case empty
            case text(String)
            case namedValues([NamedValue])
            case decibels(Double)
            /// Opacity as an FCPXML `adjust-blend` amount (`0.0`–`1.0`). Format as percent × 100.
            case opacityPercent(Double)
            case conformType(String)
            case transformCenter(Point)
            case transformRotation(Double)
            case transformScale(Point)
        }
    }
}
