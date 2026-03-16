//
//  FCPXMLElementModDate.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with optional modification date.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementOptionalModDate: FCPXMLElement {
    /// Modification date.
    var modDate: String? { get nonmutating set }
}

extension FCPXMLElementOptionalModDate {
    public var modDate: String? {
        get { element.stringValue(forAttributeNamed: "modDate") }
        nonmutating set { element.addAttribute(name: "modDate", value: newValue) }
    }
}
