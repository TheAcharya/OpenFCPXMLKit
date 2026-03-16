//
//  FCPXMLRootParsing.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Root element parsing utilities.
//

import Foundation
import SwiftExtensions
import SwiftTimecode

extension PNXMLElement {
    /// FCPXML: Returns the root-level `fcpxml` element.
    /// This may be called on any element within a FCPXML.
    ///
    /// Walks up the parent chain to find the topmost element, which should be the `fcpxml` root.
    public var fcpRoot: (any PNXMLElement)? {
        var current: any PNXMLElement = self
        while let parentEl = current.parent {
            current = parentEl
        }
        // The topmost element should be `fcpxml`
        guard current.name == "fcpxml" else { return nil }
        return current
    }
}
