//
//  FCPXMLAdjustmentStereo3D.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Stereo 3D adjustment model (FCPXML 1.13+). Backward compatible with 1.5 (omit when version < 1.13).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A stereo 3D adjustment (convergence, autoScale, swapEyes, depth).
    ///
    /// FCPXML 1.13+; backward compatible with 1.5 (omit when version < 1.13).
    public struct Stereo3DAdjustment: Sendable, Equatable, Hashable, Codable {
        public var isEnabled: Bool
        public var convergence: String
        public var autoScale: Bool
        public var swapEyes: Bool
        public var depth: String
        public var parameters: [FilterParameter]

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case convergence, autoScale, swapEyes, depth
            case parameters = "param"
        }

        public init(
            isEnabled: Bool = true,
            convergence: String = "0",
            autoScale: Bool = true,
            swapEyes: Bool = false,
            depth: String = "0",
            parameters: [FilterParameter] = []
        ) {
            self.isEnabled = isEnabled
            self.convergence = convergence
            self.autoScale = autoScale
            self.swapEyes = swapEyes
            self.depth = depth
            self.parameters = parameters
        }
    }
}
