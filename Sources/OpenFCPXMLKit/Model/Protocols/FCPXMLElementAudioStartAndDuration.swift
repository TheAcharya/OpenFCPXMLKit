//
//  FCPXMLElementAudioStartAndDuration.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for audio start and duration attributes.
//

import Foundation
import SwiftTimecode

/// FCPXML 1.11 DTD:
///
/// Use `audioStart` and `audioDuration` attributes to define J/L cuts (i.e., split edits) on
/// composite A/V clips.
public protocol FCPXMLElementAudioStartAndDuration: FCPXMLElement {
    var audioStart: Fraction? { get nonmutating set }
    var audioDuration: Fraction? { get nonmutating set }
}

extension FCPXMLElementAudioStartAndDuration {
    public var audioStart: Fraction? {
        get { element.fcpAudioStart }
        nonmutating set { element.fcpAudioStart = newValue }
    }
    
    public var audioDuration: Fraction? {
        get { element.fcpAudioDuration }
        nonmutating set { element.fcpAudioDuration = newValue }
    }
}
