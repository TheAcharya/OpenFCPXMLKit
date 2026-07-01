//
//  FCPXMLTimecodeFormat.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Timecode format attribute enum (DF, NDF).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// `tcFormat` attribute value.
    public enum TimecodeFormat: String, Equatable, Hashable, CaseIterable, Sendable {
        case dropFrame = "DF"
        case nonDropFrame = "NDF"
    }
}

extension FinalCutPro.FCPXML.TimecodeFormat: FCPXMLAttribute {
    public static let attributeName: String = "tcFormat"
}

extension FinalCutPro.FCPXML.TimecodeFormat {
    /// Returns `true` if format is drop-frame.
    public var isDrop: Bool {
        switch self {
        case .dropFrame: return true
        case .nonDropFrame: return false
        }
    }
}
