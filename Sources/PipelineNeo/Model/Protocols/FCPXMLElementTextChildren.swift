//
//  FCPXMLElementTextChildren.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with text children.
//

import Foundation
import SwiftExtensions
import SwiftTimecode

public protocol FCPXMLElementTextChildren: FCPXMLElement {
    /// Child `text` elements.
    var texts: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Text> { get nonmutating set }
}

extension FCPXMLElementTextChildren {
    public var texts: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Text> {
        get { element.fcpTexts }
        nonmutating set { element.fcpTexts = newValue }
    }
}

extension PNXMLElement {
    /// FCPXML: Returns child `text` elements.
    public var fcpTexts: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Text> {
        get { children(whereFCPElement: .text) }
        set { _updateChildElements(ofType: .text, with: newValue) }
    }
}
