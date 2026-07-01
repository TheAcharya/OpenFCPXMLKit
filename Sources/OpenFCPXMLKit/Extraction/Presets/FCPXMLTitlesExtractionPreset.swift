//
//  FCPXMLTitlesExtractionPreset.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Extraction preset for titles and generators visible on the main timeline.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Extracts title elements visible on the main timeline.
    public struct TitlesExtractionPreset: FCPXMLExtractionPreset {
        public init() { }
        
        public func perform(
            on extractable: any OFKXMLElement,
            scope: ExtractionScope
        ) async -> [ExtractedElement] {
            await extractable.fcpExtract(
                types: [.title],
                scope: .reportMainTimelineVisible(modifying: scope)
            )
        }
    }
}

extension FCPXMLExtractionPreset where Self == FinalCutPro.FCPXML.TitlesExtractionPreset {
    /// FCPXML extraction preset that extracts titles visible on the main timeline.
    public static var titles: FinalCutPro.FCPXML.TitlesExtractionPreset {
        FinalCutPro.FCPXML.TitlesExtractionPreset()
    }
}
