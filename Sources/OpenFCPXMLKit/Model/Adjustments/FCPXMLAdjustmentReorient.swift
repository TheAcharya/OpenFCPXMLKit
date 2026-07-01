//
//  FCPXMLAdjustmentReorient.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Reorient adjustment model (FCPXML 1.7+). Backward compatible with 1.5 (omit when version < 1.7).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A reorient adjustment for 360° or spatial video (tilt, pan, roll, convergence).
    ///
    /// FCPXML 1.7+; backward compatible with 1.5 (omit when version < 1.7).
    public struct ReorientAdjustment: Sendable, Equatable, Hashable, Codable {
        public var isEnabled: Bool
        public var tilt: String
        public var pan: String
        public var roll: String
        public var convergence: String
        public var parameters: [FilterParameter]

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case tilt, pan, roll, convergence
            case parameters = "param"
        }

        public init(
            isEnabled: Bool = true,
            tilt: String = "0",
            pan: String = "0",
            roll: String = "0",
            convergence: String = "0",
            parameters: [FilterParameter] = []
        ) {
            self.isEnabled = isEnabled
            self.tilt = tilt
            self.pan = pan
            self.roll = roll
            self.convergence = convergence
            self.parameters = parameters
        }
    }
}
