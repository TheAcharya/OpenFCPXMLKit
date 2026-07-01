//
//  FCPXMLElementNoteChild.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with note child.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementNoteChild: FCPXMLElement {
    /// Optional note text.
    var note: String? { get nonmutating set }
}

extension FCPXMLElementNoteChild {
    public var note: String? {
        get {
            element
                .firstChildElement(whereFCPElementType: .note)?
                .stringValue
        }
        nonmutating set {
            element
                ._updateFirstChildElement(ofType: .note, newStringValue: newValue)
        }
    }
}
