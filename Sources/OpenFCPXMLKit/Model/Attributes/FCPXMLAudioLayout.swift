//
//  FCPXMLAudioLayout.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Audio layout attribute enum (mono, stereo, surround).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// `audioLayout` attribute value.
    public enum AudioLayout: String, Equatable, Hashable, CaseIterable, Sendable {
        case mono
        case stereo
        case surround
    }
}

extension FinalCutPro.FCPXML.AudioLayout: FCPXMLAttribute {
    public static let attributeName: String = "audioLayout"
}
