//
//  FCPXMLElementAudioRoleSourceChildren.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with audio-role-source children.
//

import Foundation
import SwiftExtensions
import SwiftTimecode

public protocol FCPXMLElementAudioRoleSourceChildren: FCPXMLElement {
    /// Child `audio-role-source` elements.
    var audioRoleSources: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.AudioRoleSource> { get nonmutating set }
}

extension FCPXMLElementAudioRoleSourceChildren {
    public var audioRoleSources: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.AudioRoleSource> {
        get { element.fcpAudioRoleSources }
        nonmutating set { element.fcpAudioRoleSources = newValue }
    }
}

extension OFKXMLElement {
    /// FCPXML: Returns child `audio-role-source` elements.
    /// Use on `ref-clip`, `sync-source`, or `mc-source` elements.
    public var fcpAudioRoleSources: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.AudioRoleSource> {
        get { children(whereFCPElement: .audioRoleSource) }
        set { _updateChildElements(ofType: .audioRoleSource, with: newValue) }
    }
}
