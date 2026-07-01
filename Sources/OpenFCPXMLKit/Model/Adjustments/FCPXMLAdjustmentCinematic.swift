//
//  FCPXMLAdjustmentCinematic.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Cinematic adjustment model (FCPXML 1.10+). Backward compatible with 1.5 (omit when version < 1.10).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A cinematic adjustment for depth-of-field style effects (dataLocator, aperture).
    ///
    /// FCPXML 1.10+; backward compatible with 1.5 (omit when version < 1.10).
    public struct CinematicAdjustment: Sendable, Equatable, Hashable, Codable {
        public var isEnabled: Bool
        public var dataLocator: String?
        public var aperture: String?
        public var parameters: [FilterParameter]

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case dataLocator, aperture
            case parameters = "param"
        }

        public init(
            isEnabled: Bool = true,
            dataLocator: String? = nil,
            aperture: String? = nil,
            parameters: [FilterParameter] = []
        ) {
            self.isEnabled = isEnabled
            self.dataLocator = dataLocator
            self.aperture = aperture
            self.parameters = parameters
        }
    }
}
