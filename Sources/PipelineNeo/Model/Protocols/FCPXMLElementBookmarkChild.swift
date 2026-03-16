//
//  FCPXMLElementBookmarkChild.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with bookmark child.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementBookmarkChild: FCPXMLElement {
    /// Security-scoped bookmark data in a base64-encoded string.
    /// Access the `stringValue` property on the returned element.
    var bookmark: (any PNXMLElement)? { get nonmutating set }

    /// Security-scoped bookmark data.
    /// Returns the decoded ``bookmark`` base64-encoded string as `Data`.
    var bookmarkData: Data? { get nonmutating set }
}

extension FCPXMLElementBookmarkChild {
    public var bookmark: (any PNXMLElement)? {
        get {
            element.firstChildElement(named: FinalCutPro.FCPXML.ElementType.bookmark.rawValue)
        }
        nonmutating set {
            element._updateChildElements(ofType: .bookmark, withChild: newValue)
        }
    }
    
    public var bookmarkData: Data? {
        get {
            guard let value = element
                .firstChildElement(whereFCPElementType: .bookmark)?
                .stringValue
            else { return nil }
            
            return Data(base64Encoded: value)
        }
        nonmutating set {
            let v = newValue?.base64EncodedString()
            element._updateChildElement(named: "bookmark", newStringValue: v)
        }
    }
}
