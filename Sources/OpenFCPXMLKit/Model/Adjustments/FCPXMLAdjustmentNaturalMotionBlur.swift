//
//  FCPXMLAdjustmentNaturalMotionBlur.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Natural motion blur adjustment model (FCPXML 1.15+). Supported only on primitive video elements.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Natural Motion Blur on a primitive `<video>` element.
    ///
    /// FCPXML 1.15+. `amount` is 0–100 when present. When `amount` is omitted, Final Cut Pro
    /// uses the effect's default. Omit the element when writing a document older than 1.15.
    public struct NaturalMotionBlurAdjustment: Sendable, Equatable, Hashable, Codable {
        public var isEnabled: Bool
        /// Inspector amount (0–100). `nil` means the attribute was omitted.
        public var amount: String?
        public var parameters: [FilterParameter]

        private enum CodingKeys: String, CodingKey {
            case isEnabled = "enabled"
            case amount
            case parameters = "param"
        }

        public init(
            isEnabled: Bool = true,
            amount: String? = nil,
            parameters: [FilterParameter] = []
        ) {
            self.isEnabled = isEnabled
            self.amount = amount
            self.parameters = parameters
        }
    }
}
