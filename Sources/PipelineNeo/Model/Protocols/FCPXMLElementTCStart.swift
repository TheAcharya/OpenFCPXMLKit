//
//  FCPXMLElementTCStart.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with optional timecode start attribute.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementOptionalTCStart: FCPXMLElement {
    /// Local timeline origin time.
    var tcStart: Fraction? { get nonmutating set }
}

extension FCPXMLElementOptionalTCStart {
    public var tcStart: Fraction? {
        get { element.fcpTCStart }
        nonmutating set { element.fcpTCStart = newValue }
    }
    
    /// Returns the start time of the element as timecode.
    public func tcStartAsTimecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .localToElement
    ) -> Timecode? {
        element._fcpTCStartAsTimecode(
            frameRateSource: frameRateSource
        )
    }
}

// MARK: - XML Utils

extension PNXMLElement {
    func _fcpTCStartAsTimecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .localToElement
    ) -> Timecode? {
        guard let tcStart = fcpTCStart else { return nil }
        return try? _fcpTimecode(
            fromRational: tcStart,
            frameRateSource: frameRateSource
        )
    }
}
