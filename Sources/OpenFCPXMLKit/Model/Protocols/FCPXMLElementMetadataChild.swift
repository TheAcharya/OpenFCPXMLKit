//
//  FCPXMLElementMetadataChild.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with metadata child.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLElementMetadataChild: FCPXMLElement {
    /// Metadata for the element.
    var metadata: FinalCutPro.FCPXML.Metadata? { get nonmutating set }
}

extension FCPXMLElementMetadataChild {
    public var metadata: FinalCutPro.FCPXML.Metadata? {
        get { element.firstChild(whereFCPElement: .metadata) }
        nonmutating set { element._updateChildElements(ofType: .metadata, withChild: newValue) }
    }
}
