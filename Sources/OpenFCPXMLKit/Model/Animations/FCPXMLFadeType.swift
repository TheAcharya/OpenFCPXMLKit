//
//  FCPXMLFadeType.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Fade type enum for fade in/out effects.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Specifies the fade type for a fade in or fade out effect.
    public enum FadeType: String, Sendable, Equatable, Hashable, Codable {
        case linear
        case easeIn
        case easeOut
        case easeInOut
    }
}
