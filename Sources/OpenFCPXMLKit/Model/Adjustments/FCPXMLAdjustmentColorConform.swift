//
//  FCPXMLAdjustmentColorConform.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Color conform adjustment model (FCPXML 1.11+). Backward compatible with 1.5 (omit when version < 1.11).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A color conform adjustment for HDR/SDR conversion.
    ///
    /// FCPXML 1.11+; backward compatible with 1.5 (omit when version < 1.11).
    public struct ColorConformAdjustment: Sendable, Equatable, Hashable, Codable {
        public enum AutoOrManual: String, Sendable, Equatable, Hashable, Codable {
            case automatic
            case manual
        }

        public enum ConformType: String, Sendable, Equatable, Hashable, Codable {
            case conformNone
            case conformAuto
            case conformHLGtoSDR
            case conformPQtoSDR
            case conformHLGtoPQ
            case conformPQtoHLG
            case conformSDRtoHLG75
            case conformSDRtoHLG100
            case conformSDRtoPQ
        }

        public var isEnabled: Bool
        public var autoOrManual: AutoOrManual
        public var conformType: ConformType
        public var peakNitsOfPQSource: String
        public var peakNitsOfSDRToPQSource: String

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case autoOrManual
            case conformType
            case peakNitsOfPQSource
            case peakNitsOfSDRToPQSource
        }

        public init(
            isEnabled: Bool = true,
            autoOrManual: AutoOrManual = .automatic,
            conformType: ConformType = .conformNone,
            peakNitsOfPQSource: String,
            peakNitsOfSDRToPQSource: String
        ) {
            self.isEnabled = isEnabled
            self.autoOrManual = autoOrManual
            self.conformType = conformType
            self.peakNitsOfPQSource = peakNitsOfPQSource
            self.peakNitsOfSDRToPQSource = peakNitsOfSDRToPQSource
        }
    }
}
