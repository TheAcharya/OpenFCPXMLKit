//
//  FCPXMLElementStart.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with required start attribute.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementRequiredStart: FCPXMLElement {
    /// Local timeline start. (Required)
    var start: Fraction { get nonmutating set }
}

extension FCPXMLElementRequiredStart {
    public var start: Fraction {
        get { element.fcpStart ?? .zero }
        nonmutating set { element.fcpStart = newValue }
    }
    
    /// Returns the start time of the element as timecode.
    public func startAsTimecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .localToElement
    ) -> Timecode? {
        element._fcpStartAsTimecode(
            frameRateSource: frameRateSource,
            default: .zero
        )
    }
}

public protocol FCPXMLElementOptionalStart: FCPXMLElement {
    /// Local timeline start.
    var start: Fraction? { get nonmutating set }
}

extension FCPXMLElementOptionalStart {
    public var start: Fraction? {
        get { element.fcpStart }
        nonmutating set { element.fcpStart = newValue }
    }
    
    /// Returns the start time of the element as timecode.
    public func startAsTimecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .localToElement
    ) -> Timecode? {
        guard  start != nil else { return nil }
        return element._fcpStartAsTimecode(
            frameRateSource: frameRateSource,
            default: .zero
        )
    }
}

// MARK: - XML Utils

extension PNXMLElement {
    func _fcpStartAsTimecode(
        frameRateSource: FinalCutPro.FCPXML.FrameRateSource = .localToElement,
        default defaultStart: Fraction? = .zero
    ) -> Timecode? {
        guard let startValue = fcpStart ?? defaultStart else { return nil }
        
        return try? _fcpTimecode(
            fromRational: startValue,
            frameRateSource: frameRateSource
        )
    }
}
