//
//  FCPXMLElementFrameSampling.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with frame sampling attribute.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementFrameSampling: FCPXMLElement {
    /// Frame sampling. (Default: floor)
    var frameSampling: FinalCutPro.FCPXML.FrameSampling { get nonmutating set }
}

extension FCPXMLElementFrameSampling {
    private var _frameSamplingDefault: FinalCutPro.FCPXML.FrameSampling { .floor }
    
    public var frameSampling: FinalCutPro.FCPXML.FrameSampling {
        get {
            guard let value = element.stringValue(forAttributeNamed: "frameSampling")
            else { return _frameSamplingDefault }
            
            return FinalCutPro.FCPXML.FrameSampling(rawValue: value) ?? _frameSamplingDefault
        }
        nonmutating set {
            if newValue == _frameSamplingDefault {
                // can remove attribute if value is default
                element.removeAttribute(forName: "frameSampling")
            } else {
                element.addAttribute(name: "frameSampling", value: newValue.rawValue)
            }
        }
    }
}
