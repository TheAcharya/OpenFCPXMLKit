//
//  FCPXMLAdjustmentRollingShutter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Rolling shutter adjustment model (intrinsic video).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Rolling shutter correction adjustment. DTD: `adjust-rollingShutter` EMPTY; attributes `enabled`, `amount`.
    public struct RollingShutterAdjustment: Sendable, Equatable, Hashable, Codable {
        /// Amount of rolling shutter correction. DTD: (none | low | medium | high | extraHigh) "none".
        public enum Amount: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
            case none
            case low
            case medium
            case high
            case extraHigh
        }

        /// Whether the adjustment is enabled. DTD: (0 | 1) "1".
        public var isEnabled: Bool

        /// Correction amount.
        public var amount: Amount

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case amount
        }

        public init(isEnabled: Bool = true, amount: Amount = .none) {
            self.isEnabled = isEnabled
            self.amount = amount
        }
    }
}
