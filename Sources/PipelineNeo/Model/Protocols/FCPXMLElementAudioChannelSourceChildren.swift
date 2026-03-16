//
//  FCPXMLElementAudioChannelSourceChildren.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for elements with audio-channel-source children.
//

import Foundation
import SwiftExtensions
import SwiftTimecode

public protocol FCPXMLElementAudioChannelSourceChildren: FCPXMLElement {
    /// Child `audio-channel-source` elements.
    var audioChannelSources: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.AudioChannelSource> { get nonmutating set }
}

extension FCPXMLElementAudioChannelSourceChildren {
    public var audioChannelSources: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.AudioChannelSource> {
        get { element.fcpAudioChannelSources }
        nonmutating set { element.fcpAudioChannelSources = newValue }
    }
}

extension PNXMLElement {
    /// FCPXML: Returns child `audio-channel-source` elements.
    /// Use on `clip` or `asset-clip` elements.
    public var fcpAudioChannelSources: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.AudioChannelSource> {
        get { children(whereFCPElement: .audioChannelSource) }
        set { _updateChildElements(ofType: .audioChannelSource, with: newValue) }
    }
}
