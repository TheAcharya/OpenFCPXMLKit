//
//  FCPXMLExtractionPreset.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for element extraction presets.
//

import Foundation

/// Protocol describing an element extraction preset for FCPXML.
public protocol FCPXMLExtractionPreset<Result> where Self: Sendable {
    associatedtype Result
    
    func perform(
        on extractable: any OFKXMLElement,
        scope: FinalCutPro.FCPXML.ExtractionScope
    ) async -> Result
}
