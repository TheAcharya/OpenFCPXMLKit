//
//  FCPXMLClipSourceEnable.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Clip source enable attribute enum (all, audio, video).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Clip source enable value. (Used with `asset-clip` and `mc-clip`)
    public enum ClipSourceEnable: String, Equatable, Hashable, CaseIterable, Sendable {
        /// Audio and Video.
        case all
        
        /// Audio source.
        case audio
        
        /// Video source.
        case video
    }
}

extension FinalCutPro.FCPXML.ClipSourceEnable: FCPXMLAttribute {
    public static let attributeName: String = "srcEnable"
}

extension PNXMLElement {
    /// FCPXML: Returns value for attribute `srcEnable`. (Default: `.all`)
    /// Call on a `asset-clip` or `mc-clip` element only.
    public var fcpClipSourceEnable: FinalCutPro.FCPXML.ClipSourceEnable {
        get {
            let defaultValue: FinalCutPro.FCPXML.ClipSourceEnable = .all

            guard let value = stringValue(forAttributeNamed: FinalCutPro.FCPXML.ClipSourceEnable.attributeName)
            else { return defaultValue }

            return FinalCutPro.FCPXML.ClipSourceEnable(rawValue: value) ?? defaultValue
        }
        set {
            addAttribute(name: FinalCutPro.FCPXML.ClipSourceEnable.attributeName,
                         value: newValue.rawValue)
        }
    }
}
