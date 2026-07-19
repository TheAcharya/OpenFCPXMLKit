//
//  FCPXMLAdjustmentPanner.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Panner adjustment model (adjust-panner) for audio spatial positioning.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Audio panner / surround positioning adjustment.
    ///
    /// Corresponds to the FCPXML ``adjust-panner`` element (intrinsic audio parameters
    /// alongside ``adjust-volume``). Attribute names follow the DTD exactly, including
    /// mixed-case identifiers such as `LFE_balance`.
    ///
    /// Optional nested ``param`` children are preserved for forward compatibility.
    public struct PannerAdjustment: Sendable, Equatable, Hashable, Codable {
        /// Panner mode string when present (DTD `mode`).
        public var mode: String?

        /// Primary amount (DTD `amount`; default `0`).
        public var amount: Double

        /// Original vs decoded mix (DTD `original_decoded_mix`).
        public var originalDecodedMix: Double?

        /// Ambient vs direct mix (DTD `ambient_direct_mix`).
        public var ambientDirectMix: Double?

        /// Surround width (DTD `surround_width`).
        public var surroundWidth: Double?

        /// Left/right mix (DTD `left_right_mix`).
        public var leftRightMix: Double?

        /// Front/back mix (DTD `front_back_mix`).
        public var frontBackMix: Double?

        /// LFE balance (DTD `LFE_balance`).
        public var lfeBalance: Double?

        /// Rotation (DTD `rotation`).
        public var rotation: Double?

        /// Stereo spread (DTD `stereo_spread`).
        public var stereoSpread: Double?

        /// Attenuate/collapse mix (DTD `attenuate_collapse_mix`).
        public var attenuateCollapseMix: Double?

        /// Center balance (DTD `center_balance`).
        public var centerBalance: Double?

        /// Nested filter-style parameters, if present.
        public var parameters: [FilterParameter]

        /// Creates a panner adjustment.
        /// - Parameters:
        ///   - mode: Optional mode string.
        ///   - amount: Primary amount (default `0`).
        ///   - originalDecodedMix: Optional original/decoded mix.
        ///   - ambientDirectMix: Optional ambient/direct mix.
        ///   - surroundWidth: Optional surround width.
        ///   - leftRightMix: Optional left/right mix.
        ///   - frontBackMix: Optional front/back mix.
        ///   - lfeBalance: Optional LFE balance.
        ///   - rotation: Optional rotation.
        ///   - stereoSpread: Optional stereo spread.
        ///   - attenuateCollapseMix: Optional attenuate/collapse mix.
        ///   - centerBalance: Optional center balance.
        ///   - parameters: Nested `param` children (default empty).
        public init(
            mode: String? = nil,
            amount: Double = 0,
            originalDecodedMix: Double? = nil,
            ambientDirectMix: Double? = nil,
            surroundWidth: Double? = nil,
            leftRightMix: Double? = nil,
            frontBackMix: Double? = nil,
            lfeBalance: Double? = nil,
            rotation: Double? = nil,
            stereoSpread: Double? = nil,
            attenuateCollapseMix: Double? = nil,
            centerBalance: Double? = nil,
            parameters: [FilterParameter] = []
        ) {
            self.mode = mode
            self.amount = amount
            self.originalDecodedMix = originalDecodedMix
            self.ambientDirectMix = ambientDirectMix
            self.surroundWidth = surroundWidth
            self.leftRightMix = leftRightMix
            self.frontBackMix = frontBackMix
            self.lfeBalance = lfeBalance
            self.rotation = rotation
            self.stereoSpread = stereoSpread
            self.attenuateCollapseMix = attenuateCollapseMix
            self.centerBalance = centerBalance
            self.parameters = parameters
        }
    }
}
