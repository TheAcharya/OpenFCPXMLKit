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
        
        public enum Kind: Sendable, Equatable {
            case filterVideo
            case filterAudio
            case volume
            case implicitVolume
            case transform
            case compositing
            case spatialConform
        }
        
        public enum Settings: Sendable, Equatable {
            case empty
            case text(String)
            case decibels(Double)
            case opacityPercent(Double)
            case conformType(String)
            case transformCenter(Point)
            case transformRotation(Double)
            case transformScale(Point)
        }
    }
}
