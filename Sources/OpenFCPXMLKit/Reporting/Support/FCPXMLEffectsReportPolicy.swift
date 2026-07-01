//
//  FCPXMLEffectsReportPolicy.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Inclusion rules for the Video & Audio Effects report.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Policy for which extracted effects appear on the effects sheet.
    enum EffectsReportPolicy {
        static func shouldInclude(_ effect: ExtractedEffect) -> Bool {
            guard effect.kind == .filterVideo else { return true }
            
            // Exclude video filters on hosts that are effectively occluded.
            return effect.host.value(forContext: .effectiveOcclusion) == .notOccluded
        }
    }
}
