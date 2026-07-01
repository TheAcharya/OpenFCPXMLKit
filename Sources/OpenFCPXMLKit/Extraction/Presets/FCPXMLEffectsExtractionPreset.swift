//
//  FCPXMLEffectsExtractionPreset.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Extraction preset for timeline clip effects.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Extracts semantic effects from timeline clip hosts visible on the main timeline.
    public struct EffectsExtractionPreset: FCPXMLExtractionPreset {
        public init() { }
        
        public func perform(
            on extractable: any OFKXMLElement,
            scope: ExtractionScope
        ) async -> [ExtractedEffect] {
            let extractedHosts = await extractable.fcpExtract(
                types: EffectsCollector.extractedEffectHostTypes,
                scope: .reportMainTimelineVisible(modifying: scope)
            )
            
            return extractedHosts.flatMap { EffectsCollector.effects(on: $0) }
        }
    }
}

extension FCPXMLExtractionPreset where Self == FinalCutPro.FCPXML.EffectsExtractionPreset {
    /// FCPXML extraction preset that extracts clip-attached effects.
    public static var effects: FinalCutPro.FCPXML.EffectsExtractionPreset {
        FinalCutPro.FCPXML.EffectsExtractionPreset()
    }
}
