//
//  FCPXMLAdjustmentConform.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Conform adjustment model (fit/fill/none). DTD: The absence of adjust-conform implies "fit".
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Conform (fit/fill) adjustment. DTD: `adjust-conform` EMPTY; attribute `type` (fit | fill | none) "fit".
    public struct ConformAdjustment: Sendable, Equatable, Hashable, Codable {
        /// Conform type. DTD: (fit | fill | none) "fit".
        public enum ConformType: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
            case fit
            case fill
            case none
        }

        public var type: ConformType

        private enum CodingKeys: String, CodingKey {
            case type
        }

        public init(type: ConformType = .fit) {
            self.type = type
        }
    }
}
