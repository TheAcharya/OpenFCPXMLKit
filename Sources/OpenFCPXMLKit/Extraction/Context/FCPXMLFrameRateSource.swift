//
//  FCPXMLFrameRateSource.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Frame rate source enum for extracted elements.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Frame rate source for an extracted element.
    public enum FrameRateSource {
        /// Derive frame rate from main timeline.
        case mainTimeline
        
        /// Derive frame rate from the element's local timeline or closest parent timeline.
        case localToElement
        
        /// Provide an arbitrary frame rate to use.
        ///
        /// This is generally not recommended unless conversion to a different frame rate than the
        /// one used is desired.
        case rate(_ rate: TimecodeFrameRate)
    }
}

extension FinalCutPro.FCPXML.FrameRateSource: Sendable { }
