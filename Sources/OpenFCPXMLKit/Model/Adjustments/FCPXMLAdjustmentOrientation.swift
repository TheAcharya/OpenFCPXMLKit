//
//  FCPXMLAdjustmentOrientation.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Orientation adjustment model (FCPXML 1.7+). Backward compatible with 1.5 (omit when version < 1.7).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// An orientation adjustment for 360° or spatial video (tilt, pan, roll, field of view, mapping).
    ///
    /// FCPXML 1.7+; backward compatible with 1.5 (omit when version < 1.7).
    public struct OrientationAdjustment: Sendable, Equatable, Hashable, Codable {
        public enum Mapping: String, Sendable, Equatable, Hashable, Codable {
            case normal
            case tinyPlanet
        }

        public var isEnabled: Bool
        public var tilt: String
        public var pan: String
        public var roll: String
        public var fieldOfView: String?
        public var mapping: Mapping
        public var parameters: [FilterParameter]

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case tilt, pan, roll, fieldOfView, mapping
            case parameters = "param"
        }

        public init(
            isEnabled: Bool = true,
            tilt: String = "0",
            pan: String = "0",
            roll: String = "0",
            fieldOfView: String? = nil,
            mapping: Mapping = .normal,
            parameters: [FilterParameter] = []
        ) {
            self.isEnabled = isEnabled
            self.tilt = tilt
            self.pan = pan
            self.roll = roll
            self.fieldOfView = fieldOfView
            self.mapping = mapping
            self.parameters = parameters
        }
    }
}
