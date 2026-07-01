//
//  FCPXMLElementExtensions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Extensions for FCPXMLElement protocol.
//

import Foundation
import SwiftTimecode

extension FCPXMLElement {
    /// Returns the timecode frame rate for the local timeline.
    public func localTimecodeFrameRate() -> TimecodeFrameRate? {
        // `sequence` has a `format` attribute,
        // and a tcFormat attribute determining drop or non-drop frame timecode
        element._fcpTimecodeFrameRate()
    }
}
