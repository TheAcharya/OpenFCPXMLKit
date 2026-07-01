//
//  FCPXMLAdjustmentVoiceIsolation.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Voice isolation adjustment model (FCPXML 1.14). Used in audio-channel-source / audio-role-source.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A voice isolation adjustment for audio (amount). Lives in audio-channel-source / audio-role-source.
    ///
    /// FCPXML 1.14+; backward compatible with 1.5 (omit when version < 1.14).
    public struct VoiceIsolationAdjustment: Sendable, Equatable, Hashable, Codable {
        public var amount: String

        private enum CodingKeys: String, CodingKey {
            case amount
        }

        public init(amount: String) {
            self.amount = amount
        }
    }
}
