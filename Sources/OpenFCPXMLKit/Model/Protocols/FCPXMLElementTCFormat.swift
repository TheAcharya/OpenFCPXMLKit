//
//  FCPXMLElementTCFormat.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with optional timecode format attribute.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementOptionalTCFormat: FCPXMLElement {
    /// Local timeline timecode format.
    var tcFormat: FinalCutPro.FCPXML.TimecodeFormat? { get nonmutating set }
}

extension FCPXMLElementOptionalTCFormat {
    public var tcFormat: FinalCutPro.FCPXML.TimecodeFormat? {
        get { element.fcpTCFormat }
        nonmutating set { element.fcpTCFormat = newValue }
    }
}
